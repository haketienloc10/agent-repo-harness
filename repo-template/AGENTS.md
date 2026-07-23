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
4. Dùng bảng định tuyến bên dưới để chỉ mở artifact liên quan.

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

## Khi nào cần execution plan

Tạo hoặc tiếp tục `docs/tasks/active/<task>.md` chỉ khi task có ít nhất một
trigger sau:

- kéo dài qua nhiều phiên;
- chạm từ hai subsystem hoặc domain;
- có migration, backfill hoặc data transform;
- thay đổi public API hoặc external contract;
- có breaking change;
- chạm auth, secret hoặc sensitive data;
- cần rollout hoặc rollback phức tạp;
- cần chọn giữa nhiều phương án kiến trúc;
- có blocker hoặc dependency bên ngoài;
- người dùng yêu cầu plan;
- cần handoff cho người hoặc agent khác.

Task nhỏ không có trigger thì không tạo plan. Một code task không tự động cần
plan chỉ vì có sửa file.

Khi dùng plan, cập nhật nó khi scope, decision, blocker, progress hoặc
verification thay đổi; không ghi log từng tool call.

Lifecycle:

```text
active
→ verification hoàn tất
→ chắt lọc durable knowledge
→ final summary
→ dùng `mv` chuyển sang docs/tasks/completed/
→ giữ lâu dài
```

Trước khi archive, chuyển tri thức lâu bền sang source of truth phù hợp như
`docs/specs/`, `docs/decisions/`, `ARCHITECTURE.md`, `docs/VERIFY.md`,
`docs/SECURITY.md` hoặc `docs/KNOWN_DEBT.md`. Final summary phải ghi kết quả,
verification evidence và durable knowledge đã được chắt lọc ở đâu.

Không xóa completed plan. Completed plan không thay thế spec, ADR,
`ARCHITECTURE.md` hoặc `docs/VERIFY.md`, và fresh install không tạo
`docs/tasks/completed/` rỗng.

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
