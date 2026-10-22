#!/bin/bash
# =============================================================================
# Script kiểm tra trạng thái hoạt động (Healthcheck) của toàn bộ hệ thống Blog/CMS
# Đề tài: Triển khai và quản trị hệ thống Blog / CMS
# Sinh viên: Nguyễn Ngọc Chi - MSSV: DTC245200392
# =============================================================================

echo "======================================================="
echo "   KIỂM TRA TRẠNG THÁI HỆ THỐNG BLOG / CMS (DTC245200392)"
echo "======================================================="

# 1. Kiểm tra trạng thái các container
echo ""
echo "==> 1. Trạng thái các Docker Containers:"
docker compose ps

# 2. Kiểm tra các dịch vụ thông qua Curl
echo ""
echo "==> 2. Kiểm tra phản hồi các dịch vụ:"

check_url() {
    local name="$1"
    local url="$2"
    local expected="$3"
    
    echo -n " - Đang kiểm tra ${name} (${url})... "
    status=$(curl -k -s -o /dev/null -w "%{http_code}" --connect-timeout 5 "$url" 2>/dev/null || echo "000")
    if [[ "$status" =~ ^($expected)$ ]]; then
        echo "OK (HTTP $status)"
    else
        echo "CẢNH BÁO / CHƯA SẴN SÀNG (HTTP $status, kỳ vọng $expected)"
    fi
}

check_url "Nginx HTTPS (WordPress)" "https://localhost" "200|301|302"
check_url "Nginx HTTP Redirect" "http://localhost" "301"
check_url "phpMyAdmin" "http://localhost:8081" "200|302"
check_url "Prometheus Web UI" "http://localhost:9090/-/ready" "200"
check_url "Grafana Web UI" "http://localhost:3000/api/health" "200"
check_url "Loki Server" "http://localhost:3100/ready" "200"
check_url "Node Exporter" "http://localhost:9100/metrics" "200"
check_url "cAdvisor" "http://localhost:8080/healthz" "200"

echo ""
echo "======================================================="
echo "   HOÀN TẤT KIỂM TRA HỆ THỐNG!"
echo "======================================================="
