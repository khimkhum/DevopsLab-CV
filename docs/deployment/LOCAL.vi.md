# Chạy website CV trên máy cá nhân

Workspace Windows: `F:\Devops_Lab`. Trong Ubuntu WSL2: `/mnt/f/Devops_Lab`.

## Source và nội dung

Website dùng Astro, tạo output tĩnh. Thông tin, ảnh đại diện và CV PDF được lấy từ CV do người dùng cung cấp, không tạo kinh nghiệm hoặc công ty giả.

- Nội dung: `app/src/data/profile.ts`.
- Giao diện: `app/src/pages/index.astro`, `app/src/styles/global.css`.
- CV tải xuống: `app/public/cv/le-van-khiem-devops.pdf`.
- Metadata release: `/version.json`, được tạo lúc build; không có secret.

## Mở Ubuntu tại dự án

```powershell
wsl -d Ubuntu --cd /mnt/f/Devops_Lab
```

## Build và test trong WSL

```bash
bash scripts/build-site.sh
```

Lệnh cài dependency từ lockfile, build website rồi kiểm tra nội dung, liên kết nội bộ, CV download, health endpoint và release metadata. Node.js tối thiểu 22.22.0, npm tối thiểu 9.6.5.

Development server nếu cần sửa giao diện:

```bash
cd app
npm run dev
```

Địa chỉ dev là `http://localhost:4321`. Dev server không được dùng làm origin public.

## Chạy container local

Docker Desktop phải chạy và bật WSL integration cho Ubuntu.

```bash
cd /mnt/f/Devops_Lab
bash scripts/start-local.sh
python3 scripts/smoke-test.py
docker compose ps
```

Website: `http://localhost:8080`.

Container chạy user 101, filesystem chỉ đọc, drop toàn bộ capabilities, dùng tmpfs cho file tạm và không mount source/ổ F vào runtime. Chỉ publish `127.0.0.1:8080`; không mở port router. Container chỉ mang output website, không chứa toàn bộ workspace.

Xem log hoặc dừng:

```bash
docker compose logs --tail=50 cv
docker compose stop cv
```

`restart: unless-stopped` chỉ hỗ trợ khi Docker Engine đang chạy; không chứng minh Windows boot sẽ khởi động Docker Desktop/WSL hoặc website.

## Chuẩn bị trên bản clone mới

Docker Desktop phải chạy và bật WSL integration.

```bash
cp .env.example .env

docker build \
  --target gateway \
  --tag khimkum-gateway:local-development \
  .

bash scripts/start-local.sh
python3 scripts/smoke-test.py
```

Cấu hình mẫu dùng image local, không cần truy cập Harbor private.
Máy triển khai release dùng các biến image theo digest trong .env;
không dùng start-local.sh để build đè bản release.

## Monitoring giai đoạn Compose

Các file monitoring nằm trong `infra/monitoring`. Cần tạo password admin Grafana trước khi khởi chạy và giữ file đó ngoài Git; không dùng password mặc định. File secret được Compose đọc là `.secrets/grafana_admin_password`, thư mục này phải được bảo vệ bằng quyền Windows phù hợp.

```bash
docker compose -f compose.yaml -f compose.monitoring.yaml up -d
```

- Grafana: `http://localhost:3000`, user `admin`.
- Prometheus: `http://localhost:9090`.
- Alertmanager: `http://localhost:9093`.
- Dashboard: CV Lab / Khimkum CV — Origin health.

Prometheus kiểm tra origin qua Blackbox Exporter. Dashboard chưa chứng minh website public hoặc host còn hoạt động khi mất điện. Alertmanager hiện chưa có kênh gửi thông báo thật; cần chọn và cấu hình receiver trước khi coi cảnh báo đã hoàn chỉnh. Probe và khả năng gửi cảnh báo bên ngoài mạng nhà vẫn là mốc riêng.

## Public bằng Cloudflare Tunnel

Chỉ thực hiện sau khi local container và smoke test đạt. Binary cloudflared được tải từ release chính thức và kiểm tra SHA256. Cần chủ tài khoản đăng nhập Cloudflare, chọn zone `khimkum.xyz` và cấp quyền cho CLI; không gửi token, password hoặc cert vào chat/Git.

Sau khi có quyền, tạo named tunnel, route đúng hostname và dùng cấu hình mẫu `infra/cloudflared/config.yml.example`. Credential nằm trong home Linux với quyền hạn chế, không mount vào container CV. Không đưa Grafana, Prometheus, Alertmanager hoặc workspace lên tunnel.

## Các mốc còn lại

Harbor, GitLab CI, Kubernetes, ArgoCD, approval production, startup Windows, backup/restore và monitoring độc lập sẽ được triển khai và nghiệm thu theo roadmap; chỉ file cấu hình có sẵn chưa phải bằng chứng hệ thống đã chạy.
