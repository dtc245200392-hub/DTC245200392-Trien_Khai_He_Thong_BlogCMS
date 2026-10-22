# DTC245200392-Trien_Khai_He_Thong_BlogCMS

> **Báo Cáo Bài Tập Lớn: Triển Khai và Quản Trị Hệ Thống Phần Mềm**  
> **Đề tài**: Triển khai và quản trị hệ thống Blog / CMS  
> **Sinh viên**: Nguyễn Ngọc Chi  
> **Mã số sinh viên (MSSV)**: DTC245200392  
> **Lớp / Khóa**: CNTT K23C  
> **Trường**: Đại học Công nghệ Thông tin và Truyền thông (ICTU) - Thái Nguyên, 2026  

---

## 1. Tổng quan Kiến trúc Hệ thống

Hệ thống được thiết kế theo mô hình kiến trúc container hóa kết hợp giám sát toàn diện và cô lập mạng:
- **Nginx Reverse Proxy**: Đóng vai trò cổng giao tiếp chính (gateway) nhận request từ ngoài qua cổng 80/443, thực hiện định tuyến, áp dụng bảo mật HTTP headers và SSL/TLS tự ký.
- **Ứng dụng Web & Database**: WordPress và MySQL 8.0 chạy trong container riêng biệt, kết nối trực tiếp qua Docker network cô lập (`backend-net`, `frontend-net`).
- **Quản trị Cơ sở dữ liệu**: phpMyAdmin hỗ trợ quản trị trực quan.
- **Giám sát Metrics (Prometheus + Grafana)**:
  - **Prometheus**: Định kỳ scrape metrics từ Node Exporter và cAdvisor mỗi 15s.
  - **Node Exporter**: Thu thập chỉ số tài nguyên phần cứng hệ thống (Host CPU, RAM, Disk).
  - **cAdvisor**: Đo lường và giám sát mức độ tiêu thụ tài nguyên chi tiết của từng Docker container.
  - **Grafana**: Trực quan hóa dữ liệu thời gian thực với dashboard quản trị tự động nạp.
- **Quản lý Log tập trung (Loki + Promtail)**:
  - **Promtail**: Tự động thu thập log từ tất cả các Docker container (`/var/lib/docker/containers`) và access/error logs từ Nginx (`/var/log/nginx`).
  - **Loki Server**: Tiếp nhận, đánh chỉ mục và lưu trữ log hiệu quả.
  - **Grafana Explore**: Cho phép kỹ trị tra cứu log bằng ngôn ngữ LogQL.

---

## 2. Cấu trúc Thư mục

```text
DTC245200392-Trien_Khai_He_Thong_BlogCMS/
├── docker-compose.yml          # Khai báo toàn bộ các dịch vụ hệ thống
├── .env.example                # Mẫu khai báo biến môi trường
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
├── prometheus/
│   └── prometheus.yml          # Cấu hình scrape targets cho Prometheus
├── grafana/
│   ├── provisioning/
│   │   ├── datasources/
│   │   │   └── datasources.yml # Tự động cấu hình nguồn Prometheus & Loki
│   │   └── dashboards/
│   │       └── dashboards.yml  # Tự động nạp dashboard
│   └── dashboards/
│       └── docker-metrics.json # Dashboard mẫu giám sát container
├── loki/
│   └── loki-config.yaml        # Cấu hình lưu trữ và chỉ mục Loki Server
├── promtail/
│   └── promtail-config.yml     # Cấu hình thu thập log Promtail
└── scripts/
    ├── generate-ssl.sh         # Script sinh chứng chỉ SSL trên Linux/macOS
    └── generate-ssl.bat        # Script sinh chứng chỉ SSL trên Windows
```

---

## 3. Hướng dẫn Khởi chạy Hệ thống

### 3.1. Chuẩn bị biến môi trường
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

### 3.4. Kiểm tra trạng thái và danh sách dịch vụ
Kiểm tra các container đang chạy:
```bash
docker compose ps
```

| Dịch vụ | Cổng công khai | Đường dẫn truy cập | Ghi chú |
|---|---|---|---|
| **Blog CMS WordPress** | 80, 443 | [https://localhost](https://localhost) | Cổng 80 tự redirect sang 443 HTTPS |
| **phpMyAdmin** | 8081 | [http://localhost:8081](http://localhost:8081) | Hoặc qua [https://localhost/phpmyadmin/](https://localhost/phpmyadmin/) |
| **Prometheus Web UI** | 9090 | [http://localhost:9090](http://localhost:9090) | Xem trạng thái scrape targets và PromQL |
| **Grafana Dashboard** | 3000 | [http://localhost:3000](http://localhost:3000) | Đăng nhập: `admin` / `AdminGrafana2026!` |
| **Loki Server** | 3100 | [http://localhost:3100/ready](http://localhost:3100/ready) | Endpoint log ingestion và API |
| **Node Exporter** | 9100 | [http://localhost:9100/metrics](http://localhost:9100/metrics) | Chỉ số máy chủ host |
| **cAdvisor** | 8080 | [http://localhost:8080](http://localhost:8080) | Giao diện và metrics container Docker |

---

## 4. Quản lý Log tập trung và Các truy vấn LogQL mẫu

Vào **Grafana** -> **Explore** -> Chọn nguồn dữ liệu **Loki**:

### Truy vấn 1: Lọc log lỗi HTTP 4xx / 5xx từ Nginx
```logql
{job="nginx"} |= "HTTP/1.1" |~ " (4|5)[0-9]{2} "
```

### Truy vấn 2: Tìm kiếm các thông điệp lỗi hoặc ngoại lệ trong ứng dụng
```logql
{container_name=~"cms_wordpress|cms_mysql"} |~ "(?i)(ERROR|Exception|Failed|Fatal)"
```
Hoặc đối với job webapp:
```logql
{job="webapp"} |~ "(ERROR|Exception|Failed)"
```