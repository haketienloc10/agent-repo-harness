# Migration Harness v1 sang v2

Guide này dùng cho repository đã cài harness v1. Cleanup trong repository
`agent-repo-harness` chỉ xóa default khỏi `repo-template/`; installer và guide
này không xóa, rename hoặc ghi đè file trong repository người dùng.

Xem [release notes v2.0.0](./RELEASE_NOTES_V2.md) để biết breaking changes,
fresh-install structure, compatibility và rollback guidance.

## Nguyên tắc an toàn

1. Commit hoặc backup working tree trước khi migration.
2. Chạy installer với `--dry-run` và lưu deprecated inventory.
3. Lập audit cho mọi path v1 trước khi copy hoặc chắt lọc nội dung.
4. Copy sang path v2, xác minh, rồi mới đề xuất xóa source trong một review
   riêng. Không có bước xóa tự động trong guide này.
5. Nếu source và target cùng tồn tại, đánh dấu `conflict`, giữ cả hai và merge
   thủ công sang một file mới hoặc target đã review.
6. File chưa phân loại được đánh dấu `UNCLASSIFIED`, `review status=pending` và
   được giữ nguyên.

## Mapping

| Source v1 | Target v2 | Classification | Cách xử lý |
|---|---|---|---|
| `docs/RELIABILITY.md` | `docs/VERIFY.md` | `MIGRATE_EXTRACT` | Chắt lọc canonical command, evidence và giới hạn xác minh. |
| `docs/PROJECT_BASELINE.md` | `docs/TAKEOVER_BASELINE.md` | `MIGRATE_COPY` | Giữ snapshot bất biến; chỉ sửa link/metadata có chủ ý. |
| `docs/product-specs/*.md` | `docs/specs/*.md` | `MIGRATE_REVIEW` | Giữ spec repo-specific; sample giả được đề xuất xóa sau review. |
| `docs/design-docs/*.md` | `docs/decisions/*.md` | `MIGRATE_REVIEW` | Giữ decision repo-specific; không chuyển core belief chung. |
| `docs/FRONTEND.md` | `docs/UI.md` | `MIGRATE_EXTRACT` | Chỉ tạo khi có rule UI cụ thể của repository. |
| `docs/QUALITY_SCORE.md` | source of truth phù hợp | `REVIEW_AND_EXTRACT` | Không copy điểm chữ; chuyển gap cụ thể sang architecture, debt, issue, legacy hoặc verify. |
| `docs/exec-plans/active/*.md` | `docs/tasks/active/*.md` | `MIGRATE_COPY` | Giữ task thực sự đang active và cập nhật link nội bộ. |
| `docs/exec-plans/completed/*.md` | `docs/tasks/completed/*.md` | `MIGRATE_COPY` | Copy toàn bộ, bảo toàn số file và checksum nếu không sửa metadata/link. |
| `docs/exec-plans/tech-debt-tracker.md` | `docs/KNOWN_DEBT.md` hoặc issue tracker | `MIGRATE_EXTRACT` | Chỉ chuyển debt đang mở với evidence, risk và review trigger. |
| `docs/SECURITY.md` | `docs/SECURITY.md` | `KEEP_REVIEW` | Giữ rule repo-specific; bỏ placeholder/guidance chung sau review. |
| `docs/references/*` | `docs/references/*` | `KEEP_OR_REMOVE_SAMPLE` | Chỉ giữ reference có source, version/retrieved date, phạm vi và refresh trigger. |
| `docs/generated/*` | `docs/generated/*` | `KEEP_OR_REMOVE_GENERATED` | Chỉ giữ artifact có source, generator command/version và refresh trigger. |

## Audit bắt buộc

Tạo một TSV hoặc CSV có đúng các field sau cho từng source:

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

Dùng SHA-256 cho hai cột hash. Với extraction nhiều đích, liệt kê từng path,
phân tách bằng dấu `;`. Với file được giữ byte-identical, hai hash phải bằng
nhau. Với thay đổi link hoặc metadata có chủ ý, hash có thể khác nhưng audit
phải ghi đích durable cụ thể và `review status=reviewed`.

