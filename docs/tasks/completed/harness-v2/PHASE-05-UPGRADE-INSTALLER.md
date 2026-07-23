# Phase 5 — Upgrade installer an toàn

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

Cho phép chạy installer trên repo đã có harness v1 mà không tự xóa, ghi đè hoặc
làm mất artifact người dùng. Installer chỉ phát hiện, báo cáo và hướng migration.

## Deprecated inventory

Các path v1 cần phát hiện, nhưng phân loại khác nhau:

### Có thể loại bỏ sau khi chắt lọc

- `docs/QUALITY_SCORE.md`
- `docs/PRODUCT_SENSE.md`
- `docs/DESIGN.md`
- `docs/FRONTEND.md`
- `docs/PLANS.md`
- sample specs/references/generated.

### Cần migrate/rename

- `docs/RELIABILITY.md` → `docs/VERIFY.md`
- `docs/PROJECT_BASELINE.md` → `docs/TAKEOVER_BASELINE.md`
- `docs/product-specs/` → `docs/specs/`
- `docs/design-docs/` → `docs/decisions/`
- `docs/exec-plans/active/` → `docs/tasks/active/`
- `docs/exec-plans/completed/` → `docs/tasks/completed/`
- tech debt tracker → `docs/KNOWN_DEBT.md`

`exec-plans/completed/` không phải dữ liệu được phép xóa. Nó chỉ là path cũ.

## Hành vi installer

- Không tự xóa deprecated path.
- Không tự rename directory chứa dữ liệu người dùng.
- Không ghi đè target mới nếu target đã tồn tại.
- In inventory theo nhóm:
  - `MIGRATE`;
  - `REVIEW_AND_EXTRACT`;
  - `REMOVE_SAMPLE`;
  - `CONFLICT`.
- Giữ safe install, dry-run, overwrite backup.
- Prompt cuối dựa trên `takeover_status`.
- Workspace mode không bị thay đổi ngoài code dùng chung thực sự cần thiết.

## Commit độc lập

### Commit 5.1

```text
feat(installer): report deprecated harness v1 artifacts
```

### Commit 5.2

```text
feat(installer): render conditional takeover and migration prompt
```

### Commit 5.3

```text
test(installer): preserve customized v1 artifacts during upgrade
```

### Commit 5.4

```text
test(installer): preserve completed plans and report migration target
```

## Test bắt buộc

- v1 repo có file customized: không đổi checksum.
- `--dry-run`: không tạo/xóa/rename.
- `--overwrite`: chỉ backup và ghi core managed file; không đụng archive.
- source và target cùng tồn tại: báo conflict, giữ cả hai.
- completed plan count không giảm.
- reinstall v2 không làm metadata quay về pending nếu target đã complete.
- install-from-github giữ prompt và exit code đúng.

## Verification

```bash
./tests/run.sh
git diff --check
```

## Exit criteria

- Upgrade không mất byte dữ liệu người dùng.
- Deprecated inventory có hướng hành động cụ thể.
- Completed plan được đánh dấu MIGRATE, không REMOVE.
