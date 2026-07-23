# Quyết định Migration Harness Structure v2

- Trạng thái: Accepted
- Phạm vi: repository harness v1 sang Harness Structure v2

## Cấu trúc Đích v2

Fresh install chỉ tạo bảy core file sau:

```text
.harness-required-files
.harness/installation.json
AGENTS.md
ARCHITECTURE.md
docs/HARNESS_SETUP.md
docs/VERIFY.md
scripts/harness-check.sh
```

`docs/TAKEOVER_BASELINE.md` được tạo trong quá trình takeover, không được cài
sẵn. Artifact repo-specific chỉ xuất hiện khi có nội dung thực.

## Mapping v1 sang v2

| Path v1 | Path v2 | Quy tắc migration |
|---|---|---|
| `docs/RELIABILITY.md` | `docs/VERIFY.md` | Chắt lọc canonical commands và evidence xác minh. |
| `docs/PROJECT_BASELINE.md` | `docs/TAKEOVER_BASELINE.md` | Giữ snapshot baseline bất biến. |
| `docs/product-specs/` | `docs/specs/` | Giữ spec repo-specific, bỏ sample giả. |
| `docs/design-docs/` | `docs/decisions/` | Giữ quyết định repo-specific. |
| `docs/FRONTEND.md` | `docs/UI.md` | Chỉ tạo khi repo có quy tắc UI thực. |
| `docs/QUALITY_SCORE.md` | architecture, debt, issue, legacy hoặc verify phù hợp | Không chuyển điểm chữ; giữ gap cụ thể. |
| `docs/exec-plans/active/` | `docs/tasks/active/` | Chỉ chuyển task đang active. |
| `docs/exec-plans/completed/` | `docs/tasks/completed/` | Chuyển và bảo toàn toàn bộ plan. |
| `docs/exec-plans/tech-debt-tracker.md` | `docs/KNOWN_DEBT.md` hoặc issue tracker | Chỉ chuyển debt đang mở. |
| `docs/references/` | `docs/references/` | Giữ reference hữu ích và bổ sung metadata nguồn. |
| `docs/generated/` | `docs/generated/` | Chỉ giữ khi có generator. |

## Invariant Tương thích

- Safe install không ghi đè file đã tồn tại.
- Overwrite phải backup artifact trước khi thay thế.
- Reinstall không overwrite phải giữ nguyên installation metadata.
- Checker phải chạy được từ nested directory mà không ghi vào repo.
- Active plan directory có thể rỗng khi không có task đang thực hiện.
- Legacy issue có đủ baseline evidence không làm checker fail.
- Installer và checker giữ nguyên output và exit code v1 cho đến khi phase
  tương thích thay đổi contract có chủ ý.
- Migration không tự xóa, rename, overwrite hoặc làm mất artifact người dùng.

## Vòng đời Completed Plan

Plan hoàn thành được chuyển sang `docs/tasks/completed/` và tiếp tục được
giữ lâu dài. Trước khi archive, tri thức lâu bền phải được chắt lọc sang
spec, decision, architecture, verify, security hoặc debt tracker phù hợp.
Completed plan không thay thế các nguồn sự thật này.

Fresh install không tạo `docs/tasks/completed/` rỗng. Thư mục chỉ được tạo
khi plan hoàn thành đầu tiên được archive.
