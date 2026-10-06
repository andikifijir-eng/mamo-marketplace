const express = require('express');
const prisma = require('../lib/prisma');
const { authRequired } = require('../middleware/auth');

const router = express.Router();
router.use(authRequired);

router.get('/', async (req, res, next) => {
  try {
    const notifications = await prisma.notification.findMany({
      where: { userId: req.user.id },
      orderBy: { createdAt: 'desc' },
      take: 100,
    });
    const unread = await prisma.notification.count({ where: { userId: req.user.id, isRead: false } });
    res.json({ notifications, unread });
  } catch (e) { next(e); }
});

router.put('/:id/read', async (req, res, next) => {
  try {
    await prisma.notification.updateMany({
      where: { id: req.params.id, userId: req.user.id },
      data: { isRead: true },
    });
    res.json({ ok: true });
  } catch (e) { next(e); }
});

router.put('/read-all', async (req, res, next) => {
  try {
    await prisma.notification.updateMany({
      where: { userId: req.user.id, isRead: false },
      data: { isRead: true },
    });
    res.json({ ok: true });
  } catch (e) { next(e); }
});

module.exports = router;
