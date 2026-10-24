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
