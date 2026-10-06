const express = require('express');
const { z } = require('zod');
const prisma = require('../lib/prisma');
const { authRequired, roleRequired } = require('../middleware/auth');
const { validate } = require('../middleware/validate');
const { createNotification } = require('../lib/notify');

const router = express.Router();
router.use(authRequired, roleRequired('admin'));

router.get('/dashboard', async (req, res, next) => {
  try {
    const [
      totalUsers, activeUsers, totalProducts, activeProducts,
      totalOrders, completedOrders, pendingVerifications, openReports, revenue,
    ] = await Promise.all([
      prisma.user.count(),
      prisma.user.count({ where: { accountStatus: 'active' } }),
      prisma.product.count(),
      prisma.product.count({ where: { status: 'active' } }),
      prisma.order.count(),
      prisma.order.count({ where: { status: 'completed' } }),
      prisma.studentVerification.count({ where: { status: 'pending' } }),
      prisma.report.count({ where: { status: 'open' } }),
      prisma.order.aggregate({ where: { status: 'completed' }, _sum: { totalAmount: true } }),
    ]);

    const since = new Date(Date.now() - 7 * 86400_000);
    const recentOrders = await prisma.order.findMany({
      where: { createdAt: { gte: since } },
      select: { totalAmount: true, createdAt: true, status: true },
    });
    const daily = {};
    for (let i = 6; i >= 0; i--) {
      const d = new Date(Date.now() - i * 86400_000);
      daily[d.toISOString().slice(0, 10)] = { orders: 0, revenue: 0 };
    }
    for (const o of recentOrders) {
      const key = o.createdAt.toISOString().slice(0, 10);
      if (key in daily) {
        daily[key].orders += 1;
        if (o.status === 'completed') daily[key].revenue += o.totalAmount;
      }
    }

    const recentActivities = await prisma.order.findMany({
      orderBy: { createdAt: 'desc' }, take: 6,
      select: {
        id: true, status: true, totalAmount: true, createdAt: true,
        buyer: { select: { profile: { select: { fullName: true } } } },
        seller: { select: { profile: { select: { fullName: true } } } },
      },
    });

    res.json({
      totalUsers, activeUsers, totalProducts, activeProducts,
      totalOrders, completedOrders, pendingVerifications, openReports,
      revenue: revenue._sum.totalAmount || 0,
      chart7Days: Object.entries(daily).map(([date, v]) => ({ date, ...v })),
      recentActivities,
    });
  } catch (e) { next(e); }
});

// ===== Users =====
router.get('/users', async (req, res, next) => {
  try {
    const { search, role, status, page = '1', limit = '20' } = req.query;
    const where = {};
    if (search) {
      where.OR = [
        { email: { contains: search, mode: 'insensitive' } },
        { profile: { fullName: { contains: search, mode: 'insensitive' } } },
      ];
    }
    if (role) where.role = role;
    if (status) where.accountStatus = status;
    const skip = (parseInt(page) - 1) * parseInt(limit);
    const [users, total] = await Promise.all([
      prisma.user.findMany({
        where, skip, take: parseInt(limit), orderBy: { createdAt: 'desc' },
        include: {
          profile: true,
          _count: { select: { products: true, buyerOrders: true } },
          verifications: { orderBy: { createdAt: 'desc' }, take: 1, select: { status: true } },
        },
      }),
      prisma.user.count({ where }),
    ]);
    res.json({ users, total, page: parseInt(page), limit: parseInt(limit) });
  } catch (e) { next(e); }
});

router.get('/users/:id', async (req, res, next) => {
  try {
    const user = await prisma.user.findUnique({
      where: { id: req.params.id },
      include: {
        profile: true, addresses: true,
        verifications: { include: { campus: true }, orderBy: { createdAt: 'desc' } },
        _count: { select: { products: true, buyerOrders: true, sellerOrders: true, reviewsReceived: true } },
      },
    });
    if (!user) return res.status(404).json({ error: 'NOT_FOUND' });
    delete user.passwordHash;
    res.json({ user });
  } catch (e) { next(e); }
});

router.put('/users/:id/status', validate(z.object({
  accountStatus: z.enum(['active', 'suspended', 'banned']),
})), async (req, res, next) => {
  try {
    if (req.params.id === req.user.id) {
      return res.status(400).json({ error: 'VALIDATION_ERROR', message: 'Tidak bisa mengubah status akun sendiri' });
    }
    const user = await prisma.user.update({
      where: { id: req.params.id },
      data: { accountStatus: req.body.accountStatus },
      select: { id: true, email: true, accountStatus: true },
    });
    res.json({ user });
  } catch (e) { next(e); }
});

// ===== Products moderation =====
router.get('/products', async (req, res, next) => {
  try {
    const { search, status, page = '1', limit = '20' } = req.query;
    const where = {};
    if (search) where.name = { contains: search, mode: 'insensitive' };
    if (status) where.status = status;
    const skip = (parseInt(page) - 1) * parseInt(limit);
    const [products, total] = await Promise.all([
      prisma.product.findMany({
        where, skip, take: parseInt(limit), orderBy: { createdAt: 'desc' },
        include: {
          images: { take: 1, orderBy: { sortOrder: 'asc' } },
          seller: { select: { id: true, email: true, profile: { select: { fullName: true } } } },
          category: { select: { name: true } },
          _count: { select: { favorites: true, orderItems: true, reports: true } },
        },
      }),
      prisma.product.count({ where }),
    ]);
    res.json({ products, total, page: parseInt(page), limit: parseInt(limit) });
  } catch (e) { next(e); }
});

