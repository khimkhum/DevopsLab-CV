# Learning journal

For each session record:

1. Goal and expected outcome.
2. Commands used and their meaning.
3. Observed results and evidence.
4. Errors, diagnosis and correction.
5. Steps needed to reproduce the result.
6. Questions still unresolved.

Bổ sung bốn sự cố đã thực hành, mỗi sự cố ghi triệu chứng → bằng chứng → nguyên nhân → cách sửa → kiểm chứng:
- Nginx không tạo được thư mục tạm trên filesystem chỉ đọc.
- Cloudflare trả 1010 cho Python mặc định; client kiểm thử có tên rõ ràng nhận 200.
- Docker Desktop chưa khởi động sau đăng nhập; launcher được bổ sung bước mở Docker.
- Bind mount nội bộ không tồn tại sau reboot; tạo lại container và kiểm thử lại.
Không ghi console host là nguyên nhân đã được chứng minh; đó là giả thuyết từng kiểm tra.

## 2026-10-26 — Kubernetes runtime và kiểm thử reboot

### Kết quả
- Runtime public: cluster cv-runtime, namespace cv-production.
- Cloudflared systemd chuyển tới loopback 18082, Host khimkum.xyz.
- Smoke test nội bộ và public: PASS.
- Sau reboot và đăng nhập Windows, hệ thống tự khởi động.
- Harbor healthy; Kubernetes API, node, Traefik và CV sẵn sàng.
- Startup hoàn tất lúc 15:27:59 +07:00.
- Kiểm tra health, website và PDF bằng 4G thành công.
- Lần kiểm thử này mất khoảng 7 phút từ lúc Scheduled Task bắt đầu.

### Sự cố và cách xử lý
- IP container node thay đổi, khác Internal-IP lưu trong Kubernetes.
  Log Network Policy controller báo không tìm thấy interface.
  Đã cố định IP Docker của node thành 172.26.0.3.
- Lệnh patch Node trả "no change", không coi đó là bằng chứng
  lệnh patch đã khôi phục cluster.
- Startup bổ sung chờ API /readyz, node, rollout và HTTP.
- Harbor Core kết nối khi PostgreSQL còn khởi động.
  Đã thêm healthcheck TCP và dependency service_healthy.
- Có lúc một IP Cloudflare timeout trên cả Windows và WSL.
  Kiểm tra sau đó cả hai IP thành công; chưa xác định nguyên nhân
  sâu hơn, không kết luận nhà mạng chặn.

### Giới hạn
- Máy phải thức và có Internet; tự khởi động sau Windows sign-in.
- Một node không cung cấp khả năng chịu lỗi node.
- Connector còn chạy bằng systemd; namespace edge chưa triển khai.
