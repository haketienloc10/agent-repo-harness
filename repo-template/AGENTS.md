# AGENTS.md

File này là router cho coding agent, không phải encyclopedia. Giữ hướng dẫn
ngắn và mở tài liệu chuyên biệt theo đúng concern của task.

## Bắt đầu

Với task chỉ đọc, giải thích hoặc báo cáo, chỉ mở tài liệu cần cho câu hỏi.

Trước code task không tầm thường, bao gồm thay đổi code, test, build script,
migration hoặc cấu hình runtime:

1. Xác nhận repository root.
2. Đọc `ARCHITECTURE.md` để hiểu hệ thống và dependency hiện có.
3. Đọc `docs/VERIFY.md` để biết command bootstrap, test và guardrail chuẩn.
4. Đọc `.harness/installation.json` nếu file tồn tại.
5. Chỉ khi `takeover_status` là `pending` hoặc `blocked`, đọc
   `docs/HARNESS_SETUP.md` và hoàn tất takeover hoặc báo blocker trước khi nhận
   task sản phẩm. Khi `takeover_status` là `complete`, không đọc
   `docs/HARNESS_SETUP.md` trong luồng làm việc thông thường.
6. Dùng bảng định tuyến bên dưới để chỉ mở artifact liên quan.

## Định tuyến theo concern

| Artifact | Khi nào đọc |
|---|---|
| `docs/tasks/active/<task>.md` | Khi task có active plan liên quan. |
| `docs/specs/` | Khi thay đổi hành vi người dùng, API behavior, user flow hoặc acceptance criteria. |
| `docs/decisions/` | Khi thay đổi boundary, dependency direction, shared abstraction hoặc quyết định kiến trúc đã ghi nhận. |
| `docs/UI.md` | Khi sửa UI state, interaction, responsive behavior, accessibility hoặc design-system usage. |
| `docs/SECURITY.md` | Khi task chạm auth, secret, dữ liệu nhạy cảm, input không tin cậy, dependency hoặc hành động bên ngoài. |
| `docs/TAKEOVER_BASELINE.md` | Khi cần so sánh failure hoặc regression với snapshot takeover. |
| `docs/LEGACY_ISSUES.md` | Khi verification có failure liên quan hoặc cần phân loại legacy failure. |
| `docs/KNOWN_DEBT.md` | Khi kiểm tra constraint đã hoãn hoặc chủ động hoãn một khiếm khuyết thực sự; không dùng cho regression mới. |
| `docs/generated/` | Khi task phụ thuộc artifact do generator sở hữu. |
| `docs/references/` | Khi task cần nguồn ngoài về tool, framework hoặc standard cụ thể. |
| `docs/tasks/completed/` | Chỉ khi cần lịch sử liên quan, như tiếp tục công việc cũ hoặc điều tra regression. |

Không đọc toàn bộ cây `docs/`. Artifact optional không tồn tại thì tiếp tục bằng
source và tài liệu hiện có; không tạo file chỉ để lấp chỗ trống.

## Hợp đồng làm việc

- Làm việc theo scope đã thống nhất và dùng bằng chứng có thể chạy được.
- Không đánh dấu hoàn thành chỉ từ inspection.
- Failure có tại baseline là legacy issue; failure do thay đổi hiện tại tạo ra
  là regression; phát hiện chưa đủ bằng chứng vẫn là observation chưa phân loại.
- Không đổi regression mới thành legacy issue hoặc debt để hoàn thành task.
- Khi hành vi hoặc boundary thay đổi, cập nhật nguồn sự thật chuyên biệt trong
  cùng thay đổi.
- Khi một rule cần được thực thi lặp lại, ưu tiên test, checker hoặc linter.
- Không ghi secret hoặc dữ liệu nhạy cảm vào artifact.

## Hoàn thành

Một thay đổi chỉ hoàn thành khi hành vi mục tiêu đã được triển khai, verification
liên quan đã chạy, không có regression mới, và tài liệu nguồn sự thật bị ảnh
hưởng đã được cập nhật.
