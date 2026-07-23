# Kế hoạch: Harness có thể cài đặt và vận hành tại repo đích

## Mục tiêu

Biến repo này từ một bộ template tài liệu thành một harness tối giản có thể:

1. cài an toàn vào một Git repository đã có source code;
2. hướng dẫn agent khảo sát dự án ở chế độ read-only;
3. ghi lại trạng thái dự án tại thời điểm tiếp quản;
4. ghi riêng các legacy issue đã tồn tại tại baseline;
5. không tự sửa legacy issue hoặc hợp thức hóa regression mới;
6. kiểm tra repo đích đã cấu hình harness đầy đủ hay chưa.

## Nguyên tắc phạm vi

- Installer không sửa source code của repo đích.
- Installer không tự chạy build, test, lint, migration hoặc command production.
- File đã tồn tại không bị ghi đè theo mặc định.
- `LEGACY_ISSUES.md` chỉ chứa lỗi được chứng minh đã tồn tại tại baseline revision.
- Lỗi do task hiện tại hoặc thay đổi sau baseline tạo ra không được ghi thành legacy issue.
- Baseline có lỗi không tự động chặn công việc mới nếu lỗi không bị làm xấu hơn.
- Phiên bản đầu không tích hợp LLM API, AST analysis, dashboard hoặc plugin architecture.

## Trạng thái các task

| Task | Nội dung | Trạng thái |
|---|---|---|
| 1 | Chuẩn hóa takeover policy và template | Completed |
| 2 | Xây dựng installer an toàn | Completed |
| 3 | Xây dựng harness checker | Completed |
| 4 | Fixture, test end-to-end và tài liệu sử dụng | Completed |

Mỗi task bên dưới được thiết kế để hoàn thành, kiểm chứng và review trong một session độc lập.

---

## Task 1: Chuẩn hóa takeover policy và template

### Mục tiêu

Tạo đầy đủ tài liệu cần thiết để một agent tiếp quản repo đang vận hành mà không tự ý sửa trạng thái hiện hữu.

### Thay đổi dự kiến

- Thêm `repo-template/docs/HARNESS_SETUP.md`.
- Thêm `repo-template/docs/PROJECT_BASELINE.md`.
- Thêm `repo-template/docs/LEGACY_ISSUES.md`.
- Sửa `repo-template/AGENTS.md`:
  - đọc baseline và legacy issues khi bắt đầu;
  - bỏ quy tắc bắt buộc sửa baseline trước khi thêm phạm vi;
  - phân biệt legacy issue, regression và observation chưa phân loại;
  - cấm chuyển lỗi mới thành legacy issue hoặc technical debt để hoàn thành task.
- Cập nhật `repo-template/docs/PLANS.md`, `QUALITY_SCORE.md` và `RELIABILITY.md` để tham chiếu baseline khi phù hợp.
- Chuẩn hóa placeholder bắt buộc sang dạng `{{PLACEHOLDER_NAME}}`.

### Nội dung bắt buộc của baseline

- ngày baseline;
- Git revision;
- môi trường khảo sát;
- command đã chạy và kết quả;
- operational state;
- golden journey đã kiểm tra;
- khu vực chưa kiểm tra;
- giới hạn của bằng chứng.

### Nội dung bắt buộc của legacy issue

- ID dạng `LEGACY-NNN`;
- area;
- failure signature;
- impact;
- bằng chứng tại baseline revision;
- trạng thái `Accepted`, `In progress` hoặc `Resolved`.

### Kiểm chứng

```bash
rg -n '\{\{[A-Z0-9_]+\}\}' repo-template
rg -n 'PROJECT_BASELINE|LEGACY_ISSUES' repo-template/AGENTS.md repo-template/docs
rg -n 'sửa baseline trước' repo-template
```

Review thủ công các tình huống:

1. lỗi có tại baseline được ghi thành legacy issue;
2. lỗi do task hiện tại tạo ra phải được sửa;
3. lỗi chưa rõ nguồn gốc được ghi trong active plan để phân loại;
4. legacy issue đã sửa được chuyển thành `Resolved`, không bị xóa.

### Tiêu chí hoàn thành

- Ba tài liệu mới tồn tại và không mâu thuẫn với nhau.
- `AGENTS.md` có startup workflow và Definition of Done mới.
- Không còn hướng dẫn yêu cầu agent tự sửa baseline failure ngoài phạm vi.
- `LEGACY_ISSUES.md` có ranh giới rõ, không thể được hiểu như nơi chứa regression mới.
- Tất cả placeholder bắt buộc dùng cú pháp thống nhất.

