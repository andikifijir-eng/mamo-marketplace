const express = require('express');
const { z } = require('zod');
const prisma = require('../lib/prisma');
const { authRequired } = require('../middleware/auth');
const { validate } = require('../middleware/validate');
const { createNotification } = require('../lib/notify');
const { sendToUser } = require('../lib/ws');

const router = express.Router();
router.use(authRequired);

// Checkout — 1 order per seller (split otomatis)
router.post('/', validate(z.object({
  cartItemIds: z.array(z.string().min(1)).min(1),
  deliveryMethod: z.enum(['cod', 'delivery', 'pickup']).default('cod'),
  deliveryAddress: z.string().optional(),
  latitude: z.number().optional(),
  longitude: z.number().optional(),
})), async (req, res, next) => {
  try {
    const { cartItemIds, deliveryMethod, deliveryAddress, latitude, longitude } = req.body;
    const cart = await prisma.cart.findUnique({ where: { userId: req.user.id } });
    if (!cart) return res.status(400).json({ error: 'EMPTY_CART' });

    const items = await prisma.cartItem.findMany({
      where: { id: { in: cartItemIds }, cartId: cart.id },
      include: { product: true },
    });
    if (items.length !== cartItemIds.length) {
      return res.status(400).json({ error: 'VALIDATION_ERROR', message: 'Item cart tidak valid' });
    }
    for (const it of items) {
      if (it.product.status !== 'active') {
        return res.status(400).json({ error: 'UNAVAILABLE', message: `"${it.product.name}" sudah tidak tersedia` });
      }
      if (it.product.stock < it.quantity) {
        return res.status(400).json({ error: 'OUT_OF_STOCK', message: `Stok "${it.product.name}" tidak cukup` });
      }
      if (it.product.sellerId === req.user.id) {
        return res.status(400).json({ error: 'VALIDATION_ERROR', message: 'Tidak bisa membeli produk sendiri' });
      }
    }

    // Group per seller
    const bySeller = new Map();
    for (const it of items) {
      const sid = it.product.sellerId;
      if (!bySeller.has(sid)) bySeller.set(sid, []);
      bySeller.get(sid).push(it);
    }

    const orders = await prisma.$transaction(async (tx) => {
      const created = [];
      for (const [sellerId, sellerItems] of bySeller) {
        const total = sellerItems.reduce((s, it) => s + it.product.price * it.quantity, 0);
        const order = await tx.order.create({
          data: {
            buyerId: req.user.id, sellerId,
            totalAmount: total, deliveryMethod,
            deliveryAddress: deliveryAddress || null,
            latitude: latitude ?? null, longitude: longitude ?? null,
            items: {
              create: sellerItems.map((it) => ({
                productId: it.productId,
                quantity: it.quantity,
                price: it.product.price,
                subtotal: it.product.price * it.quantity,
              })),
            },
          },
          include: { items: true },
        });
        // Kurangi stok atomik — gagal jika stok berubah
        for (const it of sellerItems) {
          const upd = await tx.product.updateMany({
            where: { id: it.productId, stock: { gte: it.quantity } },
            data: { stock: { decrement: it.quantity } },
          });
          if (upd.count === 0) throw new Error(`OUT_OF_STOCK:${it.product.name}`);
          // Tandai sold jika stok habis
          await tx.product.updateMany({
            where: { id: it.productId, stock: 0 },
            data: { status: 'sold' },
          });
        }
        created.push(order);
      }
      // Kosongkan item yang di-checkout
      await tx.cartItem.deleteMany({ where: { id: { in: cartItemIds } } });
      return created;
    });

    for (const order of orders) {
      await createNotification(order.sellerId, 'order', 'Pesanan baru', `Kamu menerima pesanan baru senilai Rp ${order.totalAmount.toLocaleString('id-ID')}`);
      sendToUser(order.sellerId, { type: 'order:new', orderId: order.id });
    }

    res.status(201).json({ orders });
  } catch (e) {
    if (e.message?.startsWith('OUT_OF_STOCK:')) {
      return res.status(409).json({ error: 'OUT_OF_STOCK', message: `Stok "${e.message.split(':')[1]}" habis saat checkout` });
    }
    next(e);
  }
});

