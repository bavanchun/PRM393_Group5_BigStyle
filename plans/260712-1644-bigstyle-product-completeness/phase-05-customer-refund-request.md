---
phase: 5
title: "Customer Refund Request"
status: code-complete-pending-device-pass
effort: "medium"
---

# Phase 5: Customer Refund Request

## Overview

Extend the existing manager-side refund status into a full loop: customer
requests refund with reason on delivered orders → manager reviews →
approve flips order to existing `refunded` status; both sides notified.
Touches money-path adjacent code — extra care, no changes to atomic
stock/payment logic.

## Requirements

<!-- Updated: Validation Session 1 - 7-day refund window confirmed -->
- Functional: customer can submit one refund request per delivered order (reason required), **within 7 days of delivery** (user-confirmed); manager sees pending requests, approves/rejects with optional note; approval transitions order → `refunded`; notifications both directions.
- Non-functional: RLS enforces customer-own-order insert + manager-only decision; no double-request; no regression in existing order status flow (OrderStatus enum already includes `refunded`).

## Architecture

- DB: `refund_requests` table (`id`, `order_id` FK unique, `user_id`, `reason` text, `status` enum pending/approved/rejected, `manager_note`, `created_at`, `decided_at`) + RLS: customer insert own delivered order + select own; manager select all + update status. 7-day window enforced in insert RLS: order delivered AND delivered timestamp ≥ now() - interval '7 days' — verify orders table has a delivered timestamp column first; if absent, add `delivered_at` (set by existing status-transition path) in the same migration. UI hides request button outside window. Trigger or RPC on approve → update `orders.status = 'refunded'` + insert notifications (reuse existing notification-writing pattern; Phase 3/4 then deliver it live/push for free).
- Prefer single RPC `decide_refund_request(request_id, decision, note)` (SECURITY DEFINER, pinned search_path per repo convention) so decision + order transition + notification are atomic.
- FE: model + service + bloc (`refund_request`) following existing kebab/feature-dir conventions; customer entry in `order_detail_screen.dart` (delivered only, hidden when request exists); manager entry in orders screens (pending badge + decision sheet mirroring `order_status_update_sheet.dart`).

## Related Code Files

- Create: migration `FE/supabase/migrations/YYYYMMDDHHMMSS_refund_requests.sql` (table + RPC), `FE/lib/models/refund_request_model.dart`, `FE/lib/services/refund_request_service.dart`, `FE/lib/blocs/refund_request/*`, customer request sheet widget, manager decision sheet widget
- Modify: `FE/lib/screens/orders/order_detail_screen.dart`, `FE/lib/screens/manager/manager_order_detail_screen.dart`, `FE/lib/screens/manager/manager_orders_screen.dart` (pending indicator), `FE/lib/widgets/status_badge.dart` (request-pending state if needed)

## Implementation Steps

1. Migration: table + enum + RLS + `decide_refund_request` RPC (atomic decision, follows hardened function conventions: pinned `search_path`, revoke public execute where applicable).
2. FE model/service/bloc with unit tests (service mocked, bloc transitions).
3. Customer UI: "Yêu cầu hoàn tiền" on delivered order detail → reason sheet → optimistic pending state.
4. Manager UI: pending-request indicator on order list/detail → decision sheet (approve/reject + note).
5. Notifications: insert rows on request-created (→ manager) and decided (→ customer) inside RPC/trigger.
6. Regression: existing order timeline/cancel tests still green; verify `refunded` badge rendering both roles.
7. Gate: `flutter analyze` 0, `flutter test` xanh, color guard 0.

## Success Criteria

- [x] Customer requests refund on delivered order; duplicate blocked (DB unique + UI hidden) <!-- refund_requests.order_id unique constraint (DB); order_detail_screen.dart hides button when currentRequest != null. Live device UI walkthrough deferred to Phase 1. -->
- [x] Non-delivered orders cannot request (RLS + UI) <!-- INSERT policy requires o.status='delivered' (live-verified via pg_policy read); OrderModel.isRefundRequestWindowOpen also gates status==delivered client-side -->
- [x] Request ngoài window 7 ngày bị chặn (RLS probe + UI ẩn nút) <!-- INSERT policy requires delivered_at >= now() - interval '7 days' (live-verified); FE isRefundRequestWindowOpen mirrors it (strict <, marginally stricter than RLS's >=, fails closed not open) -->
- [x] Manager approve → order `refunded` atomically + both notifications <!-- code-reviewer flagged CRITICAL (enum lacks 'refunded') + HIGH (trigger-reuse claim unverifiable) — both independently DISPROVEN via live queries this session: enum_range confirms {pending,confirmed,processing,shipping,delivered,cancelled,refunded}; on_order_status_change trigger + notify_order_update() both confirmed live with an explicit 'refunded' case. Added defense-in-depth: approve UPDATE now requires status='delivered' too (migration 20260712173510). Manager-side notification-on-request-created verified via notify_refund_request_created trigger (new). Live device approve-tap deferred to Phase 1. -->
- [x] Manager reject → order status unchanged, customer notified <!-- decide_refund_request's reject branch explicitly inserts the customer notification (no order status touched) -->
- [x] RLS probes: customer cannot decide, cannot request others' orders <!-- live-read pg_policy: no customer UPDATE policy exists (default-deny); INSERT check requires both user_id=auth.uid() AND the order's own user_id=auth.uid() -->
- [x] Analyze/test/color gates pass <!-- flutter analyze 0, flutter test 140/140 (126 baseline + 14 new: 12 initial + 2 interleaved-dispatch regression tests added after code review), check_hardcoded_colors.sh exit 0 -->

### Code review (code-reviewer subagent, 2 passes — first cut off by a server error mid-report, resumed to completion)
4 findings — 2 refuted with live-DB evidence, 2 real and fixed:
1. **CRITICAL (refuted)** — claimed `order_status` enum lacks `refunded`, based on reading one migration that temporarily dropped it without finding the later one(s) that restored it. Live `enum_range` query disproves this.
2. **HIGH (refuted)** — claimed the "reuses on_order_status_change trigger" comment was unverifiable from the repo. Live `pg_trigger`/`pg_get_functiondef` queries confirm the trigger exists exactly as named and its function has an explicit `'refunded'` case.
3. **HIGH (real, fixed)** — `RefundRequestBloc` (app-scoped, same tier as `NotificationBloc`) reintroduced the exact cross-order staleness bug Phase 3 found and fixed in `NotificationBloc`: `_onLoadForOrder`/`_onSubmit`/`_onDecide` had no guard against a late-resolving async call for one order overwriting `currentRequest` after the bloc had moved on to a different order. Fixed with a `_requestedOrderId` guard (mirroring `NotificationBloc`'s `_subscribedUserId`) across all three handlers, `RefundRequestDecide` now carries `orderId` explicitly instead of reading it back from state post-await, and 2 new regression tests reproduce the interleaved-dispatch race.
4. **MEDIUM (real, fixed)** — `decide_refund_request`'s approve branch didn't re-check the order was still `delivered` before flipping it to `refunded`. Low reachability (no UI path moves a delivered order elsewhere first) but cheap to harden given this is money-adjacent code — added `and status = 'delivered'` to the UPDATE (migration `20260712173510`).

## Risk Assessment

- Money-path adjacency: refund is status-level only (SePay settlement is manual/off-app) — state this in UI copy ("hoàn tiền xử lý thủ công bởi cửa hàng") to avoid implying automatic money movement.
- Status enum churn risk: `refunded` already exists in DB + FE enum (aligned in PR #25) — do not add new order statuses.
