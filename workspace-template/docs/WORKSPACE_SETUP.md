# Thiết lập và Tiếp quản Multi-repository Workspace

Tài liệu này là quy trình bắt buộc khi khởi tạo `workspace-template` cho một
hệ thống thực tế. Mục tiêu là tạo một workspace đủ thông tin để QiQi xác định
đúng repository, contract, agent, model và cách khởi động phiên coding agent mà
không suy đoán.

Không bắt đầu task sản phẩm trước khi hoàn tất quy trình này.

## Kết quả Cần đạt

Sau khi hoàn thành:

- workspace root chứa các Git repository đã khai báo;
- `repos.yaml` liệt kê chính xác mọi repository được workspace quản lý;
- `SYSTEM_MAP.md` mô tả vai trò, dependency, contract, ownership và cách chạy
  integration có bằng chứng;
- `identity.md` xác định rõ QiQi là agent điều phối, không phải coding agent;
- `instructions/model-routing.md` ghi đúng inventory agent và model đang khả
  dụng cùng điểm mạnh, điểm yếu và trường hợp sử dụng;
- Herdr skill tồn tại tại `.agents/skills/herdr/` cùng license và provenance;
- Codex CLI và Herdr được xác nhận có mặt hoặc blocker được báo rõ;
- mọi placeholder dạng ngoặc nhọn kép trong artifact workspace đã được thay;
- `./scripts/workspace-check.sh` trả `PASS` với exit `0`.

## Nguyên tắc An toàn

- Bắt đầu bằng khảo sát read-only.
- Mỗi repository là Git repository độc lập; không dùng Git state của workspace
  root thay cho state của repository.
- Không reset, clean, stash, rebase, commit, format, update dependency,
  migration hoặc sửa source code trong giai đoạn tiếp quản.
- Không chạy command production, destructive command hoặc command có tác dụng
  phụ chưa rõ.
- Không tự phát minh repository, dependency, owner, endpoint, event, command,
  model ID, capability hoặc compatibility policy.
- Khi chưa có bằng chứng, setup bị chặn và phải yêu cầu thông tin từ owner hệ
  thống hoặc người quản lý model/provider.
- Chỉ cập nhật artifact điều phối ở workspace root, trừ khi người dùng cho phép
  phạm vi khác.
- Không cài integration, thay đổi config user-level hoặc khởi động session nền
  nếu người dùng chưa yêu cầu.

## Bước 0: Xác nhận vị trí và trạng thái ban đầu

Từ workspace root, chạy:

```bash
pwd
git rev-parse --show-toplevel 2>/dev/null || true
find . -mindepth 2 -maxdepth 2 -type d -name .git -print
```

Workspace root có thể không phải Git repository. Không biến nó thành Git repo
trừ khi người dùng yêu cầu rõ.

Xác nhận các artifact sau tồn tại:

```text
AGENTS.md
identity.md
repos.yaml
SYSTEM_MAP.md
instructions/model-routing.md
.agents/skills/herdr/SKILL.md
.agents/skills/herdr/LICENSE.txt
.agents/skills/herdr/SOURCE.md
```

## Bước 1: Lập Inventory Repository có Bằng chứng

Với từng thư mục dự kiến là repository, chạy:

```bash
git -C <repository-path> rev-parse --show-toplevel
git -C <repository-path> remote -v
git -C <repository-path> branch --show-current
git -C <repository-path> rev-parse HEAD
git -C <repository-path> status --short
```

Thu thập tên và đường dẫn local, remote, branch/revision, trạng thái working
tree, vai trò, dependency, entrypoint/runtime cùng command bootstrap, verify,
start và debug. Mọi thông tin phải lấy từ code, manifest, deployment config,
CI hoặc tài liệu hiện hữu.

Không cho repository vào `repos.yaml` nếu nó không tồn tại local. Nếu một
repository cần cho workflow nhưng chưa clone được, dừng setup và yêu cầu đường
dẫn hoặc quyền truy cập; không điền đường dẫn giả.

## Bước 2: Điền `repos.yaml`

Khai báo một entry cho mỗi repository local được workspace điều phối.

| Trường | Yêu cầu |
|---|---|
| `name` | Tên duy nhất, ổn định, dùng trong `SYSTEM_MAP.md` |
| `path` | Đường dẫn tương đối từ workspace root; phải trỏ đến Git root |
| `role` | Vai trò thực tế của repository |
| `required_for` | Workflow hoặc capability cần repository này |
| `depends_on` | Tên repository trong registry; dùng `[]` nếu không có |

`depends_on` chỉ mô tả dependency giữa repository local. Hạ tầng như PostgreSQL
hoặc Kafka thuộc `SYSTEM_MAP.md`, không phải Git repository giả.

## Bước 3: Điền `SYSTEM_MAP.md`

Chỉ điền thông tin có bằng chứng. Hoàn thành toàn bộ các phần sau:

1. Hình dạng hệ thống: tên sản phẩm, đường dẫn workspace, hạ tầng và command
   integration. Nếu chưa có command, ghi `Not available — <lý do và owner>`.
2. Danh sách repository: phải khớp một-một với `repos.yaml`.
3. Thứ tự khởi động: hạ tầng trước, provider trước consumer. Nếu không thể chạy
   local, nêu dependency thiếu thay vì đoán.
4. Contract liên repository: producer, consumer, loại, tài liệu nguồn và quy tắc
   compatibility. Nếu không áp dụng, ghi `Not applicable — <lý do>`.
