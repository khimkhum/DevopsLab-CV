# Nghiệm thu GitOps staging — 2026-10-28

## Trạng thái triển khai

- Cluster: cv-runtime.
- Namespace: cv-staging.
- Argo CD Application và AppProject: cv-staging.
- GitOps repository: https://gitlab.com/levankhiem0000/devopslab-cv-gitops.git
- Source commit: dd5cc332a694b9de9d92149a0f26688d645787e9.
- Image: harbor.cv.test:8443/cv/portfolio@sha256:98492a09fbd83b7bec5b0c04a89658ca026035e13f28bded9ba5283c518c34be.
- Image lấy từ artifacts của security gate trong pipeline #2993659716.

## Các bài kiểm chứng

1. Manual sync: Synced/Healthy, smoke test và version metadata PASS.
2. Auto-sync: GitOps commit 7830cbc đổi replica từ 1 thành 2;
   Argo CD tự triển khai, Deployment đạt 2/2.
3. Git revert: commit 34fae50 đảo thay đổi trên;
   Argo CD tự đưa Deployment về 1/1.
4. Self-heal: patch live Deployment thành 2 replica;
   phản hồi API xác nhận đã nhận thay đổi.
   Argo CD tự khôi phục thành 1 replica.
5. Operation có automated=true và phase=Succeeded.
6. GitOps revision sau self-heal vẫn là
   34fae5089fa3f35245ef330960b3ce7b94990be2.
7. Digest image được giữ nguyên; smoke test staging PASS.

## Kiến thức rút ra

- Auto-sync áp dụng thay đổi desired state từ Git.
- Self-heal sửa drift của live state khi Git không đổi.
- Deployment/ReplicaSet duy trì số Pod theo cấu hình live;
  Argo CD khôi phục cấu hình live theo Git.
- Git revert tạo commit mới để đảo thay đổi có lịch sử.
- Bài revert này khôi phục cấu hình replica, chưa thử rollback image.
- Application commit xác định source tạo image;
  GitOps commit xác định cấu hình triển khai.

## Phạm vi hiện tại

- Staging bật auto-sync và self-heal.
- Prune chưa bật.
- Production chưa do Application này quản lý.
- Cluster một node, cùng máy vật lý với CI và Harbor.
- Public smoke test có thể gặp TLS timeout tạm thời;
  retry có giới hạn và ghi rõ từng lần thử.
