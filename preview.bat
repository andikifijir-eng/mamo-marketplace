@echo off
REM ============================================================
REM  MAMO — mode PREVIEW / EDIT
REM  Menjalankan app di Chrome dengan HOT RELOAD.
REM  Setelah edit file Dart: simpan file, lalu tekan "r" di jendela ini
REM  (hot reload) atau "R" (hot restart). Tidak perlu build ulang manual.
REM
REM  Backend + database harus jalan dulu -> jalankan start-all.bat
REM ============================================================
setlocal
set ROOT=%~dp0

echo ============================================================
echo   MAMO — Preview dengan hot reload (Chrome)
echo ============================================================
echo.

curl -s -o nul --max-time 3 http://localhost:4000/api/health 2>nul
if not %errorlevel%==0 (
  echo [!] Backend belum jalan. Jalankan start-all.bat dulu di jendela lain.
  echo.
  pause
  exit /b 1
)
echo [OK] Backend terdeteksi.
echo.

echo Daftar route untuk dibuka langsung di browser (ganti #/... sesuai kebutuhan):
echo    #/login        Login
echo    #/register     Register
echo    #/home         Home
echo    #/search       Search
echo    #/favorites    Favorit
echo    #/cart         Keranjang
echo    #/chat         Chat
echo    #/profile      Profil
echo    #/seller       Dashboard penjual
echo    #/sell         Jual barang
echo.
echo Tekan "r" = hot reload, "R" = hot restart, "q" = keluar.
echo ============================================================
echo.

cd /d "%ROOT%app"
flutter run -d chrome --dart-define=MAMO_API=http://localhost:4000/api --dart-define=MAMO_WS=ws://localhost:4000

pause
