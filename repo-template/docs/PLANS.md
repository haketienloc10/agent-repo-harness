# PLANS.md

Sử dụng tài liệu này để quản lý execution-plan artifact như trạng thái bền vững
của agent trong suốt một task.

## Trigger Bắt buộc

Nếu task sẽ thay đổi code, test, build script, migration hoặc cấu hình runtime:

1. Tạo hoặc mở một execution-plan artifact riêng trong
   `docs/exec-plans/active/`.
2. Ghi mục tiêu, phạm vi dự kiến và đường dẫn xác minh.
3. Chỉ bắt đầu sửa file sau khi artifact tồn tại.
4. Giữ artifact hiện tại trong suốt task.

Không tạo artifact cho task chỉ đọc, giải thích, review hoặc báo cáo mà không
thay đổi file. Với task chỉ thay đổi tài liệu, tạo artifact khi tài liệu đó phục
vụ một task thay đổi code hoặc khi công việc:

- trải dài hơn một phiên
- thay đổi nhiều hơn một hệ thống con
- có rủi ro xác minh hoặc triển khai không tầm thường
- phụ thuộc vào các quyết định mở nên được ghi lại

## Vị trí Kế hoạch

- `docs/exec-plans/active/`: các kế hoạch hiện đang thúc đẩy công việc; có thể trống khi không có task đang làm
- `docs/exec-plans/completed/`: các kế hoạch đã hoàn thành được giữ lại để cung cấp ngữ cảnh cho agent trong tương lai
- `docs/exec-plans/tech-debt-tracker.md`: công việc đã hoãn và các follow-up

## Các Phần Kế hoạch Tối thiểu

- mục tiêu
- phạm vi và ngoài phạm vi
- đường dẫn xác minh
- rủi ro và sự cố chặn
- nhật ký tiến độ
- quyết định mở
- quan hệ với baseline và legacy issue liên quan
- observation chưa phân loại, owner và bước cần làm để phân loại

## Quy tắc Vận hành

- Giữ đúng một bước hiện tại có owner rõ ràng trong mỗi artifact active.
- Tạo artifact trước lần sửa đầu tiên; không tạo hồi tố ở cuối task chỉ để đáp ứng Definition of Done.
- Ghi file hoặc phạm vi code dự kiến thay đổi; cập nhật artifact ngay khi phạm vi thực tế thay đổi.
- Dùng `PROJECT_BASELINE.md` làm điểm so sánh, không làm lý do bỏ qua regression mới.
- Failure được chứng minh tại revision baseline có thể liên kết đến `LEGACY_ISSUES.md`; không yêu cầu sửa ngoài phạm vi nếu thay đổi hiện tại không làm nó xấu hơn.
- Failure do task hiện tại tạo ra phải được sửa trong task. Không chuyển nó thành legacy issue hoặc nợ kỹ thuật để đóng kế hoạch.
- Phát hiện chưa rõ có tồn tại ở baseline hay không phải ở lại kế hoạch active như observation chưa phân loại cho đến khi có bằng chứng.
- Cập nhật artifact sau mỗi thay đổi đáng kể về phạm vi, quyết định, tiến độ hoặc kết quả xác minh; không dùng nó như văn xuôi tĩnh.
- Chỉ chuyển artifact sang `completed/` sau khi ghi đủ thay đổi code thực tế, evidence xác minh, quyết định và trạng thái tài liệu liên quan.
- Không xóa artifact đã hoàn thành. Giữ nó trong `completed/` để agent tương lai có thể khôi phục ngữ cảnh.
- Sau khi chuyển artifact cuối cùng sang `completed/`, để `active/` trống là trạng thái hợp lệ.
