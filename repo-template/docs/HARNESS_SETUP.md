# Thiết lập Harness và Tiếp quản Repo

Tài liệu này chỉ dùng trong installation hoặc takeover. Mục tiêu là khảo sát
repo hiện hữu, ghi bằng chứng và cấu hình harness mà không tự sửa source,
dependency, dữ liệu, runtime configuration hoặc baseline failure.

Takeover chỉ complete khi `./scripts/harness-check.sh` trả exit `0`. Trước đó
không bắt đầu task sản phẩm.

## Installation state machine

`.harness/installation.json` là nguồn sự thật machine-readable:

```text
pending → complete
pending → blocked → pending
blocked → complete
```

- `pending`: fresh install mặc định; repository chưa ready.
- `blocked`: không thể tiếp tục; `blocker_reason` phải nêu dependency hoặc hành
  động cụ thể để unblock.
- `complete`: baseline và verification đã có bằng chứng, metadata đã cập nhật,
  và checker vừa trả exit `0`.

Khi bắt đầu takeover, tạo `docs/TAKEOVER_BASELINE.md`; fresh install không tạo
file này. Ghi revision tiếp quản vào `baseline_revision`. Sau khi hoàn tất nội
dung, ghi `takeover_completed_at` theo RFC 3339, đặt `takeover_status` thành
`complete`, rồi chạy checker. Nếu checker trả non-zero, đưa status về `pending`
hoặc `blocked` phù hợp; không khai báo repository ready.

Không thay đổi `source`, `ref`, `installed_at` hoặc `harness_version`.

## Quy trình takeover

### 1. Khảo sát read-only

Xác nhận root và bảo toàn trạng thái ban đầu:

```bash
pwd
git rev-parse --show-toplevel
git status --short
git rev-parse HEAD
git branch --show-current
```

Review mọi conflict từ installer trước khi tiếp tục. Không format, migrate,
update dependency, generate code, commit, reset hoặc cleanup trong lúc thu thập
baseline.

Đọc README, manifest, lockfile, CI, build/deploy configuration, source
entrypoint, test configuration, migration và external adapter liên quan. Chỉ ghi
điều có bằng chứng từ source, config, CI, tài liệu hoặc command thực tế.

### 2. Cấu hình core artifact

- Cập nhật `ARCHITECTURE.md` để phản ánh kiến trúc đang chạy, domain, entrypoint,
  dependency và external boundary thực tế.
- Cập nhật `docs/VERIFY.md` với prerequisite và command bootstrap, build, test,
  lint, type-check, start, debug, golden journey hoặc guardrail thực sự tồn tại.
- Tạo `docs/TAKEOVER_BASELINE.md` với revision, branch, working tree, command đã
  chạy, exit code, failure signature, khu vực chưa kiểm tra và giới hạn bằng
  chứng.

Command không thể chạy an toàn được ghi là `Not run` cùng lý do cụ thể.

### 3. Chỉ tạo optional artifact khi concern tồn tại

Không tạo optional artifact để hoàn thiện một checklist. Không tạo file chỉ chứa
`Not applicable`, placeholder hoặc ví dụ giả. Nếu concern không tồn tại, để file
vắng mặt.

| Artifact | Chỉ tạo khi | Nội dung tối thiểu |
|---|---|---|
| `docs/specs/<area>.md` | Có behavior/contract cần làm nguồn sự thật | scope, behavior, acceptance criteria |
| `docs/decisions/<NNNN-title>.md` | Có quyết định kiến trúc lâu dài hoặc trade-off cần lưu | context, decision, consequences, status |
| `docs/UI.md` | Repo có UI | surface, state, interaction, accessibility, responsive rule |
| `docs/SECURITY.md` | Có auth, secret, sensitive data hoặc trust boundary | asset, boundary, threat, control, verification |
| `docs/LEGACY_ISSUES.md` | Có failure được chứng minh tại baseline revision | ID, signature, impact, revision, evidence, reproduction, status |
| `docs/KNOWN_DEBT.md` | Có khiếm khuyết được chủ động hoãn | owner, risk, reason, trigger hoặc review date |
| `docs/generated/<artifact>` | Có generator và consumer thật | generator command, owner, refresh rule; nội dung do generator tạo |
| `docs/references/<source>` | Task cần giữ nguồn ngoài cục bộ | source URL, version hoặc retrieval date, refresh trigger |
| `docs/tasks/active/<task>.md` | Task thỏa plan trigger trong `AGENTS.md` | goal, scope, decisions, blockers, progress, verification |

Không tạo optional artifact chỉ vì checker hoặc template từng biết tên file đó.
Optional artifact không được thay thế source of truth chuyên biệt khác.

### 4. Chạy baseline an toàn

Với mỗi command, xác định nguồn, prerequisite, tác dụng phụ và kết quả cần ghi.
Ưu tiên bootstrap/dependency check, build/static check, test, start/health check,
golden journey rồi mechanical guardrail khi phù hợp. Sau mỗi nhóm command, chạy:

```bash
git status --short
```

Baseline có thể đỏ. Failure chỉ là legacy issue khi được tái hiện và có bằng
chứng tại đúng baseline revision. Điểm yếu chưa có failure cụ thể thuộc
`ARCHITECTURE.md`; observation chưa đủ nguồn gốc ở lại baseline để điều tra.
Không đổi regression thành legacy issue hoặc debt.

### 5. Review và đóng vòng lặp

```bash
git status --short
git diff --check
git diff --stat
git diff
./scripts/harness-check.sh
```

Xác nhận chỉ artifact harness dự kiến thay đổi, không có secret, source/config
ngoài ý muốn, dependency update, migration, generated source hoặc cache được đưa
vào Git. Nếu checker non-zero, sửa artifact bằng bằng chứng rồi chạy lại.

Checker chỉ xác nhận contract harness; nó không thay thế build, test, start hoặc
golden journey đã ghi trong `docs/VERIFY.md`.

## Định nghĩa sẵn sàng

Repository chỉ sẵn sàng khi:

- conflict cài đặt đã được xử lý;
- `docs/TAKEOVER_BASELINE.md` ghi đúng revision và giới hạn bằng chứng;
- `ARCHITECTURE.md` và `docs/VERIFY.md` phản ánh repo thật;
- optional artifact chỉ tồn tại cho concern thật và không chứa nội dung lấp chỗ;
- source/config dự án không bị thay đổi ngoài ý muốn;
- metadata ở trạng thái `complete`;
- lần chạy cuối của `./scripts/harness-check.sh` trả exit `0`.

Sau đó dừng takeover, không tự tạo task sửa legacy issue hoặc điểm yếu kiến trúc,
và chờ task sản phẩm.
