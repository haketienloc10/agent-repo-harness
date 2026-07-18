# Thiết lập Harness và Tiếp quản Repo

Tài liệu này là luồng làm việc bắt buộc sau khi harness được cài vào một repo đích đang tồn tại.

Mục tiêu của quá trình tiếp quản là khảo sát trạng thái hiện hữu, ghi lại bằng chứng và cấu hình các artifact của harness cho đúng với repo đích. Không tự sửa source code yếu, thiết kế cũ, dữ liệu, cấu hình runtime hoặc failure có sẵn chỉ để làm baseline xanh.

Quá trình tiếp quản hoàn thành khi `./scripts/harness-check.sh` trả exit `0`. Trước thời điểm đó, không bắt đầu task sản phẩm của người dùng.

## Kết quả cần đạt

Sau khi hoàn thành tài liệu này, repo phải có:

- snapshot baseline tại đúng Git revision tiếp quản;
- bản đồ kiến trúc và domain phản ánh source hiện hữu;
- command bootstrap, verify, start và debug thực tế;
- legacy failure có reproduction và evidence tại baseline;
- quality score ban đầu có lý do;
- khu vực chưa kiểm tra và giới hạn bằng chứng được ghi rõ;
- không còn placeholder bắt buộc;
- không có thay đổi source hoặc config ngoài ý muốn;
- checker của harness trả `PASS`.

## Nguyên tắc an toàn

- Bắt đầu bằng khảo sát read-only.
- Không format, migration, update dependency, generate code, commit, reset hoặc cleanup trong lúc thu thập baseline.
- Không chạy command production, command phá hủy hoặc command có tác dụng phụ chưa rõ.
- Ghi Git revision và working tree trước khi chạy command dự án.
- Không dùng bằng chứng từ revision khác để khai báo legacy issue.
- Không sửa baseline failure ngoài phạm vi chỉ để tạo baseline xanh.
- Không tự thay đổi file hiện hữu của dự án để khớp template. Mọi conflict cài đặt phải được review và xử lý có chủ ý.
- Chỉ cập nhật artifact harness trong quá trình tiếp quản, trừ khi người dùng phê duyệt thay đổi khác.

## Bước 0: Xác nhận cài đặt có thể tiếp tục

Từ root của repo đích, chạy:

```bash
pwd
git rev-parse --show-toplevel
git status --short
```

Chỉ tiếp tục khi:

- `pwd` trùng với Git root;
- mọi dòng `Conflicts` từ installer đã được review và xử lý;
- `AGENTS.md`, `ARCHITECTURE.md`, `docs/HARNESS_SETUP.md` và `scripts/harness-check.sh` tồn tại;
- agent hiểu working tree đang sạch hay đã có thay đổi từ trước.

Nếu còn conflict cài đặt, dừng quá trình tiếp quản. Không dùng `--overwrite` trước khi review nội dung hiện hữu và bản backup sẽ được tạo.

## Bước 1: Bảo toàn trạng thái ban đầu

Ghi lại kết quả của các command sau trước khi chạy build, test hoặc start:

```bash
pwd
git status --short
git rev-parse HEAD
git branch --show-current
```

Điền các giá trị có bằng chứng vào `docs/PROJECT_BASELINE.md`:

- ngày baseline;
- Git revision;
- branch hoặc ref;
- trạng thái working tree;
- người hoặc agent khảo sát.

Nếu working tree không sạch:

1. Ghi rõ các thay đổi có sẵn.
2. Không nhận chúng là thay đổi của phiên tiếp quản.
3. Không tự reset hoặc cleanup.
4. Ghi trạng thái chưa commit vào phần giới hạn bằng chứng.

Revision từ `git rev-parse HEAD` là revision baseline. Evidence từ working tree bẩn phải được mô tả riêng, không được trình bày như bằng chứng của một checkout sạch tại revision đó.

## Bước 2: Khảo sát dự án ở chế độ read-only

Đọc các nguồn hiện hữu trước khi suy luận:

- README và tài liệu vận hành;
- manifest, lockfile và build file;
- CI configuration;
- Dockerfile, compose file và deployment configuration;
- script bootstrap, test, lint, start và debug;
- source entrypoint;
- cấu hình database và migration;
- test configuration;
- các adapter tới service bên ngoài.

Xác định tối thiểu:

- sản phẩm hoặc thư viện này làm gì;
- runtime surface và entrypoint;
- toolchain và phiên bản runtime;
- các domain chính;
- hướng phụ thuộc giữa các lớp;
- database, queue và external service;
- auth, logging và các concern xuyên suốt;
- command bootstrap, verify, start và debug;
- golden journey quan trọng;
- mechanical guardrail hiện có;
- khu vực không thể kiểm tra trong môi trường hiện tại.