Ví dụ tạo inventory read-only:

```bash
find docs -type f -print0 | sort -z | xargs -0 sha256sum > /tmp/harness-v1-before.sha256
./install.sh --target /path/to/repo --dry-run > /tmp/harness-v1-inventory.txt
```

Không dùng output trong `/tmp` làm bằng chứng lâu dài. Sau review, lưu audit đã
điền trong repository đích, ví dụ `docs/migration/harness-v1-to-v2-audit.tsv`.

## Trình tự migration

### 1. Khóa inventory và completed archive

Ghi count và checksum trước khi thay đổi:

```bash
find docs/exec-plans/completed -maxdepth 1 -type f -name '*.md' -print0 |
  sort -z | tee /tmp/harness-v1-completed-files |
  xargs -0 sha256sum > /tmp/harness-v1-completed.sha256
```

Không tính file lồng sâu hoặc file không phải Markdown vào completed-plan count;
vẫn đưa chúng vào audit và giữ nguyên nếu chưa phân loại.

### 2. Copy trước, xác minh sau

Tạo parent v2 cần thiết và dùng `cp -p` cho artifact cần bảo toàn. Nếu target đã
tồn tại, không copy đè. Đánh dấu conflict trong audit, giữ source và target, rồi
review merge riêng.

Completed plan được copy nguyên byte khi không cần đổi link. Nếu cần đổi link
nội bộ, lưu hash cũ/mới, liệt kê link đã đổi trong review và xác minh target
được link tới tồn tại.

### 3. Chắt lọc durable knowledge

- Từ `QUALITY_SCORE.md`, bỏ `A/B/C/D` và benchmark score. Chuyển từng gap cụ thể:
  boundary vào `ARCHITECTURE.md` hoặc `docs/decisions/`; command/evidence vào
  `docs/VERIFY.md`; failure baseline vào `docs/LEGACY_ISSUES.md`; debt đang mở
  vào `docs/KNOWN_DEBT.md`; work item vào issue tracker hoặc active plan.
- Từ completed plan, chuyển contract và decision còn hiệu lực sang
  `docs/specs/`, `docs/decisions/`, `ARCHITECTURE.md`, `docs/VERIFY.md`,
  `docs/SECURITY.md` hoặc `docs/KNOWN_DEBT.md`. Completed plan vẫn được giữ.
- Giữ security rule cụ thể của repository. Không thay nó bằng template chung.
- Reference mẫu và generated schema không có generator chỉ được đánh dấu
  `proposed-remove`; không xóa cho đến khi review chấp thuận.

### 4. Assertions trước khi review xóa source

```bash
test "$(find docs/exec-plans/completed -maxdepth 1 -type f -name '*.md' | wc -l)" \
  -eq "$(find docs/tasks/completed -maxdepth 1 -type f -name '*.md' | wc -l)"
```

Ngoài count, review phải xác nhận:

- checksum completed plan khớp, hoặc mọi thay đổi metadata/link được ghi rõ;
- mọi link nội bộ đã đổi trỏ tới file tồn tại;
- mỗi extraction có target path cụ thể;
- không target conflict nào bị overwrite;
- mọi `UNCLASSIFIED` vẫn tồn tại;
- audit không còn dòng `review status=pending` trước khi xóa source.

Chỉ sau các assertion này, con người có thể phê duyệt một commit xóa source v1
đã được accounting đầy đủ. Việc xóa đó không thuộc installer.

## Rollback

Giữ tag/commit v1 cùng inventory/checksum trước migration. Safe install không
xóa source v1, nên có thể bỏ riêng core v2 chưa được chỉnh sửa nếu cần quay lại.
Nếu đã dùng `--overwrite`, phục hồi core file từ
`.harness/backups/<timestamp>/`. Không xóa completed plan, conflict target hoặc
artifact chưa phân loại trong quá trình rollback.
