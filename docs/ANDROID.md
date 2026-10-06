# Menyambungkan MAMO ke HP Android

## Ringkasan

Aplikasi mobile MAMO (Flutter) bisa dipasang di HP Android dengan 2 cara:

| Cara | Butuh kabel | Cocok untuk |
|---|---|---|
| **A. Pasang APK** | Tidak | Coba-coba, demo, kirim ke teman |
| **B. `flutter run`** | Ya | Development / hot reload |

Keduanya butuh **HP dan komputer di jaringan WiFi yang sama**, karena app mengambil data dari
backend yang jalan di komputer.

---

## Persyaratan

1. **HP dan komputer satu WiFi.** Kalau HP pakai data seluler, tidak akan bisa.
2. **Backend hidup.** Jalankan `D:\MAMO\start-all.bat`.
3. **IP LAN komputer.** Jalankan `ipconfig`, cari adapter **Wi-Fi** (bukan VMware):
   ```
   Wireless LAN adapter Wi-Fi:
      IPv4 Address. . . . . . . . . . . : 192.168.100.114
   ```
   Catat IP ini. Kalau WiFi berubah jaringan, IP bisa berubah — cek ulang.
4. **Windows Firewall mengizinkan port 4000.** Kalau HP tidak bisa connect, jalankan sekali
   (PowerShell **as Administrator**):
   ```powershell
   New-NetFirewallRule -DisplayName "MAMO API 4000" -Direction Inbound -Protocol TCP -LocalPort 4000 -Action Allow
   ```

Cek backend dari sisi HP: buka browser di HP, akses `http://<IP-KOMPUTER>:4000/api/health`.
Kalau muncul `{"ok":true,...}` berarti jaringan sudah beres.

---

## Cara A — Pasang APK (tanpa kabel)

### 1. Build APK

```bash
cd D:\MAMO\app
flutter build apk --release ^
  --dart-define=MAMO_API=http://192.168.100.114:4000/api ^
  --dart-define=MAMO_WS=ws://192.168.100.114:4000
```

Ganti `192.168.100.114` dengan IP LAN komputermu. Ganti juga bagian kedua (`MAMO_WS`)
supaya chat realtime ikut jalan.

Hasilnya: `D:\MAMO\app\build\app\outputs\flutter-apk\app-release.apk`

> Build pertama bisa 5–15 menit karena Gradle mengunduh dependency. Build berikutnya jauh lebih cepat.
>
> `flutter build apk` butuh **Developer Mode** Windows aktif (Flutter membuat symlink untuk plugin).
> Kalau muncul pesan "Building with plugins requires symlink support", jalankan
> `start ms-settings:developers` dan aktifkan **Developer Mode**, lalu build ulang.

### 2. Kirim APK ke HP

Pilih salah satu:

- **Google Drive / WhatsApp**: upload APK, buka di HP, download.
- **Kabel USB**: copy file ke penyimpanan HP lewat File Explorer.
- **Server lokal** (praktis kalau satu WiFi):
  ```bash
  cd D:\MAMO\app\build\app\outputs\flutter-apk
  cd D:\MAMO\server && node tools/static-server.js "D:/MAMO/app/build/app/outputs/flutter-apk" 9000
  ```
  lalu di browser HP buka `http://<IP-KOMPUTER>:9000/app-release.apk`

### 3. Install di HP

1. Buka file APK di HP.
2. Android akan minta izin "Install unknown apps" → aktifkan untuk aplikasi yang kamu pakai
   (Files / Chrome / WhatsApp).
3. Install → buka **MAMO**.

---

## Cara B — `flutter run` via kabel USB

### 1. Aktifkan USB debugging di HP

1. **Pengaturan** → **Tentang ponsel** → ketuk **Nomor bentukan / Build number** 7 kali
   → muncul "You are now a developer".
2. **Pengaturan** → **Sistem** → **Opsi developer** → aktifkan **USB debugging**.
3. Colok kabel USB. Muncul dialog **"Allow USB debugging?"** di HP → **Allow** (centang
   "Always allow" biar tidak diminta lagi).

### 2. Pastikan terdeteksi

```bash
D:\flutter\bin\flutter.bat devices
# atau
C:\Users\LENOVO\AppData\Local\Android\sdk\platform-tools\adb.exe devices
```

