# Phát hành CV qua Harbor

## Bản đã triển khai
- Commit ứng dụng: 0c3986f754979273dd86c980b50ca70e14a8d5bc
- Artifact: harbor.cv.test:8443/cv/portfolio@sha256:036a115ee4ad4e06eecee1ba30fa4138ab2e08c57a08b8f4778108db7becc3d5
- Trivy: No vulnerability tại lần quét ngày 2026-10-23.
- Smoke test: ứng viên, local và public đều PASS.
- Public version.json trả đúng commit ứng dụng.

## Kiểm soát phát hành
- Robot ci-push: repository pull và push.
- Robot deploy-pull: chỉ pull; đã kiểm chứng push bị từ chối.
- Tag release-* của portfolio được đặt immutable.
- Retention portfolio: giữ 10 artifact push gần nhất, gồm untagged.
- Retention đã Dry Run thành công; chưa đặt lịch tự động.
- Compose đọc CV_DEPLOY_IMAGE trong .env và triển khai bằng digest.

## Khôi phục
- Image dự phòng local: khimkum-cv:rollback-before-harbor-0c3986f.
- Đổi CV_DEPLOY_IMAGE trong .env sang image dự phòng.
- Tạo lại cv và cv-access bằng --no-build --pull never.
- Kiểm tra smoke test public sau khôi phục.
- Đã chuẩn bị phương án; chưa diễn tập rollback thực tế.

## Công việc tiếp theo
- Quét, kiểm thử và triển khai image gateway đã vá.
- Diễn tập rollback có kiểm soát.
- Hoàn thiện lab Kaniko.

## Gateway đã triển khai
- Commit build: 895f4e20052ebbdaaee60a0bc0d90030fcbc1d2a
- Artifact: harbor.cv.test:8443/cv/gateway@sha256:cd8edd6e4a41a2f583890865a2766bd73ed8e0eda55f4ac78486e074bdb930a1
- cv-access và monitoring-access dùng chung artifact, mount cấu hình riêng.
- nginx -t thành công trên cả hai cấu hình trước triển khai.
- CV local và public: smoke test PASS sau thay gateway.
- Grafana /api/health: database ok.
- Prometheus /-/ready và Alertmanager /-/ready: thành công.
- Triển khai chỉ tạo lại hai gateway bằng --no-deps --no-build.
- GATEWAY_DEPLOY_IMAGE được lưu trong .env để dùng lại khi khởi động.

## Giới hạn đã biết
- Kết quả scan phản ánh cơ sở dữ liệu lỗ hổng tại thời điểm quét.
- Bước apk upgrade dùng repository hiện tại, nên pin base digest
  chưa bảo đảm toàn bộ quá trình build tái lập tuyệt đối.
- - Ngày 2026-10-24: đã diễn tập rollback cấu hình trên project
  cv-rollback-lab tại 127.0.0.1:18080.
- Override entrypoint trỏ đến file Nginx không tồn tại:
  container thoát mã 1, log xác nhận đúng nguyên nhân.
- Bỏ override và tạo lại container: healthy, smoke test PASS,
  metadata trước/sau giống nhau.
- Đã dọn lab và xác nhận smoke test public PASS.
- Chưa diễn tập rollback trên production.

## Quét lại ngày 2026-10-24
- Artifact CV trước đó và artifact Kaniko bị báo High sau quét lại.
- Artifact Kaniko có CVE-2026-111497 tại brotli-libs 1.2.0-r1.
- Bản vá Alpine: brotli-libs 1.2.1-r0.
- Cập nhật stage nginx-patched dùng chung cho CV và gateway.
- Artifact thay thế cần được scan và kiểm thử trước triển khai.
