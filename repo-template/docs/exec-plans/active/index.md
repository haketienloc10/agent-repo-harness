# Kế hoạch Active

Với mỗi task active sẽ thay đổi code, test, build script, migration hoặc cấu
hình runtime, tạo một execution-plan artifact riêng trong thư mục này trước khi
dùng tool sửa file. Cập nhật artifact trong suốt task để agent khác có thể tiếp
tục từ trạng thái đã ghi. Khi không có task thay đổi code đang chạy, thư mục có
thể chỉ chứa `index.md`.

Mẫu tên tệp đề xuất:

- `{{PLAN_DATE}}-{{PLAN_SLUG}}.md`

Tuân theo nội dung tối thiểu và vòng đời trong `docs/PLANS.md`.
