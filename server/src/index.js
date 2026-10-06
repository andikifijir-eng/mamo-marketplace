require('dotenv').config();
const http = require('http');
const express = require('express');
const cors = require('cors');
const rateLimit = require('express-rate-limit');
const path = require('path');
const fs = require('fs');

const { errorHandler, notFound } = require('./middleware/error');
const { setupWebSocket } = require('./lib/ws');

const authRoutes = require('./routes/auth');
const userRoutes = require('./routes/users');
const categoryRoutes = require('./routes/categories');
const productRoutes = require('./routes/products');
const favoriteRoutes = require('./routes/favorites');
const cartRoutes = require('./routes/cart');
const orderRoutes = require('./routes/orders');
const chatRoutes = require('./routes/chat');
const notificationRoutes = require('./routes/notifications');
const reviewRoutes = require('./routes/reviews');
const verificationRoutes = require('./routes/verification');
const sellerRoutes = require('./routes/seller');
const adminRoutes = require('./routes/admin');
const uploadRoutes = require('./routes/upload');
const reportRoutes = require('./routes/reports');

const app = express();
const server = http.createServer(app);

// Upload dir
const uploadDir = path.join(__dirname, '..', process.env.UPLOAD_DIR || 'uploads');
fs.mkdirSync(uploadDir, { recursive: true });

app.use(cors({ origin: process.env.CORS_ORIGIN || '*' }));
app.use(express.json({ limit: '2mb' }));
app.use('/uploads', express.static(uploadDir));

app.use('/api', rateLimit({ windowMs: 60_000, max: 300, standardHeaders: true, legacyHeaders: false }));

app.get('/api/health', (req, res) => res.json({ ok: true, service: 'mamo-server', time: new Date().toISOString() }));

app.use('/api/auth', authRoutes);
app.use('/api/users', userRoutes);
app.use('/api/categories', categoryRoutes);
app.use('/api/products', productRoutes);
app.use('/api/favorites', favoriteRoutes);
app.use('/api/cart', cartRoutes);
app.use('/api/orders', orderRoutes);
app.use('/api', chatRoutes); // /conversations/*
app.use('/api/notifications', notificationRoutes);
app.use('/api', reviewRoutes); // /reviews, /products/:id/reviews
app.use('/api/verification', verificationRoutes);
app.use('/api/seller', sellerRoutes);
app.use('/api/admin', adminRoutes);
app.use('/api/upload', uploadRoutes);
app.use('/api/reports', reportRoutes);

app.use(notFound);
app.use(errorHandler);

setupWebSocket(server);

const PORT = process.env.PORT || 4000;
server.listen(PORT, () => {
  console.log(`[mamo-server] listening on http://localhost:${PORT}`);
});
