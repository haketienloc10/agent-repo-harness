# Gói Harness Nâng cao OpenAI

Gói này tập hợp thiết kế harness được mô tả trong bài viết "Harness Engineering" của OpenAI thành một bộ tệp bắt đầu có thể áp dụng và cấu trúc SOP đi kèm.

## Tại sao Nó Tồn tại

Bài viết harness engineering mô tả các nguyên tắc cấp cao: kho lưu trữ là hệ thống ghi chép, bộ nhớ ngoại hóa, kiểm tra cơ học thay vì ký ức, và các vòng phản hồi phục hồi. Gói này biến các nguyên tắc đó thành:

- bộ tài liệu cấu trúc rõ ràng cho một repo thực tế
- phân loại baseline, regression, observation và technical debt bằng evidence
- thư mục tài liệu tham khảo thân thiện với model
- các quy trình vận hành chuẩn cho kiến trúc, thu thập kiến thức, và xác minh runtime

## Bố cục Source Template

Fresh install repository từ [`repo-template/`](./repo-template/index.md) chỉ tạo
bảy core file:

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

Artifact optional chỉ được tạo khi repository có nội dung thực. Source of truth:

| Concern | Artifact v2 |
|---|---|
| Cấu trúc và dependency | `ARCHITECTURE.md` |
| Command và evidence xác minh hiện tại | `docs/VERIFY.md` |
| Snapshot takeover | `docs/TAKEOVER_BASELINE.md` |
| Hành vi sản phẩm/API | `docs/specs/` |
| Quyết định kiến trúc | `docs/decisions/` |
| UI rule | `docs/UI.md` |
| Security rule | `docs/SECURITY.md` |
| Legacy failure có baseline evidence | `docs/LEGACY_ISSUES.md` |
| Debt đang mở | `docs/KNOWN_DEBT.md` |
| Task đang làm / đã hoàn thành | `docs/tasks/active/`, `docs/tasks/completed/` |
| Generated/reference có provenance | `docs/generated/`, `docs/references/` |

Breaking changes, compatibility, migration và rollback của release được ghi tại
[`docs/RELEASE_NOTES_V2.md`](./docs/RELEASE_NOTES_V2.md).

Gói [`workspace-template/`](./workspace-template/README.md) dành cho một local
workspace chứa nhiều Git repository độc lập. Nó cài các artifact điều phối ở
workspace root như `AGENTS.md`, `repos.yaml`, `SYSTEM_MAP.md`, tài liệu setup và
workspace checker; nó không thay thế harness riêng của từng module.

## Cài đặt an toàn

Bootstrap installer yêu cầu người dùng chọn một trong hai loại target:

1. **Workspace**: workspace root chứa nhiều Git repository con độc lập. Nội dung
   `workspace-template/` được sao chép vào workspace root.
2. **Repository**: một Git repository gốc, không có Git repository lồng bên
   trong. Chế độ này ủy quyền cho `install.sh` như luồng cũ.

Installer chỉ sao chép file harness; nó không chạy build, test, lint, migration
hoặc source code dự án.

### Cài nhanh từ GitHub

Không cần clone repo harness. Chạy từ máy có `curl`, `tar` và Git. Khi không chỉ
định `--mode`, script hiển thị menu lựa chọn qua `/dev/tty`:

```bash
curl -fsSL https://raw.githubusercontent.com/haketienloc10/agent-repo-harness/main/install-from-github.sh | bash -s -- --target /path/to/target
```

Chạy không tương tác bằng cách chỉ định chế độ:

```bash
# Multi-repository workspace
curl -fsSL https://raw.githubusercontent.com/haketienloc10/agent-repo-harness/main/install-from-github.sh | bash -s -- --mode workspace --target /path/to/workspace

# Single Git repository
curl -fsSL https://raw.githubusercontent.com/haketienloc10/agent-repo-harness/main/install-from-github.sh | bash -s -- --mode repository --target /path/to/repo
```

Bootstrap script tải GitHub archive vào thư mục tạm, kiểm tra template bắt buộc,
rồi cài theo chế độ đã chọn. Để cố định một tag hoặc commit SHA thay vì `main`:

```bash
curl -fsSL https://raw.githubusercontent.com/haketienloc10/agent-repo-harness/main/install-from-github.sh | HARNESS_REF=<tag-or-commit-sha> bash -s -- --mode repository --target /path/to/repo
```

File hiện hữu được báo là `Conflicts` và giữ nguyên theo mặc định. Chỉ dùng
`--overwrite` sau khi review conflict; installer sẽ tạo bản sao dưới
`.harness/backups/` trước khi thay file. Nên chạy `--dry-run` trước.

Khi cài đặt thành công hoặc dừng ở conflict có thể xử lý, script in một prompt
hoàn chỉnh cho agent. Prompt hướng agent đọc tài liệu setup đúng loại, khảo sát
read-only, hoàn thiện artifact và chỉ tuyên bố ready khi checker trả exit `0`.

### Cài repo đơn từ bản clone local

```bash
./install.sh --target /path/to/repo --dry-run
./install.sh --target /path/to/repo
```

