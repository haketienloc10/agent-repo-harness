# Thiết lập và Tiếp quản Multi-repository Workspace

Tài liệu này là quy trình bắt buộc khi khởi tạo `workspace-template` cho một
hệ thống thực tế. Mục tiêu là tạo một workspace đủ thông tin để agent xác định
đúng module, contract và command xác minh mà không suy đoán.

Không bắt đầu task sản phẩm trước khi hoàn tất quy trình này.

## Kết quả Cần đạt

Sau khi hoàn thành:

- workspace root chứa các Git repository module đã khai báo;
- `repos.yaml` liệt kê chính xác mọi module được workspace quản lý;
- `SYSTEM_MAP.md` mô tả vai trò, dependency, contract, ownership và cách chạy
  integration có bằng chứng;
- mọi placeholder dạng ngoặc nhọn kép trong artifact workspace đã được thay thế;
- `./scripts/workspace-check.sh` trả `PASS` với exit `0`.

## Nguyên tắc An toàn

- Bắt đầu bằng khảo sát read-only.
- Mỗi module là Git repository độc lập; không dùng Git state của workspace root
  thay cho state của module.
- Không reset, clean, stash, rebase, commit, format, update dependency,
  migration hoặc sửa source code trong giai đoạn tiếp quản.
- Không chạy command production, destructive command hoặc command có tác dụng
  phụ chưa rõ.
- Không tự phát minh module, dependency, owner, endpoint, event, command hay
  compatibility policy. Khi chưa có bằng chứng, setup bị chặn và phải yêu cầu
  thông tin từ owner hệ thống.
- Chỉ cập nhật artifact điều phối ở workspace root, trừ khi người dùng cho phép
  phạm vi khác.

## Bước 0: Xác nhận vị trí và trạng thái ban đầu

Từ workspace root, chạy:

```bash
pwd
git rev-parse --show-toplevel 2>/dev/null || true
find . -mindepth 2 -maxdepth 2 -type d -name .git -print
```

Workspace root có thể không phải Git repository. Không biến nó thành Git repo
trừ khi người dùng yêu cầu rõ.

## Bước 1: Lập inventory module có bằng chứng

Với từng thư mục dự kiến là module, chạy:

```bash
git -C <module-path> rev-parse --show-toplevel
git -C <module-path> remote -v
git -C <module-path> branch --show-current
git -C <module-path> rev-parse HEAD
git -C <module-path> status --short
```

Thu thập tên và đường dẫn local, remote, branch/revision, trạng thái working
tree, vai trò, dependency, entrypoint/runtime cùng command bootstrap, verify,
start và debug. Mọi thông tin phải lấy từ code, manifest, deployment config,
CI hoặc tài liệu hiện hữu.

Không cho module vào `repos.yaml` nếu nó không tồn tại local. Nếu một module
cần cho workflow nhưng chưa clone được, dừng setup và yêu cầu đường dẫn hoặc
quyền truy cập; không điền đường dẫn giả.

## Bước 2: Điền `repos.yaml`

Khai báo một entry cho mỗi module local được workspace điều phối.

| Trường | Yêu cầu |
|---|---|
| `name` | Tên duy nhất, ổn định, dùng trong `SYSTEM_MAP.md` |
| `path` | Đường dẫn tương đối từ workspace root; phải trỏ đến Git root |
| `role` | Vai trò thực tế của module |
| `required_for` | Workflow hoặc capability cần module này |
| `depends_on` | Tên module trong registry; dùng `[]` nếu không có |

`depends_on` chỉ mô tả dependency giữa module local. Hạ tầng như PostgreSQL
hoặc Kafka thuộc `SYSTEM_MAP.md`, không phải Git repository giả.

## Bước 3: Điền `SYSTEM_MAP.md`

Chỉ điền thông tin có bằng chứng. Hoàn thành toàn bộ các phần sau:

1. Hình dạng hệ thống: tên sản phẩm, đường dẫn workspace, hạ tầng và command
   integration. Nếu chưa có command, ghi `Not available — <lý do và owner>`.
2. Danh sách module: phải khớp một-một với `repos.yaml`.
3. Thứ tự khởi động: hạ tầng trước, provider trước consumer. Nếu không thể chạy
   local, nêu dependency thiếu thay vì đoán.
4. Contract liên module: producer, consumer, loại, tài liệu nguồn và quy tắc
   compatibility. Nếu không áp dụng, ghi `Not applicable — <lý do>`.
5. Ownership dữ liệu: owner và đường truy cập được phép.
6. Integration check: command, module liên quan, điều kiện trước khi chạy và
   kết quả thực tế. Command chưa chạy phải ghi `Not run — <lý do>`.
7. Breaking change/rollback: owner, deprecation policy, điều kiện xóa contract
   cũ và rollback. Nếu policy chưa tồn tại, setup bị chặn cho breaking change.

Không dùng các giá trị mơ hồ như `TBD`, `TODO`, `unknown`, `configured`, `N/A`
hoặc đường dẫn giả để thay placeholder.

## Bước 4: Xác minh workspace

Từ workspace root, cài `yq` phiên bản 4 nếu chưa có, sau đó chạy:

```bash
./scripts/workspace-check.sh
```

Checker xác minh cấu trúc, placeholder và registry. Nó không thay thế test hoặc
integration test của từng module.

## Bước 5: Bàn giao

Chỉ khi checker pass, báo cáo danh sách module cùng branch/revision, working
tree có sẵn, command verify đã chạy cho từng module (nếu có), integration
evidence, khu vực chưa xác minh và hành động tiếp theo nếu còn bị chặn.

Không tuyên bố workspace sẵn sàng nếu còn placeholder, module registry không
tồn tại, hoặc contract quan trọng chưa có owner/nguồn.
