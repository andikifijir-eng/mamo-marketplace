# Cara Edit Manual & Melihat Preview

## 1. Di mana file untuk edit tiap halaman

Semua UI mobile ada di **`D:\MAMO\app\lib\`**. Satu halaman = satu file.

| Halaman | File yang diedit | URL preview |
|---|---|---|
| Splash | `screens/splash_screen.dart` | `#/splash` |
| Onboarding (4 layar) | `screens/onboarding_screen.dart` | `#/onboarding` |
| **Login** | `screens/login_screen.dart` | `#/login` |
| **Register** | `screens/register_screen.dart` | `#/register` |
| **Home** | `screens/home_screen.dart` | `#/home` |
| Bottom navigation | `screens/home_shell.dart` | (selalu tampil) |
| Search + filter | `screens/search_screen.dart` | `#/search` |
| Detail produk | `screens/product_detail_screen.dart` | `#/product/<id>` |
| Keranjang | `screens/cart_screen.dart` | `#/cart` |
| Checkout | `screens/checkout_screen.dart` | `#/checkout` |
| Pesanan saya | `screens/orders_screen.dart` | `#/orders` |
| Detail pesanan | `screens/order_detail_screen.dart` | `#/order/<id>` |
| Chat list | `screens/chat_list_screen.dart` | `#/chat` |
| Ruang chat | `screens/chat_screen.dart` | `#/chat/<id>` |
| Notifikasi | `screens/notifications_screen.dart` | `#/notifications` |
| Favorit | `screens/favorites_screen.dart` | `#/favorites` |
| Profil | `screens/profile_screen.dart` | `#/profile` |
| Pengaturan | `screens/settings_screen.dart` | `#/settings` |
| Verifikasi mahasiswa | `screens/verification_screen.dart` | `#/verification` |
| Dashboard penjual | `screens/seller_dashboard_screen.dart` | `#/seller` |
| Listing penjual | `screens/seller_products_screen.dart` | `#/seller/products` |
| Pesanan masuk | `screens/seller_orders_screen.dart` | `#/seller/orders` |
| Jual / edit barang | `screens/sell_product_screen.dart` | `#/sell` |

### File pendukung (bukan "halaman", tapi sering perlu diubah)

| Isi | File | Kapan diedit |
|---|---|---|
| **Warna & tema global** | `core/theme.dart` | ganti warna aplikasi (`MamoColors`, `MamoRadius`) |
| **Token desain halaman auth** | `core/design_tokens.dart` | Login/Register: `MamoDesign`, `MamoInput`, `MamoCheckbox`, dll |
| **Komponen umum** | `widgets/common.dart` | `ProductCard`, `StatusPill`, `EmptyState`, `MamoLogo`, `rupiah` |
| **Alamat API** | `core/api_client.dart` | ganti baseUrl backend |
| **Daftar halaman/route** | `router.dart` | tambah halaman baru atau ubah alur navigasi |
| **Ambil data dari API** | `data/repositories.dart`, `data/auth_repository.dart` | endpoint baru |
| **State / cache data** | `state/providers.dart` | provider Riverpod |
| **Model data** | `models/models.dart` | bentuk JSON → objek |

---

## 2. Melihat preview

### Cara A — Preview cepat (setelah edit, sekali build)

```
1. start-all.bat          (sekali saja, biar backend + DB + web jalan)
2. Edit file Dart
3. cd D:\MAMO\app
   flutter build web
4. Buka / refresh  http://localhost:8080/#/<halaman>
```

Untuk melihat satu halaman langsung, tambahkan hash-nya:

- `http://localhost:8080/#/cart`
- `http://localhost:8080/#/register`
- `http://localhost:8080/#/product/<id>` (id produk dari database)

> Halaman yang butuh login (`#/home`, `#/cart`, dst) akan otomatis dialihkan ke
> `#/login` kalau belum masuk. Login dulu pakai `pembeli@mamo.id` / `password123`.

### Cara B — Preview dengan HOT RELOAD (paling enak untuk edit manual)

```
1. start-all.bat          (jendela 1)
2. preview.bat            (jendela 2)  -> buka Chrome otomatis
3. Edit file Dart lalu simpan
4. Di jendela preview.bat tekan:
      r  = hot reload   (perubahan UI langsung terlihat, tanpa restart)
      R  = hot restart  (kalau state ikut berubah)
      q  = keluar
```

Cara ini **tidak perlu `flutter build web` tiap kali** — jauh lebih cepat.

### Ukuran layar HP

Di Chrome: tekan `F12` → klik ikon ponsel (`Ctrl+Shift+M`) → pilih **iPhone 14** atau **Pixel 7**.
Itu membuat tampilan persis proporsi HP, sama seperti waktu mencocokkan desain.

---

## 3. Kalau mau bandingkan dengan desain Figma

Buat file HTML berdampingan (desain kiri, hasil live kanan) seperti yang sudah dipakai
untuk Login/Register/Home:

`C:\Users\LENOVO\AppData\Local\Temp\mamo_login\preview_home.html`

Polanya: `<img>` berisi desain (base64) + `<iframe src="http://localhost:8080/#/<halaman>">`,
keduanya dibungkus ukuran frame desain. Kalau perlu, minta saya buatkan untuk halaman lain.

---

## 4. Setelah desain dianggap benar

Baru build APK (perintah dari kamu):

```bash
cd D:\MAMO\app
flutter build apk --release ^
  --dart-define=MAMO_API=http://<IP-LAN-KOMPUTER>:4000/api ^
  --dart-define=MAMO_WS=ws://<IP-LAN-KOMPUTER>:4000
```

Lalu pasang ke HP: `adb install -r build/app/outputs/flutter-apk/app-release.apk`

---

## 5. Admin Web (React) — kalau mau edit juga

| Isi | File |
|---|---|
| Halaman | `D:\MAMO\admin\src\pages\*.tsx` |
| Sidebar & header | `admin/src/Layout.tsx` |
| Warna & style | `admin/src/styles.css` |
| Ambil data API | `admin/src/api.ts` |
| Daftar halaman | `admin/src/main.tsx` |

Preview: `cd D:\MAMO\admin && npm run dev` → http://localhost:5173
(hot reload otomatis, tidak perlu build ulang)
