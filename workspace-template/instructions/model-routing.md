# Model Routing cho QiQi

Tệp này là registry vận hành cho các model mà QiQi có thể dùng khi khởi động
phiên Codex trong repository con.

Không dùng kiến thức nhớ từ phiên trước để suy đoán model đang khả dụng. Model
picker, cấu hình provider và Codex CLI đang cài trên máy là nguồn sự thật.

## Nguyên tắc Cập nhật

- Ghi **đúng model ID** cần truyền cho Codex, không dùng tên marketing mơ hồ.
- Chỉ ghi model đã xác nhận có thể khởi động trong môi trường hiện tại.
- Ghi bằng chứng availability: model picker, config provider hoặc một lần start
  thành công.
- Mô tả điểm mạnh và điểm yếu bằng task thực tế đã quan sát, không dựa riêng vào
  quảng cáo.
- Xóa hàng không dùng thay vì giữ placeholder hoặc model đã mất quyền truy cập.
- Cập nhật tệp khi provider, quota, model catalog hoặc giới hạn concurrency đổi.

## Inventory Model Đang Khả dụng

Trong quá trình setup, thay toàn bộ placeholder bên dưới bằng dữ liệu thực tế.
Có thể thêm hoặc xóa hàng để khớp đúng số model đang có.

| Model ID chính xác | Bằng chứng khả dụng | Điểm mạnh | Điểm yếu | Nên dùng cho | Không nên dùng cho | Reasoning effort mặc định | Giới hạn song song |
|---|---|---|---|---|---|---|---|
| `{{MODEL_1_ID}}` | `{{MODEL_1_EVIDENCE}}` | `{{MODEL_1_STRENGTHS}}` | `{{MODEL_1_WEAKNESSES}}` | `{{MODEL_1_USE_CASES}}` | `{{MODEL_1_AVOID}}` | `{{MODEL_1_EFFORT}}` | `{{MODEL_1_CONCURRENCY}}` |
| `{{MODEL_2_ID}}` | `{{MODEL_2_EVIDENCE}}` | `{{MODEL_2_STRENGTHS}}` | `{{MODEL_2_WEAKNESSES}}` | `{{MODEL_2_USE_CASES}}` | `{{MODEL_2_AVOID}}` | `{{MODEL_2_EFFORT}}` | `{{MODEL_2_CONCURRENCY}}` |
| `{{MODEL_3_ID}}` | `{{MODEL_3_EVIDENCE}}` | `{{MODEL_3_STRENGTHS}}` | `{{MODEL_3_WEAKNESSES}}` | `{{MODEL_3_USE_CASES}}` | `{{MODEL_3_AVOID}}` | `{{MODEL_3_EFFORT}}` | `{{MODEL_3_CONCURRENCY}}` |

## Profile Định tuyến

Một model có thể phục vụ nhiều profile. Không bắt buộc mỗi profile dùng một
model khác nhau.

| Profile | Model ID | Dùng khi | Chuyển profile khi |
|---|---|---|---|
| `fast` | `{{FAST_MODEL_ID}}` | Task cơ học, phạm vi nhỏ, yêu cầu rõ, ít file, verification trực tiếp. | Scope mở rộng, cần suy luận liên module hoặc model lặp lại sai cùng một nguyên nhân. |
| `balanced` | `{{BALANCED_MODEL_ID}}` | Implementation thông thường trong một repository, điều tra bug vừa phải, viết test và tài liệu kỹ thuật. | Task có breaking contract, migration, kiến trúc phức tạp hoặc nhiều lần sửa không đạt verification. |
| `deep` | `{{DEEP_MODEL_ID}}` | Phân tích kiến trúc, task nhiều subsystem, migration, bug khó tái hiện, yêu cầu có nhiều trade-off. | Không tự hạ profile trong cùng task nếu chưa có bằng chứng task đã trở nên cơ học. |
| `verifier` | `{{VERIFIER_MODEL_ID}}` | Review độc lập, đối chiếu spec, kiểm tra rủi ro và chất lượng evidence khi repository workflow yêu cầu. | Không dùng cùng context triển khai nếu mục tiêu là đánh giá độc lập. |

## Quy tắc Chọn Model

1. Xác định loại công việc: thảo luận, điều tra, implementation, migration,
   cross-repository contract, verification hoặc tác vụ cơ học.
2. Xác định rủi ro: phạm vi file, khả năng breaking change, dữ liệu, bảo mật,
   rollback và dependency bên ngoài.
3. Chọn profile thấp nhất vẫn đủ tin cậy cho task.
4. Lấy model ID chính xác từ bảng inventory.
5. Kiểm tra giới hạn song song trước khi tạo thêm phiên.
6. Ghi model/profile đã chọn trong báo cáo khởi tạo phiên khi lựa chọn đó ảnh
   hưởng chi phí, độ trễ hoặc chất lượng.

## Quy tắc Chuyển Model

Chỉ chuyển sang model mạnh hơn khi có bằng chứng về giới hạn năng lực, ví dụ:

- bỏ sót constraint đã có trong prompt hoặc artifact;
- không giữ được quan hệ giữa nhiều module;
- lặp lại cùng một lỗi suy luận sau khi đã có feedback rõ;
- không tạo được kế hoạch rollback hoặc migration nhất quán;
- review độc lập phát hiện lỗi hệ thống trong nhiều vòng.

Không chuyển model chỉ vì:

- thiếu dependency hoặc quyền truy cập;
- command môi trường fail;
- repository thiếu tài liệu;
- yêu cầu người dùng chưa rõ;
- test cũ đang đỏ tại baseline.

Các trường hợp đó phải được xử lý ở workflow, context hoặc môi trường trước.

## Quy tắc Song song

- Tổng số phiên không vượt giới hạn nhỏ nhất của model, provider và máy local.
- Không khởi động nhiều agent cùng model khi quota hoặc capacity chưa được xác
  nhận.
- Ưu tiên giảm concurrency thay vì để nhiều phiên tranh CPU, RAM, I/O hoặc quota
  và cùng chậm lại.
- Không chạy hai phiên sửa cùng repository/working tree nếu không có worktree
  isolation được người dùng hoặc workflow repository cho phép.

## Output QiQi Cần Ghi nhận

Khi tạo phiên, QiQi phải biết:

- repository;
- task;
- profile;
- model ID;
- reasoning effort;
- dependency với phiên khác;
- lý do lựa chọn nếu không dùng profile mặc định.

Không cần tạo tracker riêng nếu các thông tin này đã hiện rõ trong Herdr và báo
cáo cuối của QiQi.
