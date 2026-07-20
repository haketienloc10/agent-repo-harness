# Workspace Template

Template cho một local workspace chứa nhiều Git repository độc lập.

## Cài đặt

1. Sao chép các tệp trong thư mục này vào root workspace mới.
2. Clone từng module thành thư mục con của workspace.
3. Đọc và hoàn thành `docs/WORKSPACE_SETUP.md`.
4. Chỉ bắt đầu task sản phẩm sau khi `./scripts/workspace-check.sh` trả exit
   `0`.

`AGENTS.md` root điều phối nhiều repo. `AGENTS.md` trong mỗi module điều phối
việc thay đổi, xác minh và tài liệu của chính module đó nếu module lựa chọn có
tệp này. Việc cài harness cho từng module là tùy chọn và do người dùng quyết
định.
