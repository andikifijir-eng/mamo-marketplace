function notFound(req, res) {
  res.status(404).json({ error: 'NOT_FOUND', message: `Route ${req.method} ${req.path} tidak ditemukan` });
}

/**
 * Kode Prisma yang berarti "database tidak bisa dijangkau / koneksi putus".
 * Paling sering P1001 (server tidak jalan).
 */
const DB_UNREACHABLE_CODES = ['P1000', 'P1001', 'P1002', 'P1003', 'P1008', 'P1010', 'P1017'];

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

  // Database tidak terjangkau.
  // JANGAN kirim detail Prisma ke aplikasi: pesannya panjang (berisi path file
  // dan potongan kode server) sehingga di app muncul jadi snackbar raksasa yang
  // tidak berguna bagi user. Detailnya tetap dicatat lengkap di log server.
  if (DB_UNREACHABLE_CODES.includes(err.code)) {
    console.error('[error] database tidak terjangkau:', err.code, '-', err.message);
    return res.status(503).json({
      error: 'DB_UNAVAILABLE',
      message: 'Server tidak bisa mengakses database. Pastikan PostgreSQL sudah jalan.',
    });
  }

  console.error('[error]', err);
  res.status(err.status || 500).json({
    error: 'INTERNAL_ERROR',
    // `message` harus tetap layak ditampilkan ke user (dipakai langsung sebagai
    // snackbar). Detail mentah ditaruh di `debug`, hanya saat bukan production.
    message: process.env.NODE_ENV === 'production'
      ? 'Terjadi kesalahan di server. Coba lagi.'
      : 'Terjadi kesalahan di server.',
    ...(process.env.NODE_ENV === 'production' ? {} : { debug: err.message }),
  });
}

module.exports = { notFound, errorHandler };
