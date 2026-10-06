const express = require('express');
const { z } = require('zod');
const prisma = require('../lib/prisma');
const { authRequired, roleRequired } = require('../middleware/auth');
const { validate } = require('../middleware/validate');

const router = express.Router();

// User membuat report terhadap produk
router.post('/', authRequired, validate(z.object({
  productId: z.string().min(1),
  reason: z.string().min(3).max(200),
  detail: z.string().max(1000).optional(),
})), async (req, res, next) => {
  try {
    const product = await prisma.product.findUnique({ where: { id: req.body.productId } });
    if (!product) return res.status(404).json({ error: 'NOT_FOUND' });
    const report = await prisma.report.create({
      data: { reporterId: req.user.id, productId: req.body.productId, reason: req.body.reason, detail: req.body.detail || null },
    });
    res.status(201).json({ report });
  } catch (e) { next(e); }
});

// Admin: daftar & resolve reports
router.get('/', authRequired, roleRequired('admin'), async (req, res, next) => {
  try {
    const { status, page = '1', limit = '20' } = req.query;
    const where = status ? { status } : {};
    const skip = (parseInt(page) - 1) * parseInt(limit);
    const [reports, total] = await Promise.all([
      prisma.report.findMany({
        where, skip, take: parseInt(limit), orderBy: { createdAt: 'desc' },
        include: {
          reporter: { select: { id: true, email: true, profile: { select: { fullName: true } } } },
          product: { select: { id: true, name: true, status: true, images: { take: 1, orderBy: { sortOrder: 'asc' } }, seller: { select: { id: true, profile: { select: { fullName: true } } } } } },
        },
      }),
      prisma.report.count({ where }),
    ]);
    res.json({ reports, total, page: parseInt(page), limit: parseInt(limit) });
  } catch (e) { next(e); }
});

router.put('/:id', authRequired, roleRequired('admin'), validate(z.object({
  status: z.enum(['open', 'resolved', 'rejected']),
})), async (req, res, next) => {
  try {
    const report = await prisma.report.update({ where: { id: req.params.id }, data: { status: req.body.status } });
    res.json({ report });
  } catch (e) { next(e); }
});

module.exports = router;
