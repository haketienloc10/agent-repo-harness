# PRODUCT_SENSE.md

Tệp này ghi lại phán xét sản phẩm lâu bền mà agent không thể suy ra đáng tin cậy chỉ từ mã.

## Cốt lõi Sản phẩm

- Người dùng chính: `{{PRIMARY_USER}}`
- Công việc cần hoàn thành: `{{JOB_TO_BE_DONE}}`
- Sự thất vọng chính cần loại bỏ: `{{PRIMARY_FRUSTRATION}}`
- Tiêu chuẩn chất lượng để chấp nhận: `{{ACCEPTANCE_QUALITY_BAR}}`

## Quy tắc Sản phẩm

- Ưu tiên độ tin cậy có thể nhìn thấy của người dùng hơn số lượng tính năng.
- Coi hành vi mơ hồ là khoảng trống spec, không phải sự cho phép để đoán.
- Nếu việc triển khai thay đổi những gì người dùng nhìn thấy hoặc tin tưởng, hãy cập nhật spec phù hợp.
- Sử dụng product spec cho các luồng cụ thể, và sử dụng tệp này cho các ưu tiên sản phẩm xuyên suốt.

## Mẫu Không được phép

- Các hành động phá hủy ẩn
- Thất bại âm thầm mà không có phản hồi cho người dùng
- Nguồn sự thật không rõ ràng cho trạng thái có thể nhìn thấy
- Các tính năng không thể giải thích trong một câu
