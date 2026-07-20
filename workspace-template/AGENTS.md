# AGENTS.md — Multi-repository workspace

Thư mục hiện tại là local workspace chứa nhiều Git repository độc lập.
Nó không phải một Git repository sản phẩm và không phải monorepo.

Giữ tệp này ngắn. Nó chỉ điều phối công việc giữa các module; `AGENTS.md`
trong từng module là nguồn sự thật cho quy trình thay đổi module đó.

## Quy tắc Phạm vi

- Mỗi thư mục con có `.git/` là một module độc lập, với lịch sử Git, branch,
  remote và CI riêng.
- Không giả định thay đổi trong một module sẽ tự động áp dụng cho module khác.
- Không chạy `git` ở workspace root để suy luận trạng thái của các module.
  Luôn chạy Git command từ root của module đích hoặc dùng `git -C <module>`.
- `repos.yaml` là registry machine-readable của các module local. Cập nhật nó
  khi thêm, đổi tên hoặc bỏ một module khỏi workspace.

## Quy trình Khởi động

Trước khi thay đổi mã:

1. Xác định module hoặc các module bị ảnh hưởng.
2. Đọc `SYSTEM_MAP.md` nếu task đi qua API, event, database contract, auth,
   deployment hoặc runtime của từ hai module trở lên.
3. Với mỗi module đích, chạy:

   ```bash
   git -C <module> rev-parse --show-toplevel
   git -C <module> status --short
   git -C <module> branch --show-current
   ```

4. Nếu `<module>/AGENTS.md` tồn tại, đọc nó trước khi đọc hoặc sửa mã của
   module đó và tuân theo các hướng dẫn trong tệp.
5. Nếu module không có `AGENTS.md`, đọc README, tài liệu vận hành và cấu hình
   của module để xác định command khởi động và xác minh phù hợp.

## Thay đổi Đơn Module

- Tuân theo hướng dẫn, command test và Definition of Done riêng của module nếu
  module có các artifact đó.
- Chỉ sửa module đó, trừ khi bằng chứng cho thấy contract liên module phải đổi.
- Không sửa `SYSTEM_MAP.md` chỉ vì một chi tiết kiến trúc nội bộ thay đổi.

## Thay đổi Liên Module

Trước khi sửa mã, ghi rõ trong kế hoạch:

- module producer và consumer;
- contract bị ảnh hưởng: API, schema, event, auth, config hoặc deployment;
- thứ tự tương thích và rollout;
- command xác minh của từng module;
- integration check cần chạy ở workspace root, nếu có.

Ưu tiên thay đổi tương thích ngược:

1. Producer hỗ trợ contract mới.
2. Consumer chuyển sang contract mới.
3. Xác minh từng module và integration.
4. Chỉ xóa contract cũ sau khi mọi consumer đã chuyển đổi.

Không thay đổi đồng thời contract breaking ở producer và consumer nếu không có
kế hoạch rollout, migration và rollback rõ ràng.

## Trạng thái Git và Bằng chứng

- Giữ riêng trạng thái, commit và evidence của từng module.
- Không reset, clean, stash, rebase hoặc commit thay đổi có sẵn của module.
- Khi báo cáo, nêu rõ thay đổi và kết quả verify theo từng module.
- Task liên module chỉ hoàn thành khi mọi module bị ảnh hưởng đạt Definition of
  Done trong `AGENTS.md` riêng của chúng, cộng với integration evidence phù hợp.

## Bản đồ Hệ thống

`SYSTEM_MAP.md` là nguồn điều phối cấp workspace cho:

- danh sách module và vai trò;
- entrypoint và runtime local;
- API, event và database contract liên module;
- dependency direction;
- command chạy integration;
- thứ tự khởi động và dependency hạ tầng.

Không sao chép chi tiết kiến trúc nội bộ của module vào đây. Chi tiết đó thuộc
`<module>/ARCHITECTURE.md`.