---

## Task 2: Xây dựng installer an toàn

### Mục tiêu

Cài nội dung `repo-template/` vào một Git repository có sẵn mà không làm mất hoặc âm thầm thay đổi file hiện hữu.

### Thay đổi dự kiến

- Thêm `install.sh` tại root repo nguồn.
- Thêm `.harness-required-files` làm danh sách file bắt buộc dùng chung.
- Hỗ trợ:

```bash
./install.sh --target /path/to/repo
./install.sh --target /path/to/repo --dry-run
./install.sh --target /path/to/repo --overwrite
```

- Phân loại output thành `Created`, `Skipped` và `Conflicts`.
- Không ghi đè mặc định.
- `--overwrite` phải tạo backup trước khi thay file.
- Giữ executable permission cho script được cài.
- Tạo `.harness/installation.json` với ngày cài, phiên bản harness và trạng thái baseline.
- In các bước tiếp theo: xử lý conflict, đọc `HARNESS_SETUP.md`, thiết lập baseline và chạy checker.

### Kiểm chứng

Chạy installer trên các temporary Git repository:

1. repo trống;
2. repo đã có `AGENTS.md`;
3. dry run;
4. cài lần thứ hai;
5. overwrite có backup;
6. target không tồn tại;
7. target không phải Git repository.

Ví dụ:

```bash
target_dir="$(mktemp -d)"
git -C "$target_dir" init
./install.sh --target "$target_dir" --dry-run
./install.sh --target "$target_dir"
```

### Tiêu chí hoàn thành

- Cài thành công vào Git repository hợp lệ.
- Dry run không thay đổi filesystem.
- File hiện hữu không bị ghi đè mặc định.
- Overwrite tạo được backup có thể phục hồi.
- Cài lần hai không phá nội dung đã điền.
- Installer không chạy bất kỳ command dự án nào.
- Output chỉ rõ hành động tiếp theo.

---

## Task 3: Xây dựng harness checker

### Mục tiêu

Cho phép người dùng và CI xác định harness đã được cấu hình đầy đủ, độc lập với việc dự án có legacy failure hay không.

### Thay đổi dự kiến

- Thêm `repo-template/scripts/harness-check.sh`.
- Checker đọc `.harness-required-files` được cài vào repo đích.
- Kiểm tra:
  - file bắt buộc;
  - placeholder bắt buộc chưa được điền;
  - baseline date và baseline revision;
  - bootstrap, verify và start command;
  - active execution plan;
  - Markdown relative links;
  - legacy issue có ID và baseline evidence;
  - product spec index không trỏ đến file thiếu;
  - quality score đã được khởi tạo;
  - có ít nhất một mechanical guardrail được ghi nhận.
- Chuẩn hóa kết quả: `PASS`, `FAIL`, `WARN`, `BASELINE`.
- Exit `0` khi không có `FAIL`, exit `1` khi harness chưa hợp lệ.
- Checker không chạy build/test/lint mặc định.

### Kiểm chứng

Tạo các fixture nhỏ cho từng trường hợp:

1. thiếu file bắt buộc;
2. còn placeholder;
3. link tương đối hỏng;
4. baseline thiếu revision;
5. legacy issue thiếu evidence;
6. legacy issue hợp lệ không làm checker fail;
7. không có active plan;
8. harness đầy đủ trả exit `0`.

### Tiêu chí hoàn thành

- Mỗi lỗi cấu hình có thông báo chỉ rõ file và nguyên nhân.
- Legacy issue hợp lệ chỉ được báo `BASELINE`, không phải `FAIL`.
- Checker không sửa file và không chạy command của ứng dụng.
- Exit code ổn định, dùng được trong CI.
- Script chạy được từ bất kỳ working directory nào trong repo đích.

---

## Task 4: Fixture, kiểm thử end-to-end và tài liệu sử dụng

### Mục tiêu

Chứng minh toàn bộ workflow hoạt động trên một repo mô phỏng dự án legacy đang vận hành nhưng có lỗi sẵn.

### Thay đổi dự kiến

- Thêm `examples/legacy-project/` hoặc fixture được tạo tạm trong test.
- Mô phỏng:
  - source code đã tồn tại;
  - build pass;
  - test có failure sẵn;
  - lint có legacy error;
  - baseline ghi đúng revision;
  - legacy issue có evidence;
  - checker vẫn pass khi harness đã cấu hình đầy đủ.
- Thêm test cho installer và checker.
- Cập nhật root `index.md`:
  - cách cài;
  - takeover workflow;
  - baseline policy;
  - phân biệt legacy issue, regression và technical debt;
  - cách chạy checker.