Chỉ ghi điều có bằng chứng từ source, configuration, CI, tài liệu hoặc command thực tế. Không điền `configured`, `TBD`, `unknown` hoặc nội dung đoán để loại placeholder.

## Bước 3: Cập nhật bản đồ và command của repo

Cập nhật các artifact sau từ kết quả khảo sát:

| Artifact | Nội dung phải phản ánh |
|---|---|
| `ARCHITECTURE.md` | system shape, domain, layer, entrypoint, dependency rule, external boundary và hotspot hiện hữu |
| `docs/PRODUCT_SENSE.md` | người dùng chính, công việc họ cần hoàn thành, frustration và quality bar |
| `docs/RELIABILITY.md` | bootstrap, verify, start, debug, mechanical guardrail, runtime signal và golden journey |
| `docs/SECURITY.md` | secret, dữ liệu nhạy cảm, sandbox, approval và destructive boundary của repo |
| `docs/FRONTEND.md` | chỉ cập nhật khi repo có UI; nếu không có, ghi rõ không áp dụng và lý do |
| `docs/product-specs/` | hành vi sản phẩm đã có bằng chứng và acceptance quan trọng |

Với trường không áp dụng, ghi rõ lý do, ví dụ:

```text
Not applicable — repo này là thư viện và không có service để khởi động.
```

Với command chưa thể chạy an toàn, ghi rõ:

```text
Not run — command yêu cầu service nội bộ hiện không truy cập được.
```

Không suy đoán kết quả của command chưa chạy.

## Bước 4: Chọn và chạy command baseline

Trước khi chạy mỗi command, xác định:

- command đến từ đâu;
- tác dụng phụ dự kiến;
- dependency hoặc service cần thiết;
- command có an toàn trong môi trường khảo sát hay không;
- kết quả nào sẽ được ghi lại.

Ưu tiên theo thứ tự phù hợp với repo:

1. Bootstrap hoặc dependency check.
2. Build, unit test, lint hoặc verify chuẩn.
3. Start và health check nếu repo có runtime service.
4. Golden journey có thể chạy an toàn.
5. Mechanical guardrail hiện có.

Sau mỗi nhóm command, chạy lại:

```bash
git status --short
```

Nếu command tạo cache hoặc artifact không được track, ghi nhận và bảo đảm chúng không bị đưa vào baseline. Nếu command thay đổi source hoặc config, dừng lại, xác định nguyên nhân và không giữ thay đổi ngoài ý muốn.

Điền `docs/PROJECT_BASELINE.md` bằng kết quả thực tế:

- command chính xác;
- trạng thái `pass`, `fail` hoặc `not run`;
- exit code hoặc kết quả quan sát được;
- failure signature quan trọng;
- môi trường và dependency liên quan;
- golden journey đã kiểm tra;
- khu vực chưa kiểm tra;
- giới hạn bằng chứng.

Baseline có thể đỏ. Không sửa failure cũ chỉ để làm baseline xanh.

## Bước 5: Phân loại phát hiện

| Phân loại | Điều kiện | Nơi ghi | Hành động trong takeover |
|---|---|---|---|
| Legacy issue | Failure được tái hiện và chứng minh tại đúng baseline revision | `docs/LEGACY_ISSUES.md` | Ghi evidence; không tự sửa nếu người dùng chưa yêu cầu |
| Điểm yếu kiến trúc | Code yếu hoặc thiết kế xấu nhưng chưa có failure cụ thể | `ARCHITECTURE.md` và `docs/QUALITY_SCORE.md` | Ghi hotspot và khoảng trống; không giả thành legacy failure |
| Khu vực chưa kiểm tra | Không thể chạy hoặc chưa đủ môi trường để quan sát | `docs/PROJECT_BASELINE.md` | Ghi lý do và giới hạn bằng chứng; không suy đoán |
| Observation chưa phân loại | Có dấu hiệu failure nhưng chưa đủ bằng chứng về nguồn gốc | `docs/PROJECT_BASELINE.md` trong takeover; kế hoạch active khi observation phát sinh trong task | Ghi bước tái hiện tiếp theo; chưa thêm vào legacy issues |
| Nợ kỹ thuật | Khiếm khuyết đã có quyết định chủ động hoãn | `docs/exec-plans/tech-debt-tracker.md` | Ghi lý do, rủi ro và trigger; không dùng để chứa regression |
| Regression | Failure do task sản phẩm hiện tại tạo ra | Kế hoạch active của task | Không thuộc takeover; phải sửa trước khi hoàn thành task |

