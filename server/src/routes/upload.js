const express = require('express');
const multer = require('multer');
const path = require('path');
const fs = require('fs');
const crypto = require('crypto');
const { authRequired } = require('../middleware/auth');

const router = express.Router();

const uploadDir = path.join(__dirname, '..', '..', process.env.UPLOAD_DIR || 'uploads');
fs.mkdirSync(uploadDir, { recursive: true });

const ALLOWED = ['.jpg', '.jpeg', '.png', '.webp', '.gif'];

const storage = multer.diskStorage({
  destination: (req, file, cb) => cb(null, uploadDir),
  filename: (req, file, cb) => {
    const ext = path.extname(file.originalname).toLowerCase();
    cb(null, `${Date.now()}-${crypto.randomBytes(8).toString('hex')}${ext}`);
  },
});

const upload = multer({
  storage,
  limits: { fileSize: (parseInt(process.env.MAX_UPLOAD_MB) || 5) * 1024 * 1024 },
  fileFilter: (req, file, cb) => {
    const ext = path.extname(file.originalname).toLowerCase();
    if (!ALLOWED.includes(ext)) return cb(new Error('Hanya file gambar (jpg/png/webp/gif)'));
    cb(null, true);
  },
});

function absoluteUrl(req, filename) {
  const proto = req.headers['x-forwarded-proto'] || req.protocol || 'http';
  return `${proto}://${req.get('host')}/uploads/${filename}`;
}

router.post('/image', authRequired, upload.single('image'), (req, res) => {
  if (!req.file) return res.status(400).json({ error: 'VALIDATION_ERROR', message: 'File wajib diisi' });
  res.status(201).json({ url: absoluteUrl(req, req.file.filename) });
});

router.post('/images', authRequired, upload.array('images', 10), (req, res) => {
  if (!req.files?.length) return res.status(400).json({ error: 'VALIDATION_ERROR', message: 'Minimal 1 file' });
  res.status(201).json({ urls: req.files.map((f) => absoluteUrl(req, f.filename)) });
});

module.exports = router;