5. Ownership dữ liệu: owner và đường truy cập được phép.
6. Integration check: command, repository liên quan, điều kiện trước khi chạy và
   kết quả thực tế. Command chưa chạy phải ghi `Not run — <lý do>`.
7. Breaking change/rollback: owner, deprecation policy, điều kiện xóa contract
   cũ và rollback. Nếu policy chưa tồn tại, setup bị chặn cho breaking change.

Không dùng các giá trị mơ hồ như `TBD`, `TODO`, `unknown`, `configured`, `N/A`
hoặc đường dẫn giả để thay placeholder.

## Bước 4: Điền `instructions/model-routing.md`

Agent và model catalog thay đổi theo CLI, provider, account và thời điểm. Không
dùng một danh sách lấy từ tài liệu cũ hoặc trí nhớ.

1. Xác nhận từng agent CLI muốn dùng, ví dụ:

   ```bash
   command -v codex
   codex --version
   codex --help
   command -v claude
   claude --version
   claude --help
   ```

2. Dùng model picker, cấu hình provider hoặc cơ chế được agent CLI hiện tại hỗ
   trợ để lập danh sách model thật sự có thể chọn.
3. Khi cần, khởi động một phiên thử không chỉnh sửa repository để xác nhận model
   ID hoạt động.
4. Với mỗi model, ghi:
   - agent kind đúng theo `herdr agent start --help`;
   - model ID chính xác;
   - native arguments gồm model và chế độ permission;
   - bằng chứng availability;
   - điểm mạnh;
   - điểm yếu;
   - task phù hợp và không phù hợp;
   - reasoning effort mặc định;
   - giới hạn song song thực tế.
5. Gán các profile `fast`, `balanced`, `deep`, `verifier`. Nhiều profile có thể
   dùng cùng một model nếu inventory nhỏ.
6. Xóa hàng mẫu không dùng và thay toàn bộ placeholder.

Nếu không xác định được model ID hoặc quyền truy cập, workspace setup bị chặn
cho chức năng delegation. Không tự ghi một model có vẻ hợp lý.

## Bước 5: Xác nhận Herdr và Skill

Skill được vendor sẵn tại `.agents/skills/herdr/`; không cần tải lại bằng
`npx skills add` trong workspace đã cài template.

Xác nhận runtime:

```bash
command -v herdr
herdr --version
command -v codex
codex --version
```

Kiểm tra provenance:

```bash
sed -n '1,40p' .agents/skills/herdr/SOURCE.md
sed -n '1,12p' .agents/skills/herdr/SKILL.md
```

Nếu máy chưa có Herdr, báo blocker và hướng người dùng cài từ nguồn chính thức.
Không tự chạy installer tải từ mạng trong giai đoạn takeover nếu chưa được yêu
cầu.

Herdr có integration trực tiếp cho nhiều agent. Cài integration cho từng agent
kind được khai báo trong model routing, ví dụ:

```bash
herdr integration install codex
herdr integration install claude
```

Đây là thay đổi user-level; chỉ thực hiện khi người dùng đồng ý.

Setup có thể được khảo sát ngoài Herdr. Tuy nhiên, để QiQi điều khiển phiên agent,
phải khởi động Herdr tại workspace root rồi chạy Codex trong pane do Herdr quản
lý. Khi đó `HERDR_ENV=1` phải tồn tại trong phiên QiQi.

Không chạy bare `herdr` như lệnh discovery trong automation vì nó mở hoặc attach
TUI. Dùng `herdr --help` và command-group help theo Herdr skill.

## Bước 6: Xác minh Workspace

Từ workspace root, cài `yq` phiên bản 4 nếu chưa có, sau đó chạy:

```bash
./scripts/workspace-check.sh
```

Checker xác minh:

- các artifact QiQi bắt buộc tồn tại;
- model routing, system map và registry không còn placeholder;
- Herdr skill có frontmatter đúng;
- license và provenance của skill tồn tại;
- registry repository hợp lệ.

Checker không thay thế:

- kiểm tra Herdr và runtime của các agent đã khai báo trên máy;
- test hoặc integration test của từng repository;
- verification mà agent con phải chạy theo `AGENTS.md` riêng.

## Bước 7: Fresh-session Test và Bàn giao

Sau khi checker pass, mở một phiên Codex mới tại workspace root và xác nhận QiQi
có thể trả lời chỉ dựa trên artifact workspace:

1. Tôi là ai và không được trực tiếp làm gì?
2. Repository nào đang được quản lý và nằm ở đâu?
3. Repository nào phụ thuộc repository nào?
4. Model nào dùng cho task cơ học, implementation thường và task khó?
5. Herdr skill nằm ở đâu?
6. Khi `HERDR_ENV` không bằng `1`, QiQi phải làm gì?

Sau đó khởi động QiQi trong Herdr và thực hiện một smoke test không sửa code:

- liệt kê agent/workspace hiện có;
- không tạo hoặc đóng session không thuộc smoke test;
- xác nhận QiQi đọc được skill và biết cách tạo phiên tại repository con.

Chỉ khi checker pass và runtime blocker đã được phân loại, báo cáo:

- danh sách repository cùng branch/revision và working tree có sẵn;
- relation/contract quan trọng;
- inventory agent, model và profile routing;
- phiên bản Herdr và các agent CLI;
- integration Herdr-agent cần thiết đã cài hay chưa;
- khu vực chưa xác minh;
- hành động tiếp theo nếu còn bị chặn.

Không tuyên bố workspace sẵn sàng cho QiQi delegation nếu còn placeholder,
repository registry không tồn tại, model chưa được xác nhận hoặc Herdr/agent
runtime cần thiết chưa khả dụng.
