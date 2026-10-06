const express = require('express');
const { z } = require('zod');
const prisma = require('../lib/prisma');
const { authRequired } = require('../middleware/auth');
const { validate } = require('../middleware/validate');

const router = express.Router();
router.use(authRequired);

async function getOrCreateCart(userId) {
  return prisma.cart.upsert({
    where: { userId },
    create: { userId },
    update: {},
  });
}

router.get('/', async (req, res, next) => {
  try {
    const cart = await getOrCreateCart(req.user.id);
    const items = await prisma.cartItem.findMany({
      where: { cartId: cart.id },
      include: {
        product: {
          include: {
            images: { orderBy: { sortOrder: 'asc' }, take: 1 },
            seller: { select: { id: true, profile: { select: { fullName: true } } } },
          },
        },
      },
    });
    const total = items.reduce((s, it) => s + it.product.price * it.quantity, 0);
    res.json({ cartId: cart.id, items, total });
  } catch (e) { next(e); }
});

router.post('/items', validate(z.object({
  productId: z.string().min(1),
  quantity: z.number().int().min(1).default(1),
})), async (req, res, next) => {
  try {
    const { productId, quantity } = req.body;
    const product = await prisma.product.findUnique({ where: { id: productId } });
    if (!product || product.status !== 'active') {
      return res.status(404).json({ error: 'NOT_FOUND', message: 'Produk tidak tersedia' });
    }
    if (product.sellerId === req.user.id) {
      return res.status(400).json({ error: 'VALIDATION_ERROR', message: 'Tidak bisa membeli produk sendiri' });
    }
    if (product.stock < quantity) {
      return res.status(400).json({ error: 'OUT_OF_STOCK', message: 'Stok tidak cukup' });
    }
    const cart = await getOrCreateCart(req.user.id);
    const existing = await prisma.cartItem.findUnique({
      where: { cartId_productId: { cartId: cart.id, productId } },
    });
    const newQty = (existing?.quantity || 0) + quantity;
    if (product.stock < newQty) {
      return res.status(400).json({ error: 'OUT_OF_STOCK', message: 'Stok tidak cukup' });
    }
    const item = existing
      ? await prisma.cartItem.update({ where: { id: existing.id }, data: { quantity: newQty } })
      : await prisma.cartItem.create({ data: { cartId: cart.id, productId, quantity } });
    res.status(201).json({ item });
  } catch (e) { next(e); }
});

router.put('/items/:id', validate(z.object({ quantity: z.number().int().min(1) })), async (req, res, next) => {
  try {
    const item = await prisma.cartItem.findUnique({
      where: { id: req.params.id },
      include: { cart: true, product: true },
    });
    if (!item || item.cart.userId !== req.user.id) return res.status(404).json({ error: 'NOT_FOUND' });
    if (item.product.stock < req.body.quantity) {
      return res.status(400).json({ error: 'OUT_OF_STOCK', message: 'Stok tidak cukup' });
    }
    const updated = await prisma.cartItem.update({ where: { id: item.id }, data: { quantity: req.body.quantity } });
    res.json({ item: updated });
  } catch (e) { next(e); }
});

router.delete('/items/:id', async (req, res, next) => {
  try {
    const item = await prisma.cartItem.findUnique({ where: { id: req.params.id }, include: { cart: true } });
    if (!item || item.cart.userId !== req.user.id) return res.status(404).json({ error: 'NOT_FOUND' });
    await prisma.cartItem.delete({ where: { id: item.id } });
    res.json({ ok: true });
  } catch (e) { next(e); }
});

module.exports = router;
