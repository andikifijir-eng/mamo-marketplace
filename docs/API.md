# MAMO REST API

Base URL: `http://localhost:4000/api`
Auth: `Authorization: Bearer <JWT>` (kecuali endpoint publik).
Error format: `{ "error": "CODE", "message": "..." }`

## Auth

| Method | Endpoint | Role | Keterangan |
|---|---|---|---|
| POST | `/auth/register` | publik | Body: `email`, `password` (min 8), `fullName`, `phone?` → `{token, user}` |
| POST | `/auth/login` | publik | Body: `email`, `password` → `{token, user}` |
| POST | `/auth/logout` | auth | Stateless, client hapus token |
| GET | `/auth/me` | auth | User yang sedang login |
| POST | `/auth/forgot-password` | publik | Body: `email`; di non-production mengembalikan `resetToken` |
| POST | `/auth/reset-password` | publik | Body: `token`, `password` |

Password di-hash **bcrypt cost 12**. JWT expiry default `7d` (env `JWT_EXPIRES_IN`).

## Users & Profile

| Method | Endpoint | Role |
|---|---|---|
| GET | `/users/me` | auth |
| PUT | `/users/me` | auth — `fullName`, `phone`, `avatar`, `bio` |
| GET | `/users/:id` | auth — profil publik + rating seller |
| GET | `/users/me/addresses/list` | auth |
| POST | `/users/me/addresses` | auth |
| DELETE | `/users/me/addresses/:id` | auth |

## Categories

| Method | Endpoint | Role |
|---|---|---|
| GET | `/categories` | publik |
| GET | `/categories/:id` | publik |

## Products

| Method | Endpoint | Role |
|---|---|---|
| GET | `/products` | publik |
| GET | `/products/:id` | publik (opsional auth untuk `isFavorite`) |
| POST | `/products` | auth (otomatis naik ke role `seller`) |
| PUT | `/products/:id` | auth — hanya pemilik atau admin |
| DELETE | `/products/:id` | auth — soft delete (`status=archived`) |

**Query `GET /products`:** `search`, `category`, `min_price`, `max_price`, `condition` (`new`/`used`), `campus_id`, `seller_id`, `lat`+`lng`+`radius_km` (nearby), `sort` (`newest`/`price_asc`/`price_desc`/`popular`), `page`, `limit`.

## Favorites

| Method | Endpoint | Role |
|---|---|---|
| GET | `/favorites` | auth |
| POST | `/favorites` | auth — body `productId` (idempotent) |
| DELETE | `/favorites/:productId` | auth |

## Cart

| Method | Endpoint | Role |
|---|---|---|
| GET | `/cart` | auth — total dihitung dari harga DB |
| POST | `/cart/items` | auth — body `productId`, `quantity`; validasi stok & larangan beli produk sendiri |
| PUT | `/cart/items/:id` | auth — body `quantity` |
| DELETE | `/cart/items/:id` | auth |

## Orders

| Method | Endpoint | Role |
|---|---|---|
| POST | `/orders` | auth — body `cartItemIds[]`, `deliveryMethod` (`cod`/`delivery`/`pickup`), `deliveryAddress?`, `latitude?`, `longitude?` |
| GET | `/orders` | auth — `?as=seller` untuk pesanan masuk |
| GET | `/orders/:id` | auth — hanya buyer/seller order tsb atau admin |
| PUT | `/orders/:id/status` | auth — lihat transisi di bawah |

Checkout memakai **database transaction**: satu order dibuat per seller, stok dikurangi atomik
(`updateMany` dengan syarat `stock >= qty`) sehingga tidak terjadi overselling; item cart yang
di-checkout dihapus dalam transaction yang sama.

Transisi status yang sah:

```
pending  → accepted | rejected | cancelled
accepted → processed | cancelled
processed→ ready | cancelled
ready    → completed | cancelled
```

Hak akses: seller → `accepted`/`processed`/`ready`/`rejected`; buyer → `cancelled` (dari pending/accepted),
`completed` (dari ready); admin → semua. Cancel/reject mengembalikan stok.

## Chat (realtime via WebSocket)

| Method | Endpoint | Role |
|---|---|---|
| GET | `/conversations` | auth |
| POST | `/conversations` | auth — body `sellerId`, `productId?` |
| GET | `/conversations/:id/messages` | auth — hanya peserta |
| POST | `/conversations/:id/messages` | auth — body `message` |

**WebSocket:** `ws://localhost:4000/ws?token=<JWT>`
Event masuk: `{type:'chat:message', conversationId, message}`, `{type:'order:new'|'order:status', ...}`.

## Notifications

| Method | Endpoint | Role |
|---|---|---|
| GET | `/notifications` | auth — `{notifications, unread}` |
| PUT | `/notifications/:id/read` | auth |
| PUT | `/notifications/read-all` | auth |

## Reviews

| Method | Endpoint | Role |
|---|---|---|
| POST | `/reviews` | auth — body `orderId`, `rating` (1–5), `comment?` |
| GET | `/products/:id/reviews` | publik |

Aturan: hanya buyer dari order tsb, order harus `completed`, satu review per order
(`orderId` UNIQUE) → review ganda ditolak 409.

## Verification (mahasiswa)

| Method | Endpoint | Role |
|---|---|---|
| POST | `/verification` | auth — body `studentIdentifier`, `campusId?`, `document?` |
| GET | `/verification` | auth |
| GET | `/verification/status` | auth |
| GET | `/verification/campuses` | auth |

Satu user hanya boleh punya satu pengajuan aktif → 409.

## Upload

| Method | Endpoint | Role |
|---|---|---|
| POST | `/upload/image` | auth — multipart field `image`, maks 5 MB, jpg/png/webp/gif → `{url}` absolut |
| POST | `/upload/images` | auth — multipart field `images[]` (maks 10) → `{urls}` |

## Seller

| Method | Endpoint | Role |
|---|---|---|
| GET | `/seller/dashboard` | seller/admin |
| GET | `/seller/products` | seller/admin |
| GET | `/seller/orders` | seller/admin |
| GET | `/seller/statistics` | seller/admin |

Dashboard: total/aktif/terjual listing, order pending, pendapatan, rating, unread chat, penjualan 7 hari.

## Reports

| Method | Endpoint | Role |
|---|---|---|
| POST | `/reports` | auth — body `productId`, `reason`, `detail?` |
| GET | `/reports` | admin |
| PUT | `/reports/:id` | admin — `status`: `open`/`resolved`/`rejected` |

## Admin

| Method | Endpoint |
|---|---|
| GET | `/admin/dashboard` |
| GET | `/admin/users` · `/admin/users/:id` |
| PUT | `/admin/users/:id/status` |
| GET | `/admin/products` · PUT `/admin/products/:id/status` |
| GET | `/admin/orders` · PUT `/admin/orders/:id/status` |
| GET | `/admin/verifications` · PUT `/admin/verifications/:id` |
| GET/POST | `/admin/categories` · PUT/DELETE `/admin/categories/:id` |

Semua `/admin/*` butuh role `admin` (middleware `roleRequired('admin')`) — bukan hanya disembunyikan di frontend.

## Rate limit

300 request / menit / IP pada seluruh `/api`.
