# Gói Harness Nâng cao OpenAI

Gói này tập hợp thiết kế harness được mô tả trong bài viết "Harness Engineering" của OpenAI thành một bộ tệp bắt đầu có thể áp dụng và cấu trúc SOP đi kèm.

## Tại sao Nó Tồn tại

Bài viết harness engineering mô tả các nguyên tắc cấp cao: kho lưu trữ là hệ thống ghi chép, bộ nhớ ngoại hóa, kiểm tra cơ học thay vì ký ức, và các vòng phản hồi phục hồi. Gói này biến các nguyên tắc đó thành:

- bộ tài liệu cấu trúc rõ ràng cho một repo thực tế
- tính điểm chất lượng theo domain sản phẩm và lớp kiến trúc
- thư mục tài liệu tham khảo thân thiện với model
- các quy trình vận hành chuẩn cho kiến trúc, thu thập kiến thức, và xác minh runtime

## Bố cục Bắt đầu Có sẵn

Gói bắt đầu trong [`repo-template/`](./repo-template/index.md) phản ánh cấu trúc dưới đây:

```text
AGENTS.md
ARCHITECTURE.md
docs/
├── design-docs/
│   ├── index.md
│   └── core-beliefs.md
├── exec-plans/
│   ├── active/
│   ├── completed/
│   └── tech-debt-tracker.md
├── generated/
│   └── db-schema.md
├── product-specs/
│   ├── index.md
│   └── new-user-onboarding.md
├── references/
│   ├── design-system-reference-llms.txt
│   ├── nixpacks-llms.txt
│   └── uv-llms.txt
├── DESIGN.md
├── FRONTEND.md
├── PLANS.md
├── PRODUCT_SENSE.md
├── QUALITY_SCORE.md
├── RELIABILITY.md
└── SECURITY.md
```

## Cài đặt an toàn

Repo đích phải là root của một Git repository đã tồn tại. Installer chỉ sao chép
các file harness; nó không chạy build, test, lint, migration hoặc source code dự án.

```bash
./install.sh --target /path/to/repo --dry-run
./install.sh --target /path/to/repo
```

File hiện hữu được báo là `Conflicts` và giữ nguyên theo mặc định. Chỉ dùng
`--overwrite` sau khi review conflict; installer sẽ tạo bản sao dưới
`.harness/backups/` trước khi thay file.

## Takeover workflow

Sau khi cài:

1. Xử lý mọi `Conflicts`, rồi đọc `docs/HARNESS_SETUP.md` trong repo đích.
2. Ghi revision bằng `git rev-parse HEAD` trước khi chạy command khảo sát.
3. Khảo sát read-only, xác định bootstrap, verify, start command và mechanical guardrail.
4. Chạy các command an toàn đã chọn và điền kết quả thực tế vào `docs/PROJECT_BASELINE.md`.
5. Chỉ ghi failure được chứng minh tại đúng baseline revision vào `docs/LEGACY_ISSUES.md`.
6. Tạo ít nhất một kế hoạch trong `docs/exec-plans/active/` nếu còn task đang làm, rồi chạy checker. Sau khi hoàn thành task cuối cùng và chuyển plan sang `completed/`, `active/` có thể trống.

```bash
cd /path/to/repo
./scripts/harness-check.sh
```

Checker trả exit `0` khi cấu hình harness không có `FAIL`. Một legacy issue hợp lệ
được báo `BASELINE`, nên failure sẵn có không làm checker fail. Checker không chạy
command dự án.

## Baseline và phân loại failure

- **Legacy issue**: failure có reproduction và evidence tại đúng baseline revision;
  giữ trong `LEGACY_ISSUES.md`, kể cả sau khi chuyển thành `Resolved`.
- **Regression**: failure do task hiện tại hoặc thay đổi sau baseline tạo ra; phải
  sửa trước khi hoàn thành, không được chuyển thành legacy issue hoặc technical debt.
- **Observation chưa phân loại**: chưa đủ bằng chứng về nguồn gốc; giữ trong kế hoạch
  active cùng bước phân loại tiếp theo.
- **Technical debt**: khiếm khuyết được chủ động hoãn; không phải nơi hợp thức hóa
  regression mới.

## Chạy test của harness

Từ root repo nguồn, chạy một command:

```bash
./tests/run.sh
```

Test tạo Git repository tạm và bao phủ installer, tám tình huống checker, cùng
workflow end-to-end trên [`examples/legacy-project/`](./examples/legacy-project/README.md).
Fixture chứng minh build pass trong khi test và lint có legacy failure đã biết;
source fixture vẫn nguyên vẹn sau khi cài.

## Thư viện SOP

Thư mục [`sops/`](./sops/index.md) biến các sơ đồ của bài viết thành các quy trình vận hành từng bước:

- thiết lập kiến trúc domain phân lớp
- mã hóa kiến thức ẩn vào kho lưu trữ
- stack observability cục bộ và workflow vòng phản hồi
- vòng lặp xác minh Chrome DevTools cho công việc UI

## Nguyên tắc Thiết kế

- Điểm đầu vào ngắn, tài liệu liên kết sâu hơn
- Kho lưu trữ là hệ thống ghi chép
- Kiểm tra cơ học tốt hơn các quy tắc được nhớ
- Kế hoạch và lịch sử chất lượng nằm bên cạnh mã
- Dọn dẹp và đơn giản hóa là trách nhiệm hạng nhất

Gói này có chủ ý theo quan điểm, nhưng nó vẫn nên được điều chỉnh cho dự án của bạn thay vì sao chép mù quáng.
