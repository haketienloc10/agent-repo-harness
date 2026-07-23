# Harness Structure v2.0.0

Harness Structure v2 tối giản fresh install, tách core artifact khỏi artifact
optional và làm trạng thái takeover machine-readable. Release chỉ được gắn
version `2.0.0` sau khi acceptance matrix, full test suite và release gate xanh.

## Breaking changes

- Fresh install không còn tạo `docs/RELIABILITY.md`,
  `docs/PROJECT_BASELINE.md`, `docs/QUALITY_SCORE.md`, `docs/FRONTEND.md`,
  `docs/PLANS.md`, `docs/DESIGN.md` hoặc sample artifact.
- `docs/VERIFY.md` thay `docs/RELIABILITY.md`;
  `docs/TAKEOVER_BASELINE.md` thay `docs/PROJECT_BASELINE.md`.
- `docs/specs/`, `docs/decisions/`, `docs/UI.md` và `docs/SECURITY.md` là
  optional, chỉ tồn tại khi repository có concern và nội dung cụ thể tương ứng.
- Execution plan dùng `docs/tasks/active/` và `docs/tasks/completed/`.
  Completed plan được giữ lâu dài nhưng không thay thế durable source of truth.
- `.harness/installation.json` dùng schema `harness/installation/v2` với
  `takeover_status` là `pending`, `blocked` hoặc `complete`.
- Checker phân biệt `PASS`, `WARN`, `FAIL`, `BLOCKED` và `BASELINE`. Repository
  chỉ ready khi takeover `complete`, metadata/baseline khớp và checker exit `0`.

## Cấu trúc fresh install

Repository install mới có đúng bảy core file:

```text
.harness-required-files
.harness/
└── installation.json
AGENTS.md
ARCHITECTURE.md
docs/
├── HARNESS_SETUP.md
└── VERIFY.md
scripts/
└── harness-check.sh
```

`docs/TAKEOVER_BASELINE.md` và mọi artifact optional chỉ được agent tạo khi có
bằng chứng trong quá trình takeover; installer không tạo thư mục optional rỗng.

## Tương thích v1

Checker giữ alias read-only cho các path v1 cần thiết trong thời gian migration.
Installer nhận diện inventory v1 và in `MIGRATE`, `REVIEW_AND_EXTRACT`,
`REMOVE_SAMPLE` hoặc `CONFLICT`. Installer không tự xóa, rename, merge hoặc
overwrite artifact migration. Cài lại v2 giữ nguyên installation metadata và
file đã cấu hình.

Nếu dùng `--overwrite`, chỉ core file conflict được thay sau khi bản cũ được lưu
trong `.harness/backups/`. Deprecated artifact và completed plan vẫn không bị
overwrite.

## Migration path

1. Commit hoặc backup repository và chạy `./install.sh --target <repo> --dry-run`.
2. Lưu inventory/checksum v1, đặc biệt count và SHA-256 của
   `docs/exec-plans/completed/*.md`.
3. Làm theo
   [guide migration v1 sang v2](./HARNESS_V1_TO_V2_MIGRATION.md), copy trước,
   review conflict và chắt lọc durable knowledge sang source of truth v2.
4. Copy toàn bộ completed plan sang `docs/tasks/completed/`; giữ byte-identical
   nếu không cần đổi link/metadata và ghi audit cho mọi thay đổi có chủ ý.
5. Hoàn tất `docs/TAKEOVER_BASELINE.md`, `docs/VERIFY.md` và metadata v2, rồi
   chạy `./scripts/harness-check.sh` từ repository root hoặc thư mục con.
6. Chỉ đề xuất xóa source v1 trong một review riêng sau khi count, checksum,
   internal link, conflict và unclassified-artifact assertions đều đạt.

## Bảo toàn completed plan

Upgrade và installer không xóa completed plan. Nếu cả path v1 và v2 tồn tại,
installer báo `CONFLICT` và giữ cả hai. Migration acceptance yêu cầu count trước
và sau bằng nhau; checksum phải giữ nguyên hoặc mọi thay đổi link/metadata phải
được ghi trong audit cùng durable extraction target.

## Rollback

- Giữ tag/commit cuối của v1 và snapshot inventory/checksum trước migration.
- Với safe install mặc định, rollback bằng cách bỏ riêng bảy core file mới sau
  khi xác nhận chúng chưa chứa takeover work; artifact v1 vẫn còn nguyên.
- Với `--overwrite`, phục hồi core file từ `.harness/backups/<timestamp>/`.
- Không rollback bằng cách xóa `docs/tasks/completed/`, deprecated source,
  conflict target hoặc artifact chưa phân loại.
- Nếu cần revert release version, có thể giữ checker compatibility v1/v2 để
  repository đã thử v2 không bị khóa trong khi điều tra.

