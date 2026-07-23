# Agent Repo Harness

## Cài đặt

Installer hỗ trợ hai loại target:

1. **Multi-repository workspace**: workspace root chứa nhiều Git repository độc
   lập trong các thư mục con. Installer sao chép nội dung `workspace-template/`
   vào workspace root.
2. **Single Git repository**: một Git repository gốc, không chứa Git repository
   lồng bên trong. Chế độ này giữ nguyên luồng cài đặt hiện tại qua `install.sh`.

Installer chỉ thêm các file harness. Nó không chạy build, test, lint, migration
hoặc thay đổi source code của dự án hay các repository con.

### Cài nhanh từ GitHub

Cần có `curl`, `tar` và Git. Lệnh sau hiển thị menu để người dùng chọn một trong
hai chế độ. Menu đọc từ `/dev/tty`, nên vẫn hoạt động khi script được chạy bằng
`curl | bash`:

```bash
curl -fsSL https://raw.githubusercontent.com/haketienloc10/agent-repo-harness/main/install-from-github.sh | bash -s -- --target /path/to/target
```

Có thể chọn chế độ trực tiếp để chạy không tương tác:

```bash
# Workspace có nhiều Git repository con
curl -fsSL https://raw.githubusercontent.com/haketienloc10/agent-repo-harness/main/install-from-github.sh | bash -s -- --mode workspace --target /path/to/workspace

# Một Git repository gốc
curl -fsSL https://raw.githubusercontent.com/haketienloc10/agent-repo-harness/main/install-from-github.sh | bash -s -- --mode repository --target /path/to/repo
```

Nên chạy `--dry-run` trước. File đã tồn tại được báo là `Conflicts` và được giữ
nguyên mặc định. Chỉ dùng `--overwrite` sau khi review; bản cũ được sao lưu tại
`.harness/backups/` dưới target.

```bash
curl -fsSL https://raw.githubusercontent.com/haketienloc10/agent-repo-harness/main/install-from-github.sh | bash -s -- --mode workspace --target /path/to/workspace --dry-run
curl -fsSL https://raw.githubusercontent.com/haketienloc10/agent-repo-harness/main/install-from-github.sh | bash -s -- --mode repository --target /path/to/repo --dry-run
```

Để cài từ một tag hoặc commit SHA cụ thể:

```bash
curl -fsSL https://raw.githubusercontent.com/haketienloc10/agent-repo-harness/main/install-from-github.sh | HARNESS_REF=<tag-or-commit-sha> bash -s -- --mode repository --target /path/to/repo
```

Khi cài đặt kết thúc hoặc phát hiện conflict có thể xử lý, script in ra một khối
`PROMPT CHO AGENT`. Sao chép prompt đó cho coding agent để hoàn tất takeover,
điền các artifact còn thiếu và chạy checker tương ứng.

### Cài repo đơn từ bản clone local

```bash
git clone https://github.com/haketienloc10/agent-repo-harness.git
cd agent-repo-harness
./install.sh --target /path/to/repo --dry-run
./install.sh --target /path/to/repo
```

Sau khi cài repo đơn, agent phải hoàn thành `docs/HARNESS_SETUP.md` và chạy
`./scripts/harness-check.sh`.

Sau khi cài workspace, agent phải hoàn thành `docs/WORKSPACE_SETUP.md`, điền
`repos.yaml` cùng `SYSTEM_MAP.md`, rồi chạy `./scripts/workspace-check.sh`.

## Tổng quan

Agent Repo Harness là bộ khung vận hành cho coding agent trong một repository
hoặc một local workspace gồm nhiều repository. Nó biến các nguyên tắc harness
engineering thành tài liệu, quy trình và kiểm tra cơ học để agent có thể khảo sát
dự án, ghi nhận baseline, xử lý legacy issue và xác minh trạng thái nhất quán.

Thành phần chính:

- [`repo-template/`](./repo-template/index.md): các file harness được cài vào một repo đích.
- [`workspace-template/`](./workspace-template/README.md): các file điều phối cho workspace nhiều repo.
- [`install.sh`](./install.sh): installer an toàn cho repo đơn từ bản clone local.
- [`install-from-github.sh`](./install-from-github.sh): bootstrap installer và bộ chọn hai chế độ.
- [`sops/`](./sops/index.md): các quy trình vận hành chuẩn.
- [`examples/legacy-project/`](./examples/legacy-project/README.md): fixture minh họa takeover và legacy failure.
- [`docs/HARNESS_V1_TO_V2_MIGRATION.md`](./docs/HARNESS_V1_TO_V2_MIGRATION.md):
  guide audit và migration v1 sang v2 không phá hủy dữ liệu.

Harness checker tại `scripts/harness-check.sh` trong repo đích không chạy command
dự án. Checker trả exit `0` khi cấu hình không có `FAIL`; legacy issue có đủ
evidence tại baseline được báo là `BASELINE`.

Workspace checker tại `scripts/workspace-check.sh` xác minh cấu trúc điều phối,
placeholder và registry module. Nó không thay thế test của từng repository con.

## Kiểm tra thay đổi

Từ root của repo này:

```bash
./tests/run.sh
```

Xem thêm hướng dẫn đầy đủ, baseline policy và cấu trúc template tại
[`index.md`](./index.md).

Repository đã có harness v1 nên chạy installer với `--dry-run`, sau đó làm theo
[guide migration v1 sang v2](./docs/HARNESS_V1_TO_V2_MIGRATION.md). Installer
chỉ báo inventory; nó không xóa, rename hoặc overwrite artifact migration.
