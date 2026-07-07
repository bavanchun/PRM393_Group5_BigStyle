---
phase: 3
title: Manager Order Status FE
status: completed
priority: P1
dependencies:
  - 1
effort: 0.75d
---

# Phase 3: Manager Order Status FE

## Overview

Manager đổi trạng thái đơn qua bottom-sheet (từ list) + màn manager-order-detail riêng (thay việc dùng màn khách). Gọi `OrderService.updateOrderStatus` có sẵn — trigger DB `on_order_status_change` tự bắn notification cho khách, 0 code FE cho notification.

## Requirements

- Functional: chỉ hiện trạng thái KẾ hợp lệ; update xong reload list; detail hiển thị khách + items + payment info + đổi status.
- Non-functional: parallel-safe — phase này KHÔNG sửa file phase 2 sở hữu (checkout/payment/order_model/order_service/app_router — router để phase 4 nối).

## Architecture

Luồng chuyển hợp lệ (helper trên enum):
```
pending    → confirmed | cancelled
confirmed  → processing | cancelled
processing → shipping | cancelled
shipping   → delivered
delivered  → refunded
cancelled, refunded → (terminal)
```

```
ManagerOrdersScreen
 ├─ card: nút đổi trạng thái → showModalBottomSheet(OrderStatusSheet)
 │    chọn next status → ManagerUpdateOrderStatus(orderId, status)
 │    → OrderService.updateOrderStatus → reload ManagerLoadOrders(giữ filter)
 └─ nút "Chi tiết" → ManagerOrderDetailScreen(order) [constructor arg, KHÔNG cần route mới ngay]
      hiển thị: order_number/id, tên khách, items, địa chỉ, tổng tiền, payment method+status (select payments theo order_id), nút "Cập nhật trạng thái" → cùng OrderStatusSheet
```

## Related Code Files

- Modify: `lib/models/order_status.dart` — + `List<OrderStatus> get nextStatuses` (bảng chuyển trên) — file này phase 3 SỞ HỮU
- Modify: `lib/blocs/manager/manager_event.dart` — + `ManagerUpdateOrderStatus(orderId, status)`
- Modify: `lib/blocs/manager/manager_bloc.dart` — handler: updateOrderStatus → reload orders (giữ selectedStatus); error → state.error
- Modify: `lib/blocs/manager/manager_state.dart` — + `isUpdatingStatus` (nếu cần loading nút)
- Create: `lib/screens/manager/order_status_update_sheet.dart` — bottom-sheet dùng chung (list + detail)
- Create: `lib/screens/manager/manager_order_detail_screen.dart`
- Modify: `lib/screens/manager/manager_orders_screen.dart` — nút detail push MaterialPageRoute(ManagerOrderDetailScreen) thay vì '/order-detail'; card thêm nút đổi status
- Modify: `lib/screens/manager/manager_order_card.dart` — + callback onUpdateStatus (nút hiện khi `order.status.nextStatuses` không rỗng)
- KHÔNG sửa: `app_router.dart`, `order_service.dart`, `order_model.dart` (phase 2/4 sở hữu)

## Implementation Steps

1. `order_status.dart`: thêm `nextStatuses` getter theo bảng chuyển.
2. Manager bloc: event + handler (gọi `updateOrderStatus` sẵn có ở `order_service.dart:75`), reload giữ filter.
3. `order_status_update_sheet.dart`: nhận order, render `nextStatuses` (label + màu từ `managerOrderStatusColor`), confirm → add event → pop.
   - Sheet hiện 1 dòng warning payment status khi đơn `bank_transfer` chưa thanh toán (payments pending) — confirm đơn chưa trả tiền là hợp lệ (đường đối soát tay cho case thiếu tiền) nhưng manager phải THẤY để không confirm nhầm.
4. `manager_order_detail_screen.dart`: nhận `OrderModel` qua constructor; payment info: select payments theo order_id (dùng Supabase client trực tiếp trong screen là chấp nhận được, hoặc method nhỏ trong ManagerBloc — KHÔNG thêm vào OrderService để tránh đụng file phase 2).
5. Nối vào `manager_orders_screen.dart` + card.
6. `flutter analyze`; test: đổi pending→confirmed → check notification row của khách xuất hiện (DB), filter list vẫn đúng.
7. Commit (`feat(manager): order status update + detail screen`) — ≥1 commit.

## Success Criteria

- [ ] Sheet chỉ hiện trạng thái kế hợp lệ; delivered/cancelled/refunded không hiện nút (terminal/chỉ refund).
- [ ] Đổi status → list reload đúng filter; DB notifications có row mới cho user của đơn.
- [ ] Manager detail screen hiển thị khách + items + payment method/status.
- [ ] Không sửa file thuộc phase 2. `flutter analyze` 0 lỗi. ≥1 commit.

## Risk Assessment

- Đụng file khi parallel: danh sách KHÔNG-sửa ở trên là hợp đồng; vi phạm → conflict.
- RLS: manager update orders được nhờ policy "Managers manage all orders" (đã có). Đọc payments nhờ "Managers manage all payments" (đã có).
- `manager_orders_screen` đang push '/order-detail' (màn khách) — thay bằng MaterialPageRoute trực tiếp để không sửa app_router.
