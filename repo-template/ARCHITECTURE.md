# ARCHITECTURE.md

Tệp này là bản đồ cấp cao nhất của hệ thống. Nó nên ngắn gọn và trỏ đến các tài liệu sâu hơn khi cần.

## Hình dạng Hệ thống

- Sản phẩm: `{{PRODUCT_NAME}}`
- Workflow người dùng chính: `{{PRIMARY_USER_WORKFLOW}}`
- Bề mặt runtime: `{{RUNTIME_SURFACES}}`
- Nguồn sự thật cho hành vi sản phẩm: `docs/product-specs/`

## Bản đồ Domain

| Domain | Mục đích | Điểm đầu vào chính | Spec liên quan |
|--------|---------|----------------------|----------------|
| `{{DOMAIN_1_NAME}}` | `{{DOMAIN_1_OWNERSHIP}}` | `{{DOMAIN_1_ENTRY_POINTS}}` | `{{DOMAIN_1_SPEC_PATH}}` |
| `{{DOMAIN_2_NAME}}` | `{{DOMAIN_2_OWNERSHIP}}` | `{{DOMAIN_2_ENTRY_POINTS}}` | `{{DOMAIN_2_SPEC_PATH}}` |

## Mô hình Lớp

Sử dụng mô hình định hướng cố định để agent không tự phát minh ra kiến trúc ad hoc:

`Types -> Config -> Repo -> Service -> Runtime -> UI`

Các mối quan tâm xuyên suốt nên đi vào qua các ranh giới provider hoặc adapter rõ ràng thay vì tiếp cận trực tiếp qua các lớp.

## Quy tắc Phụ thuộc Cứng

- Các lớp thấp hơn không được phụ thuộc vào các lớp cao hơn.
- UI không được bỏ qua các hợp đồng runtime hoặc service.
- Truy cập dữ liệu phải đi qua các repository hoặc adapter tương đương.
- Các tiện ích dùng chung phải là chung chung và không được tích lũy logic domain.
- Các phụ thuộc mới nên được chứng minh trong kế hoạch hoặc tài liệu thiết kế phù hợp.

## Giao diện Xuyên suốt

| Mối quan tâm | Ranh giới được phê duyệt | Ghi chú |
|--------|-------------------|---------|
| Logging và tracing | `{{LOGGING_BOUNDARY}}` | `{{LOGGING_RULES}}` |
| Auth | `{{AUTH_BOUNDARY}}` | `{{AUTH_RULES}}` |
| External API | `{{EXTERNAL_API_BOUNDARY}}` | `{{EXTERNAL_API_RULES}}` |
| Feature flags | `{{FEATURE_FLAG_BOUNDARY}}` | `{{FEATURE_FLAG_OWNERSHIP}}` |

## Điểm Nóng Hiện tại

- `{{CHANGE_SAFETY_HOTSPOT}}`
- `{{WEAK_BOUNDARY_OR_FLAKY_TEST_AREA}}`

## Danh sách Kiểm tra Thay đổi

Khi bạn chạm vào mã liên quan đến kiến trúc:

1. Cập nhật tệp này nếu bản đồ domain hoặc ranh giới được phép thay đổi.
2. Cập nhật tài liệu thiết kế liên quan trong `docs/design-docs/` nếu lý luận thay đổi.
3. Thêm hoặc cập nhật kiểm tra có thể thực thi nếu quy tắc nên được thực thi cơ học.
