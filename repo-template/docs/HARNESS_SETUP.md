# Thiết lập Harness và Tiếp quản Repo

Tài liệu này hướng dẫn thiết lập hồ sơ tiếp quản cho một repo đang vận hành. Mục tiêu là ghi lại trạng thái hiện hữu bằng bằng chứng, không tự sửa source code, dữ liệu, cấu hình runtime hoặc các failure đã có.

## Nguyên tắc an toàn

- Bắt đầu bằng khảo sát read-only. Không format, migration, update dependency, generate code, commit, reset hoặc cleanup trong lúc thu thập baseline.
- Không chạy command production hoặc command phá hủy. Chỉ chạy command dự án sau khi đã xác định tác dụng phụ và được phép chạy trong môi trường khảo sát.
- Ghi Git revision trước khi chạy command. Không dùng bằng chứng từ revision khác để khai báo legacy issue.
- Không sửa baseline failure ngoài phạm vi chỉ để tạo một baseline xanh.
- Không thay đổi file hiện hữu của dự án để khớp với template. Ghi conflict hoặc khoảng trống và xử lý có chủ ý trong một kế hoạch active.

## Bước 1: Bảo toàn trạng thái ban đầu

Từ root của repo, ghi lại kết quả của các kiểm tra read-only sau:

```bash
pwd
git status --short
git rev-parse HEAD
git branch --show-current
```

Nếu working tree không sạch, ghi rõ các thay đổi có sẵn và không nhận chúng là thay đổi của phiên tiếp quản. Revision từ `git rev-parse HEAD` là revision baseline; trạng thái chưa commit phải được ghi riêng trong giới hạn bằng chứng.

## Bước 2: Khảo sát dự án ở chế độ read-only

Đọc manifest, lockfile, CI config, tài liệu vận hành và script sẵn có để xác định:

- toolchain và phiên bản runtime;
- command bootstrap, verify, start và debug;
- service hoặc dependency bên ngoài;
- golden journey quan trọng;
- mechanical guardrail hiện có;
- khu vực không thể kiểm tra trong môi trường hiện tại.

Điền `ARCHITECTURE.md`, `docs/PRODUCT_SENSE.md` và `docs/RELIABILITY.md` từ thông tin có bằng chứng. Không đoán giá trị còn thiếu; giữ placeholder và ghi khoảng trống vào kế hoạch active.

## Bước 3: Thiết lập baseline

Điền `docs/PROJECT_BASELINE.md` trước khi phân loại legacy issue. Ghi chính xác môi trường, command đã thực sự chạy, exit code hoặc kết quả, trạng thái vận hành, golden journey đã kiểm tra, khu vực chưa kiểm tra và giới hạn bằng chứng.

Command khảo sát có thể tạo cache hoặc artifact. Sau mỗi nhóm command, kiểm tra lại `git status --short`; không đưa thay đổi source hoặc config phát sinh vào baseline. Nếu không thể chạy an toàn, ghi command là chưa chạy và nêu lý do thay vì suy đoán kết quả.

## Bước 4: Phân loại phát hiện

| Phân loại | Điều kiện | Nơi ghi | Hành động |
|---|---|---|---|
| Legacy issue | Failure được tái hiện và chứng minh tại đúng revision baseline | `docs/LEGACY_ISSUES.md` | Ghi bằng chứng và trạng thái; không bắt buộc sửa ngoài phạm vi |
| Regression | Failure do task hiện tại hoặc thay đổi sau baseline tạo ra | Kế hoạch active của thay đổi | Sửa trước khi hoàn thành task; không chuyển thành legacy issue hoặc nợ kỹ thuật |
| Observation chưa phân loại | Chưa đủ bằng chứng xác định failure có ở baseline hay không | Kế hoạch active | Ghi owner/bước tái hiện và tiếp tục phân loại; chưa thêm vào legacy issues |
| Nợ kỹ thuật | Khiếm khuyết được chủ động hoãn, không phải cách hợp thức hóa regression | `docs/exec-plans/tech-debt-tracker.md` | Ghi lý do, rủi ro và trigger xem xét lại |

Legacy issue đã được sửa phải chuyển sang `Resolved` và giữ nguyên bằng chứng lịch sử. Không xóa entry để làm baseline trông sạch hơn.

## Bước 5: Tạo kế hoạch active

Tạo ít nhất một kế hoạch trong `docs/exec-plans/active/` cho công việc tiếp theo. Kế hoạch phải chỉ rõ phạm vi, command xác minh, quan hệ với baseline, observation chưa phân loại và guardrail cần thêm nếu có.

## Bước 6: Review hồ sơ tiếp quản

Trước khi dựa vào harness:

1. Xác nhận revision trong mọi legacy evidence trùng với revision baseline.
2. Xác nhận mọi command ghi trong baseline có kết quả thực tế hoặc được đánh dấu chưa chạy.
3. Xác nhận regression mới không xuất hiện trong `LEGACY_ISSUES.md` hoặc debt tracker.
4. Xác nhận các khu vực chưa kiểm tra và giới hạn bằng chứng được nêu rõ.
5. Chạy checker của harness khi script đó đã được cài.

