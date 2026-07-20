# AGENTS.md

Kho lưu trữ này được tối ưu hóa cho công việc coding-agent chạy lâu. Giữ tệp này ngắn. Sử dụng nó như lớp định tuyến vào các tài liệu hệ thống ghi chép, không phải như một đống hướng dẫn khổng lồ.

## Quy trình Khởi động

Trước khi thay đổi mã:

1. Xác nhận thư mục gốc repo bằng `pwd`.
2. Đọc `ARCHITECTURE.md` để biết bản đồ hệ thống hiện tại và các quy tắc phụ thuộc cứng.
3. Đọc `docs/QUALITY_SCORE.md` để xem domain hoặc lớp nào yếu nhất.
4. Đọc `docs/PLANS.md`, sau đó mở kế hoạch active bạn đang làm việc từ đó nếu task có kế hoạch.
5. Đọc spec sản phẩm liên quan trong `docs/product-specs/`.
6. Đọc command chuẩn trong `docs/RELIABILITY.md`, rồi chạy bootstrap và xác minh phù hợp với phạm vi.
7. Không đọc `docs/PROJECT_BASELINE.md` hoặc `docs/LEGACY_ISSUES.md` theo mặc định. Chỉ đọc chúng khi xác minh phát hiện failure, khi điều tra hành vi bất thường hoặc regression, hoặc khi cần phân loại nguồn gốc của một failure.
8. Khi đã đọc baseline hoặc legacy issue liên quan, so sánh failure đang quan sát với bằng chứng baseline. Không tự sửa legacy failure ngoài phạm vi và không coi baseline failure là regression mới nếu nó không bị làm xấu hơn.

## Chất lượng Câu trả lời

Tránh câu trả lời trừu tượng.

Khi giải thích quyết định, kế hoạch, rủi ro, bug, kiến trúc hoặc trade-off, dùng ví dụ cụ thể và lập luận nhân quả theo từng bước.

Khi phù hợp, ưu tiên cấu trúc sau:

1. Điều gì xảy ra
2. Vì sao điều đó xảy ra
3. Ví dụ cụ thể
4. Tác động dẫn đến
5. Hành động được khuyến nghị

## Bản đồ Định tuyến

- `ARCHITECTURE.md`: bản đồ domain, mô hình lớp, quy tắc phụ thuộc
- `docs/design-docs/index.md`: các quyết định thiết kế và niềm tin cốt lõi
- `docs/product-specs/index.md`: các hành vi sản phẩm hiện tại và mục tiêu chấp nhận
- `docs/PROJECT_BASELINE.md`: tra cứu khi cần đối chiếu failure hoặc trạng thái hiện tại với snapshot tại revision tiếp quản và giới hạn bằng chứng
- `docs/LEGACY_ISSUES.md`: tra cứu khi cần xác minh failure đã tồn tại tại baseline hoặc phân loại một failure là legacy issue hay regression
- `docs/PLANS.md`: vòng đời kế hoạch và chính sách kế hoạch thực thi
- `docs/QUALITY_SCORE.md`: sức khỏe domain sản phẩm và lớp
- `docs/RELIABILITY.md`: tín hiệu runtime, benchmark và kỳ vọng khởi động lại
- `docs/SECURITY.md`: bí mật, sandbox, dữ liệu và quy tắc hành động bên ngoài
- `docs/FRONTEND.md`: ràng buộc UI, quy tắc design system, kiểm tra accessibility

## Hợp đồng Làm việc

- Làm việc từ một kế hoạch có ranh giới hoặc slice tính năng tại một thời điểm.
- Không đánh dấu công việc xong chỉ từ kiểm tra mã; cần bằng chứng có thể chạy được.
- Phân loại phát hiện theo bằng chứng: failure có tại baseline là legacy issue; failure do thay đổi hiện tại tạo ra là regression; phát hiện chưa rõ nguồn gốc là observation chưa phân loại trong kế hoạch active.
- Không chuyển regression mới thành legacy issue hoặc nợ kỹ thuật để hoàn thành task.
- Legacy issue không tự động chặn thay đổi ngoài phạm vi khi kết quả không bị làm xấu hơn. Issue đã sửa được chuyển thành `Resolved`, không bị xóa.
- Nếu bạn thay đổi hành vi, hãy cập nhật tài liệu sản phẩm, kế hoạch hoặc độ tin cậy phù hợp trong cùng phiên.
- Nếu bạn thấy phản hồi review lặp đi lặp lại, hãy thúc đẩy nó thành quy tắc cơ học, kiểm tra hoặc linter thay vì giải thích lại trong chat.
- Giữ tài liệu được tạo ra trong `docs/generated/` và tài liệu tham khảo nguồn trong `docs/references/`.
- Ưu tiên thêm tài liệu nhỏ, hiện tại hơn là phát triển tệp này.

## Định nghĩa Hoàn thành

Một thay đổi chỉ xong khi tất cả những điều sau đây là đúng:

- hành vi mục tiêu đã được triển khai
- xác minh cần thiết đã thực sự chạy
- không có regression mới; mọi failure mới do thay đổi hiện tại tạo ra đã được sửa
- nếu xác minh phát hiện failure liên quan, failure đó đã được phân loại bằng bằng chứng phù hợp; legacy failure đã đối chiếu với `docs/PROJECT_BASELINE.md` không bị làm xấu hơn
- observation chưa đủ bằng chứng được ghi trong kế hoạch active để phân loại, không bị gán thành legacy issue hoặc nợ kỹ thuật
- bằng chứng được liên kết từ kế hoạch hoặc tài liệu chất lượng liên quan
- các tài liệu bị ảnh hưởng vẫn là hiện tại
- kho lưu trữ có thể khởi động lại sạch sẽ từ đường dẫn khởi động chuẩn

## Cuối Phiên

Trước khi kết thúc phiên:

1. Cập nhật kế hoạch thực thi active nếu task có kế hoạch.
2. Cập nhật `docs/QUALITY_SCORE.md` nếu bất kỳ domain hoặc lớp nào thay đổi có ý nghĩa.
3. Ghi lại nợ thực sự được chủ động hoãn trong `docs/exec-plans/tech-debt-tracker.md`; không dùng tracker để chứa regression.
4. Di chuyển các kế hoạch đã hoàn thành sang `docs/exec-plans/completed/` khi phù hợp.
5. Để repo ở trạng thái có thể khởi động lại với hành động tiếp theo rõ ràng.
