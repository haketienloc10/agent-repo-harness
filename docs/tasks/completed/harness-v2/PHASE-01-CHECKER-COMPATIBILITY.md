# Phase 1 — Checker compatibility foundation

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

Làm checker hiểu được cả cấu trúc v1 và v2 trước khi template/installer chuyển
sang v2. Đây là lớp tương thích bắt buộc để các commit sau không tạo trạng thái
“installer sinh ra thứ checker chưa hiểu”.

## Thiết kế

### Chế độ v1

Khi metadata không có `schema: harness/installation/v2`, checker giữ hành vi v1
đủ để repo cũ tiếp tục được kiểm tra.

### Chế độ v2

Khi metadata có schema v2, checker đọc:

- `takeover_status`: `pending`, `blocked`, `complete`;
- `baseline_revision`;
- `takeover_completed_at`;
- path v2 như `docs/VERIFY.md`, `docs/TAKEOVER_BASELINE.md`.

### Exit code

| Trạng thái | Kết quả |
|---|---|
| `pending` | non-zero, chưa ready |
| `blocked` | non-zero, in `BLOCKED` với lý do |
| `complete` hợp lệ | `0` |
| schema/metadata sai | non-zero, `FAIL` |

## Phạm vi

- Refactor checker thành các nhóm:
  - report/summary;
  - metadata parsing;
  - path resolution;
  - core validation;
  - state validation.
- Hỗ trợ v1/v2 path alias.
- Thêm trạng thái output `PASS`, `WARN`, `FAIL`, `BLOCKED`.
- Giữ `BASELINE` của v1 trong compatibility mode nếu cần; v2 dùng PASS/WARN
  rõ ràng.
- Không thay manifest hoặc installer.

## Commit độc lập

### Commit 1.1

```text
refactor(checker): isolate reporting and metadata helpers
```

Không đổi output kỳ vọng. Chỉ tách hàm để giảm diff ở commit sau.

### Commit 1.2

```text
feat(checker): support installation metadata v1 and v2
```

- parse JSON bằng công cụ có sẵn hoặc fallback rõ ràng;
- không dùng grep mơ hồ cho JSON;
- validate schema và enum;
- resolve file path theo schema.

### Commit 1.3

```text
test(checker): cover pending blocked complete and legacy compatibility
```

Test ít nhất:

- v1 configured repo vẫn pass;
- v2 pending không ready;
- v2 blocked yêu cầu blocker;
- v2 complete thiếu baseline fail;
- v2 complete baseline mismatch fail;
- v2 complete hợp lệ pass.

## File dự kiến thay đổi

- `repo-template/scripts/harness-check.sh`
- `tests/lib.sh`
- `tests/test-checker.sh`

## Rủi ro

- Máy đích không có `jq`.
- Metadata v1 đã được người dùng chỉnh thủ công.
- Output mới làm test downstream phụ thuộc chuỗi cũ bị hỏng.

## Biện pháp

- Không bắt buộc `jq` nếu installer không tuyên bố dependency này.
- Parser phải fail có hướng dẫn khi JSON không hợp lệ.
- Compatibility mode giữ thông báo chính của v1 trong phase này.

## Verification

```bash
./tests/run.sh
git diff --check
```

## Exit criteria

- Checker chạy được trên fixture v1 và v2.
- Chưa có thay đổi fresh-install output.
- Không có test v1 bị xóa để làm suite xanh.
