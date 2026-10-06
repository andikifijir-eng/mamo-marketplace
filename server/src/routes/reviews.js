const express = require('express');
const { z } = require('zod');
const prisma = require('../lib/prisma');
const { authRequired } = require('../middleware/auth');
const { validate } = require('../middleware/validate');

const router = express.Router();

// POST /reviews — hanya buyer dari order completed
router.post('/reviews', authRequired, validate(z.object({
  orderId: z.string().min(1),
  rating: z.number().int().min(1).max(5),
  comment: z.string().max(1000).optional(),
})), async (req, res, next) => {
  try {
    const order = await prisma.order.findUnique({
      where: { id: req.body.orderId },
      include: { items: true, review: true },
    });
    if (!order) return res.status(404).json({ error: 'NOT_FOUND' });
    if (order.buyerId !== req.user.id) {
      return res.status(403).json({ error: 'FORBIDDEN', message: 'Hanya buyer dari transaksi ini' });
    }
    if (order.status !== 'completed') {
      return res.status(400).json({ error: 'INVALID_STATE', message: 'Order belum selesai' });
    }
    if (order.review) {
      return res.status(409).json({ error: 'CONFLICT', message: 'Order sudah direview' });
    }
    const firstItem = order.items[0];
    const review = await prisma.review.create({
      data: {
        orderId: order.id,
        productId: firstItem.productId,
        reviewerId: req.user.id,
        sellerId: order.sellerId,
        rating: req.body.rating,
        comment: req.body.comment || null,
      },
    });
    res.status(201).json({ review });
  } catch (e) { next(e); }
});

// GET /products/:id/reviews
router.get('/products/:id/reviews', async (req, res, next) => {
  try {
    const reviews = await prisma.review.findMany({
      where: { productId: req.params.id },
      orderBy: { createdAt: 'desc' },
      include: { reviewer: { select: { id: true, profile: { select: { fullName: true, avatar: true } } } } },
    });
    const agg = await prisma.review.aggregate({
      where: { productId: req.params.id },
      _avg: { rating: true }, _count: true,
    });
    res.json({ reviews, average: agg._avg.rating, count: agg._count });
  } catch (e) { next(e); }
});

module.exports = router;
