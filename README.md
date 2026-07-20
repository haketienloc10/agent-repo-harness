# Agent Repo Harness

## Cài đặt

Repo đích phải là root của một Git repository đã tồn tại. Installer chỉ thêm các
file harness; không chạy build, test, lint, migration hoặc thay đổi source code
của dự án.

### Cài nhanh từ GitHub

Cần có `curl`, `tar` và Git:

```bash
curl -fsSL https://raw.githubusercontent.com/haketienloc10/agent-repo-harness/main/install-from-github.sh | bash -s -- --target /path/to/repo --dry-run
curl -fsSL https://raw.githubusercontent.com/haketienloc10/agent-repo-harness/main/install-from-github.sh | bash -s -- --target /path/to/repo
```

Để cài từ một tag hoặc commit SHA cụ thể:

```bash
curl -fsSL https://raw.githubusercontent.com/haketienloc10/agent-repo-harness/main/install-from-github.sh | HARNESS_REF=<tag-or-commit-sha> bash -s -- --target /path/to/repo
```

### Cài từ bản clone local

```bash
git clone https://github.com/haketienloc10/agent-repo-harness.git
cd agent-repo-harness
./install.sh --target /path/to/repo --dry-run
./install.sh --target /path/to/repo
```

File đã tồn tại được báo là `Conflicts` và luôn được giữ nguyên mặc định. Chỉ sử
dụng `--overwrite` sau khi review conflict; bản cũ sẽ được sao lưu tại
`.harness/backups/` trong repo đích.

Sau khi cài, mở `docs/HARNESS_SETUP.md` trong repo đích và hoàn thành takeover
workflow trước khi bắt đầu task sản phẩm.

## Tổng quan

Agent Repo Harness là bộ khung vận hành cho coding agent trong một repository.
Nó biến các nguyên tắc harness engineering thành tài liệu, quy trình và kiểm tra
cơ học để agent có thể khảo sát dự án, ghi nhận baseline, xử lý legacy issue và
xác minh trạng thái repository nhất quán.

Thành phần chính:

- [`repo-template/`](./repo-template/index.md): các file harness được cài vào repo đích.
- [`install.sh`](./install.sh): installer an toàn cho bản clone local.
- [`install-from-github.sh`](./install-from-github.sh): bootstrap installer dùng với `curl`.
- [`sops/`](./sops/index.md): các quy trình vận hành chuẩn.
- [`examples/legacy-project/`](./examples/legacy-project/README.md): fixture minh họa takeover và legacy failure.

Harness checker tại `scripts/harness-check.sh` trong repo đích không chạy command
dự án. Checker trả exit `0` khi cấu hình không có `FAIL`; legacy issue có đủ
evidence tại baseline được báo là `BASELINE`.

## Kiểm tra thay đổi

Từ root của repo này:

```bash
./tests/run.sh
```

Xem thêm hướng dẫn đầy đủ, baseline policy và cấu trúc template tại
[`index.md`](./index.md).
