---
phase: 2
title: Payment FE (Checkout + QR)
status: completed
priority: P1
dependencies:
  - 1
effort: 1d
---

# Phase 2: Payment FE (Checkout + QR)

## Overview

Checkout thêm selector COD | Chuyển khoản; flow SePay: tạo order pending + payments pending → màn QR (ảnh qr.sepay.vn + khối nhập tay) → Realtime + polling phát hiện paid → clear cart → màn thành công.

## Requirements

- Functional: COD giữ nguyên hành vi cũ (thêm lưu payment_method + payments row); SePay flow như Overview; bỏ ngang → cart nguyên vẹn.
- Non-functional: paid detect ≤5s (polling 3s); không thêm package mới (QR = `Image.network`).

## Architecture

```
CheckoutScreen: thêm PaymentMethodSelector (cod | bank_transfer, default cod)
CheckoutPlaceOrder(+ paymentMethod):
  ├─ cod:  createOrder + payments(cod,pending) → clearCart → isSuccess → /orders (flow cũ)
  └─ bank: createOrder + payments(bank_transfer,pending) → KHÔNG clearCart
           → state {awaitingPayment, orderId, orderNumber, total}
           → Navigator /payment-qr (args: orderId, orderNumber, total, userId)
PaymentQrScreen + PaymentBloc:
  - QR: Image.network("https://qr.sepay.vn/img?acc=$acc&bank=$bank&amount=${total.toInt()}&des=$orderNumber&template=compact")
    * amount BẮT BUỘC toInt() — total là double, "$total" ra "150000.0" làm sai QR (schema numeric(12,0), VND luôn nguyên)
    * errorBuilder trên Image.network + assert/log khi sepayBank/sepayAcc rỗng (AppConfig fallback '' → ảnh hỏng câm là failure demo-day số 1)
  - Khối nhập tay: bank, STK, số tiền, nội dung CK ($orderNumber) — mỗi dòng IconButton copy (Clipboard.setData)
  - Detect: PaymentService.watchPaymentStatus(orderId)
      * Realtime: supabase.channel().onPostgresChanges(table: payments, filter: order_id=eq.$orderId)
      * Polling: Timer.periodic 3s — select payments theo order_id `order('created_at', desc).limit(1)` + maybeSingle (KHÔNG .single() — phòng nhiều rows)
      * LATCH bắt buộc: bool _paidHandled trong PaymentBloc — realtime event và poll in-flight có thể cùng bắn "paid" trước khi cancel kịp → side effect (clearCart, navigate) chỉ chạy 1 lần
      * cancel cả realtime channel + timer khi paid/dispose
  - paid (lần đầu qua latch) → CartService.clearCart(userId) → dialog/màn thành công → /orders
  - Nút "Kiểm tra thanh toán" (force poll 1 phát) + nút "Quay lại" (huỷ theo dõi, cart nguyên, hint đơn chờ trong Đơn hàng)
  - Thiếu tiền (payments vẫn pending): màn QR poll mãi — chấp nhận cho scope này; recovery = manager confirm tay (phase 3)
```

order_number: DB tự sinh → `createOrder` phải trả về row (`insert().select().single()`) hoặc select lại; thêm field `orderNumber` (nullable) vào `OrderModel`.

## Related Code Files

- Create: `lib/services/payment_service.dart` — createPayment(orderId,userId,method,amount), watchPaymentStatus(orderId) (realtime+polling stream), buildQrUrl(total,orderNumber) đọc `SEPAY_BANK/SEPAY_ACC` từ dotenv qua `AppConfig`
- Create: `lib/blocs/payment/payment_bloc.dart`, `payment_event.dart`, `payment_state.dart`
- Create: `lib/screens/checkout/payment_qr_screen.dart`
- Modify: `lib/blocs/checkout/checkout_event.dart` — CheckoutPlaceOrder + `paymentMethod`
- Modify: `lib/blocs/checkout/checkout_state.dart` — + `awaitingPayment`, `orderNumber`, `total`
- Modify: `lib/blocs/checkout/checkout_bloc.dart` — branch cod/bank, timing clearCart
- Modify: `lib/screens/checkout/checkout_screen.dart` — selector UI + điều hướng /payment-qr
- Modify: `lib/models/order_model.dart` — + field `orderNumber` (fromMap `order_number`; KHÔNG đưa vào toMap), toMap set `payment_method`
- Modify: `lib/services/order_service.dart` — createOrder trả OrderModel (insert...select().single())
- Modify: `lib/config/app_config.dart` — + `sepayBank`, `sepayAcc` getters
- Modify: `lib/config/routes/app_router.dart` — + case '/payment-qr'
- Modify: `lib/main.dart` — provide PaymentService/PaymentBloc (theo pattern MultiBlocProvider hiện có)

## Implementation Steps

1. `order_model.dart`: + `orderNumber`, toMap + `payment_method` (thêm field `paymentMethod`, default 'cod').
2. `order_service.dart`: createOrder → `insert(order.toMap()).select().single()` trả OrderModel.fromMap (giữ vòng insert order_items như cũ).
3. `payment_service.dart` (mới) theo Architecture.
4. `app_config.dart`: getters sepayBank/sepayAcc; `.env.example` đã có key từ phase 1.
5. Checkout bloc/event/state/screen: selector + branch. **COD path phải giữ nguyên hành vi cũ** (test regression).
   - `_onPlaceOrder` RESET `isSuccess/awaitingPayment/orderId` ngay đầu handler (CheckoutBloc app-scoped trong main.dart — isSuccess=true từ đơn COD trước sẽ làm listener bắn 2 navigation ở đơn bank sau). Listener trong screen branch mutually-exclusive (if/else if).
   - Thứ tự SePay: createOrder (order + items) THÀNH CÔNG rồi mới createPayment; createPayment fail → hiện lỗi + nút retry (orderId là UUID client-side nên retry idempotent), CHỈ điều hướng /payment-qr khi CẢ HAI xong (order không có payments row = webhook không match được).
6. PaymentBloc + PaymentQrScreen; route '/payment-qr'; providers trong main.dart.
7. `flutter analyze` sạch; test thủ công cả 2 nhánh trên emulator (SePay dùng test-webhook/curl từ phase 1).
8. Commit theo cụm logic (`feat(payment): ...`) — ≥1 commit.

## Success Criteria

- [ ] COD: đặt hàng như cũ, orders.payment_method='cod', payments row (cod,pending), cart clear ngay.
- [ ] SePay: order pending + payments pending, màn QR đúng amount + des=order_number, cart CHƯA clear.
- [ ] curl webhook → app chuyển màn thành công ≤5s (cả khi tắt Realtime chỉ còn polling), cart clear.
- [ ] Quay lại từ màn QR: cart nguyên.
- [ ] `flutter analyze` 0 lỗi. ≥1 commit.

## Risk Assessment

- Checkout regression: nhánh COD đổi ít nhất có thể; test trước/sau.
- Realtime channel không nhận event (chưa bật publication/policy): polling fallback đảm bảo detect; đừng block trên Realtime.
- Emulator không quét được QR: khối nhập tay + curl webhook là đường demo chính.
- KHÔNG sửa `lib/models/order_status.dart` (phase 3 sở hữu file này khi chạy parallel).
