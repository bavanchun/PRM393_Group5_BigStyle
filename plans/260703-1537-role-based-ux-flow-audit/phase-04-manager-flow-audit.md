---
phase: 4
title: "Manager Flow Audit"
status: pending
priority: P1
dependencies: [1]
effort: "0.5d"
---

# Phase 4: Manager Flow Audit

## Overview

Audit surface manager: dashboard → quản lý sản phẩm (CRUD) → quản lý đơn (đổi trạng
thái) → profile. **Chưa có manager account → promote 1 user thành `role=manager`**
qua Supabase trước khi audit (hỏi user email; tránh dùng account customer đang test,
hoặc flip tạm rồi trả về `customer` sau phase). Điền `## Actor: Manager`.

## Requirements

- Functional: mỗi screen States + bảng findings; đi trọn CRUD sản phẩm + đổi trạng
  thái đơn (xác nhận notification khách bắn ra).
- Non-functional: bắt các lệch design-system nặng ở nhóm product screens.

## Screens

manager_shell (dashboard/products/orders/profile) · manager_dashboard · manager_orders
+ card · manager_order_detail · order_status_update_sheet · product_list ·
create_product · product_detail.

## Seed findings (từ scout — XÁC NHẬN + severity hoá)

- **routing**: **không có role guard** — customer/manager với tới route của nhau;
  chỉ có landing redirect ở splash/login bảo vệ ngầm. (flow, nghi P1)
- **dashboard**: mở **nhầm màn đơn của customer** (`/order-detail` named → customer
  `OrderDetailScreen`) thay vì `ManagerOrderDetailScreen`; quick actions ("Thêm SP",
  "Danh mục", "Khuyến mãi") **đều coming-soon** dù create SP đã có thật. (flow/dead)
- **order_status_update_sheet**: cập nhật lỗi trên list KHÔNG rỗng = **silent
  failure** (bloc.error chỉ render khi list rỗng); không confirm khi `cancelled`;
  query Supabase trực tiếp (trùng với detail). (flow, nghi P1)
- **manager_order_detail**: sau update **không refresh** → badge/nút status stale
  (giữ `widget.order` immutable); query `payments` trực tiếp trong widget (bỏ qua
  bloc/service); payment fetch fail = im lặng. (flow)
- **create/edit product**: **category dropdown giả** (chọn không lưu vào product);
  **color swatch giả**, `colorHex` hardcode `#914B34`; "+ Thêm màu" coming-soon;
  create không set `_isSaving` (không spinner); `_isDirty()` **luôn true** → dialog
  huỷ luôn hiện; ~90% code trùng giữa 2 màn (~900 dòng mỗi màn). (flow/ux/consistency)
- **product_list**: **không có error state** (fail giống hệt empty); hardcode
  Colors.*, `.withOpacity` deprecated; AppBar hồng vs trắng; branding "CurveFit
  Admin" ≠ BigStyle; hamburger + pagination chevrons là no-op; placeholder image URL. (ui/consistency/dead)
- **cross (seed cho phase 5)**: product screens lệch design-system nặng; ManagerBloc
  & ManagerProductBloc global (sống cả session customer); 2 style state khác nhau.

## Implementation Steps

0. Promote user → manager: `update public.users set role='manager' where email=<email>`
   (Supabase). Ghi lại để trả về `customer` sau nếu là account dùng chung.
1. Login manager thật. Chụp 4 tab shell.
2. Dashboard: bấm quick actions (xác nhận coming-soon), tap recent order (xác nhận
   mở nhầm màn customer), pull-to-refresh.
3. Products: list (thử search/filter, bấm hamburger + chevrons = no-op), mở create
   (thử chọn category/color rồi lưu → kiểm DB có lưu không), mở edit (bấm back không
   sửa gì → dialog huỷ có hiện không), thử delete.
4. Orders: filter chips; mở detail; đổi trạng thái qua sheet (pending→confirmed) →
   xác nhận notification khách + kiểm detail screen có refresh badge không; thử tạo
   lỗi update xem có feedback không.
5. Thử role-guard: từ session manager điều hướng tay tới route customer & ngược lại
   (xác nhận không bị chặn).
6. Điền `## Actor: Manager`. Ảnh giữ local (không commit); doc dùng chữ + evidence.
7. Trả role về `customer` nếu đã flip account dùng chung.

## Success Criteria

- [ ] 8 screen manager có States + bảng findings.
- [ ] Xác nhận 3 nghi P1: no role guard, silent status-update failure, dashboard mở
      nhầm màn đơn.
- [ ] Kiểm chứng thực tế category/color khi tạo SP có lưu không (DB check).
- [ ] Mọi seed finding giữ/loại + severity + evidence.

## Risk Assessment

- Promote account customer đang dùng → manager sẽ mất đường test customer cùng lúc.
  Mitigation: dùng email thứ 2, hoặc chạy phase 3 (customer) xong mới flip sang
  manager cho phase 4, rồi trả về `customer`.
- Đổi trạng thái đơn thật sẽ tạo notification thật cho khách → dùng đơn test, dọn sau.
