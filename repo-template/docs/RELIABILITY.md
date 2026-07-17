# RELIABILITY.md

Tệp này định nghĩa cách hệ thống chứng minh nó khỏe mạnh và có thể khởi động lại.

## Đường dẫn Chuẩn

- Bootstrap: `{{BOOTSTRAP_COMMAND}}`
- Xác minh: `{{VERIFY_COMMAND}}`
- Khởi động app hoặc service: `{{START_COMMAND}}`
- Debug hoặc kiểm tra runtime: `{{DEBUG_COMMAND}}`
- Mechanical guardrail: `{{MECHANICAL_GUARDRAIL}}`

Kết quả tại thời điểm tiếp quản được ghi trong `PROJECT_BASELINE.md`. Command ở đây là đường dẫn chuẩn hiện tại; khi thay đổi command, cập nhật tài liệu và kế hoạch liên quan mà không viết lại bằng chứng lịch sử của baseline.

## Tín hiệu Runtime Bắt buộc

- log có cấu trúc cho khởi động và các luồng quan trọng
- health check cho các service chính
- dữ liệu trace hoặc timing cho các đường dẫn chậm khi có sẵn
- trạng thái lỗi có thể nhìn thấy của người dùng cho các thất bại có thể phục hồi

## Journey Vàng

- `{{GOLDEN_JOURNEY_1}}`
- `{{GOLDEN_JOURNEY_2}}`
- `{{GOLDEN_JOURNEY_3}}`

Mỗi journey vàng nên có đường dẫn xác minh có thể lặp lại và tín hiệu thất bại rõ ràng.

## Quy tắc Độ tin cậy

- Không có tính năng nào hoàn thành nếu hệ thống không thể khởi động lại sạch sẽ sau đó.
- Các thất bại runtime nên có thể chẩn đoán từ các tín hiệu cục bộ repo.
- Nếu một chế độ thất bại lặp đi lặp lại xuất hiện, hãy thêm benchmark hoặc guardrail cho nó.
- So sánh kết quả xác minh với baseline: legacy failure không chặn công việc ngoài phạm vi nếu không xấu hơn, còn regression mới phải được sửa trước khi hoàn thành.
- Failure chưa rõ nguồn gốc phải được ghi trong kế hoạch active để phân loại; không tự thêm vào `LEGACY_ISSUES.md`.
- Dọn dẹp là một phần của độ tin cậy, không phải một mối quan tâm riêng biệt.
