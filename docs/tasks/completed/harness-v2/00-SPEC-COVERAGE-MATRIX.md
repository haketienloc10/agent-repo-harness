# Ma trận bao phủ spec

> Bộ tài liệu này phân rã “Spec: Tối giản hóa Repo Harness và Làm rõ Vòng đời Artifact”
> thành các phase triển khai có thể review và commit độc lập.
>
> Quyết định được ưu tiên theo yêu cầu mới nhất:
> - execution plan hoàn thành **vẫn được lưu lâu dài** trong `docs/tasks/completed/`;
> - trước khi chuyển plan sang `completed/`, tri thức lâu bền vẫn phải được chắt lọc
>   sang spec, decision, architecture, verify, security hoặc debt tracker phù hợp;
> - fresh install không tạo thư mục `completed/` rỗng. Thư mục chỉ xuất hiện khi
>   có plan hoàn thành đầu tiên.


## Mục đích

Ma trận này ngăn việc chia nhỏ làm thất lạc yêu cầu. Một mục chỉ được coi là
đã triển khai khi có phase sở hữu, commit dự kiến và test xác nhận.

| Khu vực của spec | Phase sở hữu | Bằng chứng hoàn thành |
|---|---|---|
| Mục tiêu, ngoài phạm vi, nguyên tắc artifact | 0, 3 | Decision lock + routing docs |
| Một nguồn sự thật cho mỗi loại thông tin | 3 | `AGENTS.md`, `HARNESS_SETUP.md` |
| Core files tối đa 7 | 2 | Fresh-install test |
| `AGENTS.md` router-only | 3 | Routing assertions + line warning |
| `ARCHITECTURE.md` không áp layer cố định | 3 | Template assertions |
| `RELIABILITY.md` → `VERIFY.md` | 2 | Manifest + install test + checker |
| Installation state machine-readable | 1, 2 | Metadata parser + installer test |
| `HARNESS_SETUP.md` chỉ dùng trước takeover complete | 3 | Routing + E2E |
| `PROJECT_BASELINE.md` → `TAKEOVER_BASELINE.md` | 1, 2 | State-specific checker tests |
| `product-specs/` → `specs/` | 3, 4, 6 | Optional validation + migration fixture |
| `design-docs/` → `decisions/` | 3, 4, 6 | ADR validation + migration fixture |
| `FRONTEND.md` → optional `UI.md` | 3, 4, 6 | Optional file tests |
| `SECURITY.md` optional, repo-specific | 3, 4 | Boundary validation tests |
| Active plan không bắt buộc cho task nhỏ | 3, 4 | Empty active state passes |
| Completed plan được giữ lâu dài | 3, 4, 6 | Active→completed migration test |
| `QUALITY_SCORE.md` bị loại bỏ | 4, 6 | Không còn checker rule; template cleanup |
| `PLANS.md`, `DESIGN.md`, sample docs bị loại bỏ | 6 | Tree assertions |
| `KNOWN_DEBT.md` chỉ giữ debt đang mở | 3, 4, 6 | Validator + migration mapping |
| `LEGACY_ISSUES.md` có baseline evidence | 4 | Valid/invalid fixture tests |
| Generated chỉ tồn tại khi có generator | 3, 4, 6 | Metadata validation |
| References có source/version/refresh trigger | 3, 4, 6 | Metadata validation |
| Checker PASS/WARN/FAIL/BLOCKED | 1, 4 | Output and exit-code tests |
| Installer fresh install tối giản | 2 | Installer test |
| Installer upgrade không tự xóa | 5 | Deprecated fixture tests |
| Migration không mất dữ liệu | 6 | Hash/inventory assertions |
| Test plan library/frontend/backend | 7 | Matrix E2E |
| Regression classification | 4, 7 | Baseline/new/unknown cases |
| README/index/migration docs | 6, 7 | Link checks |
| Release readiness | 7 | Full suite + version/release notes |

## Quyết định completed plan đã điều chỉnh

Các câu trong spec cũ như “xóa completed plan”, “không cho phép completed/” hoặc
“Git là nơi duy nhất giữ lịch sử plan” được thay bằng quy tắc sau:

1. Git vẫn giữ lịch sử thay đổi.
2. `docs/tasks/completed/` giữ bản kế hoạch hoàn thành để người dùng theo dõi.
3. Plan hoàn thành không được dùng làm nguồn sự thật cho kiến trúc hoặc hành vi.
4. Tri thức lâu bền phải được chắt lọc trước khi archive.
5. Checker không yêu cầu thư mục này tồn tại trên fresh install.
6. Checker chỉ kiểm tra file đang tồn tại, không đọc toàn bộ archive trong mọi task.
7. Installer không tự xóa hoặc ghi đè completed plan.
8. Migration phải chuyển toàn bộ `docs/exec-plans/completed/*.md` sang
   `docs/tasks/completed/` mà không mất file.

## Điều kiện xác nhận không mất thông tin

Migration test phải chứng minh:

- số file completed trước và sau bằng nhau;
- checksum nội dung gốc được bảo toàn, trừ thay đổi metadata có chủ ý;
- mọi link nội bộ được cập nhật;
- durable knowledge checklist có kết quả cho từng plan;
- file chưa phân loại không bị xóa;
- conflict tạo cảnh báo và giữ cả source lẫn target.
