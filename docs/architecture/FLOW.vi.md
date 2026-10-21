# Luồng hoạt động dự kiến của dự án CV DevOps

Ngày cập nhật: 20 tháng 10 năm 2026. Đây là thiết kế trước triển khai, không phải xác nhận các thành phần bên dưới đã được cài hoặc tên miền đã hoạt động.

Workspace duy nhất là `F:\Devops_Lab`, tương ứng `/mnt/f/Devops_Lab` trong Ubuntu WSL2. Windows Terminal là giao diện làm việc; Ubuntu WSL2 cung cấp môi trường chạy lệnh Linux.

## 1 Người xem truy cập website

Trước khi kết nối, trình duyệt phân giải tên miền qua DNS. DNS trả thông tin để trình duyệt kết nối tới Cloudflare; DNS không chuyển tiếp request HTTP.

```text
Browser --- DNS lookup khimkum.xyz ---> DNS resolver / Cloudflare DNS
Browser <--- DNS answer -------------- DNS resolver / Cloudflare DNS
```

Sau khi có kết quả DNS, request web đi theo luồng này:

```text
[Nguoi xem]
     |
     | HTTPS: https://khimkum.xyz
     v
[Cloudflare Edge: TLS, cac rule bao ve da cau hinh]
     |
     | Request di qua tunnel da duoc thiet lap
     v
+---------------------- MAY CA NHAN WINDOWS ----------------------+
|                                                                |
|  +---------------------- UBUNTU WSL2 ------------------------+  |
|  |                                                         |  |
|  |  [cloudflared]                                          |  |
|  |        |                                                |  |
|  |        v                                                |  |
|  |  [Traefik noi bo: ClusterIP + Ingress rule]               |  |
|  |        | Host = khimkum.xyz                              |  |
|  |        v                                                |  |
|  |  [Service CV production: ClusterIP]                      |  |
|  |        |                                                |  |
|  |        v                                                |  |
|  |  [Pod CV: web server non-root, cong 8080]                 |  |
|  |        |                                                |  |
|  |        +--- HTML / CSS / JS / CV PDF                     |  |
|  |                                                         |  |
|  +---------------------------------------------------------+  |
|                                                                |
+----------------------------------------------------------------+
```

Kết nối tunnel được khởi tạo theo chiều outbound:

```text
cloudflared trong WSL2 --- outbound connection ---> Cloudflare
```

Request và response đi hai chiều trên kết nối đó. Không cần port forwarding trên router cho CV. Cloudflare không đồng nghĩa mọi WAF/rate limit đã tự bật; chỉ tính những kiểm soát thực tế đã cấu hình và kiểm chứng.

Trong bản Kubernetes đích, cloudflared, Traefik và CV là các workload trong cluster K3s. K3s dùng containerd; không phụ thuộc việc bật Docker Desktop để làm container runtime cho cluster. Ở chặng Docker trước đó, Compose được dùng làm mốc học riêng.

Staging và các UI quản trị giữ riêng; không tạo wildcard public route đi vào cả lab. Cache ở Cloudflare có thể trả nội dung mà không đi tới origin; kiểm tra revision/origin cần đường không bị cache che kết quả.

## 2 Từ sửa source đến production

```text
[Developer: F:\Devops_Lab = /mnt/f/Devops_Lab]
     |
     | commit / push / Merge Request
     v
[GitLab: app repository]
     |
     | Runner lay job qua ket noi outbound toi GitLab
     v
[GitLab Runner trong moi truong cach ly]
     |
     +--- Lint / test / secret scan
     |
     +--- Build image mot lan bang BuildKit rootless
     |
     +--- Push image vao Harbor, scan dung image digest
     |
     +--- Neu gate dat: cap nhat GitOps staging bang digest do
                            |
                            v
                 [GitLab: GitOps repository]
                            ^
                            | ArgoCD pull Git / doc desired state
                            |
                       [ArgoCD]
                            |
                            | reconcile / sync
                            v
                     [CV staging]
                            |
                            | Kiem tra health + dung revision + smoke test
                            v
                    [Duyet promotion]
                            |
                            | Sua GitOps production: CUNG image digest
                            v
                 [GitOps production duoc chap nhan]
                            ^
                            | ArgoCD pull Git
                            |
                       [ArgoCD]
                            |
                            v
                    [CV production]
                            |
                            +--- Kiem tra version origin va URL public
```

Harbor lưu image; khi tạo container từ image chưa có cache, node K3s pull image từ Harbor bằng credential chỉ đọc. CI không cần kubeconfig quản trị và không trực tiếp SSH vào runtime để triển khai.

