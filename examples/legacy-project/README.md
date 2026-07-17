# Legacy Project Fixture

Fixture tối giản này mô phỏng một dự án đang vận hành trước khi cài harness.

- `./project-checks/build.sh` pass.
- `./project-checks/test.sh` fail với lỗi đã tồn tại.
- `./project-checks/lint.sh` fail với lỗi đã tồn tại.
- `./app.sh Codex` là golden journey và in `Hello, Codex`.

Không chạy fixture trực tiếp trong thư mục này. `tests/test-e2e.sh` sao chép nó vào
một thư mục tạm, khởi tạo Git repository và gắn evidence với revision đã commit.
