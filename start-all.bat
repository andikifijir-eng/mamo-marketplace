@echo off
REM ============================================================
REM  MAMO — start semua layanan sekaligus
REM  Menunggu tiap layanan BENAR-BENAR siap (bukan jeda tetap),
REM  supaya API tidak error 500 karena database belum siap.
REM ============================================================
setlocal enabledelayedexpansion
set ROOT=%~dp0

echo ============================================================
echo   MAMO — menyalakan semua layanan
echo ============================================================
echo.

REM ---------- 1. PostgreSQL ----------
echo [1/4] PostgreSQL (port 5432)...
start "MAMO PostgreSQL" cmd /k ""%ROOT%server\pgsql\bin\postgres.exe" -D "%ROOT%server\pgsql_data" -p 5432"

set /a TRY=0
:waitdb
set /a TRY+=1
"%ROOT%server\pgsql\bin\pg_isready.exe" -U postgres -p 5432 >nul 2>&1
if %errorlevel%==0 goto dbready
if %TRY% GEQ 30 (
  echo   [X] PostgreSQL tidak siap setelah 30 detik. Cek jendela "MAMO PostgreSQL".
  goto apistep
)
timeout /t 1 /nobreak >nul
goto waitdb

:dbready
echo   [OK] Database siap (menunggu %TRY% detik)

:apistep
REM ---------- 2. Backend API ----------
echo [2/4] Backend API (port 4000)...
start "MAMO API" cmd /k "cd /d "%ROOT%server" && node src/index.js"

set /a TRY=0
:waitapi
set /a TRY+=1
curl -s -o nul --max-time 2 http://localhost:4000/api/health 2>nul
if %errorlevel%==0 goto apiready
if %TRY% GEQ 30 (
  echo   [X] API tidak merespons setelah 30 detik. Cek jendela "MAMO API".
  goto adminstep
)
timeout /t 1 /nobreak >nul
goto waitapi

:apiready
echo   [OK] API siap

:adminstep
REM ---------- 3. Admin Web ----------
echo [3/4] Admin Web (port 5173)...
start "MAMO Admin" cmd /k "cd /d "%ROOT%admin" && npm run dev"

REM ---------- 4. Mobile Web ----------
echo [4/4] Mobile Web (port 8080)...
start "MAMO Mobile" cmd /k "cd /d "%ROOT%server" && node tools\static-server.js "%ROOT%app\build\web" 8080"

timeout /t 6 /nobreak >nul

REM ---------- Info LAN untuk HP ----------
set LOCALIP=
for /f "tokens=2 delims=:" %%A in ('ipconfig ^| findstr /c:"IPv4" ^| findstr /r "192\.168\."') do (
  if not defined LOCALIP set LOCALIP=%%A
)
set LOCALIP=%LOCALIP: =%

echo.
echo ============================================================
echo   MAMO siap dipakai
echo ============================================================
echo.
echo   API          http://localhost:4000/api/health
echo   Admin Web    http://localhost:5173
echo   Mobile Web   http://localhost:8080
echo.
echo   Akun demo (semua password: password123):
echo     admin@mamo.id      - panel admin
echo     pembeli@mamo.id    - pembeli
echo     penjual1@mamo.id   - penjual
echo.
echo ------------------------------------------------------------
echo   UNTUK HP ANDROID (satu jaringan WiFi):
echo     IP komputer ini : %LOCALIP%
echo.
echo     1) Pastikan HP di WiFi yang sama
echo     2) Build APK (sekali saja, di terminal baru):
echo        cd D:\MAMO\app
echo        flutter build apk --release ^
echo          --dart-define=MAMO_API=http://%LOCALIP%:4000/api ^
echo          --dart-define=MAMO_WS=ws://%LOCALIP%:4000
echo     3) Kirim app-release.apk ke HP lalu install
echo.
echo     (Atau pakai kabel: flutter run --dart-define=MAMO_API=http://%LOCALIP%:4000/api)
echo ------------------------------------------------------------
echo.
echo   Matikan semua: stop-all.bat
echo ============================================================
pause