Harus muncul HP-mu. Kalau kosong, coba:

- Ganti kabel USB (sebagian kabel hanya untuk charging).
- Cabut-colok, pilih mode **File Transfer / MTP** di HP.
- `adb kill-server && adb start-server` lalu cek lagi.
- Di HP: **Opsi developer** → **Revoke USB debugging authorizations**, colok ulang.
- Ganti port USB di komputer, hindari hub.

### 3. Jalankan

```bash
cd D:\MAMO\app
flutter run --dart-define=MAMO_API=http://192.168.100.114:4000/api ^
            --dart-define=MAMO_WS=ws://192.168.100.114:4000
```

Di terminal akan muncul menu: tekan `r` = hot reload, `R` = hot restart, `q` = keluar.

---

## Kenapa tidak pakai `10.0.2.2` atau `localhost`?

| Konteks | Alamat API |
|---|---|
| Android **emulator** | `http://10.0.2.2:4000/api` — `10.0.2.2` = localhost komputer dilihat dari emulator |
| **HP fisik** | `http://<IP-KOMPUTER>:4000/api` — mis. `http://192.168.100.114:4000/api` |
| Desktop / web / iOS simulator | `http://localhost:4000/api` |

`localhost` di HP berarti **HP itu sendiri**, bukan komputermu — itu sebabnya HP fisik wajib
pakai IP LAN.

---

## Yang sudah disiapkan di project

`app/android/app/src/main/AndroidManifest.xml` sudah berisi:

```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE"/>
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<application android:label="MAMO" android:usesCleartextTraffic="true" ...>
```

Dua hal penting di situ:

- **`INTERNET` di manifest `main/`.** Flutter hanya menaruh izin ini di manifest `debug/` dan
  `profile/`. Tanpa menambahkannya ke `main/`, APK **release** tidak bisa mengakses API sama
  sekali (di debug sepertinya jalan, padahal release gagal — jebakan yang mudah terlewat).
- **`usesCleartextTraffic="true"`.** Mulai Android 9 (API 28), HTTP biasa (`http://`) diblokir
  secara default. Karena backend lokal memakai `http://`, flag ini wajib. Untuk backend
  production, pakai HTTPS dan matikan flag ini.

---

## Troubleshooting

| Gejala | Penyebab | Solusi |
|---|---|---|
| App terbuka tapi "Tidak bisa terhubung ke server" | Backend/DB mati, atau IP salah | Jalankan `start-all.bat`; cek `http://<IP>:4000/api/health` dari browser HP |
| Health bisa dibuka di HP tapi app tetap gagal | IP di `--dart-define` salah / perlu build ulang | Build ulang APK dengan IP yang benar — `--dart-define` tertanam di saat build, bukan saat jalan |
| Semua gagal connect | Windows Firewall | Tambahkan rule port 4000 (lihat Persyaratan) |
| Produk tidak ada fotonya | URL gambar memakai `localhost` | Restart API dari `start-all.bat` (URL gambar dibuat dari host request) |
| Chat tidak realtime | Port WS diblokir / `MAMO_WS` tidak di-set | Chat tetap jalan lewat REST (refresh manual), atau build ulang dengan `MAMO_WS` benar |
| `flutter build apk` gagal: "requires symlink support" | Developer Mode Windows nonaktif | `start ms-settings:developers` → aktifkan Developer Mode |
| APK terinstall tapi langsung crash | APK lama / arsitektur tidak cocok | `flutter clean` lalu build ulang |
| HP tidak terdeteksi `adb devices` | Kabel/driver/USB debugging | Lihat langkah di Cara B |

---

## Kalau IP WiFi sering berubah

Cara paling nyaman: pakai **USB reverse port** sehingga HP mengakses `localhost` komputermu
lewat kabel, tanpa peduli IP.

```bash
# 1. Colok HP (USB debugging aktif)
adb reverse tcp:4000 tcp:4000

# 2. Build/run dengan API localhost
cd D:\MAMO\app
flutter run --dart-define=MAMO_API=http://localhost:4000/api
```

`adb reverse` membuat `localhost:4000` di HP diteruskan ke `localhost:4000` di komputer.
Kalau HP dicabut, jalankan `adb reverse` lagi.
