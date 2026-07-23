# Kế hoạch triển khai Harness Structure v2

> Bộ tài liệu này phân rã “Spec: Tối giản hóa Repo Harness và Làm rõ Vòng đời Artifact”
> thành các phase triển khai có thể review và commit độc lập.
>
> Quyết định được ưu tiên theo yêu cầu mới nhất:
> - execution plan hoàn thành **vẫn được lưu lâu dài** trong `docs/tasks/completed/`;
> - trước khi chuyển plan sang `completed/`, tri thức lâu bền vẫn phải được chắt lọc
>   sang spec, decision, architecture, verify, security hoặc debt tracker phù hợp;
> - fresh install không tạo thư mục `completed/` rỗng. Thư mục chỉ xuất hiện khi
>   có plan hoàn thành đầu tiên.


## Mục tiêu của cách chia phase

1. Mỗi commit có một mục đích rõ ràng và có thể review riêng.
2. `./tests/run.sh` phải xanh sau từng commit.
3. Không đổi đồng thời producer và consumer khi chưa có lớp tương thích.
4. Không xóa artifact cũ trước khi có mapping migration và test bảo toàn dữ liệu.
5. Không làm mất execution plan đã hoàn thành.
6. Fresh install đạt cấu trúc tối giản, nhưng upgrade từ v1 vẫn an toàn.

## Thứ tự phase

| Phase | Tên | Kết quả chính | Điều kiện bắt đầu |
|---|---|---|---|
| 0 | Khóa hợp đồng và characterization | Có baseline test bảo vệ hành vi v1 | Bắt đầu ngay |
| 1 | Checker compatibility foundation | Checker hiểu metadata/path v1 và v2 | Phase 0 xanh |
| 2 | Core install v2 vertical slice | Fresh install tạo đúng 7 core files | Phase 1 xanh |
| 3 | Routing và vòng đời artifact | AGENTS/HARNESS_SETUP phản ánh mô hình v2 | Phase 2 xanh |
| 4 | Optional artifact validation | Checker kiểm tra có điều kiện | Phase 3 xanh |
| 5 | Upgrade installer an toàn | Phát hiện deprecated, không tự xóa | Phase 4 xanh |
| 6 | Cleanup template và migration | Xóa sample dư, bảo toàn dữ liệu v1 | Phase 5 xanh |
| 7 | Acceptance matrix và release gate | E2E đầy đủ, sẵn sàng phát hành v2 | Phase 6 xanh |

## Quy tắc commit chung

- Không commit trạng thái mà installer tạo file mới nhưng checker chưa hiểu file đó.
- Không commit manifest mới khi source template chưa có đủ file tương ứng.
- Không xóa hoặc rename artifact chứa dữ liệu người dùng trong cùng commit với
  thay đổi installer tự động.
- Mỗi commit phải kèm test trực tiếp cho hành vi vừa đổi.
- Không dùng “cleanup” để che giấu thay đổi hành vi.
- Mọi rename có thay đổi vai trò phải được review như migration nội dung, không
  chỉ là `git mv`.

## Cổng kiểm tra sau mỗi commit

```bash
./tests/run.sh
git diff --check
```

Khuyến nghị thêm khi môi trường có sẵn:

```bash
shellcheck install.sh install-from-github.sh repo-template/scripts/harness-check.sh tests/*.sh
```

## Danh sách file trong gói

- `00-SPEC-COVERAGE-MATRIX.md`
- `PHASE-00-CONTRACT-AND-CHARACTERIZATION.md`
- `PHASE-01-CHECKER-COMPATIBILITY.md`
- `PHASE-02-CORE-INSTALL-V2.md`
- `PHASE-03-ROUTING-AND-LIFECYCLE.md`
- `PHASE-04-OPTIONAL-VALIDATION.md`
- `PHASE-05-UPGRADE-INSTALLER.md`
- `PHASE-06-CLEANUP-AND-MIGRATION.md`
- `PHASE-07-ACCEPTANCE-AND-RELEASE.md`
