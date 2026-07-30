# Workspace Template

Template cho một local workspace chứa nhiều Git repository độc lập.

Agent chạy tại workspace root mang danh tính **QiQi**: thư ký điều phối agent
của người dùng. QiQi chính chạy bằng Codex và không trực tiếp sửa code trong
repository con; QiQi dùng Herdr để tạo và quản lý các phiên coding agent được
khai báo trong model routing tại đúng repository root.

## Thành phần

```text
AGENTS.md
identity.md
SYSTEM_MAP.md
repos.yaml
instructions/
└── model-routing.md
.agents/
└── skills/
    └── herdr/
        ├── SKILL.md
        ├── LICENSE.txt
        └── SOURCE.md
docs/
└── WORKSPACE_SETUP.md
scripts/
└── workspace-check.sh
```

- `AGENTS.md`: contract khởi động và vòng đời điều phối của QiQi.
- `identity.md`: vai trò, mục tiêu, giới hạn và cách giao tiếp của QiQi.
- `repos.yaml`: registry machine-readable của các repository local.
- `SYSTEM_MAP.md`: dependency, contract và runtime liên repository.
- `instructions/model-routing.md`: inventory model và quy tắc chọn model.
- `.agents/skills/herdr/`: Herdr skill được vendor cùng license và provenance.

## Cài đặt

1. Sao chép các tệp trong thư mục này vào root workspace mới hoặc dùng
   `install-from-github.sh --mode workspace`.
2. Clone từng repository thành thư mục con của workspace.
3. Đọc và hoàn thành `docs/WORKSPACE_SETUP.md`.
4. Điền `repos.yaml`, `SYSTEM_MAP.md` và `instructions/model-routing.md` bằng
   dữ liệu thực tế.
5. Chỉ bắt đầu task sản phẩm sau khi `./scripts/workspace-check.sh` trả exit
   `0`.

## Runtime QiQi

Máy local cần có Codex CLI và Herdr. Skill được cài ở project-local path
`.agents/skills/herdr/`, nên Codex khởi động tại workspace root có thể khám phá
skill cùng workspace.

Để QiQi có quyền điều khiển Herdr:

```bash
cd /path/to/workspace
herdr
```

Sau đó khởi động Codex trong một pane do Herdr quản lý. QiQi chỉ điều khiển
Herdr khi `HERDR_ENV=1`.

`AGENTS.md` root điều phối nhiều repository. `AGENTS.md` trong mỗi repository
điều phối việc khám phá, thay đổi, xác minh và tài liệu của chính repository đó.
Việc cài harness riêng vào từng repository vẫn là tùy chọn và do người dùng
quyết định.
