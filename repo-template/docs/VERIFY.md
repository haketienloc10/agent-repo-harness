# Xác minh Repository

File này là nguồn sự thật cho cách bootstrap, kiểm tra và chạy repository sau
khi cài harness v2. Chỉ ghi command và kết quả được xác nhận từ source,
configuration, CI hoặc lần chạy thực tế.

## Contract

- Ghi runtime/toolchain và dependency cần thiết trước khi chạy command.
- Ghi nguyên văn command bootstrap, build, test, lint, type-check và start áp
  dụng cho repository.
- Với command đã chạy, ghi exit code, thời điểm và kết quả quan sát được.
- Với command chưa thể chạy an toàn, ghi `Not run` cùng lý do cụ thể.
- Ghi golden journey và mechanical guardrail thực tế nếu repository có chúng.
- Không suy đoán kết quả, không che baseline failure, và không đưa secret vào
  file này.

## Bootstrap

Chưa được cấu hình — hoàn tất trong takeover.

## Build và kiểm tra tĩnh

Chưa được cấu hình — hoàn tất trong takeover.

## Test

Chưa được cấu hình — hoàn tất trong takeover.

## Start và debug

Chưa được cấu hình — hoàn tất trong takeover.

## Golden journey và guardrail

Chưa được cấu hình — hoàn tất trong takeover.

## Giới hạn bằng chứng

Chưa được cấu hình — hoàn tất trong takeover.
