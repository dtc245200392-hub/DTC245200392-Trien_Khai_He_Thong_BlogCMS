@echo off
REM Script tu dong tao chung chi SSL/TLS tu ky (Self-signed Certificate) cho Windows
REM De tai: Trien khai va quan tri he thong Blog / CMS
REM Sinh vien: Nguyen Ngoc Chi - MSSV: DTC245200392

set SSL_DIR=%~dp0..\nginx\ssl
if not exist "%SSL_DIR%" mkdir "%SSL_DIR%"

echo [INFO] Dang kiem tra OpenSSL...
where openssl >nul 2>nul
if %errorlevel% neq 0 (
    if exist "D:\Git\Git\usr\bin\openssl.exe" (
        set "OPENSSL=D:\Git\Git\usr\bin\openssl.exe"
    ) else if exist "C:\Program Files\Git\usr\bin\openssl.exe" (
        set "OPENSSL=C:\Program Files\Git\usr\bin\openssl.exe"
    ) else (
        echo [ERROR] Khong tim thay OpenSSL. Vui long cai dat Git for Windows hoac OpenSSL.
        exit /b 1
    )
) else (
    set "OPENSSL=openssl"
)

echo [INFO] Dang khoi tao chung chi SSL cho localhost...
"%OPENSSL%" req -x509 -nodes -days 365 -newkey rsa:2048 ^
  -keyout "%SSL_DIR%\nginx.key" ^
  -out "%SSL_DIR%\nginx.crt" ^
  -subj "/C=VN/ST=Thai Nguyen/L=Thai Nguyen/O=ICTU/OU=CNTT K23C/CN=localhost" ^
  -addext "subjectAltName=DNS:localhost,IP:127.0.0.1"

echo [SUCCESS] Tao chung chi SSL thanh cong tai %SSL_DIR%!
