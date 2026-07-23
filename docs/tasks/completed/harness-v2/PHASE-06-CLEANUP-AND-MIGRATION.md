# Phase 6 — Cleanup template và migration bảo toàn dữ liệu

> Bộ tài liệu này phân rã “Spec: Tối giản hóa Repo Harness và Làm rõ Vòng đời Artifact”
> thành các phase triển khai có thể review và commit độc lập.
>
> Quyết định được ưu tiên theo yêu cầu mới nhất:
> - execution plan hoàn thành **vẫn được lưu lâu dài** trong `docs/tasks/completed/`;
> - trước khi chuyển plan sang `completed/`, tri thức lâu bền vẫn phải được chắt lọc
>   sang spec, decision, architecture, verify, security hoặc debt tracker phù hợp;
> - fresh install không tạo thư mục `completed/` rỗng. Thư mục chỉ xuất hiện khi
>   có plan hoàn thành đầu tiên.


## Mục tiêu

Sau khi fresh install, checker và upgrade installer đã an toàn, mới xóa artifact
dư khỏi source template và cập nhật toàn bộ tài liệu. Đồng thời cung cấp đường
migration có thể kiểm chứng.

## Cleanup source template

Xóa khỏi template cài mới:

- `QUALITY_SCORE.md`
- `PRODUCT_SENSE.md`
- `PLANS.md`
- `DESIGN.md`
- `FRONTEND.md`
- sample onboarding
- sample references Nixpacks/uv/design-system
- generated DB schema mẫu
- core-beliefs không thuộc repo đích.

Không xóa bất kỳ file nào trong target repo người dùng.

## Migration mapping

| Nguồn v1 | Đích v2 | Chính sách |
|---|---|---|
| RELIABILITY | VERIFY | Chắt lọc canonical commands |
| PROJECT_BASELINE | TAKEOVER_BASELINE | Snapshot bất biến |
| product-specs | specs | Bỏ sample giả |
| design-docs | decisions | Chỉ giữ quyết định repo-specific |
| FRONTEND | UI | Chỉ khi có UI rule thực |
| QUALITY_SCORE | architecture/debt/issue/legacy/verify | Không chuyển điểm chữ |
| exec-plans/active | tasks/active | Chỉ task đang active |
| exec-plans/completed | tasks/completed | Bảo toàn toàn bộ plan |
| tech-debt-tracker | KNOWN_DEBT/issue tracker | Chỉ debt đang mở |
| references | references | Thêm metadata |
| generated | generated | Chỉ giữ khi có generator |

## Cách đảm bảo không mất thông tin

Tạo migration audit/report cho mỗi target repo:

```text
source path
classification
target path
content hash before
content hash after
durable knowledge extracted to
conflict status
review status
```

Không bắt buộc tự động mutate. Một script dry-run/audit hoặc guide thao tác rõ ràng
được ưu tiên hơn migration tự động phá hủy.

## Commit độc lập

### Commit 6.1

```text
docs: add harness v1 to v2 migration guide
```

### Commit 6.2

```text
test: add migration fixture with customized and completed artifacts
```

### Commit 6.3

```text
chore(template): remove deprecated default artifacts
```

### Commit 6.4

```text
docs: update repository indexes and source-of-truth map
```

## Fixture migration bắt buộc

Fixture phải có:

- QUALITY_SCORE với điểm và gap cụ thể;
- completed plan chứa decision + verification;
- custom security rule;
- sample reference;
- generated schema không có generator;
- active plan;
- legacy issue;
- file target mới đã tồn tại để tạo conflict.

Kỳ vọng:

- điểm chữ bị bỏ, gap cụ thể được mapping;
- completed plan vẫn tồn tại tại target;
- security rule repo-specific được giữ;
- sample/reference không dùng được đề xuất xóa;
- generated không generator được đề xuất xóa;
- conflict không overwrite.

## Verification

```bash
./tests/run.sh
git diff --check
```

Ngoài ra kiểm tra link:

```bash
grep -R "docs/RELIABILITY.md\|docs/PROJECT_BASELINE.md\|docs/product-specs\|docs/design-docs"   README.md index.md repo-template sops examples tests
```

Mọi kết quả còn lại phải được phân loại là migration reference có chủ ý.

## Exit criteria

- Source template không còn artifact mặc định dư.
- Root docs không link hỏng.
- Migration fixture chứng minh completed plan và durable knowledge được bảo toàn.
