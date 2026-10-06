# MAMO — Mapping Figma → Implementasi

Source of truth: `https://www.figma.com/design/sCjI7KHjXKO7riLBc50FW2/MAMO`
File berisi 2 page: **Mobile** (23 screen) dan **Admin Website** (7 screen + style guide).

Design token diekstrak dari layer **Color** dan **Logo**, lalu dipakai konsisten di
`app/lib/core/theme.dart` dan `admin/src/styles.css`.

## Design Token (dari Figma)

| Token | Nilai | Pemakaian |
|---|---|---|
| Primary | `#3B5BFF` | tombol utama, aksen, chart line |
| Brand gradient | `#1E2A78 → #3B5BFF` | splash, kartu login, logo |
| Indigo | `#4F46E5` | sidebar active state, brand |
| Purple | `#8B5CF6` | ikon statistik, chart sekunder |
| Background | `#F7FBFB` | canvas seluruh screen admin |
| Surface | `#FFFFFF` | kartu, sidebar, tabel |
| Border | `#EDF1F5` | garis kartu & tabel |
| Text | `#111827` / `#6B7280` / `#9CA3AF` | judul / sekunder / muted |
| Success / Warning / Danger | `#22C55E` / `#FACC15` / `#EF4444` | status pill |
| Font | **Inter** | seluruh UI |
| Radius | card 16px, pill 999px | kartu, tombol, badge |

## Mobile — 23 screen → Flutter

| Figma screen | Flutter file | API / Data |
|---|---|---|
| Splash | `screens/splash_screen.dart` | `GET /auth/me` (auto-login) |
| Onboarding-1..4 | `screens/onboarding_screen.dart` | 4 halaman PageView + flag lokal |
| Login | `screens/login_screen.dart` | `POST /auth/login`, `POST /auth/forgot-password` |
| Register | `screens/register_screen.dart` | `POST /auth/register` |
| Home | `screens/home_screen.dart` | `GET /products`, `GET /categories` |
| Search | `screens/search_screen.dart` | `GET /products?search=&category=&min_price=&max_price=&condition=&sort=` |
| Spesific-search | `screens/search_screen.dart` (bottom sheet filter) | query param `category` dari Home |
| Detail-produk | `screens/product_detail_screen.dart` | `GET /products/:id`, `GET /products/:id/reviews`, `POST/DELETE /favorites` |
| Chat | `screens/chat_list_screen.dart` | `GET /conversations` |
| Chat-penjual | `screens/chat_screen.dart` | `GET/POST /conversations/:id/messages` + WebSocket `/ws` |
| Notifikasi | `screens/notifications_screen.dart` | `GET /notifications`, `PUT /notifications/read-all` |
| Favorit | `screens/favorites_screen.dart` | `GET /favorites`, `DELETE /favorites/:productId` |
| Listing | `screens/seller_products_screen.dart` | `GET /seller/products`, `DELETE /products/:id` |
| Jual-barang-1..4 | `screens/sell_product_screen.dart` | `POST /upload/image`, `POST /products`, `PUT /products/:id` |
| Pengaturam (Pengaturan) | `screens/settings_screen.dart` | `PUT /users/me` |
| Profile | `screens/profile_screen.dart` | `GET /auth/me`, `GET /verification/status` |
| — (cart & checkout flow) | `screens/cart_screen.dart`, `screens/checkout_screen.dart` | `GET /cart`, `POST /orders` |
| — (order tracking) | `screens/orders_screen.dart`, `screens/order_detail_screen.dart` | `GET /orders`, `PUT /orders/:id/status`, `POST /reviews` |
| — (seller dashboard) | `screens/seller_dashboard_screen.dart` | `GET /seller/dashboard`, `GET /seller/statistics` |
| Color / Logo / Share | `core/theme.dart`, `widgets/common.dart` (`MamoLogo`) | style guide, bukan screen |

Komponen reusable: `ProductCard`, `ProductImageBox`, `StatusPill`, `EmptyState`, `ErrorState`,
`AsyncView`, `SectionHeader`, `MamoLogo`, `MamoHeader`, `HomeShell` (bottom navigation).

## Admin Web — 7 screen → React

| Figma screen | File | API |
|---|---|---|
| Login | `pages/LoginPage.tsx` | `POST /auth/login` + guard role admin |
| Dashboard | `pages/DashboardPage.tsx` | `GET /admin/dashboard`, `GET /admin/products?status=flagged` |
| Users | `pages/UsersPage.tsx` | `GET /admin/users`, `PUT /admin/users/:id/status` |
| Listings | `pages/ListingsPage.tsx` | `GET /admin/products`, `PUT /admin/products/:id/status` |
| Moderation-queue | `pages/ModerationPage.tsx` | `GET /admin/products?status=flagged|draft`, approve/reject |
| Reports | `pages/ReportsPage.tsx` | `GET /reports`, `PUT /reports/:id` |
| Analytics | `pages/AnalyticsPage.tsx` | agregasi `GET /admin/{products,orders,users}` + recharts |
| — (tambahan) | `pages/VerificationsPage.tsx` | `GET /admin/verifications`, `PUT /admin/verifications/:id` |
| — (tambahan) | `pages/OrdersPage.tsx` | `GET /admin/orders`, `PUT /admin/orders/:id/status` |
| — (tambahan) | `pages/CategoriesPage.tsx` | CRUD `/admin/categories` |
| Color / Logo / Sidebar / Header | `styles.css`, `Layout.tsx`, `components.tsx`, `icons.tsx` | design system |

## Perbedaan yang disengaja

1. **Figma pakai data dummy statis** ("Penjual 1", "Rp 8.250.000", angka 16.469). Implementasi
   menarik semua angka dari PostgreSQL, jadi nilai di layar = data nyata.
2. **Inkonsistensi Figma yang tidak dikopi**: typo "Acvtive users" → "Active users";
   "Missleading information" → "misleading"; breadcrumb statis `Admin / Listings` di semua
   halaman → breadcrumb dinamis per halaman; ID `RPT-1087` duplikat → ID unik dari database.
3. **Screen tambahan** yang tidak ada di Figma tapi dibutuhkan alur end-to-end: cart, checkout,
   order detail, verifikasi mahasiswa, transaksi & kategori admin.
4. **Visual QA pixel-level** belum bisa dijalankan otomatis (canvas Flutter tidak bisa dibaca
   sebagai teks, dan akses Figma via sesi browser terputus). Verifikasi render yang sudah
   dilakukan: analisis distribusi warna screenshot mobile web → `#F7FBFB` (82.7%) dan
   `#3B5BFF` (7.8%) muncul sesuai token; 1281 warna unik (bukan halaman kosong).
