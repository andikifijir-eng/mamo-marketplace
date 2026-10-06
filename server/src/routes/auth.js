const express = require('express');
const bcrypt = require('bcryptjs');
const crypto = require('crypto');
const { z } = require('zod');
const prisma = require('../lib/prisma');
const { signToken } = require('../lib/jwt');
const { authRequired } = require('../middleware/auth');
const { validate } = require('../middleware/validate');

const router = express.Router();

const registerSchema = z.object({
  email: z.string().email(),
  password: z.string().min(8),
  fullName: z.string().min(2),
  phone: z.string().optional(),
});

const loginSchema = z.object({
  email: z.string().email(),
  password: z.string().min(1),
});

function publicUser(u) {
  return {
    id: u.id, email: u.email, role: u.role, accountStatus: u.accountStatus,
    createdAt: u.createdAt,
    profile: u.profile ? {
      fullName: u.profile.fullName, phone: u.profile.phone,
      avatar: u.profile.avatar, bio: u.profile.bio,
    } : null,
  };
}

router.post('/register', validate(registerSchema), async (req, res, next) => {
  try {
    const { email, password, fullName, phone } = req.body;
    const exists = await prisma.user.findUnique({ where: { email } });
    if (exists) return res.status(409).json({ error: 'CONFLICT', message: 'Email sudah terdaftar' });

    const passwordHash = await bcrypt.hash(password, 12);
    const user = await prisma.user.create({
      data: {
        email, passwordHash,
        profile: { create: { fullName, phone: phone || null } },
        cart: { create: {} },
      },
      include: { profile: true },
    });
    const token = signToken(user);
    res.status(201).json({ token, user: publicUser({ ...user, profile: user.profile }) });
  } catch (e) { next(e); }
});

router.post('/login', validate(loginSchema), async (req, res, next) => {
  try {
    const { email, password } = req.body;
    const user = await prisma.user.findUnique({ where: { email }, include: { profile: true } });
    if (!user) return res.status(401).json({ error: 'UNAUTHORIZED', message: 'Email atau password salah' });
    const ok = await bcrypt.compare(password, user.passwordHash);
    if (!ok) return res.status(401).json({ error: 'UNAUTHORIZED', message: 'Email atau password salah' });
    if (user.accountStatus !== 'active') return res.status(403).json({ error: 'FORBIDDEN', message: 'Akun tidak aktif' });
    const token = signToken(user);
    res.json({ token, user: publicUser(user) });
  } catch (e) { next(e); }
});

router.post('/logout', authRequired, async (req, res) => {
  // JWT stateless: logout = client menghapus token
  res.json({ ok: true });
});

router.get('/me', authRequired, async (req, res, next) => {
  try {
    const user = await prisma.user.findUnique({ where: { id: req.user.id }, include: { profile: true } });
    res.json({ user: publicUser(user) });
  } catch (e) { next(e); }
});

// Forgot password: buat token reset (disimpan hashed di tabel verification-agnostic).
// Sederhana: kirim token via response hanya di non-production (karena tidak ada SMTP).
router.post('/forgot-password', validate(z.object({ email: z.string().email() })), async (req, res, next) => {
  try {
    const user = await prisma.user.findUnique({ where: { email: req.body.email } });
    if (!user) return res.json({ ok: true }); // jangan bocorkan email terdaftar/tidak
    const token = crypto.randomBytes(32).toString('hex');
    await prisma.user.update({
      where: { id: user.id },
      data: { /* disimpan di tabel terpisah via prisma tidak tersedia; gunakan cache sederhana */ },
    });
    resetTokens.set(token, { userId: user.id, expires: Date.now() + 30 * 60_000 });
    const out = { ok: true };
    if (process.env.NODE_ENV !== 'production') out.resetToken = token;
    res.json(out);
  } catch (e) { next(e); }
});

const resetTokens = new Map(); // in-memory, cukup untuk dev; production -> tabel/redis

router.post('/reset-password', validate(z.object({ token: z.string(), password: z.string().min(8) })), async (req, res, next) => {
  try {
    const entry = resetTokens.get(req.body.token);
    if (!entry || entry.expires < Date.now()) {
      return res.status(400).json({ error: 'INVALID_TOKEN', message: 'Token reset tidak valid/kedaluwarsa' });
    }
    const passwordHash = await bcrypt.hash(req.body.password, 12);
    await prisma.user.update({ where: { id: entry.userId }, data: { passwordHash } });
    resetTokens.delete(req.body.token);
    res.json({ ok: true });
  } catch (e) { next(e); }
});

module.exports = router;
