const express = require('express');
const prisma = require('../lib/prisma');
const { authRequired } = require('../middleware/auth');

const router = express.Router();
router.use(authRequired);

router.get('/', async (req, res, next) => {
  try {
    const favorites = await prisma.favorite.findMany({
      where: { userId: req.user.id },
      orderBy: { createdAt: 'desc' },
      include: {
        product: {
          include: {
            images: { orderBy: { sortOrder: 'asc' }, take: 1 },
            seller: { select: { id: true, profile: { select: { fullName: true } } } },
          },
        },
      },
    });
    res.json({ favorites: favorites.filter((f) => f.product.status === 'active') });
  } catch (e) { next(e); }
});

router.post('/', async (req, res, next) => {
  try {
    const { productId } = req.body;
    if (!productId) return res.status(400).json({ error: 'VALIDATION_ERROR', message: 'productId wajib' });
    const product = await prisma.product.findUnique({ where: { id: productId } });
    if (!product) return res.status(404).json({ error: 'NOT_FOUND' });
    const favorite = await prisma.favorite.upsert({
      where: { userId_productId: { userId: req.user.id, productId } },
      create: { userId: req.user.id, productId },
      update: {},
    });
    res.status(201).json({ favorite });
  } catch (e) { next(e); }
});

router.delete('/:productId', async (req, res, next) => {
  try {
    await prisma.favorite.deleteMany({ where: { userId: req.user.id, productId: req.params.productId } });
    res.json({ ok: true });
  } catch (e) { next(e); }
});

module.exports = router;
