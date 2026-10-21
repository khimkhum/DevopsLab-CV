# Bắt đầu dự án DevOps bằng Ubuntu WSL2

Môi trường dự án đã chuyển sang Ubuntu WSL2 đang có trên máy. Bạn không cần tạo VM VirtualBox hoặc cài lại Ubuntu.

## Cấu hình đã thực hiện

| Hạng mục | Kết quả |
| --- | --- |
| Linux | Ubuntu 26.04.1 LTS trên WSL2 |
| User làm việc | khimkum, user thường có nhóm sudo |
| Dịch vụ Linux | systemd hoạt động, PID 1 là systemd |
| Giới hạn WSL2 | 2 logical processor, tối đa 3 GB RAM, 2 GB swap |
| File cấu hình Windows | C:\Users\levan\.wslconfig |
| Workspace Windows | F:\Devops_Lab |
| Cùng workspace trong WSL | /mnt/f/Devops_Lab |
| Git | Repo local, nhánh main; chưa commit hoặc kết nối remote |
| Kiểm tra mạng | HTTPS đến ubuntu.com trả HTTP 200 |

Giới hạn tài nguyên áp dụng chung cho WSL2, bao gồm Docker Desktop khi bật. Đã restart WSL và xác minh CPU/RAM mới có hiệu lực. Giới hạn RAM có thể tăng khi chuyển sang Docker/Kubernetes, sau khi đo nhu cầu thực tế.

Filesystem Linux dùng VHD mở rộng theo dữ liệu. Dung lượng logic khoảng 1 TB mà `df` hiển thị không có nghĩa ổ Windows còn 1 TB trống. Không tạo thêm hoặc thu nhỏ ổ 60 GB cho bước này.

## Mở môi trường làm việc

Chạy trong PowerShell hoặc tab PowerShell của Windows Terminal:

```powershell
wsl -d Ubuntu --cd /mnt/f/Devops_Lab
```

Nếu đã ở trong Ubuntu:

```bash
cd /mnt/f/Devops_Lab
```

Không dùng distro `docker-desktop` làm môi trường học hoặc lưu source.

## Những file đã tạo

```text
Devops_Lab/
  .gitignore
  README.md
  docs/linux/ENVIRONMENT.txt
  notes/learning-log.md
  scripts/verify-foundation.sh
```

Toàn bộ source, tài liệu và script nằm trong folder `F:\Devops_Lab`. WSL dùng đường dẫn `/mnt/f/Devops_Lab` để truy cập cùng folder đó; không có workspace thứ hai trong home Linux.

Kiểm tra lại môi trường trong Ubuntu tại thư mục dự án:

```bash
bash scripts/verify-foundation.sh
cat docs/linux/ENVIRONMENT.txt
git status
```

Script kiểm tra công cụ, systemd, user, RAM, CPU và disk. Script ghi lại metadata môi trường, không thu thập password, token hoặc toàn bộ biến môi trường.

## Bài thực hành Linux đầu tiên

Chạy từng lệnh và ghi lại ý nghĩa, không chạy cả khối rồi chỉ nhìn kết quả cuối:

```bash
pwd
whoami
id
ls -la
ip -brief address
ip route
ss -lntup
free -h
df -h /
systemctl --failed
```

Ghi kết quả giải thích vào `notes/learning-log.md`. Mục tiêu là trả lời được: đang là user nào, file thuộc ai, mạng đi qua đâu, service nào đang lỗi và RAM/disk nào đang được đo.

Tiếp theo học quyền file và process, rồi tạo một service demo an toàn. Sau nền Linux mới chuyển sang website CV, Docker và các phase còn lại trong `PROJECT_GUIDE.vi.md`.

## Điều kiện trước khi đưa website ra Internet

Baseline hiện tại phục vụ học và phát triển local. Chưa cấu hình public tunnel hoặc startup khi Windows boot. systemd chạy bình thường không tự chứng minh WSL luôn sống khi đóng terminal.

WSL hiện vẫn có tích hợp filesystem Windows và khả năng chạy chương trình Windows. Phải đánh giá quyền truy cập host, credential, mạng và mount vào workload trước khi công khai website. Không coi nhiều distro WSL là nhiều VM cách ly độc lập.

Nguồn tham khảo: [Cấu hình WSL](https://learn.microsoft.com/en-us/windows/wsl/wsl-config), [Filesystem WSL](https://learn.microsoft.com/en-us/windows/wsl/filesystems), [systemd trong WSL](https://learn.microsoft.com/en-us/windows/wsl/systemd).
