const { verifyToken } = require('../lib/jwt');
const prisma = require('../lib/prisma');

async function authRequired(req, res, next) {
  const header = req.headers.authorization || '';
  const token = header.startsWith('Bearer ') ? header.slice(7) : null;
  if (!token) return res.status(401).json({ error: 'UNAUTHORIZED', message: 'Token tidak ada' });
  try {
    const payload = verifyToken(token);
    const user = await prisma.user.findUnique({ where: { id: payload.sub } });
    if (!user) return res.status(401).json({ error: 'UNAUTHORIZED', message: 'User tidak ditemukan' });
    if (user.accountStatus !== 'active') return res.status(403).json({ error: 'FORBIDDEN', message: 'Akun tidak aktif' });
    req.user = user;
    next();
  } catch {
    return res.status(401).json({ error: 'UNAUTHORIZED', message: 'Token tidak valid' });
  }
}

function roleRequired(...roles) {
  return (req, res, next) => {
    if (!req.user) return res.status(401).json({ error: 'UNAUTHORIZED' });
    if (!roles.includes(req.user.role)) {
      return res.status(403).json({ error: 'FORBIDDEN', message: 'Akses ditolak' });
    }
    next();
  };
}

module.exports = { authRequired, roleRequired };