### Kiểm chứng end-to-end

```bash
./install.sh --target /path/to/fixture-repo
cd /path/to/fixture-repo
./scripts/harness-check.sh
```

Xác nhận:

- source code fixture không bị thay đổi;
- conflict không bị overwrite ngoài ý muốn;
- baseline gắn với revision cụ thể;
- legacy failure không làm checker thất bại;
- regression giả lập không thể được hợp thức hóa thành legacy issue trong tài liệu hướng dẫn;
- toàn bộ test installer/checker pass.

### Tiêu chí hoàn thành

- Có một ví dụ end-to-end tái tạo được.
- Các test chính chạy bằng một command được ghi trong root `index.md`.
- Workflow cài đặt và post-install có thể làm theo mà không cần đọc source script.
- Không còn link nội bộ hỏng trong repo nguồn.
- Tất cả tiêu chí hoàn thành của Task 1–3 vẫn pass.

---

## Quy tắc thực thi qua nhiều session

Khi bắt đầu một task:

1. đọc kế hoạch này;
2. kiểm tra trạng thái Git và giữ nguyên thay đổi không liên quan;
3. chỉ đánh dấu task `In progress` khi bắt đầu thực hiện;
4. chạy toàn bộ kiểm chứng của task trước khi đánh dấu `Completed`;
5. ghi kết quả, command đã chạy và giới hạn còn lại vào nhật ký dưới đây;
6. không bắt đầu task tiếp theo nếu task hiện tại chưa đạt tiêu chí hoàn thành, trừ khi blocker được ghi rõ.

## Nhật ký tiến độ

| Ngày | Task | Kết quả | Bằng chứng / Ghi chú |
|---|---|---|---|
| 2026-07-17 | Planning | Completed | Chia phạm vi thành bốn task có thể kiểm chứng độc lập. |
| 2026-07-17 | Task 1 | Completed | Ba command `rg` bắt buộc đã chạy: placeholder và tham chiếu trả exit `0`; quy tắc `sửa baseline trước` không còn match, trả exit `1` như kỳ vọng. Review thủ công xác nhận legacy issue tại baseline, regression phải sửa, observation chưa rõ nằm trong active plan và issue đã sửa giữ lại với `Resolved`. Assertion bổ sung cho trường bắt buộc, placeholder cũ, trailing whitespace và `git diff --check` đều pass. |
| 2026-07-17 | Task 3 | Completed | `bash -n`, `git diff --check` và 8 fixture bắt buộc đều pass: thiếu file, placeholder, link hỏng, thiếu revision, legacy thiếu evidence và thiếu active plan trả exit `1`; legacy hợp lệ trả `BASELINE`/exit `0`; harness đầy đủ trả exit `0` từ thư mục con. Kiểm tra bổ sung xác nhận spec thiếu, quality score chưa khởi tạo, guardrail/command trống đều fail; checker không sửa file, không chạy command ứng dụng và bỏ qua Markdown ngoài phạm vi harness. Giới hạn: fixture còn được tạo tạm; test tái sử dụng và end-to-end cố định thuộc Task 4. `shellcheck` không có trong môi trường. |
| 2026-07-17 | Task 4 | Completed | `bash -n`, `./tests/run.sh`, kiểm tra link Markdown toàn repo, regression assertions Task 1–3 và `git diff --check` đều pass. Bộ test bao phủ 7 tình huống installer, 8 tình huống checker và end-to-end trên `examples/legacy-project`: build pass; test/lint có failure baseline; revision và legacy evidence khớp; checker trả `BASELINE`/exit `0`; source đã commit không đổi; conflict được giữ hoặc backup khi overwrite. Root `index.md` ghi đầy đủ install, takeover, baseline policy, phân loại failure, checker và một command chạy test. Giới hạn: `shellcheck` không có trong môi trường nên không chạy. |

## Definition of Done toàn kế hoạch

Toàn kế hoạch hoàn thành khi:

```bash
./install.sh --target ../legacy-project
cd ../legacy-project
./scripts/harness-check.sh
```

đạt các điều kiện:

- source code dự án không bị installer thay đổi;
- file hiện hữu không bị ghi đè ngoài ý muốn;
- post-install playbook đủ để thiết lập baseline;
- legacy issues được lưu riêng với bằng chứng tại baseline revision;
- lỗi mới không được phân loại thành legacy issue;
- harness checker có output và exit code ổn định;
- repo đích có active plan, verification commands và ít nhất một mechanical guardrail;
- toàn bộ test installer và checker đều pass.
