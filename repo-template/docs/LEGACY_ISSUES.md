# LEGACY_ISSUES.md

Tài liệu này chỉ lưu failure được chứng minh đã tồn tại tại revision trong `PROJECT_BASELINE.md`. Đây không phải nơi để chuyển regression mới, observation chưa phân loại hoặc công việc của task hiện tại thành trạng thái được chấp nhận.

## Ranh giới Phân loại

Một entry chỉ hợp lệ khi có ID dạng `LEGACY-NNN` với đúng ba chữ số (ví dụ `LEGACY-001`), command hoặc bước tái hiện, failure signature và bằng chứng gắn với đúng revision baseline. Nếu chưa chứng minh được nguồn gốc, ghi phát hiện trong kế hoạch active để phân loại. Nếu task hiện tại hoặc thay đổi sau baseline tạo ra failure, đó là regression và phải được sửa trước khi task hoàn thành.

Trạng thái hợp lệ:

- `Accepted`: được thừa nhận tại baseline và chưa nằm trong phạm vi sửa hiện tại;
- `In progress`: đang được xử lý bởi một kế hoạch active có liên kết;
- `Resolved`: đã sửa và xác minh; giữ entry cùng bằng chứng baseline để bảo toàn lịch sử.

## Issue

### `{{LEGACY_ISSUE_ID}}`: `{{LEGACY_ISSUE_TITLE}}`

- Area: `{{LEGACY_ISSUE_AREA}}`
- Failure signature: `{{LEGACY_FAILURE_SIGNATURE}}`
- Impact: `{{LEGACY_ISSUE_IMPACT}}`
- Status: `{{LEGACY_ISSUE_STATUS}}`
- Baseline revision: `{{LEGACY_BASELINE_REVISION}}`
- Baseline evidence: `{{LEGACY_BASELINE_EVIDENCE}}`
- Reproduction command / steps: `{{LEGACY_REPRODUCTION}}`
- Active plan hoặc resolution evidence: `{{LEGACY_PLAN_OR_RESOLUTION}}`

Không xóa issue đã giải quyết. Chuyển trạng thái sang `Resolved` và bổ sung resolution evidence.
