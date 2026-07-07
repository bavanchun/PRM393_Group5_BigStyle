# Brainstorm Report — SePay Payment + Manager Order Status

- Date: 2026-07-03 · Branch: dev · Supabase project: bigstyle-prm393 (`agbnpqgxsppdrpbqoipo`)
- Follow-up của scout report `app-feature-flow-inventory-260703-1358` (2 gap lớn nhất: payment không tồn tại, manager không đổi được status).

## Problem

1. **Payment**: checkout hiện tạo order thẳng, không có bước thanh toán. Bảng `payments` + cột `orders.payment_method` có trong schema nhưng FE chưa dùng dòng nào (`OrderModel.toMap()` không set payment_method → luôn null).
2. **Manager order status**: `OrderService.updateOrderStatus` (order_service.dart:75) tồn tại nhưng **không có caller**. Manager xem detail bằng màn khách (read-only). DB trigger `on_order_status_change` (schema.sql:356) tự tạo notification khi status đổi — chưa bao giờ chạy vì FE không đổi status.

## Evaluated & DECIDED (user-locked)

| # | Câu hỏi | Quyết định | Ghi chú |
|---|---|---|---|
| 0a | Payment provider | **SePay** (user chọn, thay vì COD-only/mock/VNPay) | SePay = giám sát bank + webhook, VietQR, không phải ví trung gian |
| 0b | Phương thức checkout | **SePay (bank_transfer) + COD** | COD làm fallback an toàn khi demo |
| 0c | Manager status scope | **Đổi status + notification qua trigger + guard luồng chuyển hợp lệ** | Không làm refund/hoàn kho logic |
| 1 | Paid detection | **Realtime + polling fallback** | Realtime cho UX tức thì, polling 3-5s làm lưới an toàn khi socket rớt. Cần bật Realtime publication cho bảng `payments` |
| 2 | Order timing | **Tạo order `pending` + payments `pending` TRƯỚC khi hiện QR** | order_number (DB tự sinh) = nội dung CK. Cart chỉ clear khi paid (SePay) / ngay (COD) |
| 3 | Pending bỏ dở | **Manager tự huỷ** (dùng chính tính năng đổi status). Webhook gặp order cancelled vẫn ghi payments row để đối soát | Không auto-cancel, không pg_cron |
| 4 | payment_method value | **`bank_transfer`** (không gắn vendor) | Migration thêm vào 2 check constraints: `orders.payment_method`, `payments.method` |
| 5 | Màn QR | **Có khối nhập tay**: bank + STK + số tiền + nội dung CK, nút copy từng dòng | Bắt buộc thực tế vì demo emulator khó quét QR |
| 6 | Manager UI | **Cả hai**: bottom-sheet đổi nhanh từ card + màn manager-order-detail riêng (items, khách, payment status, nút đổi trạng thái) | Detail screen fix luôn gap manager xem bằng màn khách |

## Final Architecture

### Payment (SePay) flow
```
Checkout (chọn COD | bank_transfer)
 ├─ COD: tạo order pending + payments(method=cod,pending) → clear cart → /orders (flow cũ giữ nguyên)
 └─ SePay: tạo order pending + payments(method=bank_transfer,pending) → màn QR
      QR img: https://qr.sepay.vn/img?acc=..&bank=..&amount=TOTAL&des=ORDER_NUMBER
      Khách chuyển khoản → SePay POST webhook → Supabase Edge Function `sepay-webhook`
        - verify header `Authorization: Apikey <SEPAY_WEBHOOK_KEY>` (secret trong function env)
        - normalize content ([^A-Z0-9]→'', uppercase) match order_number
        - service_role: payments.status=success + paid_at + transaction_id; orders.status=confirmed
        - order đã cancelled → vẫn insert payments row (đối soát tay), trả success
        - trả {"success": true} <30s
      App: Realtime subscribe payments(order_id) + polling 3-5s fallback
        → paid: clear cart → màn thành công → /orders
        → nút "Tôi đã chuyển khoản" (force check) + nút huỷ/quay lại (cart giữ nguyên)
```

