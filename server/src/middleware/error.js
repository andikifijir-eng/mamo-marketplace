function notFound(req, res) {
  res.status(404).json({ error: 'NOT_FOUND', message: `Route ${req.method} ${req.path} tidak ditemukan` });
}

// eslint-disable-next-line no-unused-vars
function errorHandler(err, req, res, next) {
  if (err.name === 'ZodError') {
    return res.status(400).json({
      error: 'VALIDATION_ERROR',
      message: 'Data tidak valid',
      details: err.issues.map((i) => ({ path: i.path.join('.'), message: i.message })),
    });
  }
  if (err.code === 'P2002') {
    return res.status(409).json({ error: 'CONFLICT', message: 'Data sudah ada (duplikat)' });
  }
  if (err.code === 'P2025') {
    return res.status(404).json({ error: 'NOT_FOUND', message: 'Data tidak ditemukan' });
  }
  console.error('[error]', err);
  res.status(err.status || 500).json({
    error: 'INTERNAL_ERROR',
    message: process.env.NODE_ENV === 'production' ? 'Terjadi kesalahan server' : err.message,
  });
}

module.exports = { notFound, errorHandler };
