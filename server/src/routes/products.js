const express = require('express');
const { z } = require('zod');
const prisma = require('../lib/prisma');
const { authRequired, roleRequired } = require('../middleware/auth');
const { validate } = require('../middleware/validate');

const router = express.Router();

// GET /products — search + filter + nearby
router.get('/', async (req, res, next) => {
  try {
    const {
      search, category, min_price, max_price, condition,
      campus_id, seller_id, lat, lng, radius_km,
      sort = 'newest', page = '1', limit = '20',
    } = req.query;

    const where = { status: 'active' };
    if (search) {
      where.OR = [
        { name: { contains: search, mode: 'insensitive' } },
        { description: { contains: search, mode: 'insensitive' } },
      ];
    }
    if (category) where.categoryId = category;
    if (condition && ['new', 'used'].includes(condition)) where.condition = condition;
    if (campus_id) where.campusId = campus_id;
    if (seller_id) where.sellerId = seller_id;
    if (min_price) where.price = { ...where.price, gte: parseInt(min_price) };
    if (max_price) where.price = { ...where.price, lte: parseInt(max_price) };

    // Nearby filter (haversine via raw query bounds sederhana)
    if (lat && lng && radius_km) {
      const r = parseFloat(radius_km);
      const latD = r / 111;
      const lngD = r / (111 * Math.cos(parseFloat(lat) * Math.PI / 180) || 1);
      where.latitude = { gte: parseFloat(lat) - latD, lte: parseFloat(lat) + latD };
      where.longitude = { gte: parseFloat(lng) - lngD, lte: parseFloat(lng) + lngD };
    }

    const orderBy = sort === 'price_asc' ? { price: 'asc' }
      : sort === 'price_desc' ? { price: 'desc' }
      : sort === 'popular' ? { favorites: { _count: 'desc' } }
      : { createdAt: 'desc' };

    const skip = (parseInt(page) - 1) * parseInt(limit);
    const [products, total] = await Promise.all([
      prisma.product.findMany({
        where, orderBy, skip, take: parseInt(limit),
        include: {
          images: { orderBy: { sortOrder: 'asc' }, take: 1 },
          seller: { select: { id: true, profile: { select: { fullName: true, avatar: true } } } },
          category: { select: { id: true, name: true } },
          campus: { select: { id: true, name: true, city: true } },
          _count: { select: { favorites: true, reviews: true } },
        },
      }),
      prisma.product.count({ where }),
    ]);

    res.json({ products, total, page: parseInt(page), limit: parseInt(limit) });
  } catch (e) { next(e); }
});

router.get('/:id', async (req, res, next) => {
  try {
    const product = await prisma.product.findUnique({
      where: { id: req.params.id },
      include: {
        images: { orderBy: { sortOrder: 'asc' } },
        seller: { select: { id: true, createdAt: true, profile: { select: { fullName: true, avatar: true, bio: true } } } },
        category: true, campus: true,
        _count: { select: { favorites: true } },
      },
    });
    if (!product) return res.status(404).json({ error: 'NOT_FOUND' });

    const rating = await prisma.review.aggregate({
      where: { OR: [{ productId: product.id }, { sellerId: product.sellerId }] },
      _avg: { rating: true }, _count: true,
    });

    let isFavorite = false;
    const header = req.headers.authorization || '';
    if (header.startsWith('Bearer ')) {
      try {
        const { verifyToken } = require('../lib/jwt');
        const payload = verifyToken(header.slice(7));
        const fav = await prisma.favorite.findUnique({
          where: { userId_productId: { userId: payload.sub, productId: product.id } },
        });
        isFavorite = !!fav;
      } catch {}
    }

    res.json({ product, rating: { average: rating._avg.rating, count: rating._count }, isFavorite });
  } catch (e) { next(e); }
});

const productSchema = z.object({
  name: z.string().min(3).max(120),
  description: z.string().max(5000).optional(),
  price: z.number().int().min(0),
  stock: z.number().int().min(0).default(1),
  condition: z.enum(['new', 'used']).default('used'),
  categoryId: z.string().min(1).optional(),
  campusId: z.string().min(1).optional(),
  location: z.string().optional(),
  latitude: z.number().optional(),
  longitude: z.number().optional(),
  images: z.array(z.string()).max(10).optional(),
  status: z.enum(['draft', 'active']).default('active'),
});

router.post('/', authRequired, validate(productSchema), async (req, res, next) => {
  try {
    const { images, ...data } = req.body;
    // Otomatis jadi seller saat membuat listing pertama
    if (req.user.role === 'buyer') {
      await prisma.user.update({ where: { id: req.user.id }, data: { role: 'seller' } });
    }
    const product = await prisma.product.create({
      data: {
        ...data,
        sellerId: req.user.id,
        images: images?.length ? { create: images.map((url, i) => ({ imageUrl: url, sortOrder: i })) } : undefined,
      },
      include: { images: true },
    });
    res.status(201).json({ product });
  } catch (e) { next(e); }
});

router.put('/:id', authRequired, validate(productSchema.partial()), async (req, res, next) => {
  try {
    const existing = await prisma.product.findUnique({ where: { id: req.params.id } });
    if (!existing) return res.status(404).json({ error: 'NOT_FOUND' });
    if (existing.sellerId !== req.user.id && req.user.role !== 'admin') {
      return res.status(403).json({ error: 'FORBIDDEN', message: 'Bukan pemilik listing' });
    }
    const { images, ...data } = req.body;
    const product = await prisma.$transaction(async (tx) => {
      if (images) {
        await tx.productImage.deleteMany({ where: { productId: existing.id } });
        await tx.productImage.createMany({
          data: images.map((url, i) => ({ productId: existing.id, imageUrl: url, sortOrder: i })),
        });
      }
      return tx.product.update({ where: { id: existing.id }, data, include: { images: true } });
    });
    res.json({ product });
  } catch (e) { next(e); }
});

router.delete('/:id', authRequired, async (req, res, next) => {
  try {
    const existing = await prisma.product.findUnique({ where: { id: req.params.id } });
    if (!existing) return res.status(404).json({ error: 'NOT_FOUND' });
    if (existing.sellerId !== req.user.id && req.user.role !== 'admin') {
      return res.status(403).json({ error: 'FORBIDDEN', message: 'Bukan pemilik listing' });
    }
    await prisma.product.update({ where: { id: existing.id }, data: { status: 'archived' } });
    res.json({ ok: true });
  } catch (e) { next(e); }
});

module.exports = router;
