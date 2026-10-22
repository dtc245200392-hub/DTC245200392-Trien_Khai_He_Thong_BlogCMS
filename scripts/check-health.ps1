# =============================================================================
# Script kiểm tra trạng thái hoạt động (Healthcheck) của toàn bộ hệ thống Blog/CMS
# Đề tài: Triển khai và quản trị hệ thống Blog / CMS
# Sinh viên: Nguyễn Ngọc Chi - MSSV: DTC245200392
# =============================================================================

Write-Host "=======================================================" -ForegroundColor Cyan
Write-Host "   KIEM TRA TRANG THAI HE THONG BLOG / CMS (DTC245200392)" -ForegroundColor Cyan
Write-Host "=======================================================" -ForegroundColor Cyan

Write-Host "`n==> 1. Trang thai cac Docker Containers:" -ForegroundColor Yellow
docker compose ps

Write-Host "`n==> 2. Kiem tra phan hoi cac endpoints dich vu:" -ForegroundColor Yellow

$endpoints = @(
    @{ Name = "Nginx HTTPS (WordPress)"; Url = "https://localhost"; Expected = @(200, 301, 302) },
    @{ Name = "Nginx HTTP (Redirect)"; Url = "http://localhost"; Expected = @(301) },
    @{ Name = "phpMyAdmin"; Url = "http://localhost:8081"; Expected = @(200, 302) },
    @{ Name = "Prometheus Web UI"; Url = "http://localhost:9090/-/ready"; Expected = @(200) },
    @{ Name = "Grafana Web UI"; Url = "http://localhost:3000/api/health"; Expected = @(200) },
    @{ Name = "Loki Server"; Url = "http://localhost:3100/ready"; Expected = @(200) },
    @{ Name = "Node Exporter"; Url = "http://localhost:9100/metrics"; Expected = @(200) },
    @{ Name = "cAdvisor"; Url = "http://localhost:8080/healthz"; Expected = @(200) }
)

# Bỏ qua kiểm tra chứng chỉ tự ký khi test
[System.Net.ServicePointManager]::ServerCertificateValidationCallback = {$true}

foreach ($ep in $endpoints) {
    Write-Host -NoNewline " - Dang kiem tra $($ep.Name) ($($ep.Url))... "
    try {
        $req = [System.Net.HttpWebRequest]::Create($ep.Url)
        $req.Timeout = 5000
        $req.AllowAutoRedirect = $false
        $res = $req.GetResponse()
        $code = [int]$res.StatusCode
        $res.Close()
        if ($ep.Expected -contains $code) {
            Write-Host "OK (HTTP $code)" -ForegroundColor Green
        } else {
            Write-Host "CANH BAO (HTTP $code, ky vong $($ep.Expected -join '|'))" -ForegroundColor Yellow
        }
    } catch [System.Net.WebException] {
        if ($_.Response) {
            $code = [int]$_.Response.StatusCode
            if ($ep.Expected -contains $code) {
                Write-Host "OK (HTTP $code)" -ForegroundColor Green
            } else {
                Write-Host "CANH BAO (HTTP $code, ky vong $($ep.Expected -join '|'))" -ForegroundColor Yellow
            }
        } else {
            Write-Host "CHUA SAN SANG (Loi ket noi)" -ForegroundColor Red
        }
    } catch {
        Write-Host "CHUA SAN SANG" -ForegroundColor Red
    }
}

Write-Host "`n=======================================================" -ForegroundColor Cyan
Write-Host "   HOAN TAT KIEM TRA HE THONG!" -ForegroundColor Cyan
Write-Host "=======================================================" -ForegroundColor Cyan
