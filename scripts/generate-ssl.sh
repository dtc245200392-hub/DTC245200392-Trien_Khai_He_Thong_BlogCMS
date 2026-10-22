#!/bin/bash
# Script tự động tạo chứng chỉ SSL/TLS tự ký (Self-signed Certificate)
# Đề tài: Triển khai và quản trị hệ thống Blog / CMS
# Sinh viên: Nguyễn Ngọc Chi - MSSV: DTC245200392

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SSL_DIR="${SCRIPT_DIR}/../nginx/ssl"

mkdir -p "${SSL_DIR}"

echo "==> Đang tạo chứng chỉ SSL/TLS tự ký cho localhost..."
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout "${SSL_DIR}/nginx.key" \
  -out "${SSL_DIR}/nginx.crt" \
  -subj "/C=VN/ST=Thai Nguyen/L=Thai Nguyen/O=ICTU/OU=CNTT K23C/CN=localhost" \
  -addext "subjectAltName=DNS:localhost,IP:127.0.0.1"

chmod 600 "${SSL_DIR}/nginx.key"
chmod 644 "${SSL_DIR}/nginx.crt"

echo "==> Tạo chứng chỉ SSL thành công tại: ${SSL_DIR}"
