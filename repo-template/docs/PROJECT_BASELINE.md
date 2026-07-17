# PROJECT_BASELINE.md

Tài liệu này là snapshot có bằng chứng của dự án tại thời điểm tiếp quản. Baseline mô tả trạng thái; nó không tuyên bố mọi failure là chấp nhận được và không miễn trừ regression về sau.

## Danh tính Baseline

- Ngày baseline: `{{BASELINE_DATE}}`
- Git revision: `{{BASELINE_GIT_REVISION}}`
- Branch hoặc ref quan sát: `{{BASELINE_GIT_REF}}`
- Trạng thái working tree ban đầu: `{{BASELINE_WORKTREE_STATE}}`
- Người hoặc agent khảo sát: `{{BASELINE_OBSERVER}}`

## Môi trường Khảo sát

| Thuộc tính | Giá trị |
|---|---|
| OS / container | `{{SURVEY_OS}}` |
| Runtime và phiên bản | `{{SURVEY_RUNTIME}}` |
| Toolchain chính | `{{SURVEY_TOOLCHAIN}}` |
| Service / dependency bên ngoài | `{{SURVEY_DEPENDENCIES}}` |
| Biến môi trường hoặc fixture liên quan, đã loại bỏ secret | `{{SURVEY_CONFIGURATION}}` |

## Command Đã chạy và Kết quả

Chỉ ghi command đã thực sự chạy. Giữ nguyên command, exit code và failure signature quan trọng; nếu một command chưa thể chạy, ghi riêng trong phần giới hạn.

| Mục đích | Command | Kết quả / exit code | Bằng chứng hoặc ghi chú |
|---|---|---|---|
| Bootstrap | `{{BASELINE_BOOTSTRAP_COMMAND}}` | `{{BASELINE_BOOTSTRAP_RESULT}}` | `{{BASELINE_BOOTSTRAP_EVIDENCE}}` |
| Verify | `{{BASELINE_VERIFY_COMMAND}}` | `{{BASELINE_VERIFY_RESULT}}` | `{{BASELINE_VERIFY_EVIDENCE}}` |
| Start / health | `{{BASELINE_START_COMMAND}}` | `{{BASELINE_START_RESULT}}` | `{{BASELINE_START_EVIDENCE}}` |

## Trạng thái Vận hành

- Trạng thái tổng thể: `{{BASELINE_OPERATIONAL_STATE}}`
- Service hoặc bề mặt đang hoạt động: `{{BASELINE_WORKING_SURFACES}}`
- Trạng thái degraded hoặc unavailable: `{{BASELINE_DEGRADED_SURFACES}}`
- Điều kiện khởi động lại đã quan sát: `{{BASELINE_RESTART_STATE}}`

## Golden Journey Đã kiểm tra

| Journey | Cách kiểm tra | Kết quả | Bằng chứng |
|---|---|---|---|
| `{{GOLDEN_JOURNEY_NAME}}` | `{{GOLDEN_JOURNEY_METHOD}}` | `{{GOLDEN_JOURNEY_RESULT}}` | `{{GOLDEN_JOURNEY_EVIDENCE}}` |

## Khu vực Chưa kiểm tra

- `{{UNTESTED_AREA}}`: `{{UNTESTED_REASON}}`

## Giới hạn của Bằng chứng

- `{{EVIDENCE_LIMITATION}}`

## Liên kết Legacy Issue

Các failure chỉ được ghi trong `LEGACY_ISSUES.md` khi có bằng chứng chúng tồn tại tại Git revision nêu trên. Working tree chưa commit, môi trường khác hoặc suy luận không đủ để chứng minh một issue là legacy.