router.get('/', async (req, res, next) => {
  try {
    const as = req.query.as === 'seller' ? 'sellerId' : 'buyerId';
    const orders = await prisma.order.findMany({
      where: { [as]: req.user.id },
      orderBy: { createdAt: 'desc' },
      include: {
        items: { include: { product: { include: { images: { take: 1, orderBy: { sortOrder: 'asc' } } } } } },
        buyer: { select: { id: true, profile: { select: { fullName: true, avatar: true } } } },
        seller: { select: { id: true, profile: { select: { fullName: true, avatar: true } } } },
        review: { select: { id: true } },
      },
    });
    res.json({ orders });
  } catch (e) { next(e); }
});

router.get('/:id', async (req, res, next) => {
  try {
    const order = await prisma.order.findUnique({
      where: { id: req.params.id },
      include: {
        items: { include: { product: { include: { images: { take: 1, orderBy: { sortOrder: 'asc' } } } } } },
        buyer: { select: { id: true, profile: { select: { fullName: true, avatar: true, phone: true } } } },
        seller: { select: { id: true, profile: { select: { fullName: true, avatar: true, phone: true } } } },
        review: true,
      },
    });
    if (!order) return res.status(404).json({ error: 'NOT_FOUND' });
    if (![order.buyerId, order.sellerId].includes(req.user.id) && req.user.role !== 'admin') {
      return res.status(403).json({ error: 'FORBIDDEN' });
    }
    res.json({ order });
  } catch (e) { next(e); }
});

// Transisi status yang sah
const TRANSITIONS = {
  pending: ['accepted', 'rejected', 'cancelled'],
  accepted: ['processed', 'cancelled'],
  processed: ['ready', 'cancelled'],
  ready: ['completed', 'cancelled'],
  completed: [],
  cancelled: [],
  rejected: [],
};

router.put('/:id/status', validate(z.object({
  status: z.enum(['accepted', 'processed', 'ready', 'completed', 'cancelled', 'rejected']),
})), async (req, res, next) => {
  try {
    const order = await prisma.order.findUnique({ where: { id: req.params.id } });
    if (!order) return res.status(404).json({ error: 'NOT_FOUND' });
    const target = req.body.status;

    const isSeller = order.sellerId === req.user.id;
    const isBuyer = order.buyerId === req.user.id;
    const isAdmin = req.user.role === 'admin';

    // Hak: seller bisa accept/process/ready/reject; buyer bisa cancel (pending) & complete (ready); admin semua
    const sellerActions = ['accepted', 'processed', 'ready', 'rejected'];
    const buyerActions = { cancelled: ['pending', 'accepted'], completed: ['ready'] };

    if (!isAdmin) {
      if (sellerActions.includes(target) && !isSeller) {
        return res.status(403).json({ error: 'FORBIDDEN', message: 'Hanya seller yang bisa mengubah status ini' });
      }
      if (target in buyerActions) {
        if (!isBuyer) return res.status(403).json({ error: 'FORBIDDEN', message: 'Hanya buyer' });
        if (!buyerActions[target].includes(order.status)) {
          return res.status(400).json({ error: 'INVALID_TRANSITION', message: `Tidak bisa ${target} dari status ${order.status}` });
        }
      }
    }

    const allowed = TRANSITIONS[order.status] || [];
    if (!allowed.includes(target)) {
      return res.status(400).json({ error: 'INVALID_TRANSITION', message: `Transisi ${order.status} → ${target} tidak valid` });
    }

    const updated = await prisma.$transaction(async (tx) => {
      const o = await tx.order.update({ where: { id: order.id }, data: { status: target } });
      // Kembalikan stok saat cancel/reject
      if (['cancelled', 'rejected'].includes(target)) {
        const items = await tx.orderItem.findMany({ where: { orderId: order.id } });
        for (const it of items) {
          await tx.product.update({ where: { id: it.productId }, data: { stock: { increment: it.quantity } } });
          await tx.product.updateMany({ where: { id: it.productId, status: 'sold', stock: { gt: 0 } }, data: { status: 'active' } });
        }
      }
      return o;
    });

    const notifTarget = target === 'completed' || target === 'cancelled' ? order.sellerId : order.buyerId;
    await createNotification(notifTarget, 'order', 'Status pesanan berubah', `Pesanan #${order.id.slice(0, 8)} kini berstatus ${target}`);
    sendToUser(notifTarget, { type: 'order:status', orderId: order.id, status: target });

    res.json({ order: updated });
  } catch (e) { next(e); }
});

module.exports = router;
