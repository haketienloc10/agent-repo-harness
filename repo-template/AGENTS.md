# AGENTS.md

Kho lưu trữ này được tối ưu hóa cho công việc coding-agent chạy lâu. Giữ tệp này ngắn. Sử dụng nó như lớp định tuyến vào các tài liệu hệ thống ghi chép, không phải như một đống hướng dẫn khổng lồ.

## Quy trình Khởi động

Với task chỉ đọc, giải thích hoặc báo cáo, chỉ mở tài liệu cần cho câu hỏi. Không
chạy toàn bộ quy trình dưới đây.

Trước mọi task, đọc `.harness/installation.json` nếu file tồn tại. Với schema
`harness/installation/v2`, chỉ nhận task sản phẩm khi `takeover_status` là
`complete`. Khi status là `pending` hoặc `blocked`, mở `docs/HARNESS_SETUP.md`
và tiếp tục hoặc báo blocker của quá trình takeover; không báo repository ready.

Trước khi thay đổi code, test, build script, migration hoặc cấu hình runtime:

1. Xác nhận thư mục gốc repo bằng `pwd`.
2. Đọc bốn file luôn bắt buộc:
   - `ARCHITECTURE.md`: bản đồ hệ thống và quy tắc phụ thuộc cứng.
   - `docs/QUALITY_SCORE.md`: domain, layer yếu và khoảng trống evidence hiện tại.
   - `docs/PLANS.md`: quy tắc tạo và duy trì execution-plan artifact.
   - `docs/VERIFY.md` (hoặc `docs/RELIABILITY.md` trên installation v1):
     command bootstrap, verify và start chuẩn.
3. Tạo hoặc mở execution-plan artifact trong `docs/exec-plans/active/` trước khi dùng tool sửa file.
4. Dùng Bản đồ Định tuyến bên dưới để chỉ đọc thêm file có điều kiện khớp task.
5. Chạy bootstrap và xác minh ban đầu phù hợp với phạm vi theo `docs/RELIABILITY.md`.

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

Không đọc toàn bộ cây `docs/`. Mở file khi điều kiện tương ứng đúng:

| File | Điều kiện đọc |
|---|---|
| `docs/exec-plans/active/<task>.md` | Luôn đọc với task thay đổi code; tạo file trước nếu chưa tồn tại. |
| `docs/product-specs/index.md` và spec liên quan | Khi thay đổi hành vi người dùng, API behavior, user flow hoặc acceptance criteria. |
| `docs/PRODUCT_SENSE.md` | Khi yêu cầu sản phẩm mơ hồ hoặc task cần quyết định product trade-off, priority hay quality bar. |
| `docs/design-docs/index.md` và design doc liên quan | Khi thay đổi domain boundary, layer, dependency direction, shared abstraction hoặc quyết định kiến trúc đã có. |
| `docs/DESIGN.md` | Khi thay đổi interaction, visual hierarchy, design primitive hoặc trải nghiệm UI. |
| `docs/FRONTEND.md` | Khi sửa frontend, UI state, responsive behavior, accessibility hoặc design-system usage. |
| `docs/SECURITY.md` | Khi task chạm auth, secret, dữ liệu nhạy cảm, input không tin cậy, dependency hoặc hành động bên ngoài. |
| `docs/generated/db-schema.md` | Khi sửa schema, migration, query, persistence model hoặc data ownership. |
| `docs/PROJECT_BASELINE.md` | Chỉ khi cần đối chiếu failure, hành vi bất thường hoặc regression với snapshot tiếp quản. |
| `docs/LEGACY_ISSUES.md` | Chỉ khi verification có failure liên quan hoặc cần phân loại failure là legacy hay regression. |
| `docs/exec-plans/completed/` | Khi task phụ thuộc quyết định lịch sử, tiếp tục công việc cũ hoặc điều tra regression liên quan thay đổi trước đó. |
| `docs/exec-plans/tech-debt-tracker.md` | Khi kiểm tra ràng buộc đã hoãn hoặc chủ động hoãn một khiếm khuyết thực sự; không dùng cho regression mới. |
| `docs/references/` | Chỉ khi task cần tài liệu nguồn về tool, framework hoặc chuẩn cụ thể. |
| `docs/HARNESS_SETUP.md` | Chỉ trong quá trình cài đặt hoặc takeover khi baseline chưa hoàn tất; không đọc trong task sản phẩm thông thường. |

Khi đã đọc baseline hoặc legacy issue liên quan, so sánh failure đang quan sát
với evidence tại baseline. Không tự sửa legacy failure ngoài phạm vi và không
coi baseline failure là regression mới nếu nó không bị làm xấu hơn.

## Hợp đồng Làm việc

- Trước lần sửa đầu tiên của mọi task thay đổi code, test, build script, migration hoặc cấu hình runtime, tạo một execution-plan artifact riêng trong `docs/exec-plans/active/`. Không tạo artifact cho task chỉ đọc, giải thích hoặc báo cáo mà không thay đổi file.
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
- nếu task thay đổi code, test, build script, migration hoặc cấu hình runtime, execution-plan artifact đã ghi phạm vi thực tế, quyết định và evidence xác minh
- xác minh cần thiết đã thực sự chạy
- không có regression mới; mọi failure mới do thay đổi hiện tại tạo ra đã được sửa
- nếu xác minh phát hiện failure liên quan, failure đó đã được phân loại bằng bằng chứng phù hợp; legacy failure đã đối chiếu với `docs/PROJECT_BASELINE.md` không bị làm xấu hơn
- observation chưa đủ bằng chứng được ghi trong kế hoạch active để phân loại, không bị gán thành legacy issue hoặc nợ kỹ thuật
- bằng chứng được liên kết từ kế hoạch hoặc tài liệu chất lượng liên quan
- các tài liệu bị ảnh hưởng vẫn là hiện tại
- kho lưu trữ có thể khởi động lại sạch sẽ từ đường dẫn khởi động chuẩn

## Cuối Phiên

Trước khi kết thúc phiên:

1. Nếu task đã thay đổi code, test, build script, migration hoặc cấu hình runtime, cập nhật execution-plan artifact active bằng thay đổi thực tế và evidence xác minh.
2. Cập nhật `docs/QUALITY_SCORE.md` nếu bất kỳ domain hoặc lớp nào thay đổi có ý nghĩa.
3. Ghi lại nợ thực sự được chủ động hoãn trong `docs/exec-plans/tech-debt-tracker.md`; không dùng tracker để chứa regression.
4. Di chuyển các kế hoạch đã hoàn thành sang `docs/exec-plans/completed/` khi phù hợp.
5. Để repo ở trạng thái có thể khởi động lại với hành động tiếp theo rõ ràng.
