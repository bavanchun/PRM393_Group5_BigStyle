---
phase: 3
title: Customer Flow Audit
status: completed
priority: P1
dependencies:
  - 1
effort: 0.75d
---

# Phase 3: Customer Flow Audit

## Overview

Audit toàn bộ trải nghiệm khách: duyệt → chi tiết → giỏ → checkout → thanh toán →
đơn hàng, cùng favorites/profile/edit/notifications/chat/delivery-map. Đây là actor
nhiều screen nhất. Đăng nhập bằng account thật `hoangbavan4478@gmail.com` để đi hết
flow mua (mock-user bị guard chặn).

## Requirements

- Functional: mỗi screen States + bảng findings; đi trọn happy-path mua hàng thật
  (giá đã set 10k, ship 1k) + các nhánh (giỏ rỗng, chưa chọn size, huỷ QR).
- Non-functional: phân biệt rõ `flow` vs `ui` vs `ux` vs `dead` vs `consistency`.

## Screens

home (tab0) · product_list (tab1) · product_detail (+review section/editor, size
guide) · cart (tab2) · checkout · payment_qr · orders · order_detail · favorites
(tab3) · profile (tab4) · edit_profile · notifications · chat · delivery_map.

## Seed findings (từ scout — XÁC NHẬN + severity hoá)

- **cart**: `CartLoad` **không bao giờ được dispatch** → giỏ DB không hiện lúc mở
  app; sau COD checkout xoá cart DB nhưng **không bắn `CartClear`** → badge/list
  stale. (flow, nghi P1)
- **shipping**: 3 mô hình phí ship phân kỳ — checkout charge **flat ~1000đ**, còn
  CheckoutBloc distance-based (15k–70k) + delivery_map bảng khác — cả hai không dùng. (flow/consistency)
- **delivery_map**: **unreachable dead code**; Profile "Cửa hàng" mở placeholder
  sheet thay vì màn thật; nút "Chỉ đường" = snackbar mock. (dead, nghi P2)
- **edit_profile**: snackbar "Cập nhật thành công" **hiện vô điều kiện** + pop trước
  khi bloc xác nhận → lỗi update vô hình; nút camera avatar không wire picker. (flow, nghi P1)
- **product_detail**: nút Share `onPressed:(){}` chết; `_buyNow` cho guest push
  `/login` RỒI vẫn `pushNamed('/cart')` (double-nav); size không có color match →
  âm thầm rơi về "first variant" (sai màu). (dead/flow)
- **product_list**: filter chips hardcode, map theo label string; category id từ home
  bị bỏ qua (mở list không filter); 'Sale' chỉ sort giá chứ không lọc sale. (flow)
- **home**: không có error state; greeting "Xin chào!" + avatar tĩnh (không tên);
  banner "Giảm 30%" hardcode; search bar là nút giả. (ui/ux)
- **orders**: không có cancel/reorder/pay-again cho đơn `pending` (đơn bank-transfer
  pending kẹt, không quay lại QR được); không error state; không pull-to-refresh. (flow, nghi P1)
- **order_detail**: `OrderLoadDetail` dispatch **trong `build()`** (re-fire mỗi
  rebuild); không error/not-found → spin vĩnh viễn khi fail; badge luôn 1 màu. (flow)
- **notifications**: `NotificationLoad` trong `build()`; không mark-all-read; không
  điều hướng từ notif → đơn. (flow/ux)
- **checkout**: success dialog show `orderId.substring(0,8)` (UUID) thay vì
  `orderNumber`; guard chặn `mock-` sau khi điền hết form (late fail). (ux)
- **chat**: là **AI bot** (không phải chat manager); nút ảnh mock; dot "online" xanh
  hardcode; mock user không lưu history. (dead/ux)

## Implementation Steps

1. Login account thật. Đi tab0→tab4, chụp mỗi tab.
2. Happy-path mua: home → product_detail (chọn size+color) → add-to-cart → cart →
   checkout (COD) → success; lặp lại nhánh bank_transfer → payment_qr → (mô phỏng)
   thành công. Chụp từng bước. Đối chiếu số tiền hiển thị vs charge (xác nhận flat 1k).
3. Nhánh lỗi/edge: giỏ rỗng; add-to-cart chưa chọn size; huỷ giữa QR (cart còn
   nguyên?); order pending có đường "trả lại" không; edit_profile với mạng lỗi.
4. Màn phụ: favorites (toggle), profile (bấm từng menu — bắt "Sản phẩm yêu thích"
   không onTap, "Cửa hàng" ra placeholder), notifications, chat (gõ + nút ảnh),
   thử mở `/delivery-map` (xác nhận không có lối vào từ UI).
5. Điền `## Actor: Customer`: mỗi screen States + bảng findings. Ảnh giữ local
   (không commit); doc dùng chữ + evidence file:line.

## Success Criteria

- [ ] Tất cả 14 screen customer có States + bảng findings.
- [ ] Happy-path mua (COD + bank_transfer) đi trọn, kiểm visual từng bước (ảnh local).
- [ ] Mọi seed finding đánh giá giữ/loại + severity + evidence.
- [ ] Xác nhận rõ 3 vấn đề nghi P1: CartLoad/CartClear, edit_profile false-success,
      pending-order không recovery.

## Risk Assessment

- Thanh toán thật: dùng flow mô phỏng webhook như session trước (không tốn tiền);
  ghi rõ là simulate.
- Nhiều screen → tốn ảnh. Mitigation: chụp state tiêu biểu, không chụp trùng.
- Mock user bị guard → phải dùng account thật cho nhánh mua; note screen nào chỉ
  xem được bằng mock (UI) vs cần real (flow).
