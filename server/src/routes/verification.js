const express = require('express');
const { z } = require('zod');
const prisma = require('../lib/prisma');
const { authRequired } = require('../middleware/auth');
const { validate } = require('../middleware/validate');
const { createNotification } = require('../lib/notify');

const router = express.Router();
router.use(authRequired);

router.post('/', validate(z.object({
  campusId: z.string().min(1).nullable().optional(),
  studentIdentifier: z.string().min(3),
  document: z.string().nullable().optional(),
})), async (req, res, next) => {
  try {
    // satu user hanya boleh punya 1 verification aktif (pending/approved)
    const existing = await prisma.studentVerification.findFirst({
      where: { userId: req.user.id, status: { in: ['pending', 'approved'] } },
    });
    if (existing) {
      return res.status(409).json({
        error: 'CONFLICT',
        message: existing.status === 'approved' ? 'Kamu sudah terverifikasi' : 'Pengajuan sedang diproses',
      });
    }
    const verification = await prisma.studentVerification.create({
      data: {
        userId: req.user.id,
        campusId: req.body.campusId || null,
        studentIdentifier: req.body.studentIdentifier,
        document: req.body.document || null,
      },
    });
    res.status(201).json({ verification });
  } catch (e) { next(e); }
});

router.get('/', async (req, res, next) => {
  try {
    const verifications = await prisma.studentVerification.findMany({
      where: { userId: req.user.id },
      orderBy: { createdAt: 'desc' },
      include: { campus: true },
    });
    res.json({ verifications });
  } catch (e) { next(e); }
});

router.get('/status', async (req, res, next) => {
  try {
    const latest = await prisma.studentVerification.findFirst({
      where: { userId: req.user.id },
      orderBy: { createdAt: 'desc' },
      include: { campus: true },
    });
    res.json({ status: latest?.status || 'none', verification: latest });
  } catch (e) { next(e); }
});

// Campuses list (untuk dropdown saat submit verification)
router.get('/campuses', async (req, res, next) => {
  try {
    const campuses = await prisma.campus.findMany({ orderBy: { name: 'asc' } });
    res.json({ campuses });
  } catch (e) { next(e); }
});

module.exports = router;