## Takeover workflow cho repository

Sau khi cài repo đơn:

1. Xử lý mọi `Conflicts`, rồi đọc `docs/HARNESS_SETUP.md` trong repo đích.
2. Ghi revision bằng `git rev-parse HEAD` trước khi chạy command khảo sát.
3. Khảo sát read-only, xác định bootstrap, verify, start command và mechanical guardrail.
4. Chạy các command an toàn đã chọn và điền snapshot vào
   `docs/TAKEOVER_BASELINE.md`, command hiện tại vào `docs/VERIFY.md`.
5. Chỉ ghi failure được chứng minh tại đúng baseline revision vào `docs/LEGACY_ISSUES.md`.
6. Chỉ tạo `docs/tasks/active/` khi task đạt planning trigger. Trước khi chuyển
   plan hoàn thành sang `docs/tasks/completed/`, chắt lọc durable knowledge về
   source of truth phù hợp.

```bash
cd /path/to/repo
./scripts/harness-check.sh
```

Checker trả exit `0` khi cấu hình harness không có `FAIL`. Một legacy issue hợp lệ
được báo `BASELINE`, nên failure sẵn có không làm checker fail. Checker không chạy
command dự án.

## Takeover workflow cho workspace

Sau khi cài workspace:

1. Xử lý mọi `Conflicts`, rồi đọc `docs/WORKSPACE_SETUP.md`.
2. Lập inventory read-only cho từng repository con bằng `git -C <module>`.
3. Điền `repos.yaml` và `SYSTEM_MAP.md` chỉ từ bằng chứng trong code, manifest,
   CI, deployment config hoặc tài liệu hiện hữu.
4. Thay toàn bộ placeholder `{{...}}`.
5. Chạy checker tại workspace root:

```bash
cd /path/to/workspace
./scripts/workspace-check.sh
```

Workspace chỉ ready khi checker trả exit `0`. Checker không chạy test thay cho
các module và không chứng minh integration nếu chưa có command/evidence thực tế.

## Baseline và phân loại failure

- **Legacy issue**: failure có reproduction và evidence tại đúng baseline revision;
  giữ trong `LEGACY_ISSUES.md` khi trạng thái là `Accepted` hoặc `In progress`.
  Khi resolved, chuyển resolution evidence sang completed plan hoặc Git và bỏ
  item khỏi optional open-state file.
- **Regression**: failure do task hiện tại hoặc thay đổi sau baseline tạo ra; phải
  sửa trước khi hoàn thành, không được chuyển thành legacy issue hoặc technical debt.
- **Observation chưa phân loại**: chưa đủ bằng chứng về nguồn gốc; giữ trong kế hoạch
  active cùng bước phân loại tiếp theo.
- **Technical debt**: khiếm khuyết được chủ động hoãn; không phải nơi hợp thức hóa
  regression mới.

## Chạy test của harness

Từ root repo nguồn, chạy một command:

```bash
./tests/run.sh
```

Test tạo Git repository tạm và bao phủ installer cho repository/workspace, các
tình huống checker, cùng workflow end-to-end trên
[`examples/legacy-project/`](./examples/legacy-project/README.md). Fixture chứng
minh build pass trong khi test và lint có legacy failure đã biết; source fixture
vẫn nguyên vẹn sau khi cài.

Fixture migration tại `tests/fixtures/migration-v1-to-v2/` kiểm tra audit hash,
completed-plan checksum/count, link v2, durable extraction, conflict và file
chưa phân loại. Xem
[`docs/HARNESS_V1_TO_V2_MIGRATION.md`](./docs/HARNESS_V1_TO_V2_MIGRATION.md)
trước khi xử lý repository v1.

Các path v1 còn xuất hiện trong `repo-template/scripts/harness-check.sh` là alias
tương thích read-only cho repository chưa migration. Các path v1 trong
`tests/lib.sh`, `tests/test-installer.sh`, `tests/test-checker.sh` và
`tests/test-e2e-upgrade.sh`, `tests/fixtures/migration-v1-to-v2/` là
migration/compatibility fixture có chủ ý. Chúng không phải link hướng dẫn hiện
hành và không được installer tạo trên fresh install.

## Thư viện SOP

Thư mục [`sops/`](./sops/index.md) biến các sơ đồ của bài viết thành các quy trình vận hành từng bước:

- thiết lập kiến trúc domain phân lớp
- mã hóa kiến thức ẩn vào kho lưu trữ
- stack observability cục bộ và workflow vòng phản hồi
- vòng lặp xác minh Chrome DevTools cho công việc UI

## Nguyên tắc Thiết kế

- Điểm đầu vào ngắn, tài liệu liên kết sâu hơn
- Kho lưu trữ là hệ thống ghi chép
- Kiểm tra cơ học tốt hơn các quy tắc được nhớ
- Kế hoạch active/completed và durable source of truth nằm bên cạnh mã
- Dọn dẹp và đơn giản hóa là trách nhiệm hạng nhất

Gói này có chủ ý theo quan điểm, nhưng nó vẫn nên được điều chỉnh cho dự án của bạn thay vì sao chép mù quáng.
