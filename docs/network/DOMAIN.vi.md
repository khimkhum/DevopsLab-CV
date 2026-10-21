# Tên miền website CV

Người dùng cung cấp tên miền `khimkum.xyz` cho dự án tại `F:\Devops_Lab`.

Nhà cung cấp đăng ký đã xác nhận: **GoDaddy**. Người dùng đã thêm tên miền vào Cloudflare và nhận hướng dẫn cập nhật nameserver để kích hoạt. Phương án là giữ việc đăng ký/gia hạn tại GoDaddy và dùng Cloudflare cho authoritative DNS cùng Tunnel.

## Nameserver đã được cấp

Các giá trị sau do người dùng cung cấp từ bước kích hoạt Cloudflare:

| Loại | Nameserver |
| --- | --- |
| Cloudflare mới | jay.ns.cloudflare.com |
| Cloudflare mới | julissa.ns.cloudflare.com |
| GoDaddy cần thay | ns65.domaincontrol.com |
| GoDaddy cần thay | ns66.domaincontrol.com |

Registry RDAP đã ghi nhận đúng cặp Cloudflare trong lần kiểm tra sau khi người dùng cập nhật GoDaddy. DNS công khai và zone Active vẫn phải được xác minh riêng; chưa xác nhận Cloudflare Active.

## Địa chỉ dự kiến

| Thành phần | Hostname hoặc cách truy cập |
| --- | --- |
| CV production | https://khimkum.xyz |
| Alias tùy chọn | www.khimkum.xyz chuyển hướng về hostname chính |
| Staging | Giữ riêng trong giai đoạn đầu |
| Grafana, ArgoCD, Harbor, Prometheus | Kênh quản trị riêng, không tự tạo hostname public |

Đây là địa chỉ dự kiến, chưa phải xác nhận website đã hoạt động.

## Kết quả kiểm tra DNS

Kiểm tra ngày 19 tháng 10 năm 2026. Truy vấn NS cho `khimkum.xyz` qua cả
Cloudflare DNS over HTTPS và Google Public DNS trả `Status: 3` (NXDOMAIN),
không có Answer. Resolver của Windows cũng chưa phân giải được tên miền.

Kết quả phản ánh trạng thái DNS được quan sát tại thời điểm kiểm tra. Chưa
đủ thông tin để kết luận nguyên nhân là chưa hoàn tất đăng ký, delegation
chưa có, thao tác cấu hình mới thực hiện hay tên miền cần được kiểm tra lại.

Kiểm tra tiếp theo sau cập nhật GoDaddy: RDAP từ endpoint registry được tra qua IANA đã có `jay.ns.cloudflare.com` và `julissa.ns.cloudflare.com`. Tuy nhiên, truy vấn NS/A/AAAA qua Cloudflare và Google còn trả NXDOMAIN; truy vấn NS trực tiếp tới `ns0.centralnic.net` cũng chưa có delegation tại thời điểm kiểm tra. Như vậy cặp nameserver đã được lưu ở dữ liệu đăng ký, nhưng DNS chưa phục vụ tên miền. Không coi đây là bằng chứng đã có website hoạt động.

Cập nhật ngày 20 tháng 10 năm 2026: cả Cloudflare DNS over HTTPS và Google Public DNS trả Status 0 cho truy vấn NS, cùng đúng `jay.ns.cloudflare.com`, `julissa.ns.cloudflare.com`. Delegation công khai đã phân giải thành công. Điều này chưa xác nhận có route tunnel, record phục vụ CV hoặc website public; các mục đó cần kiểm tra sau triển khai.

## Trạng thái hiện tại và thông tin còn cần xác nhận

- Nhà cung cấp: GoDaddy, theo thông tin người dùng.
- Tên miền đã xuất hiện trong tài khoản nhà cung cấp và trạng thái đang active chưa.
- Cloudflare: đã thêm zone, DNS delegation đã phân giải đúng cặp nameserver qua hai public resolver ngày 20 tháng 10 năm 2026; chưa kiểm tra trực tiếp trạng thái zone trong dashboard.
- Có website, email hoặc DNS record hiện có cần giữ lại không.

Không gửi password, API token, mã khôi phục hay private key vào tài liệu này.

## Thêm tên miền vào Cloudflare

1. Kiểm tra `khimkum.xyz` đang active trong GoDaddy và lưu các DNS record đang dùng, nhất là email.
2. Đăng nhập Cloudflare, vào Domains, chọn Onboard a domain, nhập `khimkum.xyz`, chọn gói Free cho bước DNS cơ bản.
3. Rà soát record được quét; bổ sung record đang dùng nếu còn thiếu. Chưa tạo A/AAAA trỏ về IP nhà hoặc IP riêng của WSL.
4. Cặp nameserver đã cấp là `jay.ns.cloudflare.com` và `julissa.ns.cloudflare.com`.

[Hướng dẫn Cloudflare](https://developers.cloudflare.com/dns/zone-setups/full-setup/setup/).

## Đổi nameserver ở GoDaddy

1. Mở Domain Portfolio, chọn `khimkum.xyz`, vào phần Nameservers của tên miền.
2. Chọn Change Nameservers và phương án dùng nameserver riêng; thay `ns65.domaincontrol.com`, `ns66.domaincontrol.com` bằng `jay.ns.cloudflare.com`, `julissa.ns.cloudflare.com`, rồi lưu và xác thực tài khoản nếu được yêu cầu.
3. Đổi tại cấu hình nameserver của tên miền, không chỉ thêm NS record trong bảng DNS thông thường.
4. Nếu đang có DNSSEC/DS cũ, xử lý theo hướng dẫn migration trước khi đổi; không giữ DS không khớp. Sau khi Cloudflare active, có thể cấu hình lại DNSSEC đúng cặp khóa mới.
5. Quay lại Cloudflare, kiểm tra activation và đợi trạng thái Active. Sau khi chuyển thành công, sửa DNS tại Cloudflare; đăng ký và gia hạn vẫn ở GoDaddy.

[Hướng dẫn GoDaddy](https://www.godaddy.com/help/change-my-domain-nameservers-664).

## Nghiệm thu DNS

Chạy trong PowerShell:

```powershell
Resolve-DnsName khimkum.xyz -Type NS -Server 1.1.1.1
```

Kết quả cần khớp cặp nameserver được cấp và Cloudflare báo zone Active. Website chưa có A/AAAA/CNAME phục vụ web vẫn có thể chưa mở được; DNS delegation hoạt động không có nghĩa CV đã được triển khai.

Khi website local và baseline bảo mật đã được kiểm tra, tạo named tunnel, map đúng hostname CV tới dịch vụ nội bộ và kiểm tra HTTPS từ mạng ngoài. Các hostname quản trị vẫn giữ riêng.

Chưa thay nameserver, tạo record hoặc public dịch vụ trong lần cập nhật này.

Hướng dẫn giới hạn IP Cloudflare trong trang kích hoạt là hướng dẫn chung cho origin nhận kết nối inbound. Với thiết kế Cloudflare Tunnel của dự án, không mở port router để nhận traffic web trực tiếp. Chính sách firewall cho connector outbound và quản trị sẽ được thiết kế theo luồng thực tế; không áp một allowlist inbound chung rồi coi đã hoàn tất bảo mật WSL.
