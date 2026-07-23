# Phase 0 — Khóa hợp đồng và characterization

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

Đóng băng hành vi hiện tại trước khi refactor. Phase này không thay đổi output
installer/checker; nó chỉ làm rõ những gì phải được bảo toàn và bổ sung test
characterization cho v1.

## Vì sao phải làm trước

Hiện tại:

- manifest bắt buộc nhiều artifact;
- installer sinh metadata v1;
- checker đọc trực tiếp tên file v1;
- test hard-code các path như `docs/RELIABILITY.md`,
  `docs/PROJECT_BASELINE.md`, `docs/exec-plans/*`.

Nếu đổi tên trước khi có characterization, regression có thể bị nhầm thành thay
đổi dự kiến.

## Phạm vi

- Ghi decision lock cho Harness Structure v2.
- Ghi rõ completed plan tiếp tục được archive.
- Bổ sung assertion cho hành vi v1 hiện tại:
  - safe install;
  - overwrite có backup;
  - reinstall không đổi metadata;
  - checker chạy từ nested directory;
  - completed plan được chấp nhận;
  - legacy evidence không làm checker fail.
- Tạo helper fixture phân biệt `make_v1_repo` và `make_v2_repo`, nhưng chưa bật
  test v2 yêu cầu production code hỗ trợ.

## Ngoài phạm vi

- Không sửa manifest.
- Không đổi metadata.
- Không đổi checker output.
- Không xóa hoặc rename artifact.

## Commit độc lập

### Commit 0.1

```text
docs: lock harness v2 migration decisions
```

Nội dung:

- thêm implementation decision;
- ghi target file map;
- ghi quy tắc completed archive;
- ghi invariants không được phá.

### Commit 0.2

```text
test: characterize v1 installer and checker contracts
```

Nội dung:

- tăng assertion trong `tests/test-installer.sh`;
- tăng assertion trong `tests/test-checker.sh`;
- tăng assertion trong `tests/test-e2e.sh`;
- tách helper fixture nếu cần, không đổi production behavior.

## File dự kiến thay đổi

- `docs/...` hoặc plan triển khai của chính repo harness
- `tests/lib.sh`
- `tests/test-installer.sh`
- `tests/test-checker.sh`
- `tests/test-e2e.sh`

## Verification

```bash
./tests/run.sh
git diff --check
```

## Exit criteria

- Toàn bộ test hiện tại vẫn xanh.
- Có test chứng minh completed plan hiện được giữ và checker chấp nhận.
- Có danh sách invariant v1 để Phase 1 dùng làm regression guard.
- Không có file production bị thay đổi ngoài tài liệu quyết định.