router.put('/products/:id/status', validate(z.object({
  status: z.enum(['draft', 'active', 'sold', 'archived', 'flagged', 'rejected']),
})), async (req, res, next) => {
  try {
    const product = await prisma.product.update({
      where: { id: req.params.id },
      data: { status: req.body.status },
    });
    if (['flagged', 'rejected'].includes(req.body.status)) {
      await createNotification(product.sellerId, 'listing', 'Listing dimoderasi', `Produk "${product.name}" berstatus ${req.body.status}`);
    }
    res.json({ product });
  } catch (e) { next(e); }
});

// ===== Orders monitoring =====
router.get('/orders', async (req, res, next) => {
  try {
    const { status, page = '1', limit = '20' } = req.query;
    const where = status ? { status } : {};
    const skip = (parseInt(page) - 1) * parseInt(limit);
    const [orders, total] = await Promise.all([
      prisma.order.findMany({
        where, skip, take: parseInt(limit), orderBy: { createdAt: 'desc' },
        include: {
          items: { include: { product: { select: { name: true } } } },
          buyer: { select: { id: true, email: true, profile: { select: { fullName: true } } } },
          seller: { select: { id: true, email: true, profile: { select: { fullName: true } } } },
        },
      }),
      prisma.order.count({ where }),
    ]);
    res.json({ orders, total, page: parseInt(page), limit: parseInt(limit) });
  } catch (e) { next(e); }
});

// ===== Verifications =====
router.get('/verifications', async (req, res, next) => {
  try {
    const { status, page = '1', limit = '20' } = req.query;
    const where = status ? { status } : {};
    const skip = (parseInt(page) - 1) * parseInt(limit);
    const [verifications, total] = await Promise.all([
      prisma.studentVerification.findMany({
        where, skip, take: parseInt(limit), orderBy: { createdAt: 'desc' },
        include: {
          user: { select: { id: true, email: true, profile: { select: { fullName: true, avatar: true } } } },
          campus: true,
        },
      }),
      prisma.studentVerification.count({ where }),
    ]);
    res.json({ verifications, total, page: parseInt(page), limit: parseInt(limit) });
  } catch (e) { next(e); }
});

router.put('/verifications/:id', validate(z.object({
  status: z.enum(['approved', 'rejected']),
})), async (req, res, next) => {
  try {
    const verification = await prisma.studentVerification.update({
      where: { id: req.params.id },
      data: { status: req.body.status, reviewedBy: req.user.id, reviewedAt: new Date() },
      include: { user: true },
    });
    await createNotification(
      verification.userId, 'verification',
      req.body.status === 'approved' ? 'Verifikasi disetujui' : 'Verifikasi ditolak',
      req.body.status === 'approved' ? 'Selamat! Kamu kini mahasiswa terverifikasi.' : 'Pengajuan verifikasimu ditolak. Periksa kembali dokumen.'
    );
    res.json({ verification });
  } catch (e) { next(e); }
});

// ===== Categories management =====
router.get('/categories', async (req, res, next) => {
  try {
    const categories = await prisma.category.findMany({
      orderBy: { name: 'asc' },
      include: {
        parent: { select: { id: true, name: true } },
        _count: { select: { products: true } },
      },
    });
    res.json({ categories });
  } catch (e) { next(e); }
});

router.post('/categories', validate(z.object({
  name: z.string().min(2), icon: z.string().optional(), parentId: z.string().optional(),
})), async (req, res, next) => {
  try {
    const category = await prisma.category.create({ data: req.body });
    res.status(201).json({ category });
  } catch (e) { next(e); }
});

router.put('/categories/:id', validate(z.object({
  name: z.string().min(2).optional(), icon: z.string().optional(),
  status: z.string().optional(), parentId: z.string().nullable().optional(),
})), async (req, res, next) => {
  try {
    const category = await prisma.category.update({ where: { id: req.params.id }, data: req.body });
    res.json({ category });
  } catch (e) { next(e); }
});

router.delete('/categories/:id', async (req, res, next) => {
  try {
    const used = await prisma.product.count({ where: { categoryId: req.params.id } });
    if (used > 0) {
      await prisma.category.update({ where: { id: req.params.id }, data: { status: 'inactive' } });
      return res.json({ ok: true, softDeleted: true, message: 'Kategori dipakai produk, dinonaktifkan' });
    }
    await prisma.category.delete({ where: { id: req.params.id } });
    res.json({ ok: true });
  } catch (e) { next(e); }
});

router.put('/orders/:id/status', validate(z.object({
  status: z.enum(['pending', 'accepted', 'processed', 'ready', 'completed', 'cancelled', 'rejected']),
})), async (req, res, next) => {
  try {
    const order = await prisma.order.update({
      where: { id: req.params.id },
      data: { status: req.body.status },
    });
    res.json({ order });
  } catch (e) { next(e); }
});

module.exports = router;