Mỗi legacy issue phải có:

- ID `LEGACY-NNN`;
- area;
- failure signature;
- impact;
- status;
- baseline revision;
- baseline evidence;
- reproduction command hoặc steps.

Nếu không tìm thấy legacy failure có đủ bằng chứng, giữ file và ghi rõ rằng chưa có failure nào đủ điều kiện phân loại trong lần tiếp quản này. Không tạo issue giả để lấp template.

Legacy issue được sửa về sau phải chuyển sang `Resolved` và giữ nguyên bằng chứng lịch sử.

## Bước 6: Khởi tạo quality score

Cập nhật `docs/QUALITY_SCORE.md` theo trạng thái thật của từng domain hoặc layer liên quan.

- `A`: rõ ràng, ổn định và có bằng chứng tốt.
- `B`: hoạt động, còn khoảng trống nhỏ.
- `C`: khó thay đổi, thiếu guardrail hoặc chỉ được xác minh một phần.
- `D`: hỏng, nguy hiểm hoặc cấu trúc không đủ rõ để thay đổi an toàn.

Mỗi điểm phải có lý do, evidence hoặc khoảng trống chính. Không nâng điểm chỉ vì failure được ghi thành legacy issue.

## Bước 7: Xử lý placeholder và ví dụ mẫu

Tìm placeholder còn lại trong các file harness:

```bash
grep -RIn '{{[A-Z0-9_][A-Z0-9_]*}}' \
  AGENTS.md ARCHITECTURE.md docs scripts
```

Với mỗi placeholder:

1. Điền giá trị có bằng chứng; hoặc
2. Ghi `Not applicable` cùng lý do; hoặc
3. Ghi `Not run` cùng lý do và đưa giới hạn vào baseline.

Xóa hoặc thay các ví dụ mẫu không đúng với repo đích. Không dùng từ chung chung chỉ để checker pass.

## Bước 8: Review tính toàn vẹn của repo

Chạy:

```bash
git status --short
git diff --check
git diff --stat
git diff
```

Xác nhận:

- chỉ artifact harness dự kiến được thay đổi;
- source code dự án không bị sửa ngoài ý muốn;
- không có dependency update, migration hoặc generated source ngoài phạm vi;
- không có cache hoặc file tạm được đưa vào Git;
- không có token, secret hoặc dữ liệu nhạy cảm trong artifact;
- mọi command trong baseline có kết quả thực tế hoặc lý do `Not run`;
- mọi legacy issue dùng đúng baseline revision;
- code yếu được ghi nhận nhưng chưa bị tự ý sửa.

Nếu có thay đổi ngoài harness mà không được người dùng phê duyệt, chưa được kết thúc takeover.

## Bước 9: Chạy checker và đóng vòng lặp

Chạy:

```bash
./scripts/harness-check.sh
```

Nếu checker trả `FAIL`:

1. Đọc từng failure.
2. Quay lại bước tương ứng trong tài liệu này.
3. Sửa artifact bằng bằng chứng, không bằng nội dung giả.
4. Review lại Git diff.
5. Chạy checker lần nữa.

Lặp lại cho đến khi checker trả exit `0` và có dòng `PASS [summary]`.

Checker chỉ xác nhận cấu hình harness. Nó không thay thế build, test, start hoặc golden journey đã được ghi trong baseline.

## Định nghĩa Sẵn sàng

Repo sẵn sàng nhận task người dùng khi tất cả điều kiện sau đúng:

- mọi conflict cài đặt đã được xử lý;
- baseline ghi đúng revision, branch và working tree;
- architecture, product sense và reliability phản ánh repo thật;
- command đã chạy có kết quả thực tế;
- command chưa chạy có lý do rõ ràng;
- legacy issue có reproduction và evidence tại baseline;
- điểm yếu thiết kế được ghi nhận nhưng không bị tự ý sửa;
- khu vực chưa kiểm tra và giới hạn bằng chứng được nêu rõ;
- quality score ban đầu đã được khởi tạo;
- không còn placeholder bắt buộc hoặc ví dụ sai dự án;
- source và config dự án không bị thay đổi ngoài ý muốn;
- `./scripts/harness-check.sh` trả exit `0`.

Sau khi đạt các điều kiện trên:

- `docs/exec-plans/active/` có thể trống nếu chưa có task đang làm;
- dừng quá trình tiếp quản;
- không tự tạo task sửa legacy issue hoặc điểm yếu kiến trúc;
- chờ người dùng giao task sản phẩm tiếp theo.
