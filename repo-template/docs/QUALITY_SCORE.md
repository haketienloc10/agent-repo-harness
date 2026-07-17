# QUALITY_SCORE.md

Tài liệu này theo dõi liệu kho lưu trữ có đang trở nên mạnh hơn hay yếu hơn theo thời gian.

Điểm khởi đầu phải tham chiếu snapshot trong `PROJECT_BASELINE.md`. Legacy failure đã biết có thể làm giảm điểm nhưng không tự động chặn công việc ngoài phạm vi; regression sau baseline không được hợp thức hóa bằng cách hạ điểm hoặc ghi thành nợ.

## Thang điểm

- `A`: đã xác minh, có thể đọc được, ổn định, ranh giới được thực thi
- `B`: hoạt động với các khoảng trống nhỏ
- `C`: hoạt động một phần, nhầm lẫn hoặc không ổn định đáng kể
- `D`: bị hỏng, không an toàn, hoặc cấu trúc không rõ ràng

## Domain Sản phẩm

| Domain | Điểm | Xác minh | Khả năng đọc của Agent | Độ ổn định Test | Khoảng trống chính | Cập nhật lần cuối |
|--------|-------|-------------|-----------------|---------------|----------|-------------|
| `{{PRODUCT_DOMAIN_1}}` | `{{DOMAIN_1_SCORE}}` | `{{DOMAIN_1_VERIFICATION}}` | `{{DOMAIN_1_AGENT_READABILITY}}` | `{{DOMAIN_1_TEST_STABILITY}}` | `{{DOMAIN_1_GAP}}` | `{{DOMAIN_1_UPDATED_AT}}` |
| `{{PRODUCT_DOMAIN_2}}` | `{{DOMAIN_2_SCORE}}` | `{{DOMAIN_2_VERIFICATION}}` | `{{DOMAIN_2_AGENT_READABILITY}}` | `{{DOMAIN_2_TEST_STABILITY}}` | `{{DOMAIN_2_GAP}}` | `{{DOMAIN_2_UPDATED_AT}}` |
| `{{PRODUCT_DOMAIN_3}}` | `{{DOMAIN_3_SCORE}}` | `{{DOMAIN_3_VERIFICATION}}` | `{{DOMAIN_3_AGENT_READABILITY}}` | `{{DOMAIN_3_TEST_STABILITY}}` | `{{DOMAIN_3_GAP}}` | `{{DOMAIN_3_UPDATED_AT}}` |

## Lớp Kiến trúc

| Lớp | Điểm | Thực thi Ranh giới | Khả năng đọc của Agent | Khoảng trống chính | Cập nhật lần cuối |
|-------|-------|---------------------|-----------------|----------|-------------|
| Types | `{{TYPES_SCORE}}` | `{{TYPES_BOUNDARY_ENFORCEMENT}}` | `{{TYPES_AGENT_READABILITY}}` | `{{TYPES_GAP}}` | `{{TYPES_UPDATED_AT}}` |
| Services | `{{SERVICES_SCORE}}` | `{{SERVICES_BOUNDARY_ENFORCEMENT}}` | `{{SERVICES_AGENT_READABILITY}}` | `{{SERVICES_GAP}}` | `{{SERVICES_UPDATED_AT}}` |
| Runtime | `{{RUNTIME_SCORE}}` | `{{RUNTIME_BOUNDARY_ENFORCEMENT}}` | `{{RUNTIME_AGENT_READABILITY}}` | `{{RUNTIME_GAP}}` | `{{RUNTIME_UPDATED_AT}}` |
| UI | `{{UI_SCORE}}` | `{{UI_BOUNDARY_ENFORCEMENT}}` | `{{UI_AGENT_READABILITY}}` | `{{UI_GAP}}` | `{{UI_UPDATED_AT}}` |

## Snapshot Benchmark

| Ngày | Biến thể Harness | Tỷ lệ Hoàn thành | Thử lại | Lỗi trước Review | Ghi chú |
|------|-----------------|----------------|--------|-----------------------|---------|
| `{{BENCHMARK_DATE}}` | `{{HARNESS_VARIANT}}` | `{{COMPLETION_RATE}}` | `{{RETRY_COUNT}}` | `{{PRE_REVIEW_FAILURES}}` | `{{BENCHMARK_NOTES}}` |

## Nhật ký Đơn giản hóa

| Ngày | Thành phần Đã xóa | Kết quả | Quyết định |
|------|-------------------|---------|------------|
| `{{SIMPLIFICATION_DATE}}` | `{{REMOVED_COMPONENT}}` | `{{SIMPLIFICATION_RESULT}}` | `{{SIMPLIFICATION_DECISION}}` |

## Liên kết Bằng chứng

- Baseline: `PROJECT_BASELINE.md`
- Legacy issues ảnh hưởng đến điểm: `LEGACY_ISSUES.md`
- Kế hoạch cải thiện active: `{{ACTIVE_QUALITY_PLAN}}`
