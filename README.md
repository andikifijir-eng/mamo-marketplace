# MAMO — Marketplace Mahasiswa Online

Marketplace jual-beli antar mahasiswa. **Flutter (mobile) + React (admin) + Express/Prisma (API) + PostgreSQL.**

```
Flutter Mobile ─┐
                ├─→ REST API (Express + Prisma) ─→ PostgreSQL
React Admin  ───┘         │
                          └─→ WebSocket (chat realtime)
```

## Struktur Project

```
D:\MAMO
├── app/            Flutter mobile app (Riverpod + go_router + Dio)
├── admin/          React + Vite + TS admin web (recharts)
├── server/         Express + Prisma + PostgreSQL + WebSocket
│   ├── prisma/     schema.prisma, migrations, seed.js
│   ├── src/routes/ 15 route module (auth, products, orders, chat, admin, ...)
│   ├── tests/      e2e.js (58 assertion end-to-end)
│   └── pgsql/      PostgreSQL 17.6 portable (tidak perlu install admin)
└── docs/           API.md, DATABASE.md, FIGMA-MAPPING.md, ANDROID.md
```

## Menjalankan Project

### 1. Database (PostgreSQL portable — sudah include)

```bash
cd D:\MAMO\server
./pgsql/bin/postgres.exe -D "D:/MAMO/server/pgsql_data" -p 5432    # biarkan jalan
```

Database `mamo` sudah dibuat dan terisi seed. Untuk reset dari nol:

```bash
./pgsql/bin/dropdb.exe -U postgres mamo
./pgsql/bin/createdb.exe -U postgres mamo
npx prisma migrate deploy
node prisma/seed.js
```

### 2. Backend API (port 4000)

```bash
cd D:\MAMO\server
cp .env.example .env      # lalu isi JWT_SECRET
npx prisma generate
node src/index.js
# → http://localhost:4000/api/health
```

### 3. Admin Web (port 5173 dev / 4173 preview)

```bash
cd D:\MAMO\admin
npm install
npm run dev        # http://localhost:5173  (proxy /api → :4000)
```

Login: `admin@mamo.id` / `password123`

### 4. Mobile App

```bash
cd D:\MAMO\app
flutter pub get
flutter run                  # emulator/device
flutter run -d chrome        # web
```

Untuk Android emulator, API default `http://10.0.2.2:4000/api`:

```bash
flutter run --dart-define=MAMO_API=http://10.0.2.2:4000/api
```

### 5. Menyambungkan ke HP Android

Panduan lengkap: **`docs/ANDROID.md`** (build APK, USB debugging, firewall, troubleshooting,
`adb reverse`).

```bash
cd D:\MAMO\app
flutter build apk --release ^
  --dart-define=MAMO_API=http://<IP-LAN-KOMPUTER>:4000/api ^
  --dart-define=MAMO_WS=ws://<IP-LAN-KOMPUTER>:4000
```

Cek IP LAN: `ipconfig` → adapter **Wi-Fi** → `IPv4 Address` (bukan VMware).

## Akun Seed

| Role   | Email              | Password    |
|--------|--------------------|-------------|
| admin  | admin@mamo.id      | password123 |
| seller | penjual1@mamo.id   | password123 |
| seller | penjual2@mamo.id   | password123 |
| seller | penjual3@mamo.id   | password123 |
| buyer  | pembeli@mamo.id    | password123 |

## Verifikasi (sudah dijalankan)

| Cek | Hasil |
|---|---|
| `node tests/e2e.js` (58 assertion, 5 skenario) | **58 PASS / 0 FAIL** |
| `flutter analyze` | **No issues found** |
| `flutter test` (11 unit + widget test) | **11/11 pass** |
| `flutter build web` | **Built build\web** |
| `tsc -b` (admin) | **0 error** |
| `vite build` (admin) | **built** |
| Endpoint admin via browser (9 halaman) | **semua render dengan data nyata** |

## Catatan Figma

Design token diambil dari file Figma MAMO (`sCjI7KHjXKO7riLBc50FW2`):

- Primary `#3B5BFF` · brand gradient `#1E2A78 → #3B5BFF` · indigo `#4F46E5` · purple `#8B5CF6`
- Background `#F7FBFB` · teks `#111827` / `#6B7280` / `#9CA3AF`
- Status: success `#22C55E` · warning `#FACC15` · danger `#EF4444`
- Font **Inter**, card radius 16px, pill radius 999px

Screen yang diimplementasikan (23 mobile + 7 admin) — lihat `docs/FIGMA-MAPPING.md`.
