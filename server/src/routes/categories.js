const express = require('express');
const prisma = require('../lib/prisma');
const { authRequired, roleRequired } = require('../middleware/auth');

const router = express.Router();

router.get('/', async (req, res, next) => {
  try {
    const categories = await prisma.category.findMany({
      where: { status: 'active' },
      orderBy: { name: 'asc' },
      include: { children: true },
    });
    res.json({ categories });
  } catch (e) { next(e); }
});

router.get('/:id', async (req, res, next) => {
  try {
    const category = await prisma.category.findUnique({
      where: { id: req.params.id },
      include: { children: true, _count: { select: { products: { where: { status: 'active' } } } } },
    });
    if (!category) return res.status(404).json({ error: 'NOT_FOUND' });
    res.json({ category });
  } catch (e) { next(e); }
});

module.exports = router;
