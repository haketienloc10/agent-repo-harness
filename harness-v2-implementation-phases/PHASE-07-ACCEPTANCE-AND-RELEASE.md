# Phase 7 — Acceptance matrix và release gate

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

Xác minh toàn bộ luồng thay vì chỉ test từng helper. Phase này không mở rộng scope
sản phẩm; nó đóng các lỗ hổng integration và chuẩn bị phát hành v2.

## Ma trận E2E

### Repo loại A — Library

- không UI;
- không DB;
- không service;
- start dùng `Not applicable — <reason>`;
- không optional artifact;
- takeover complete và checker pass.

### Repo loại B — Frontend

- có UI.md repo-specific;
- có spec behavior;
- optional validator pass;
- broken spec link fail.

### Repo loại C — Backend auth + DB

- có SECURITY.md;
- architecture ghi data ownership;
- generated schema chỉ tồn tại nếu có generator;
- baseline/legacy classification đúng.

### State matrix

- pending;
- blocked có blocker;
- complete;
- invalid metadata;
- baseline mismatch.

### Upgrade matrix

- clean v1;
- customized v1;
- v1 + completed plans;
- v1/v2 path conflict;
- reinstall v2;
- dry-run;
- overwrite backup.

## Commit độc lập

### Commit 7.1

```text
test(e2e): cover library frontend and backend takeover profiles
```

### Commit 7.2

```text
test(e2e): cover v1 upgrade and completed-plan preservation
```

### Commit 7.3

```text
docs: publish harness structure v2 release notes
```

### Commit 7.4

```text
chore: bump harness version to 2.0.0
```

Chỉ bump version sau khi toàn bộ gate xanh.

## Release gate

```bash
./tests/run.sh
git diff --check
```

Nếu có shellcheck:

```bash
shellcheck install.sh install-from-github.sh repo-template/scripts/harness-check.sh tests/*.sh
```

Kiểm tra thủ công tối thiểu:

1. Fresh install vào repo rỗng.
2. Chạy checker khi pending.
3. Điền takeover fixture và chuyển complete.
4. Chạy checker từ nested directory.
5. Upgrade fixture v1 có completed plan.
6. So sánh inventory/checksum trước và sau.
7. Xác nhận workspace mode không regression.

## Definition of Done

- Không test nào bị skip để phát hành.
- Fresh install có tối đa 7 core files.
- Optional absent không fail.
- Completed plan được giữ.
- Upgrade không tự xóa.
- Checker phân biệt PASS/WARN/FAIL/BLOCKED.
- README/index/migration guide khớp hành vi.
- Release note nêu breaking changes và migration path.

## Rollback strategy

- Tag commit cuối v1 trước khi release.
- Không phát hành installer v2 nếu migration fixture chưa xanh.
- Revert version bump không đồng nghĩa xóa support v2 checker; compatibility có thể
  được giữ để repo đã thử v2 không bị khóa.
