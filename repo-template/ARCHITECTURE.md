# ARCHITECTURE.md

File này mô tả kiến trúc thực đang tồn tại ở revision hiện tại. Không dùng nó
để áp một mô hình layer chung lên mọi repository, và không mô tả target
architecture như thể đã được triển khai.

Chỉ ghi claim có bằng chứng từ source, configuration, runtime, test hoặc tài liệu
dự án. Đề xuất chưa triển khai phải được ghi rõ là proposal trong
`docs/decisions/` hoặc active plan phù hợp.

## System shape

- Sản phẩm hoặc thư viện: `{{PRODUCT_NAME}}`
- Primary workflow: `{{PRIMARY_USER_WORKFLOW}}`
- Runtime surface: `{{RUNTIME_SURFACES}}`
- Entrypoint: `{{SYSTEM_ENTRY_POINTS}}`
- Source of truth cho behavior: `{{BEHAVIOR_SOURCE_PATH}}`

## Component và domain map

Mô tả các boundary thực sự có trong repo. Component có thể là package, service,
process, module, job, frontend surface hoặc data store; không ép chúng vào một
layer taxonomy cố định.

| Component/domain | Trách nhiệm hiện tại | Entrypoint hoặc path | Phụ thuộc chính | Evidence |
|---|---|---|---|---|
| `{{COMPONENT_1_NAME}}` | `{{COMPONENT_1_OWNERSHIP}}` | `{{COMPONENT_1_ENTRY_POINTS}}` | `{{COMPONENT_1_DEPENDENCIES}}` | `{{COMPONENT_1_EVIDENCE}}` |
| `{{COMPONENT_2_NAME}}` | `{{COMPONENT_2_OWNERSHIP}}` | `{{COMPONENT_2_ENTRY_POINTS}}` | `{{COMPONENT_2_DEPENDENCIES}}` | `{{COMPONENT_2_EVIDENCE}}` |

## Dependency và data flow hiện tại

Ghi hướng gọi, data ownership, state transition và boundary giữa process đúng
như implementation hiện tại. Nếu dependency direction chưa rõ hoặc đang bị vi
phạm, mô tả cả evidence và impact thay vì viết một rule lý tưởng như hiện trạng.

```text
{{CURRENT_DEPENDENCY_OR_DATA_FLOW}}
```

## External boundary

| Boundary | Owner/caller | Contract và failure mode | Evidence |
|---|---|---|---|
| `{{EXTERNAL_BOUNDARY_1}}` | `{{EXTERNAL_BOUNDARY_1_OWNER}}` | `{{EXTERNAL_BOUNDARY_1_CONTRACT}}` | `{{EXTERNAL_BOUNDARY_1_EVIDENCE}}` |

Ghi rõ auth, persistence, queue, external API, filesystem hoặc platform boundary
khi chúng thực sự tồn tại. Security detail thuộc `docs/SECURITY.md` nếu concern
đó đủ lớn để cần artifact riêng.

## Invariant đã được thực thi

Chỉ liệt kê invariant có enforcement hoặc evidence cụ thể.

| Invariant | Enforcement/evidence |
|---|---|
| `{{ARCHITECTURE_INVARIANT}}` | `{{ARCHITECTURE_INVARIANT_EVIDENCE}}` |

## Hotspot và giới hạn hiểu biết

- Hotspot hiện tại: `{{CHANGE_SAFETY_HOTSPOT}}`
- Boundary yếu hoặc khu vực khó verify: `{{WEAK_BOUNDARY_OR_UNVERIFIED_AREA}}`
- Điều chưa được xác nhận: `{{ARCHITECTURE_EVIDENCE_LIMIT}}`

Không biến một target architecture, refactor mong muốn hoặc assumption chưa kiểm
chứng thành current architecture. Khi implementation thay đổi, cập nhật bản đồ
này cùng evidence và cập nhật `docs/VERIFY.md` nếu command hoặc guardrail đổi.
