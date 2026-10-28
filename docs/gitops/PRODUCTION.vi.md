# Nghiệm thu GitOps production — 2026-10-28

## Kiến trúc và quyền triển khai

- Application và AppProject: cv-production.
- Repository GitOps: levankhiem0000/devopslab-cv-gitops.
- Nhánh theo dõi: main.
- Manifest path: overlays/production.
- Namespace: cv-production.
- Production dùng manual sync sau khi MR được merge.
- AppProject giới hạn repository, namespace và loại tài nguyên.
- Namespace và Secret được bootstrap riêng.
- CI bot có quyền cập nhật staging, không được push hoặc merge main.

## Baseline và promotion

- Baseline GitOps revision:
  9715094ba930943b032fa5b2fa0e639c1a529835.
- Argo tiếp quản production, giữ nguyên Pod template và 2 replica.
- Promotion GitOps revision:
  8275a3bfce46341f53fb0b7d9a3ca2a08df16259.
- Image promotion lấy từ pipeline ứng dụng #2999807523.
- Cùng image digest được kiểm thử trên staging rồi đưa lên production;
  không build lại khi promotion.

## Rollback

- Dùng git revert để đảo commit promotion, đưa qua MR vào main.
- GitOps revision:
  d350b095b7a59956b69f8a2c86b4551dbbfbeaf8.
- Runtime digest:
  sha256:7d38473f34f52e231ef38e10ec067dab9e2271b54194a35530c1673061346925.
- Public application commit:
  6e2a6d17ae240b3e8d6683f588b7128ff9db51f7.
- Argo Synced/Healthy, 2 replica available.
- Smoke test local/public và đối chiếu release cuối cùng PASS.

## Phục hồi release mới

- Revert commit rollback, đưa qua MR vào main.
- GitOps revision:
  d4c95615c8465b0c6eb3f82dd186af501bac687a.
- Runtime digest:
  sha256:6b7cef88cfda0b75e837fd35efe67c81eb2eb48b11c8b834e7c78930909a2d68.
- Public application commit:
  73e16e7d9f6be3455baa37d8099dea0a50dbc1e4.
- Argo Synced/Healthy, 2 replica available.
- Smoke test local/public và đối chiếu release PASS.

## Bài học vận hành

- Git revert tạo commit đảo thay đổi và giữ lịch sử kiểm toán.
- GitOps revision và application commit có vai trò khác nhau.
- Argo Healthy chưa thay thế được kiểm tra chức năng qua HTTP.
- Smoke test đầu tiên sau rollback thất bại ở kiểm tra PDF.
  Kiểm tra lại xác nhận PDF hợp lệ và smoke test PASS;
  chưa xác định được nguyên nhân của lần thất bại đầu tiên.
- Smoke test sau rollout chưa chứng minh không có downtime
  trong toàn bộ quá trình.
- Hai replica trên cùng một node không bảo vệ được khi máy chủ tắt.

## Bằng chứng

Các file cục bộ được lưu tại:
.artifacts/gitops/production/drill/rollback/
.artifacts/gitops/production/drill/restored/

Mỗi lượt có revision kỳ vọng, trạng thái Application,
Deployment, version public và evidence.json.
.artifacts được loại khỏi Git; tài liệu này ghi kết quả đã kiểm chứng.
