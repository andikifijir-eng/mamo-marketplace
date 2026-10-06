const prisma = require('../lib/prisma');

function createNotification(userId, type, title, body) {
  return prisma.notification.create({
    data: { userId, type, title, body: body || null },
  }).catch((e) => console.error('[notify]', e.message));
}

module.exports = { createNotification };
