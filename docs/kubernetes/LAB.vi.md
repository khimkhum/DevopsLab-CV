# Kubernetes CV lab

- Cluster: cv-lab, một node K3s.
- Namespace: cv-lab, Pod Security restricted.
- Image lấy từ Harbor bằng digest và robot deploy-pull.
- Hai Pod CV Ready; Service có hai endpoint.
- Smoke test qua Service port-forward: PASS.
- Ingress Traefik tại 127.0.0.1:18081: smoke test PASS.
- Xóa một Pod: ReplicaSet tạo Pod thay thế, trở lại hai Pod Ready.
- Smoke test sau phục hồi: PASS.
- Scale lên ba replica: đạt; apply manifest trở lại hai replica.
- Các bài thử chưa đo khả năng phục vụ liên tục khi có lỗi.
- Một node không cung cấp khả năng chịu lỗi node.

## ConfigMap, RBAC và NetworkPolicy

- Nginx dùng ConfigMap immutable cv-nginx-v1.
- nginx -t thành công; smoke test qua Ingress PASS.
- Một lần smoke test ngay sau rollout bị timeout.
  Chạy lại PASS; nguyên nhân timeout chưa xác định.

- ServiceAccount cv-observer được xem Pod trong cv-lab.
- Không được đọc Secret, xóa Pod hoặc xem Pod ở kube-system.

- Trước NetworkPolicy: HTTP hai chiều giữa Pod kiểm thử
  và ứng dụng CV đều trả ok.
- Sau NetworkPolicy: cả hai kết nối bị Connection refused.
- Kiểm tra firewall node thấy cơ chế REJECT
  với icmp-port-unreachable.
- Truy cập qua Traefik và phân giải DNS vẫn hoạt động.
- Pod kiểm thử đã được dọn.
- Giữ policy cv-isolation trong cấu hình triển khai.

## Rollout lỗi và rollback

- Baseline: hai Pod Ready; lưu revision, Pod template và version.json.
- Patch command Nginx để đọc file cấu hình không tồn tại.
- Pod mới CrashLoopBackOff; log xác nhận nguyên nhân.
- Rollout status hết thời gian chờ; không tự rollback.
- Hai Pod cũ vẫn Ready; smoke test trong lúc lỗi PASS.
- Endpoint Pod lỗi có ready=false.
- Rollback về revision đã lưu thành công.
- Pod template trước/sau giống nhau.
- Release metadata trước/sau giống nhau; smoke test PASS.
- ReplicaSet lỗi về 0; Deployment có hai replica cập nhật và khả dụng.
- Bài thử giữ nguyên image digest.

## ResourceQuota, LimitRange và lưu trữ

- Thực hành trong namespace riêng cv-practice.
- LimitRange tự điền request 25m/32Mi, limit 100m/64Mi.
- CPU limit 400m bị từ chối vì vượt maximum 300m.
- CPU request 100m bị từ chối vì tổng request vượt quota.
- PVC local-path Pending trước khi có consumer, sau đó Bound.
- PV được cấp động, access mode RWO, reclaim policy Delete.
- Thay Pod: UID thay đổi, dữ liệu PVC còn nguyên.
- emptyDir mất dữ liệu sau khi thay Pod.
- Smoke test Kubernetes và public sau thực hành PASS.
- Chưa kiểm chứng phục hồi khi mất node/cluster.
- local-path không thực thi giới hạn cứng dung lượng volume.
