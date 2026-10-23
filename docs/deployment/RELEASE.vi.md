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