### Manager order status flow
```
ManagerOrdersScreen card
 ├─ long-press/nút → bottom-sheet: các trạng thái KẾ hợp lệ → ManagerUpdateOrderStatus → OrderService.updateOrderStatus (có sẵn)
 └─ "Chi tiết" → ManagerOrderDetailScreen (MỚI, thay cho màn khách): items + khách + địa chỉ + payment method/status + nút đổi trạng thái
DB trigger on_order_status_change tự tạo notification cho khách — 0 code FE.
```

Luồng chuyển hợp lệ: `pending→confirmed|cancelled`, `confirmed→processing|cancelled`, `processing→shipping|cancelled`, `shipping→delivered`, `delivered→refunded`; `cancelled`/`refunded` terminal. SePay tự đẩy `pending→confirmed`, manager tiếp `confirmed→…→delivered`.

## Work Packages (parallel plan)

- **WP1 — Nền (tuần tự, trước)**: migration constraint (`bank_transfer` vào 2 checks) + bật Realtime cho `payments` + Edge Function `sepay-webhook` (deploy qua Supabase MCP) + `.env.example` thêm `SEPAY_BANK`, `SEPAY_ACC` (FE cần để build QR URL).
- **WP2 — Payment FE**: `payment_service.dart` (tạo payments row, build QR URL, realtime subscribe + polling), `payment/` bloc, `payment_qr_screen.dart`, sửa `checkout_bloc/screen` (selector phương thức, timing clear cart), `order_model.toMap` set payment_method, route mới.
- **WP3 — Manager FE**: `ManagerUpdateOrderStatus` event/handler trong `manager_bloc`, status-transition helper (thêm vào `order_status.dart`), bottom-sheet, `manager_order_detail_screen.dart` + đổi route trong `manager_orders_screen`.
- WP2 ⊥ WP3: không chung file ghi. Điểm chạm chung chỉ đọc: `OrderStatus`, `OrderService`. WP3 sửa `order_status.dart` (thêm helper) — WP2 chỉ đọc enum → an toàn.

## Risks

1. **Content matching**: bank strip ký tự đặc biệt trong nội dung CK → normalize 2 phía bắt buộc; test webhook bằng nút "Gửi test" trong SePay dashboard.
2. **Check constraint chưa migrate** → insert `bank_transfer` fail. Migration là bước đầu tiên.
3. **SePay cần TK ngân hàng thật link vào SePay account** (user tự setup, tương tự checklist Resend). Demo: chuyển khoản nhỏ thật hoặc test-webhook từ dashboard.
4. **Checkout regression**: đổi flow đụng CheckoutBloc — đơn COD phải giữ hành vi cũ (test kỹ).
5. **Realtime miss event**: đã chốt polling fallback nên rủi ro thấp.
6. **RLS insert payments từ client**: bảng payments hiện chỉ có policy select (user) + all (manager) — **cần thêm policy insert cho user** (with check auth.uid() = user_id) trong migration WP1.

## Success Criteria

- [ ] Checkout chọn COD → flow cũ nguyên vẹn, payment_method=cod lưu đúng, payments row tạo.
- [ ] Checkout chọn CK → order pending + màn QR đúng số tiền/nội dung; test-webhook SePay → app tự chuyển màn thành công ≤5s, order=confirmed, payments=success, notification "✅ Đơn hàng đã được xác nhận" xuất hiện.
- [ ] Bỏ ngang màn QR → cart còn nguyên, order pending còn đó, manager huỷ được.
- [ ] Manager đổi status qua sheet + detail screen, chỉ hiện trạng thái kế hợp lệ, khách nhận notification.
- [ ] `flutter analyze` sạch.

## User setup (ngoài code, sẽ có checklist trong plan)

- Tạo tài khoản SePay + link TK ngân hàng.
- SePay dashboard → Webhooks: URL = Edge Function endpoint, chọn auth Apikey, đặt key trùng secret của function.
- Điền `SEPAY_BANK`/`SEPAY_ACC` vào `.env`.

## Unresolved Questions

- None — tất cả 9 quyết định đã user-locked ở bảng trên.
