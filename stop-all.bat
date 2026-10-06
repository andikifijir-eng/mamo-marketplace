@echo off
REM ============================================================
REM  MAMO — matikan semua layanan
REM ============================================================
echo Menghentikan MAMO...

REM Matikan proses berdasarkan port yang dipakai
for %%P in (4000 5173 8080 5432) do (
  for /f "tokens=5" %%A in ('netstat -ano ^| findstr ":%%P " ^| findstr LISTENING') do (
    echo   kill port %%P ^(PID %%A^)
    taskkill /F /PID %%A >nul 2>&1
  )
)

echo.
echo Semua layanan MAMO dihentikan.
echo Catatan: data PostgreSQL tetap tersimpan di server\pgsql_data
timeout /t 3 /nobreak >nul
