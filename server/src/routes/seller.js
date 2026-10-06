const express = require('express');
const prisma = require('../lib/prisma');
const { authRequired, roleRequired } = require('../middleware/auth');

const router = express.Router();
router.use(authRequired, roleRequired('seller', 'admin'));

router.get('/dashboard', async (req, res, next) => {
  try {
    const sellerId = req.user.id;
    const [
      totalListings, activeListings, soldListings, pendingOrders,
      totalOrders, revenue, rating, unreadChats,
    ] = await Promise.all([
      prisma.product.count({ where: { sellerId } }),
      prisma.product.count({ where: { sellerId, status: 'active' } }),
      prisma.product.count({ where: { sellerId, status: 'sold' } }),
      prisma.order.count({ where: { sellerId, status: 'pending' } }),
      prisma.order.count({ where: { sellerId, status: 'completed' } }),
      prisma.order.aggregate({ where: { sellerId, status: 'completed' }, _sum: { totalAmount: true } }),
      prisma.review.aggregate({ where: { sellerId }, _avg: { rating: true }, _count: true }),
      prisma.message.count({
        where: { conversation: { sellerId }, isRead: false, NOT: { senderId: sellerId } },
      }),
    ]);

    // Penjualan 7 hari terakhir
    const since = new Date(Date.now() - 7 * 86400_000);
    const recentOrders = await prisma.order.findMany({
      where: { sellerId, status: 'completed', createdAt: { gte: since } },
      select: { totalAmount: true, createdAt: true },
    });
    const daily = {};
    for (let i = 6; i >= 0; i--) {
      const d = new Date(Date.now() - i * 86400_000);
      daily[d.toISOString().slice(0, 10)] = 0;
    }
    for (const o of recentOrders) {
      const key = o.createdAt.toISOString().slice(0, 10);
      if (key in daily) daily[key] += o.totalAmount;
    }

    res.json({
      totalListings, activeListings, soldListings, pendingOrders,
      completedOrders: totalOrders,
      revenue: revenue._sum.totalAmount || 0,
      rating: { average: rating._avg.rating, count: rating._count },
      unreadChats,
      salesLast7Days: Object.entries(daily).map(([date, amount]) => ({ date, amount })),
    });
  } catch (e) { next(e); }
});

router.get('/products', async (req, res, next) => {
  try {
    const products = await prisma.product.findMany({
      where: { sellerId: req.user.id, status: { not: 'archived' } },
      orderBy: { createdAt: 'desc' },
      include: {
        images: { orderBy: { sortOrder: 'asc' }, take: 1 },
        category: { select: { name: true } },
        _count: { select: { favorites: true, orderItems: true } },
      },
    });
    res.json({ products });
  } catch (e) { next(e); }
});

router.get('/orders', async (req, res, next) => {
  try {
    const status = req.query.status;
    const orders = await prisma.order.findMany({
      where: { sellerId: req.user.id, ...(status ? { status } : {}) },
      orderBy: { createdAt: 'desc' },
      include: {
        items: { include: { product: { include: { images: { take: 1, orderBy: { sortOrder: 'asc' } } } } } },
        buyer: { select: { id: true, profile: { select: { fullName: true, avatar: true } } } },
      },
    });
    res.json({ orders });
  } catch (e) { next(e); }
});

router.get('/statistics', async (req, res, next) => {
  try {
    const sellerId = req.user.id;
    const topProducts = await prisma.orderItem.groupBy({
      by: ['productId'],
      where: { order: { sellerId, status: 'completed' } },
      _sum: { quantity: true, subtotal: true },
      orderBy: { _sum: { subtotal: 'desc' } },
      take: 5,
    });
    const products = await prisma.product.findMany({
      where: { id: { in: topProducts.map((t) => t.productId) } },
      select: { id: true, name: true },
    });
    const nameMap = Object.fromEntries(products.map((p) => [p.id, p.name]));

    res.json({
      topProducts: topProducts.map((t) => ({
        productId: t.productId,
        name: nameMap[t.productId],
        sold: t._sum.quantity,
        revenue: t._sum.subtotal,
      })),
    });
  } catch (e) { next(e); }
});

module.exports = router;
