const express = require('express');
const { z } = require('zod');
const prisma = require('../lib/prisma');
const { authRequired } = require('../middleware/auth');
const { validate } = require('../middleware/validate');

const router = express.Router();

router.get('/me', authRequired, async (req, res, next) => {
  try {
    const user = await prisma.user.findUnique({
      where: { id: req.user.id },
      include: { profile: true, addresses: true },
    });
    res.json({ user });
  } catch (e) { next(e); }
});

router.put('/me', authRequired, validate(z.object({
  fullName: z.string().min(2).optional(),
  phone: z.string().nullable().optional(),
  avatar: z.string().nullable().optional(),
  bio: z.string().nullable().optional(),
})), async (req, res, next) => {
  try {
    const profile = await prisma.userProfile.upsert({
      where: { userId: req.user.id },
      create: { userId: req.user.id, fullName: req.body.fullName || 'User', ...req.body },
      update: req.body,
    });
    res.json({ profile });
  } catch (e) { next(e); }
});

router.get('/:id', authRequired, async (req, res, next) => {
  try {
    const user = await prisma.user.findUnique({
      where: { id: req.params.id },
      select: {
        id: true, role: true, createdAt: true,
        profile: { select: { fullName: true, avatar: true, bio: true } },
        _count: { select: { products: { where: { status: 'active' } } } },
      },
    });
    if (!user) return res.status(404).json({ error: 'NOT_FOUND' });
    const rating = await prisma.review.aggregate({
      where: { sellerId: req.params.id },
      _avg: { rating: true }, _count: true,
    });
    res.json({ user, sellerRating: { average: rating._avg.rating, count: rating._count } });
  } catch (e) { next(e); }
});

// Addresses
router.get('/me/addresses/list', authRequired, async (req, res, next) => {
  try {
    const addresses = await prisma.userAddress.findMany({ where: { userId: req.user.id } });
    res.json({ addresses });
  } catch (e) { next(e); }
});

router.post('/me/addresses', authRequired, validate(z.object({
  label: z.string().min(1), address: z.string().min(3),
  latitude: z.number().optional(), longitude: z.number().optional(),
  isDefault: z.boolean().optional(),
})), async (req, res, next) => {
  try {
    if (req.body.isDefault) {
      await prisma.userAddress.updateMany({ where: { userId: req.user.id }, data: { isDefault: false } });
    }
    const address = await prisma.userAddress.create({ data: { ...req.body, userId: req.user.id } });
    res.status(201).json({ address });
  } catch (e) { next(e); }
});

router.delete('/me/addresses/:id', authRequired, async (req, res, next) => {
  try {
    await prisma.userAddress.delete({ where: { id: req.params.id, userId: req.user.id } });
    res.json({ ok: true });
  } catch (e) { next(e); }
});

module.exports = router;