Staging và production dùng cùng artifact đã kiểm tra, không rebuild khi promote. Gate production phải bảo vệ việc thay desired state trong Git; nếu sửa manifest production trước khi duyệt, ArgoCD auto-sync có thể triển khai trước gate.

Pipeline lỗi trước promotion thì production giữ version hiện tại. Rollback đi qua Git:

```text
Revert GitOps ve digest tot --- ArgoCD pull/sync ---> Khoi phuc version cu
```

Kaniko vẫn có bài thực hành riêng theo roadmap; BuildKit rootless là lựa chọn cho pipeline duy trì lâu dài. Job không tin cậy không được nhận secret registry/production, không mount socket điều khiển host vào job. Harbor và runner là hai vai trò cần được cách ly phù hợp, không mặc định gộp vào distro phát triển chỉ để vừa RAM.

## 3 Monitoring va canh bao

```text
                         +--- Node / VM metrics
                         |
[Prometheus] --- scrape --+--- Kubernetes / Pod metrics
      |                  |
      |                  +--- Traefik / cloudflared metrics neu duoc bat
      |                  |
      |                  +--- Blackbox probe results
      |
      +--- evaluate alert rules ---> [Alertmanager] ---> [Kenh nhan da chon]
      ^
      |
      | query metrics
  [Grafana] <--- Quan tri vien qua kenh rieng

[Probe va canh bao NGOAI mang nha]
      |
      +--- HTTPS probe ---> https://khimkum.xyz
      |
      +--- Neu host / mang nha ngung ---> Canh bao tu noi doc lap
```

Prometheus chủ động scrape; target trả metrics về Prometheus. Grafana truy vấn dữ liệu để hiển thị dashboard. Alertmanager gửi cảnh báo theo rule/receiver đã cấu hình. Metrics endpoint và dashboard không công khai cùng CV.

Nếu host tắt thì monitoring nằm trên host cũng tắt. Vì vậy phép kiểm tra bên ngoài cần cả khả năng gửi cảnh báo độc lập. Probe URL qua CDN kiểm tra trải nghiệm public; phải bổ sung kiểm tra origin/revision phù hợp để phát hiện origin chết nhưng cache vẫn trả trang.

## 4 Khi bat Windows

```text
[Windows boot]
     |
     v
[Co che khoi chay WSL dung tai khoan so huu distro]
     |
     v
[Ubuntu WSL2 + systemd]
     |
     v
[K3s / containerd]
     |
     +--- Khoi tao / khoi phuc Pods, services va volumes
     |
     +--- Pull image neu can: Harbor phai truy cap duoc
     |
     v
[cloudflared: ket noi lai khi mang san sang]
     |
     v
[CV truy cap duoc qua khimkum.xyz]
```

Cơ chế startup và vòng đời WSL phải được triển khai, thử đóng terminal, idle, reboot Windows và mất mạng/có lại. systemd running không tự chứng minh các bước đó đã đạt. Hiện tại mới có nền WSL2, workspace và script kiểm tra; chưa cấu hình startup website.

## 5 Phan bo va bien truy cap

```text
PUBLIC:          Internet --- Cloudflare Tunnel ---> Chi CV production
ADMIN:           Quan tri vien --- Kenh rieng ----> Grafana / ArgoCD / Harbor
APP SOURCE:      F:\Devops_Lab <== cung folder ==> /mnt/f/Devops_Lab
SECRETS:         Kho credential rieng -----------> Chi thanh phan can su dung
BACKUP:          Du lieu can giu --- ma hoa ------> Ban sao NGOAI o dia host
```

Không tự public Kubernetes API, SSH, Docker API, exporter hoặc toàn bộ ổ F. Website phục vụ artifact CV, không phục vụ root workspace. Workload CV không cần mount source hoặc credential quản trị.

Giới hạn hiện tại 3 GB RAM và 2 CPU là cho chặng Linux, dùng chung bởi WSL2. Trước khi chạy stack đích phải đo và phân bổ lại tài nguyên; sơ đồ này không có nghĩa toàn bộ thành phần vừa trong 3 GB. Staging và production trên cùng host vẫn chung điểm lỗi vật lý.

## 6 Thu tu trien khai

```text
Linux WSL2
   --- Website CV local
   --- Docker / Compose / Harbor va bai Kaniko
   --- Kubernetes thu cong
   --- GitLab CI
   --- GitOps / ArgoCD
   --- Staging + duyet + production
   --- Monitoring + canh bao ngoai nha
   --- Startup, backup, restore va dien tap loi
```

DNS được chuẩn bị song song. Chỉ mở public sau khi route, quyền, dữ liệu host và kết nối tunnel được kiểm tra. Monitoring và bảo mật được tích hợp dần từ các chặng trước, không để đến cuối mới bắt đầu kiểm tra.
