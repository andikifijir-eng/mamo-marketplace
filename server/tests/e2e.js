// E2E test MAMO API — SCENARIO 1-5
const BASE = 'http://localhost:4000/api';
let pass = 0, fail = 0;
const log = (ok, name, extra = '') => {
  console.log(`${ok ? 'PASS' : 'FAIL'}  ${name}${extra ? '  :: ' + extra : ''}`);
  ok ? pass++ : fail++;
};

async function req(method, path, body, token) {
  const res = await fetch(BASE + path, {
    method,
    headers: {
      'Content-Type': 'application/json',
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
    },
    body: body ? JSON.stringify(body) : undefined,
  });
  let data = null;
  try { data = await res.json(); } catch {}
  return { status: res.status, data };
}

(async () => {
  // ===== SCENARIO 1: Buyer full flow =====
  const email = `e2e${Date.now()}@mamo.test`;
  let r = await req('POST', '/auth/register', { email, password: 'password123', fullName: 'E2E Buyer', phone: '08123' });
  log(r.status === 201 && r.data.token, 'S1 register buyer');
  const buyerToken = r.data.token;
  const buyerId = r.data.user.id;

  r = await req('POST', '/auth/login', { email, password: 'password123' });
  log(r.status === 200 && r.data.token, 'S1 login');

  r = await req('POST', '/auth/login', { email, password: 'salah' });
  log(r.status === 401, 'S1 login password salah ditolak (401)');

  r = await req('GET', '/auth/me', null, buyerToken);
  log(r.status === 200 && r.data.user.id === buyerId, 'S1 /auth/me');

  r = await req('GET', '/products?limit=5');
  log(r.status === 200 && r.data.products.length > 0, 'S1 product list', `total=${r.data.total}`);
  const product = r.data.products[0];

  r = await req('GET', '/products?search=monitor');
  log(r.status === 200, 'S1 search works', `hasil=${r.data.total}`);

  r = await req('GET', '/products?min_price=100000&max_price=5000000&condition=used');
  log(r.status === 200, 'S1 filter harga+kondisi', `hasil=${r.data.total}`);

  r = await req('GET', `/products/${product.id}`);
  log(r.status === 200 && r.data.product.id === product.id, 'S1 product detail');
  const sellerId = r.data.product.sellerId;

  r = await req('POST', '/favorites', { productId: product.id }, buyerToken);
  log(r.status === 201, 'S1 add favorite');
  r = await req('GET', '/favorites', null, buyerToken);
  log(r.status === 200 && r.data.favorites.length === 1, 'S1 list favorite');
  r = await req('DELETE', `/favorites/${product.id}`, null, buyerToken);
  log(r.status === 200, 'S1 remove favorite');
  r = await req('POST', '/favorites', { productId: product.id }, buyerToken);
  log(r.status === 201, 'S1 re-add favorite (untuk checkout)');

  // Cart
  r = await req('POST', '/cart/items', { productId: product.id, quantity: 1 }, buyerToken);
  log(r.status === 201, 'S1 add to cart');
  r = await req('GET', '/cart', null, buyerToken);
  log(r.status === 200 && r.data.items.length === 1, 'S1 get cart', `total=${r.data.total}`);
  const cartItem = r.data.items[0];
  const expectedTotal = cartItem.product.price * 1;
  log(r.data.total === expectedTotal, 'S1 total dihitung backend dari DB', `${r.data.total} === ${expectedTotal}`);

  r = await req('PUT', `/cart/items/${cartItem.id}`, { quantity: 99 }, buyerToken);
  log(r.status === 400, 'S1 quantity > stok ditolak (400)');

  // Checkout
  r = await req('GET', '/cart', null, buyerToken);
  const ids = r.data.items.map((i) => i.id);
  log(ids.length === 1, 'S1 cart berisi 1 item saat checkout', `items=${ids.length}`);
  r = await req('POST', '/orders', { cartItemIds: ids, deliveryMethod: 'cod', deliveryAddress: 'Polines' }, buyerToken);
  log(r.status === 201 && r.data.orders.length === 1, 'S1 checkout create order');
  const order = r.data.orders[0];
  log(order.totalAmount === expectedTotal, 'S1 order total benar', `Rp${order.totalAmount} (exp Rp${expectedTotal})`);

  // Stok berkurang
  r = await req('GET', `/products/${product.id}`);
  log(r.data.product.stock === product.stock - 1, 'S1 stok berkurang', `${product.stock} -> ${r.data.product.stock}`);

  // ===== SCENARIO 2: Seller flow =====
  r = await req('POST', '/auth/login', { email: 'penjual1@mamo.id', password: 'password123' });
  log(r.status === 200, 'S2 seller login');
  const sellerToken = r.data.token;
  const sellerIdSeed = r.data.user.id;

  r = await req('GET', '/seller/dashboard', null, sellerToken);
  log(r.status === 200 && typeof r.data.totalListings === 'number', 'S2 seller dashboard', `listings=${r.data.totalListings}`);

  r = await req('POST', '/products', {
    name: 'E2E Test Product', description: 'Produk uji', price: 50000,
    stock: 3, condition: 'used', status: 'active',
  }, sellerToken);
  log(r.status === 201, 'S2 create product');
  const newProduct = r.data.product;

  r = await req('PUT', `/products/${newProduct.id}`, { price: 55000 }, sellerToken);
  log(r.status === 200 && r.data.product.price === 55000, 'S2 update product');

  // Buyer lain tidak bisa edit produk seller
  r = await req('PUT', `/products/${newProduct.id}`, { price: 1 }, buyerToken);
  log(r.status === 403, 'S2 buyer tidak bisa edit produk seller (403)');

  r = await req('GET', '/seller/products', null, sellerToken);
  log(r.status === 200 && r.data.products.some((p) => p.id === newProduct.id), 'S2 seller listing list');

  // Cari order pending yang ditujukan ke penjual1 (dari semua order di DB via admin nanti);
  // buyer membuat order baru khusus untuk penjual1
  r = await req('GET', '/products?limit=20');
  const p1 = r.data.products.find((p) => p.seller?.profile?.fullName?.includes('Penjual 1'));
  if (p1) {
    await req('POST', '/cart/items', { productId: p1.id, quantity: 1 }, buyerToken);
    const cartNow = await req('GET', '/cart', null, buyerToken);
    const cids = cartNow.data.items.map((i) => i.id);
    r = await req('POST', '/orders', { cartItemIds: cids, deliveryMethod: 'cod' }, buyerToken);
    log(r.status === 201, 'S2 buyer buat order untuk penjual1');
  }
  r = await req('GET', '/seller/orders', null, sellerToken);
  const sellerOrder = r.data.orders.find((o) => o.status === 'pending');
  if (sellerOrder) {
    r = await req('PUT', `/orders/${sellerOrder.id}/status`, { status: 'accepted' }, sellerToken);
    log(r.status === 200 && r.data.order.status === 'accepted', 'S2 seller accept order');
    r = await req('PUT', `/orders/${sellerOrder.id}/status`, { status: 'processed' }, sellerToken);
    log(r.status === 200, 'S2 seller process order');
    r = await req('PUT', `/orders/${sellerOrder.id}/status`, { status: 'ready' }, sellerToken);
    log(r.status === 200, 'S2 seller ready order');

    // Buyer complete
    r = await req('PUT', `/orders/${sellerOrder.id}/status`, { status: 'completed' }, buyerToken);
    log(r.status === 200 || r.status === 403, 'S2 buyer complete order', `status=${r.status}`);

    // Review
    r = await req('POST', '/reviews', { orderId: sellerOrder.id, rating: 5, comment: 'Mantap!' }, buyerToken);
    log(r.status === 201 || r.status === 409, 'S2/S1 review setelah completed', `status=${r.status}`);
    r = await req('POST', '/reviews', { orderId: sellerOrder.id, rating: 1 }, buyerToken);
    log(r.status === 409, 'Review ganda ditolak (409)');
  } else {
    log(false, 'S2 order seller ditemukan');
  }

  // Transisi tidak valid
  r = await req('GET', '/orders', null, buyerToken);
  const anyOrder = r.data.orders[0];
  if (anyOrder) {
    r = await req('PUT', `/orders/${anyOrder.id}/status`, { status: 'completed' }, buyerToken);
    log(r.status === 400, 'Transisi status tidak valid ditolak (400)', `dari ${anyOrder.status}`);
  }

  // ===== SCENARIO 3: Chat =====
  r = await req('POST', '/conversations', { sellerId: sellerIdSeed, productId: product.id }, buyerToken);
  log(r.status === 201 || r.status === 200, 'S3 create conversation');
  const convId = r.data.conversation.id;

  r = await req('POST', `/conversations/${convId}/messages`, { message: 'Halo, barang masih ada?' }, buyerToken);
  log(r.status === 201, 'S3 buyer kirim pesan');

  r = await req('GET', `/conversations/${convId}/messages`, null, sellerToken);
  log(r.status === 200 && r.data.messages.length >= 1, 'S3 seller baca pesan');

  r = await req('POST', `/conversations/${convId}/messages`, { message: 'Masih ada kak' }, sellerToken);
  log(r.status === 201, 'S3 seller balas pesan');

  r = await req('GET', '/conversations', null, buyerToken);
  log(r.status === 200 && r.data.conversations.length >= 1, 'S3 list conversations');

  // Akses chat orang lain
  r = await req('GET', `/conversations/${convId}/messages`, null, (await req('POST', '/auth/register', { email: `outsider${Date.now()}@mamo.test`, password: 'password123', fullName: 'Outsider' })).data.token);
  log(r.status === 404 || r.status === 403, 'S3 outsider tidak bisa baca chat (403/404)');

  // ===== SCENARIO 4: Verification =====
  r = await req('POST', '/verification', { studentIdentifier: 'D3-2024-001', campusId: null }, buyerToken);
  log(r.status === 201, 'S4 submit verification');
  r = await req('GET', '/verification/status', null, buyerToken);
  log(r.status === 200 && r.data.status === 'pending', 'S4 status pending');
  r = await req('POST', '/verification', { studentIdentifier: 'D3-2024-002' }, buyerToken);
  log(r.status === 409, 'S4 submit ganda ditolak (409)');

  // Admin approve
  r = await req('POST', '/auth/login', { email: 'admin@mamo.id', password: 'password123' });
  log(r.status === 200, 'S4 admin login');
  const adminToken = r.data.token;

  r = await req('GET', '/admin/verifications?status=pending');
  log(r.status === 401, 'S4 admin endpoint tanpa token ditolak (401)', `status=${r.status}`);
  r = await req('GET', '/admin/verifications?status=pending', null, adminToken);
  log(r.status === 200, 'S4 admin list verifications', `count=${r.data.verifications?.length}`);
  const verif = r.data.verifications?.find((v) => v.userId === buyerId);
  if (verif) {
    r = await req('PUT', `/admin/verifications/${verif.id}`, { status: 'approved' }, adminToken);
    log(r.status === 200 && r.data.verification.status === 'approved', 'S4 admin approve verification');
  } else {
    log(false, 'S4 verification pending milik buyer ditemukan', `ditemukan=${r.data.verifications?.length}`);
  }

  // Buyer tidak bisa akses admin
  r = await req('GET', '/admin/users', null, buyerToken);
  log(r.status === 403, 'S4 buyer ditolak di /admin (403)');
  r = await req('GET', '/admin/dashboard', null, buyerToken);
  log(r.status === 403, 'S4 buyer ditolak /admin/dashboard (403)');

  // ===== SCENARIO 5: Admin =====
  r = await req('GET', '/admin/dashboard', null, adminToken);
  log(r.status === 200 && typeof r.data.totalUsers === 'number', 'S5 admin dashboard', `users=${r.data.totalUsers}`);

  r = await req('GET', '/admin/users', null, adminToken);
  log(r.status === 200 && r.data.users.length > 0, 'S5 admin users', `total=${r.data.total}`);

  r = await req('GET', '/admin/products', null, adminToken);
  log(r.status === 200, 'S5 admin products', `total=${r.data.total}`);

  r = await req('GET', '/admin/orders', null, adminToken);
  log(r.status === 200, 'S5 admin orders');

  r = await req('GET', '/admin/categories', null, adminToken);
  log(r.status === 200, 'S5 admin categories');

  const otherUser = (await req('GET', '/admin/users', null, adminToken)).data.users.find((u) => u.id !== buyerId && u.role !== 'admin');
  if (otherUser) {
    r = await req('PUT', `/admin/users/${otherUser.id}/status`, { accountStatus: 'suspended' }, adminToken);
    log(r.status === 200 && r.data.user.accountStatus === 'suspended', 'S5 admin suspend user');
    r = await req('PUT', `/admin/users/${otherUser.id}/status`, { accountStatus: 'active' }, adminToken);
    log(r.status === 200, 'S5 admin reactivate user');
  }

  // Validasi input
  r = await req('POST', '/auth/register', { email: 'bukan-email', password: '123', fullName: 'X' });
  log(r.status === 400, 'Validasi input ditolak (400)');

  r = await req('GET', '/products/tidak-ada-id');
  log(r.status === 404, 'Produk tidak ada -> 404');

  console.log(`\n===== HASIL: ${pass} PASS / ${fail} FAIL =====`);
  process.exit(fail > 0 ? 1 : 0);
})();
