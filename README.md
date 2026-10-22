# DTC245200392-Trien_Khai_He_Thong_BlogCMS

<div align="center">

# BÁO CÁO BÀI TẬP LỚN
### MÔN HỌC: TRIỂN KHAI VÀ QUẢN TRỊ HỆ THỐNG PHẦN MỀM
**Đề tài: Triển khai và quản trị hệ thống Blog / CMS**

**Sinh viên thực hiện:** Nguyễn Ngọc Chi  
**Mã số sinh viên (MSSV):** DTC245200392  
**Lớp / Khóa:** CNTT K23C  
**Khoa:** Công nghệ Thông tin  
**Trường:** Đại học Công nghệ Thông tin và Truyền thông (ICTU) - Thái Nguyên  
**Năm thực hiện:** 2026  

---

[![Docker](https://img.shields.io/badge/Docker-20.10+-2496ED?logo=docker&logoColor=white)](https://www.docker.com/)
[![Docker Compose](https://img.shields.io/badge/Docker_Compose-v2+-2496ED?logo=docker&logoColor=white)](https://docs.docker.com/compose/)
[![Nginx](https://img.shields.io/badge/Nginx-Reverse_Proxy_SSL-009639?logo=nginx&logoColor=white)](https://nginx.org/)
[![WordPress](https://img.shields.io/badge/WordPress-CMS-21759B?logo=wordpress&logoColor=white)](https://wordpress.org/)
[![MySQL](https://img.shields.io/badge/MySQL-8.0-4479A1?logo=mysql&logoColor=white)](https://www.mysql.com/)
[![Prometheus](https://img.shields.io/badge/Prometheus-Monitoring-E6522C?logo=prometheus&logoColor=white)](https://prometheus.io/)
[![Grafana](https://img.shields.io/badge/Grafana-Visualization-F46800?logo=grafana&logoColor=white)](https://grafana.com/)
[![Loki](https://img.shields.io/badge/Loki-Centralized_Logging-F46800?logo=grafana&logoColor=white)](https://grafana.com/oss/loki/)

</div>

---

## MỤC LỤC
1. [Tổng quan Kiến trúc Hệ thống](#1-tổng-quan-kiến-trúc-hệ-thống)
2. [Cấu trúc Thư mục Dự án](#2-cấu-trúc-thư-mục-dự-án)
3. [Yêu cầu Hệ thống & Chuẩn bị Môi trường](#3-yêu-cầu-hệ-thống--chuẩn-bị-môi-trường)
4. [Hướng dẫn Triển khai Từng bước](#4-hướng-dẫn-triển-khai-từng-bước)
5. [Thông tin Dịch vụ & Cổng Truy cập](#5-thông-tin-dịch-vụ--cổng-truy-cập)
6. [Hệ thống Giám sát Hiệu năng (Prometheus + Grafana)](#6-hệ-thống-giám-sát-hiệu-năng-prometheus--grafana)
7. [Hệ thống Quản lý Log tập trung (Loki + Promtail)](#7-hệ-thống-quản-lý-log-tập-trung-loki--promtail)
8. [Các biện pháp Gia cố An ninh & Hardening](#8-các-biện-pháp-gia-cố-an-ninh--hardening)
9. [Lịch sử Commit theo Tiến độ Yêu cầu](#9-lịch-sử-commit-theo-tiến-độ-yêu-cầu)
10. [Xử lý Sự cố Thường gặp (Troubleshooting)](#10-xử-lý-sự-cố-thường-gặp-troubleshooting)

---

## 1. Tổng quan Kiến trúc Hệ thống

Hệ thống được thiết kế theo mô hình kiến trúc container hóa kết hợp giám sát toàn diện (Observability) và bảo mật nhiều lớp (Defense in Depth) thông qua Docker internal networks:

```text
                                  [ INTERNET / CLIENT ]
                                            │
                                    Ports 80/443 (HTTP/HTTPS)
                                            ▼
                           ┌─────────────────────────────────┐
                           │      Nginx Reverse Proxy        │
                           │   (SSL/TLS + Security Headers)  │
                           └────────┬───────────────┬────────┘
                                    │               │
       [frontend-net]               │               │
      ┌─────────────────────────────┼───────────────┴─────────────────────────────┐
      │                             ▼                                             │
      │                  ┌────────────────────┐      ┌─────────────────────┐      │
      │                  │   WordPress CMS    │      │     phpMyAdmin      │      │
      │                  │   (Container)      │      │   (Web Database UI) │      │
      │                  └──────────┬─────────┘      └──────────┬──────────┘      │
      └─────────────────────────────┼───────────────────────────┼─────────────────┘
       [backend-net] (Cô lập hoàn toàn) │                       │
      ┌─────────────────────────────┼───────────────────────────┼─────────────────┐
      │                             ▼                           ▼                 │
      │                  ┌─────────────────────────────────────────────────┐      │
      │                  │                MySQL 8.0 Database               │      │
      │                  │           (Không mở cổng ra ngoài Host)         │      │
      │                  └─────────────────────────────────────────────────┘      │
      └───────────────────────────────────────────────────────────────────────────┘

       [monitoring-net] (Mạng giám sát & Logging)
      ┌───────────────────────────────────────────────────────────────────────────┐
      │                                                                           │
      │   ┌───────────────┐     Scrape Metrics    ┌───────────────────────────┐   │
      │   │ Node Exporter │ ◄───────────────────  │     Prometheus Server     │   │
      │   └───────────────┘                       └─────────────┬─────────────┘   │
      │                                                         │                 │
      │   ┌───────────────┐     Scrape Metrics                  │ Data Source     │
      │   │    cAdvisor   │ ◄───────────────────┐               ▼                 │
      │   └───────────────┘                     │     ┌───────────────────┐       │
      │                                         │     │ Grafana Dashboard │       │
      │   ┌───────────────┐     Collect Logs    │     │   (Port 3000)     │       │
      │   │   Promtail    │ ─────────────────┐  │     └─────────▲─────────┘       │
      │   └───────────────┘                  ▼  │               │ Data Source     │
      │                                ┌────────┴──────┐        │                 │
      │                                │  Loki Server  │ ───────┘                 │
      │                                │  (Port 3100)  │                          │
      │                                └───────────────┘                          │
      └───────────────────────────────────────────────────────────────────────────┘
```

### Các thành phần chính:
1. **Nginx Reverse Proxy**: Cổng gateway chính, tự động chuyển hướng HTTP sang HTTPS, giải mã SSL/TLS, bổ sung Security Headers chống tấn công XSS, Clickjacking, MIME-sniffing.
2. **WordPress CMS**: Nền tảng quản trị nội dung chạy container độc lập, kết nối an toàn với cơ sở dữ liệu MySQL qua `backend-net`.
3. **MySQL 8.0 Database**: Lưu trữ dữ liệu hệ thống, được cô lập hoàn toàn trong mạng nội bộ Docker, dữ liệu lưu bền vững qua Docker volume.
4. **phpMyAdmin**: Giao diện web hỗ trợ quản trị viên tương tác trực tiếp với cơ sở dữ liệu.
5. **Prometheus + Grafana**: Thu thập chỉ số tài nguyên phần cứng (Node Exporter) và chỉ số từng container Docker (cAdvisor), hiển thị trên dashboard thời gian thực.
6. **Loki + Promtail**: Hệ thống thu thập, tổng hợp và phân tích log tập trung toàn bộ hệ thống bằng ngôn ngữ truy vấn LogQL.

---

## 2. Cấu trúc Thư mục Dự án

```text
DTC245200392-Trien_Khai_He_Thong_BlogCMS/
├── docker-compose.yml          # Khai báo toàn bộ 8 services, 3 networks, 6 volumes
├── .env.example                # Bản mẫu khai báo biến môi trường an toàn
├── .env                        # Biến môi trường cục bộ (được bỏ qua bởi .gitignore)
├── .gitignore                  # Cấu hình bỏ qua tệp nhạy cảm và tệp build
├── README.md                   # Tài liệu hướng dẫn triển khai và quản trị chi tiết
├── nginx/
│   ├── nginx.conf              # Cấu hình lõi Nginx (tối ưu hóa worker, log format, gzip)
│   ├── conf.d/
│   │   └── default.conf        # Cấu hình Reverse Proxy, SSL, Security Headers, Proxy Rules
│   └── ssl/
│       ├── nginx.crt           # Chứng chỉ SSL/TLS tự ký (Self-signed Certificate)
│       └── nginx.key           # Khóa riêng tư RSA 2048-bit bảo mật
├── prometheus/
│   └── prometheus.yml          # Cấu hình scrape targets (prometheus, node-exporter, cadvisor)
├── grafana/
│   ├── provisioning/
│   │   ├── datasources/
│   │   │   └── datasources.yml # Tự động nạp nguồn dữ liệu Prometheus và Loki
│   │   └── dashboards/
│   │       └── dashboards.yml  # Tự động nạp danh mục dashboards
│   └── dashboards/
│       └── docker-metrics.json # Dashboard JSON giám sát CPU/Memory container
├── loki/
│   └── loki-config.yaml        # Cấu hình lưu trữ và index engine của Loki Server
├── promtail/
│   └── promtail-config.yml     # Cấu hình pipeline thu thập log container & Nginx
└── scripts/
    ├── generate-ssl.sh         # Script sinh chứng chỉ SSL tự ký cho Linux/macOS
    ├── generate-ssl.bat        # Script sinh chứng chỉ SSL tự ký cho Windows
    ├── check-health.sh         # Script kiểm tra sức khỏe hệ thống tự động cho Linux/macOS
    └── check-health.ps1        # Script kiểm tra sức khỏe hệ thống tự động cho Windows PowerShell
```

---

## 3. Yêu cầu Hệ thống & Chuẩn bị Môi trường

- **Hệ điều hành**: Linux (Ubuntu 20.04/22.04 LTS), macOS, hoặc Windows 10/11 (với WSL2 & Docker Desktop).
- **Phần mềm yêu cầu**:
  - [Docker Engine](https://docs.docker.com/engine/install/) (khuyến nghị phiên bản 20.10 trở lên).
  - [Docker Compose](https://docs.docker.com/compose/install/) (khuyến nghị phiên bản v2 trở lên).
  - [Git](https://git-scm.com/).
  - [OpenSSL](https://www.openssl.org/) (có sẵn trong Linux/macOS hoặc kèm theo Git for Windows).

---

## 4. Hướng dẫn Triển khai Từng bước

### Bước 1: Sao chép (Clone) Repository về máy chủ
```bash
git clone https://github.com/dtc245200392-hub/DTC245200392-Trien_Khai_He_Thong_BlogCMS.git
cd DTC245200392-Trien_Khai_He_Thong_BlogCMS
```

### Bước 2: Thiết lập Biến môi trường (.env)
Sao chép tệp mẫu cấu hình sang tệp cấu hình thực tế:
```bash
# Trên Linux/macOS:
cp .env.example .env

# Trên Windows PowerShell:
Copy-Item .env.example .env
```
> **Lưu ý bảo mật:** Có thể chỉnh sửa tệp `.env` để thay đổi mật khẩu quản trị và các cổng dịch vụ mong muốn trước khi khởi chạy.

### Bước 3: Khởi tạo Chứng chỉ SSL/TLS tự ký (Nếu cần tái tạo mới)
Kho lưu trữ đã có sẵn chứng chỉ mẫu tại `nginx/ssl/`. Nếu bạn muốn tự tạo mới chứng chỉ riêng:
```bash
# Trên Linux/macOS:
chmod +x scripts/generate-ssl.sh
./scripts/generate-ssl.sh

# Trên Windows:
.\scripts\generate-ssl.bat
```

### Bước 4: Khởi chạy toàn bộ hệ thống
Sử dụng Docker Compose để tải image và khởi chạy toàn bộ 8 containers trong chế độ nền:
```bash
docker compose up -d
```

### Bước 5: Kiểm tra trạng thái hoạt động của hệ thống
Kiểm tra danh sách container và health status:
```bash
docker compose ps
```
Hoặc chạy script kiểm tra tự động đã tích hợp sẵn:
```bash
# Trên Linux/macOS:
chmod +x scripts/check-health.sh && ./scripts/check-health.sh

# Trên Windows PowerShell:
.\scripts\check-health.ps1
```

---

## 5. Thông tin Dịch vụ & Cổng Truy cập

| Tên Dịch Vụ | Tên Container | Cổng Host | URL Truy Cập | Mục Đích & Tài Khoản Mặc Định |
|---|---|---|---|---|
| **Nginx (HTTPS)** | `cms_nginx` | `443` | [https://localhost](https://localhost) | Cổng truy cập chính của Blog/CMS (SSL) |
| **Nginx (HTTP)** | `cms_nginx` | `80` | [http://localhost](http://localhost) | Tự động chuyển hướng (301) sang HTTPS |
| **WordPress CMS** | `cms_wordpress` | Nội bộ | Thông qua Nginx | Nền tảng xuất bản nội dung Blog |
| **phpMyAdmin** | `cms_phpmyadmin` | `8081` | [http://localhost:8081](http://localhost:8081) | Quản trị DB. User: `root`, Pass: `CmsSecureRootPass2026!` |
| **MySQL 8.0** | `cms_mysql` | Nội bộ (`3306`) | Cô lập mạng nội bộ | DB: `wordpress_cms`, User: `cms_user` |
| **Grafana** | `cms_grafana` | `3000` | [http://localhost:3000](http://localhost:3000) | Giám sát & Logs. User: `admin`, Pass: `AdminGrafana2026!` |
| **Prometheus** | `cms_prometheus` | `9090` | [http://localhost:9090](http://localhost:9090) | Tra cứu PromQL & xem trạng thái Scrape Targets |
| **Loki Server** | `cms_loki` | `3100` | [http://localhost:3100/ready](http://localhost:3100/ready) | Máy chủ nhận và đánh chỉ mục Log |
| **Node Exporter** | `cms_node_exporter` | `9100` | [http://localhost:9100/metrics](http://localhost:9100/metrics) | Chỉ số tài nguyên Host (CPU, RAM, Disk) |
| **cAdvisor** | `cms_cadvisor` | `8080` | [http://localhost:8080](http://localhost:8080) | Thống kê tài nguyên từng Docker Container |

---

## 6. Hệ thống Giám sát Hiệu năng (Prometheus + Grafana)

Prometheus được cấu hình tự động scrape định kỳ mỗi 15 giây với 3 mục tiêu giám sát quan trọng:
1. `prometheus`: Chỉ số hoạt động nội tại của Prometheus Server (`localhost:9090`).
2. `node-exporter`: Chỉ số tải hệ thống, bộ nhớ RAM, lưu lượng đĩa cứng máy chủ (`node-exporter:9100`).
3. `cadvisor`: Chỉ số tiêu thụ CPU, RAM, Network I/O chi tiết từng container Docker (`cadvisor:8080`).

### Các truy vấn PromQL thông dụng:
- **Tỷ lệ CPU sử dụng theo từng Container:**
  ```promql
  sum(rate(container_cpu_usage_seconds_total{name=~"cms_.*"}[1m])) by (name)
  ```
- **Dung lượng Bộ nhớ RAM đang sử dụng theo từng Container:**
  ```promql
  sum(container_memory_working_set_bytes{name=~"cms_.*"}) by (name)
  ```
- **Tỷ lệ sử dụng CPU của toàn bộ máy chủ Host:**
  ```promql
  100 - (avg by (instance) (rate(node_cpu_seconds_total{mode="idle"}[1m])) * 100)
  ```

---

## 7. Hệ thống Quản lý Log tập trung (Loki + Promtail)

Hệ thống ghi log tập trung hoạt động theo cơ chế:
- **Promtail** giám sát thư mục log của Docker (`/var/lib/docker/containers/*/*-json.log`) cùng với access/error logs của Nginx (`/var/log/nginx/*log`).
- Promtail trích xuất nhãn (labels) như `job`, `container_name`, `stream`, sau đó đẩy luồng log về **Loki**.
- Kỹ trị viên truy cập **Grafana** -> Menu **Explore** -> Chọn nguồn dữ liệu **Loki** để tra cứu log thời gian thực.

### Các câu truy vấn LogQL tiêu biểu (Theo tiêu chí Báo cáo):

#### 1. Lọc log lỗi HTTP 4xx / 5xx từ Nginx access log:
```logql
{job="nginx"} |= "HTTP/1.1" |~ " (4|5)[0-9]{2} "
```

#### 2. Lọc riêng các lỗi HTTP 5xx (Lỗi phía Server):
```logql
{job="nginx"} |= "HTTP/1.1" 5"
```

#### 3. Tìm kiếm các thông điệp ngoại lệ hoặc lỗi nghiêm trọng trong ứng dụng:
```logql
{job="webapp"} |~ "(ERROR|Exception|Failed)"
```
Hoặc truy vấn trực tiếp theo tên container `cms_wordpress` và `cms_mysql`:
```logql
{container_name=~"cms_wordpress|cms_mysql"} |~ "(?i)(ERROR|Exception|Failed|Fatal)"
```

---

## 8. Các biện pháp Gia cố An ninh & Hardening

Theo đúng các tiêu chí chuyên sâu tại **Chương 4** của bài báo cáo, các biện pháp Hardening đã được áp dụng triệt để:

### 8.1. Phân tách mạng nội bộ (Network Isolation)
- **`backend-net`**: Cô lập tầng dữ liệu. Cổng 3306 của MySQL không được ánh xạ ra ngoài máy chủ chủ (Host). Chỉ có container `wordpress` và `phpmyadmin` trong cùng mạng mới có thể kết nối.
- **`frontend-net`**: Mạng kết nối giữa Nginx và WordPress/phpMyAdmin. Nginx đóng vai trò là điểm tiếp nhận duy nhất từ Internet.
- **`monitoring-net`**: Mạng độc lập cho hệ thống quan sát, tách biệt khỏi luồng lưu lượng người dùng ứng dụng.

### 8.2. Chạy container dưới quyền Non-root User
- Nginx cấu hình chạy tiến trình công nhân dưới người dùng hệ thống `nginx` (`nginx.conf: user nginx;`).
- Prometheus chạy dưới tài khoản chuẩn `nobody`.
- Grafana chạy dưới UID hạn chế `472`.
- Loki và Promtail chạy dưới UID bảo mật `10001`.
- Ngăn chặn triệt để nguy cơ leo thang đặc quyền (Privilege Escalation) từ container lên máy chủ Host.

### 8.3. Hoàn thiện Security Headers trên Nginx
Nginx Reverse Proxy được tích hợp đầy đủ các HTTP Security Headers chuẩn OWASP:
```nginx
add_header X-Frame-Options "SAMEORIGIN" always;
add_header X-Content-Type-Options "nosniff" always;
add_header X-XSS-Protection "1; mode=block" always;
add_header Referrer-Policy "strict-origin-when-cross-origin" always;
```
- Ngăn chặn tấn công Clickjacking bằng cách giới hạn khung iFrame.
- Ngăn chặn MIME-type sniffing nhằm tránh thực thi file độc hại.
- Kích hoạt cơ chế chống Cross-Site Scripting (XSS).

### 8.4. Giới hạn bề mặt tấn công Web Server
- Tắt hiển thị thông tin phiên bản Nginx: `server_tokens off;`.
- Chặn tuyệt đối truy cập vào các file nhạy cảm:
  ```nginx
  location ~ /\.(ht|git|env|svn) {
      deny all;
      return 404;
  }
  ```
- Cấm thực thi script PHP trong thư mục tải lên:
  ```nginx
  location ~* /(?:uploads|files)/.*\.php$ {
      deny all;
  }
  ```
- Giới hạn dung lượng tải lên an toàn: `client_max_body_size 64M;`.

### 8.5. Quản lý Mật khẩu mạnh và Biến môi trường
- Sử dụng tệp `.env` riêng biệt, được bảo vệ bởi `.gitignore`, không lưu trữ mật khẩu tĩnh (hardcoded secrets) trong mã nguồn hoặc kho lưu trữ Git.
- Cung cấp tệp `.env.example` làm khuôn mẫu an toàn.

### 8.6. Cấu hình Tường lửa Hệ điều hành (Khuyến nghị trên Host Linux UFW)
```bash
# Bật UFW
sudo ufw default deny incoming
sudo ufw default allow outgoing

# Chỉ mở cổng SSH và các cổng dịch vụ Nginx, Grafana công khai
sudo ufw allow 22/tcp
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw allow 3000/tcp

sudo ufw enable
```

---

## 9. Lịch sử Commit theo Tiến độ Yêu cầu

Dự án được thực hiện và lưu vết lịch sử trên Git repository một cách mạch lạc, phản ánh chính xác các bước trong báo cáo:

| Commit / Bước | Mã Commit (Ví dụ) | Nội Dung Công Việc |
|---|---|---|
| **Initial** | `e7568f9` | Khởi tạo kho lưu trữ ban đầu |
| **Bước 1, 2 & 3 (Commit 1)** | `feat(step1-3)` | Triển khai Web WordPress, MySQL, phpMyAdmin và cấu hình Nginx Reverse Proxy với HTTPS, Security Headers |
| **Bước 4 (Commit 2)** | `feat(step4)` | Tích hợp hệ thống giám sát Metrics với Prometheus, Grafana, Node-Exporter và cAdvisor |
| **Bước 5 (Commit 3)** | `feat(step5)` | Triển khai hệ thống lưu trữ và quản lý log tập trung với Loki và Promtail |
| **Bước 6 (Commit 4)** | `feat(step6)` | Áp dụng các biện pháp Hardening bảo mật hệ thống, scripts kiểm tra sức khỏe và hoàn thiện toàn bộ tài liệu kỹ thuật |

---

## 10. Xử lý Sự cố Thường gặp (Troubleshooting)

### 1. Trình duyệt cảnh báo "Your connection is not private" (NET::ERR_CERT_AUTHORITY_INVALID)
- **Nguyên nhân**: Do hệ thống sử dụng chứng chỉ SSL tự ký (Self-signed Certificate).
- **Khắc phục**: Đây là hành vi hoàn toàn bình thường trong môi trường thử nghiệm và triển khai nội bộ. Bấm chọn **Advanced (Nâng cao)** -> Chọn **Proceed to localhost (Tiếp tục truy cập localhost)**.

### 2. WordPress bị lỗi "Error establishing a database connection"
- **Nguyên nhân**: Container MySQL chưa hoàn tất quá trình khởi tạo dữ liệu ban đầu.
- **Khắc phục**: Hệ thống đã được thiết lập `healthcheck` trên MySQL và `depends_on: { db: { condition: service_healthy } }` để WordPress chỉ khởi động khi cơ sở dữ liệu đã sẵn sàng. Chờ từ 15-30 giây và tải lại trang.

### 3. Cổng 80 hoặc 443 bị xung đột trên máy tính Host
- **Nguyên nhân**: Một dịch vụ khác như IIS, Skype hoặc Apache đang chiếm dụng cổng 80/443 trên máy tính của bạn.
- **Khắc phục**: Mở tệp `.env`, thay đổi giá trị `NGINX_HTTP_PORT=8080` và `NGINX_HTTPS_PORT=8443`, sau đó chạy lại lệnh:
  ```bash
  docker compose up -d --force-recreate
  ```

### 4. Dừng hoặc khởi động lại toàn bộ hệ thống
```bash
# Dừng hệ thống nhưng giữ nguyên dữ liệu volumes
docker compose down

# Dừng và xóa toàn bộ dữ liệu volumes (chỉ dùng khi muốn reset trắng)
docker compose down -v
```

---
*Báo cáo và mã nguồn được xây dựng chuẩn mực theo yêu cầu bài tập lớn môn Triển khai và Quản trị Hệ thống Phần mềm - ICTU 2026.*