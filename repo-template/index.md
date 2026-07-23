# Source Template Repository Harness v2

Installer dùng template này để tạo đúng bảy core file. Không copy toàn bộ thư
mục bằng tay và không thêm optional placeholder vào source template.

## Thứ tự Thiết lập

1. Cài core harness bằng `install.sh`.
2. Xử lý mọi conflict cài đặt trước khi khảo sát.
3. Đọc `docs/HARNESS_SETUP.md` khi takeover còn `pending` hoặc `blocked`.
4. Ghi snapshot vào `docs/TAKEOVER_BASELINE.md` và command hiện tại vào
   `docs/VERIFY.md`.
5. Chỉ tạo optional artifact khi có nội dung repo-specific thực.
6. Chạy `./scripts/harness-check.sh` cho đến khi trả exit `0`.
7. Khi không có task cần plan, `docs/tasks/active/` có thể không tồn tại.

## Mẫu Này Tối ưu hóa Cho

- ngữ cảnh cục bộ repo lâu bền
- tiếp quản repo cũ mà không tự ý sửa code yếu hoặc failure có sẵn
- tiết lộ tiến triển thay vì một tệp hướng dẫn khổng lồ
- vòng đời kế hoạch rõ ràng
- một source of truth cho mỗi concern
- ranh giới có thể đọc được cho agent và con người

Optional artifact được định tuyến trong `AGENTS.md`; chúng không phải default
của template. Repository v1 phải dùng guide
`docs/HARNESS_V1_TO_V2_MIGRATION.md` ở source repository harness để audit và
migration mà không mất dữ liệu.
