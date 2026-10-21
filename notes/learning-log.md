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
