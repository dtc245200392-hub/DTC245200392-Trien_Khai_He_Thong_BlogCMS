# DTC245200392-Trien_Khai_He_Thong_BlogCMS

> **Báo Cáo Bài Tập Lớn: Triển Khai và Quản Trị Hệ Thống Phần Mềm**  
> **Đề tài**: Triển khai và quản trị hệ thống Blog / CMS  
> **Sinh viên**: Nguyễn Ngọc Chi  
> **Mã số sinh viên (MSSV)**: DTC245200392  
> **Lớp / Khóa**: CNTT K23C  
> **Trường**: Đại học Công nghệ Thông tin và Truyền thông (ICTU) - Thái Nguyên, 2026  

---

## 1. Tổng quan Kiến trúc Hệ thống

Hệ thống được thiết kế theo mô hình kiến trúc container hóa kết hợp reverse proxy bảo mật và cô lập mạng:
- **Ứng dụng Web**: WordPress (latest) chạy trên mạng nội bộ Docker.
- **Cơ sở dữ liệu**: MySQL 8.0 được cô lập an toàn trong `backend-net`, dữ liệu được lưu trữ bền vững qua Docker Named Volume `db_data`.
- **Quản trị Cơ sở dữ liệu**: phpMyAdmin kết nối an toàn với MySQL.
- **Reverse Proxy Gateway**: Nginx Reverse Proxy tiếp nhận lưu lượng cổng 80 (HTTP) và cổng 443 (HTTPS), tự động chuyển hướng sang HTTPS, sử dụng chứng chỉ SSL/TLS tự ký, và áp dụng các Security Headers (X-Frame-Options, X-Content-Type-Options, X-XSS-Protection).

---

## 2. Cấu trúc Thư mục

```text
DTC245200392-Trien_Khai_He_Thong_BlogCMS/
├── docker-compose.yml          # Khai báo các dịch vụ hệ thống
├── .env.example                # Mẫu biến môi trường
├── .env                        # Biến môi trường thực tế (được bảo vệ)
├── .gitignore                  # Bỏ qua tệp nhạy cảm và tệp rác
├── README.md                   # Hướng dẫn chi tiết
├── nginx/
│   ├── nginx.conf              # Cấu hình chính của Nginx
│   ├── conf.d/
│   │   └── default.conf        # Cấu hình vhost, SSL & Security Headers
│   └── ssl/
│       ├── nginx.crt           # Chứng chỉ SSL tự ký
│       └── nginx.key           # Private key RSA 2048-bit
└── scripts/
    ├── generate-ssl.sh         # Script sinh chứng chỉ SSL trên Linux/macOS
    └── generate-ssl.bat        # Script sinh chứng chỉ SSL trên Windows
```

---

## 3. Hướng dẫn Khởi chạy Hệ thống

### 3.1. Chuẩn bị biến môi trường
Sao chép tệp mẫu cấu hình sang tệp cấu hình thực tế:
```bash
cp .env.example .env
```
*(Trên Windows PowerShell: `Copy-Item .env.example .env`)*

### 3.2. Sinh chứng chỉ SSL (Nếu cần tái tạo)
```bash
# Trên Linux/macOS:
chmod +x scripts/generate-ssl.sh && ./scripts/generate-ssl.sh

# Trên Windows:
.\scripts\generate-ssl.bat
```

### 3.3. Khởi chạy toàn bộ dịch vụ
Khởi chạy hệ thống ở chế độ nền (detached mode):
```bash
docker compose up -d
```

### 3.4. Kiểm tra trạng thái và truy cập dịch vụ
Kiểm tra các container đang chạy:
```bash
docker compose ps
```

- **Blog CMS WordPress (HTTPS)**: [https://localhost](https://localhost)
- **phpMyAdmin**: [http://localhost:8081](http://localhost:8081) hoặc [https://localhost/phpmyadmin/](https://localhost/phpmyadmin/)