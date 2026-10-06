const express = require('express');
const { z } = require('zod');
const prisma = require('../lib/prisma');
const { authRequired } = require('../middleware/auth');
const { validate } = require('../middleware/validate');
const { sendToUser } = require('../lib/ws');
const { createNotification } = require('../lib/notify');

const router = express.Router();
router.use(authRequired);

router.get('/conversations', async (req, res, next) => {
  try {
    const conversations = await prisma.conversation.findMany({
      where: { OR: [{ buyerId: req.user.id }, { sellerId: req.user.id }] },
      orderBy: { createdAt: 'desc' },
      include: {
        buyer: { select: { id: true, profile: { select: { fullName: true, avatar: true } } } },
        seller: { select: { id: true, profile: { select: { fullName: true, avatar: true } } } },
        product: { select: { id: true, name: true, price: true, images: { take: 1, orderBy: { sortOrder: 'asc' } } } },
        messages: { orderBy: { createdAt: 'desc' }, take: 1 },
        _count: { select: { messages: { where: { isRead: false, NOT: { senderId: req.user.id } } } } },
      },
    });
    // urutkan berdasar pesan terakhir
    conversations.sort((a, b) => {
      const ta = a.messages[0]?.createdAt || a.createdAt;
      const tb = b.messages[0]?.createdAt || b.createdAt;
      return tb - ta;
    });
    res.json({ conversations });
  } catch (e) { next(e); }
});

router.post('/conversations', validate(z.object({
  sellerId: z.string().min(1),
  productId: z.string().min(1).optional(),
})), async (req, res, next) => {
  try {
    const { sellerId, productId } = req.body;
    if (sellerId === req.user.id) {
      return res.status(400).json({ error: 'VALIDATION_ERROR', message: 'Tidak bisa chat diri sendiri' });
    }
    const seller = await prisma.user.findUnique({ where: { id: sellerId } });
    if (!seller) return res.status(404).json({ error: 'NOT_FOUND', message: 'Seller tidak ditemukan' });

    const conversation = await prisma.conversation.upsert({
      where: { buyerId_sellerId_productId: { buyerId: req.user.id, sellerId, productId: productId || null } },
      create: { buyerId: req.user.id, sellerId, productId: productId || null },
      update: {},
      include: {
        buyer: { select: { id: true, profile: { select: { fullName: true, avatar: true } } } },
        seller: { select: { id: true, profile: { select: { fullName: true, avatar: true } } } },
        product: { select: { id: true, name: true, price: true } },
      },
    });
    res.status(201).json({ conversation });
  } catch (e) { next(e); }
});

async function memberOf(conversationId, userId) {
  const c = await prisma.conversation.findUnique({ where: { id: conversationId } });
  if (!c) return null;
  if (![c.buyerId, c.sellerId].includes(userId)) return null;
  return c;
}

router.get('/conversations/:id/messages', async (req, res, next) => {
  try {
    const conv = await memberOf(req.params.id, req.user.id);
    if (!conv) return res.status(404).json({ error: 'NOT_FOUND' });
    const messages = await prisma.message.findMany({
      where: { conversationId: conv.id },
      orderBy: { createdAt: 'asc' },
      take: parseInt(req.query.limit || '100'),
    });
    // tandai pesan lawan sebagai dibaca
    await prisma.message.updateMany({
      where: { conversationId: conv.id, isRead: false, NOT: { senderId: req.user.id } },
      data: { isRead: true },
    });
    res.json({ messages, conversation: conv });
  } catch (e) { next(e); }
});

router.post('/conversations/:id/messages', validate(z.object({
  message: z.string().min(1).max(2000),
})), async (req, res, next) => {
  try {
    const conv = await memberOf(req.params.id, req.user.id);
    if (!conv) return res.status(404).json({ error: 'NOT_FOUND' });
    const message = await prisma.message.create({
      data: { conversationId: conv.id, senderId: req.user.id, message: req.body.message },
      include: { sender: { select: { id: true, profile: { select: { fullName: true, avatar: true } } } } },
    });
    const recipientId = conv.buyerId === req.user.id ? conv.sellerId : conv.buyerId;
    sendToUser(recipientId, { type: 'chat:message', conversationId: conv.id, message });
    res.status(201).json({ message });
  } catch (e) { next(e); }
});

module.exports = router;
