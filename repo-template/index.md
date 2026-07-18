# Mẫu Repo Nâng cao

Sao chép starter này vào một kho lưu trữ thực khi bạn muốn một bề mặt tài liệu agent-first theo phong cách OpenAI thay vì chỉ một harness tối giản.

## Thứ tự Thiết lập

1. Cài `AGENTS.md`, `ARCHITECTURE.md`, cây `docs/` và checker bằng `install.sh`.
2. Xử lý mọi conflict cài đặt trước khi khảo sát.
3. Đọc và làm lần lượt toàn bộ `docs/HARNESS_SETUP.md`.
4. Ghi `docs/PROJECT_BASELINE.md` trước khi phân loại failure.
5. Điền `docs/LEGACY_ISSUES.md`, `docs/PRODUCT_SENSE.md`, `docs/QUALITY_SCORE.md` và `docs/RELIABILITY.md` từ bằng chứng khảo sát.
6. Chạy `./scripts/harness-check.sh` cho đến khi trả exit `0`.
7. Khi chưa có task người dùng, `docs/exec-plans/active/` có thể trống.
8. Giữ các tệp đầu vào ngắn và định tuyến chi tiết vào các tài liệu được liên kết.

## Mẫu Này Tối ưu hóa Cho

- ngữ cảnh cục bộ repo lâu bền
- tiếp quản repo cũ mà không tự ý sửa code yếu hoặc failure có sẵn
- tiết lộ tiến triển thay vì một tệp hướng dẫn khổng lồ
- vòng đời kế hoạch rõ ràng
- theo dõi chất lượng theo thời gian
- ranh giới có thể đọc được cho agent và con người

Coi mỗi tệp ở đây là một starter. Thay thế các placeholder, ví dụ và lệnh mẫu bằng các đặc thù dự án thực trước khi dựa vào harness để xử lý task người dùng.
