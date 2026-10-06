# MAMO — Database PostgreSQL

Schema di `server/prisma/schema.prisma`. Migrasi: `server/prisma/migrations/`.
PostgreSQL **17.6** (portable build, port 5432, database `mamo`).

## 19 Tabel

### USER
- **users** — `id` (uuid PK), `email` (UNIQUE), `password_hash`, `role` (buyer|seller|admin), `account_status` (active|suspended|banned), `created_at`, `updated_at`
- **user_profiles** — `id` PK, `user_id` (UNIQUE, FK→users CASCADE), `full_name`, `phone`, `avatar`, `bio`, timestamps

### CAMPUS
- **campuses** — `id` PK, `name`, `city`, `address`, `latitude`, `longitude`
- **student_verifications** — `id` PK, `user_id` FK→users CASCADE, `campus_id` FK→campuses, `student_identifier`, `document`, `status` (pending|approved|rejected), `reviewed_by`, `reviewed_at`, `created_at` · INDEX(user_id), INDEX(status)

### ADDRESS
- **user_addresses** — `id` PK, `user_id` FK→users CASCADE, `label`, `address`, `latitude`, `longitude`, `is_default`, `created_at` · INDEX(user_id)

### CATEGORY
- **categories** — `id` PK, `parent_id` FK→categories (self, hierarki), `name`, `icon`, `status`, `created_at`

### PRODUCT
- **products** — `id` PK, `seller_id` FK→users, `category_id` FK→categories, `campus_id` FK→campuses, `name`, `description`, `price`, `stock`, `condition` (new|used), `status` (draft|active|sold|archived|flagged|rejected), `latitude`, `longitude`, `location`, timestamps · INDEX(seller_id, category_id, status, campus_id)
- **product_images** — `id` PK, `product_id` FK→products CASCADE, `image_url`, `sort_order` · INDEX(product_id)

### FAVORITE
- **favorites** — `id` PK, `user_id` FK, `product_id` FK, `created_at` · **UNIQUE(user_id, product_id)** · INDEX(product_id)

### CART
- **carts** — `id` PK, `user_id` (UNIQUE, FK CASCADE), timestamps
- **cart_items** — `id` PK, `cart_id` FK→carts CASCADE, `product_id` FK→products CASCADE, `quantity` · **UNIQUE(cart_id, product_id)** · INDEX(product_id)

### ORDER
- **orders** — `id` PK, `buyer_id` FK→users, `seller_id` FK→users, `total_amount`, `delivery_method`, `delivery_address`, `latitude`, `longitude`, `status` (pending|accepted|processed|ready|completed|cancelled|rejected), timestamps · INDEX(buyer_id, seller_id, status)
- **order_items** — `id` PK, `order_id` FK→orders CASCADE, `product_id` FK→products, `quantity`, `price`, `subtotal` · INDEX(product_id)

`order_items.price` menyimpan harga **snapshot** saat transaksi, jadi histori harga tidak
berubah kalau seller mengubah harga produk.

### CHAT
- **conversations** — `id` PK, `buyer_id` FK→users, `seller_id` FK→users, `product_id` FK→products, `created_at` · **UNIQUE(buyer_id, seller_id, product_id)** · INDEX(seller_id)
- **messages** — `id` PK, `conversation_id` FK→conversations CASCADE, `sender_id` FK→users, `message`, `is_read`, `created_at` · INDEX(conversation_id)

### NOTIFICATION
- **notifications** — `id` PK, `user_id` FK→users CASCADE, `type`, `title`, `body`, `is_read`, `created_at` · INDEX(user_id)

### REVIEW
- **reviews** — `id` PK, `order_id` (**UNIQUE** FK→orders CASCADE), `product_id` FK, `reviewer_id` FK→users, `seller_id` FK→users, `rating` (1–5), `comment`, `created_at` · INDEX(product_id, seller_id)

`order_id` UNIQUE mencegah review ganda untuk satu transaksi.

### REPORT (moderasi)
- **reports** — `id` PK, `reporter_id` FK→users, `product_id` FK→products, `reason`, `detail`, `status` (open|resolved|rejected), `created_at` · INDEX(status)

## Relasi penting

```
users ─1:1─ user_profiles
users ─1:N─ products (seller)          products ─1:N─ product_images
users ─1:N─ orders (buyer / seller)    orders   ─1:N─ order_items ─N:1─ products
users ─1:1─ carts ─1:N─ cart_items     orders   ─1:1─ reviews
users ─N:M─ products (via favorites, unique pair)
conversations ─1:N─ messages
```

## Aturan yang dijaga di level database

| Aturan | Implementasi |
|---|---|
| Satu email = satu akun | UNIQUE(`users.email`) |
| Favorite tidak duplikat | UNIQUE(`favorites.user_id, product_id`) |
| Satu produk satu kali per cart | UNIQUE(`cart_items.cart_id, product_id`) |
| Satu review per transaksi | UNIQUE(`reviews.order_id`) |
| Satu pengajuan verifikasi aktif | dicek di service (pending/approved) |
| Harga transaksi stabil | snapshot di `order_items.price` + `subtotal` |

## Seed development

`cd server && node prisma/seed.js` — 1 admin, 3 seller, 1 buyer, 6 kategori, 8 produk, campuses.
Dummy hanya untuk pengembangan; aplikasi mengambil data utama dari API/DB.
