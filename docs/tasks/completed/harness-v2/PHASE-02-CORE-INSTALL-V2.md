# Phase 2 — Core install v2 vertical slice

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

Chuyển fresh install repository mode sang cấu trúc v2 tối giản theo một vertical
slice hoàn chỉnh: metadata, template core, manifest, installer và tests cùng
khớp nhau.

## Target fresh install

```text
.harness-required-files
.harness/installation.json
AGENTS.md
ARCHITECTURE.md
docs/HARNESS_SETUP.md
docs/VERIFY.md
scripts/harness-check.sh
```

`docs/TAKEOVER_BASELINE.md` chưa được cài sẵn; nó được tạo trong takeover.

## Thứ tự commit

### Commit 2.1

```text
feat(installer): emit harness installation metadata v2
```

- đổi metadata sang `harness/installation/v2`;
- ghi source/ref thực tế;
- status ban đầu `pending`;
- giữ metadata khi reinstall không overwrite;
- backup trước overwrite.

Commit này vẫn dùng manifest cũ, nên checker dual-schema từ Phase 1 là điều kiện
tiên quyết.

### Commit 2.2

```text
feat(template): add v2 core verification and takeover contracts
```

- thêm `docs/VERIFY.md`;
- cập nhật `docs/HARNESS_SETUP.md`;
- chuẩn bị contract tạo `docs/TAKEOVER_BASELINE.md`;
- cập nhật `AGENTS.md` ở mức tối thiểu để nhận biết status v2;
- chưa xóa file v1.

### Commit 2.3

```text
chore(template): switch repository manifest to minimal v2 core files
```

- thay `.harness-required-files`;
- không đưa optional artifact vào manifest;
- bảo đảm mọi entry có source hoặc được installer render;
- không xóa file cũ khỏi source tree ở commit này.

### Commit 2.4

```text
test(installer): verify minimal v2 fresh install
```

Assertions:

- đúng 7 core files;
- không có QUALITY_SCORE/PRODUCT_SENSE/PLANS/DESIGN/FRONTEND;
- không có sample spec/reference/generated;
- metadata v2 hợp lệ;
- checker ở `pending` không báo ready;
- executable bit của checker được giữ.

## File dự kiến thay đổi

- `install.sh`
- `.harness-required-files`
- `repo-template/AGENTS.md`
- `repo-template/ARCHITECTURE.md`
- `repo-template/docs/HARNESS_SETUP.md`
- `repo-template/docs/VERIFY.md`
- `tests/test-installer.sh`
- `tests/test-e2e.sh`
- `tests/lib.sh`

## Không làm trong phase này

- Chưa xóa file v1 khỏi source template.
- Chưa implement toàn bộ optional validators.
- Chưa phát hiện deprecated artifact trong upgrade target.
- Chưa đổi toàn bộ tài liệu root/index.

## Verification

```bash
./tests/run.sh
git diff --check
```

## Rollback

Có thể revert Phase 2 mà không ảnh hưởng repo đã cài trước đó vì installer không
tự sửa target trừ khi người dùng chạy lại. Metadata target đã sinh v2 vẫn được
checker Phase 1 hiểu.

## Exit criteria

- Fresh install chỉ có core files.
- Reinstall không đổi metadata đã cấu hình.
- Checker hiểu output installer.
- Source tree có thể còn file cũ nhưng chúng không được cài.
