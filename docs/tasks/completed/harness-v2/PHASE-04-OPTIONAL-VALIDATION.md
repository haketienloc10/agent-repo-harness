# Phase 4 — Optional artifact validation

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

Biến mô hình “optional nhưng có hợp đồng” thành kiểm tra cơ học. File không tồn
tại không làm checker fail; file đã tồn tại phải đạt schema tối thiểu.

## Nhóm validator

### Specs

- thư mục tồn tại phải có ít nhất một spec;
- index link hợp lệ;
- spec có scope, behavior, acceptance, out-of-scope, update trigger.

### Decisions

- ADR status hợp lệ;
- index link hợp lệ;
- có context, decision, consequences, verification/enforcement.

### UI và Security

- không placeholder;
- có rule/boundary repo-specific;
- nội dung chỉ là best-practice chung tạo WARN, không giả PASS.

### Legacy và Debt

- legacy có failure signature, reproduction, baseline revision/evidence;
- v2 status legacy chỉ `Accepted` hoặc `In progress`;
- debt có evidence, risk, owner/tracking, review trigger;
- không chứa resolved item như state hiện tại.

### Tasks

- active không bắt buộc tồn tại;
- active plan có Goal, Scope, Current state, Next action, Verification,
  Durable knowledge to extract;
- completed plan được phép tồn tại lâu dài;
- completed plan có final outcome, verification evidence, durable extraction;
- checker không quét toàn bộ completed archive cho mọi check nặng.

### Generated và References

- generated có source, command, version/date, refresh trigger;
- reference có source, version/retrieved-at, applies-to, refresh trigger.

## Commit độc lập

### Commit 4.1

```text
feat(checker): validate optional specs decisions ui and security
```

### Commit 4.2

```text
feat(checker): validate legacy debt and task lifecycle
```

### Commit 4.3

```text
feat(checker): validate generated artifacts and references
```

### Commit 4.4

```text
test(checker): add optional artifact matrix
```

Mỗi commit phải có test cùng nhóm validator, không dồn test đến cuối nếu commit
trung gian làm suite đỏ.

## Output policy

- Không in hàng chục PASS cho concern không tồn tại.
- Optional absent: tối đa một summary ngắn hoặc im lặng.
- Placeholder: FAIL có path và line.
- Nội dung chung chung: WARN có hướng sửa.
- Blocker takeover: BLOCKED, không masquerade thành FAIL cấu hình.

## Regression classification tests

1. Failure có tại baseline → legacy hợp lệ.
2. Failure do thay đổi mới → không được đưa legacy/debt.
3. Failure chưa rõ → observation trong active plan hoặc issue điều tra.
4. Resolved legacy → không bắt buộc giữ trong LEGACY_ISSUES.
5. Completed task plan → archive giữ lại, không always-read.

## Verification

```bash
./tests/run.sh
git diff --check
```

## Exit criteria

- Optional absent không fail.
- Optional invalid fail đúng vị trí.
- Completed archive được hỗ trợ và không bị cấm.
- Checker v2 không còn quality-score check.
