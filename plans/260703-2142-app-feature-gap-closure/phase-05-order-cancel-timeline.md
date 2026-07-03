---
phase: 5
title: Order Cancel & Timeline
status: completed
priority: P1
dependencies: []
---

# Phase 5: Order Cancel & Timeline

## Overview
Give customers two things on their order detail: (1) a **status timeline** showing
progress pending→confirmed→processing→shipping→delivered, and (2) a **cancel
button** available only while the order is pending or confirmed. Cancel goes
through a DB RPC because customers have no UPDATE right on `orders`.

## Requirements
- Functional: cancel own order (status ∈ {pending, confirmed}) → status becomes
  `cancelled`; existing notification trigger fires; UI reflects immediately.
  Timeline renders current step; cancelled/refunded shown as a terminal badge.
- Non-functional: cancel is server-authorized (ownership + status guard), not a
  client-trusted write; no broad UPDATE policy added to `orders`.

## Architecture
RLS confirmed: `orders` has customer INSERT + SELECT (own) only; manager ALL. So
add a `SECURITY DEFINER` function `cancel_my_order(p_order_id uuid)`. **Guard must
be atomic (red-team finding):** do the ownership + status check inside a single
UPDATE, not SELECT-then-UPDATE (a manager advancing to `shipping` between a SELECT
and UPDATE could otherwise let a cancel land on a shipped order under READ
COMMITTED):

```sql
create or replace function cancel_my_order(p_order_id uuid)
returns void
language plpgsql
security definer
set search_path = public          -- red-team #3: avoid mutable search_path
as $$
begin
  update orders set status = 'cancelled'
   where id = p_order_id
     and user_id = auth.uid()
     and status in ('pending','confirmed');
  if not found then
    raise exception 'Order cannot be cancelled';
  end if;
end $$;
grant execute on function cancel_my_order(uuid) to authenticated;
```

Verified: `auth.uid()` works inside SECURITY DEFINER (reads JWT GUC), and the
existing `AFTER UPDATE` trigger `on_order_status_change` DOES fire on this update
(`old.status IS DISTINCT FROM new.status`) → notification auto-inserted. FE calls
`supabase.rpc('cancel_my_order', {'p_order_id': orderId})`.

Timeline is derived from a fixed linear happy-path list `[pending, confirmed,
processing, shipping, delivered]` and the order's current status index —
`order_status.dart` has `nextStatuses` (branching) but no linear list, so add a
`static const List<OrderStatus> happyPath` (or a `timelineSteps` getter) there.

## Related Code Files
- Create (DB migration via `apply_migration`): function `cancel_my_order` +
  `grant execute` to `authenticated`. Name it plainly (no plan/phase IDs).
- Modify: `FE/lib/models/order_status.dart` — add linear `happyPath` list for the
  timeline; keep `isActive`, `label`, `nextStatuses`.
- Modify: `FE/lib/services/order_service.dart` — add
  `Future<void> cancelOrder(String orderId)` calling
  `_client.rpc('cancel_my_order', params: {'p_order_id': orderId})`.
- Modify: `FE/lib/blocs/order/order_event.dart` — add `OrderCancel(orderId, userId)`.
- Modify: `FE/lib/blocs/order/order_bloc.dart` — handler calls
  `cancelOrder`, then re-dispatch `OrderLoadDetail` (and refresh list) or
  optimistically `selectedOrder.copyWith(status: OrderStatus.cancelled)`; emit
  error on failure.
- Modify: `FE/lib/screens/orders/order_detail_screen.dart`
  - Timeline widget: insert right after the header card (after line ~109), before
    "Sản phẩm". Render `happyPath` with current index highlighted; if status is
    cancelled/refunded show a terminal badge instead.
  - Cancel button: append after the address card (after line ~176), gated on
    `order.status == pending || order.status == confirmed`. Confirm dialog
    ("Huỷ đơn hàng?") → dispatch `OrderCancel`. `AppButton` already imported.
- Modify: `FE/lib/screens/orders/orders_screen.dart` (list) — optional: reflect
  cancelled badge after returning; the list re-queries on load.

## Implementation Steps
1. Write + apply the `cancel_my_order` migration; test it manually with a
   customer JWT context (should succeed on pending/confirmed, reject otherwise).
2. Add `happyPath` to `order_status.dart`.
3. Add `cancelOrder` to the service; `OrderCancel` event + handler to the bloc.
4. Build the timeline widget (stepper-style: dot + label per step, current
   highlighted; cancelled → red terminal chip).
5. Add the gated cancel button + confirm dialog; on success reload detail.
6. Verify the notification row appears (trigger) and customer sees it.

## Success Criteria
- [ ] Customer cancels a pending order → DB status `cancelled`, notification row
      created, UI shows cancelled.
- [ ] Cancel button hidden for processing/shipping/delivered/cancelled/refunded.
- [ ] RPC rejects a cancel on someone else's order or a non-cancellable status.
- [ ] Timeline highlights the correct current step; cancelled shows terminal state.
- [ ] `flutter analyze` clean; manager order flow unaffected.

## Risk Assessment
- **RLS/authorization**: broad UPDATE policy would let customers set any status.
  Mitigation: `SECURITY DEFINER` RPC with ownership + status whitelist in a single
  atomic UPDATE; `SET search_path = public`; grant to `authenticated` only.
- Race/TOCTOU: manager advances status between UI load and cancel. Mitigation:
  single-statement UPDATE with the status guard in the WHERE clause + `if not
  found then raise` (never SELECT-then-UPDATE); FE surfaces the error and reloads.
- Timeline vs branching graph: don't reuse `nextStatuses` for the line.
  Mitigation: dedicated `happyPath` constant.
