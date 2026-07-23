# Phase 3 — Routing và vòng đời artifact

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

Cập nhật hợp đồng làm việc của agent và vòng đời artifact. Phase này là thay đổi
tài liệu điều khiển, không phải checker enforcement đầy đủ.

## Routing target

### Luôn đọc cho code task không tầm thường

- `ARCHITECTURE.md`
- `docs/VERIFY.md`

### Đọc có điều kiện

- `docs/tasks/active/<task>.md`
- `docs/specs/`
- `docs/decisions/`
- `docs/UI.md`
- `docs/SECURITY.md`
- `docs/TAKEOVER_BASELINE.md`
- `docs/LEGACY_ISSUES.md`
- `docs/KNOWN_DEBT.md`
- `docs/generated/`
- `docs/references/`
- `docs/tasks/completed/` chỉ khi cần lịch sử liên quan.

## Plan trigger

Plan chỉ bắt buộc khi có ít nhất một trigger:

- nhiều phiên;
- từ hai subsystem/domain;
- migration/backfill/data transform;
- public API/external contract;
- breaking change;
- auth/secret/sensitive data;
- rollout/rollback phức tạp;
- nhiều phương án kiến trúc;
- blocker/dependency ngoài;
- người dùng yêu cầu;
- cần handoff.

Task nhỏ không tạo plan.

## Vòng đời plan đã điều chỉnh

```text
create active plan
→ cập nhật khi scope/decision/blocker/verification đổi
→ hoàn tất verification
→ chắt lọc durable knowledge
→ ghi final summary
→ chuyển sang docs/tasks/completed/
→ giữ lâu dài để người dùng theo dõi
```

Không ghi log từng tool call. Completed plan không thay thế spec/ADR/VERIFY.

## Phạm vi

- Viết lại `AGENTS.md` router-only.
- Viết lại `ARCHITECTURE.md` để mô tả kiến trúc thực, không áp layer cố định.
- Hoàn thiện `VERIFY.md`.
- Viết lại `HARNESS_SETUP.md` theo state machine.
- Ghi schema nội dung cho optional artifact.
- Ghi quy tắc active/completed plan.

## Commit độc lập

### Commit 3.1

```text
docs(agents): route code tasks through architecture and verify
```

### Commit 3.2

```text
docs(takeover): define optional artifact creation rules
```

### Commit 3.3

```text
docs(tasks): define selective planning and completed archive lifecycle
```

### Commit 3.4

```text
docs(architecture): remove fixed layering assumptions
```

## Review checklist

- `AGENTS.md` không yêu cầu QUALITY_SCORE hoặc PLANS.
- Không đọc HARNESS_SETUP khi status complete.
- Không tạo file `Not applicable`.
- Không bắt task nhỏ tạo plan.
- Có route tới completed plan nhưng không always-read.
- Completed plan phải có final verification và durable extraction summary.
- Không có câu nào nói xóa completed plan.

## Verification

```bash
./tests/run.sh
git diff --check
```

Bổ sung assertion nội dung trong test để tránh routing bị quay lại hành vi cũ.

## Exit criteria

- Agent mới có thể xác định chính xác khi nào tạo plan.
- Vòng đời completed plan không mâu thuẫn với minimal fresh install.
- Tài liệu không nhắc tên path v1 như nguồn sự thật mới.
