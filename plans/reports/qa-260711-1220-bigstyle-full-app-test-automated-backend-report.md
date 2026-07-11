# QA Test Report — BigStyle Full App (Layer 1 Automated + Layer 2 Backend)

**Date:** 2026-07-11 12:20 | **Branch:** `dev` | **Tester:** automated + Supabase MCP live verification
**Supabase:** project `agbnpqgxsppdrpbqoipo` (bigstyle-prm393, ACTIVE_HEALTHY, Postgres 17)
**Companion:** [scout report](scout-260711-1208-bigstyle-full-app-architecture-map-report.md)

## Overview
| Layer | Status |
|---|---|
| 1. Automated (analyze + unit/widget/bloc tests) | ✅ DONE — green |
| 2. Backend contract (live DB, RPCs, RLS, advisors) | ✅ DONE — 4 real findings |
| 3. Interactive UI web (customer + manager) | ✅ DONE — verified, 1 new bug (F5) |
| 3b. Interactive UI web (admin) | ⛔ deferred — app has no admin dart-define; needs emulator |
| 4. Interactive native emulator (maps/geo/picker/google/SePay + 0-row features) | ⛔ BLOCKED — no /dev/kvm (needs `sudo modprobe kvm_amd`) |

## Layer 1 — Automated (ground truth)
- `flutter analyze` → **0 issues** (25s).
- `flutter test` → **104/104 pass** (grew from 66; covers OTP input, checkout bloc COD/empty-guard, notification mark-read, admin add-user, order customer-name mapping, revenue recognition incl. UTC day-boundary, variant color_hex mapping, order-item id mapping, order-status cancellable gate, support model mapping).
- Stack trace in output = intentional error-path logging inside a passing test, not a failure.

## Layer 2 — Backend contract findings (live DB)

### 🔴 F1 (HIGH) — Voucher discount never applied to orders
`create_order` RPC (SECURITY DEFINER) body:
```
if p_promo_code is not null and p_promo_code <> '' then
    v_discount := 0;          -- <-- always 0, never calls validate_voucher
end if;
v_total := v_subtotal + p_shipping_fee - v_discount;
```
Discount is hard-stubbed to 0 regardless of promo code. `validate_voucher` exists but is only used client-side for a **preview** at checkout. Result: customer sees a discount at checkout, but the created order charges **full price** (discount_amount=0). Voucher/promo feature is non-functional end-to-end. Trust/correctness bug. (2 vouchers seeded, so feature is meant to work.)

### 🟠 F2 (MEDIUM) — No stock decrement / oversell possible
No trigger on orders/order_items touches `product_variants.stock_qty`, and `create_order` never decrements it. `stock_qty` is display-only. Concurrent/repeat orders can oversell a variant indefinitely. No inventory hold. (Intentional backorder? Undocumented → treat as gap.)

### 🟠 F3 (MEDIUM) — Order-status enum mismatch → silent mislabel
DB enum `order_status` = {pending, confirmed, **processing**, shipping, delivered, cancelled, **refunded**} (7). Dart `OrderStatus` = 5 (no processing/refunded). `OrderModel.fromMap` uses `firstWhere(... orElse: () => OrderStatus.pending)` → any `processing`/`refunded` order **renders as "Chờ xác nhận" (pending)** to customer AND manager. No crash, but wrong status shown (e.g. a refunded order looks pending). Manager UI can't set those (5-state machine), so only reachable via SQL/admin/webhook — but mislabels whenever present.

### 🟠 F5 (MEDIUM) — Manager dashboard "Khách hàng" always 0
Manager dashboard stat card "Khách hàng" renders **0**, but DB has 1 customer profile (and 2 distinct users have placed orders). Customer-count query is wrong (returns 0 despite existing customers). Matches an earlier carried demo-fix concern. Verified live via web login (manager role) + SQL cross-check (`customer_profiles=1`).

### 🟡 F4 (LOW) — `create_order` trusts client shipping fee
`p_shipping_fee` inserted verbatim, no server validation/derivation. UI uses flat 30000, but the RPC (callable by any authenticated user) accepts arbitrary values. Low impact (self-harm only; totals still recomputed for subtotal).

### Security advisors (Supabase linter)
- WARN `function_search_path_mutable` ×2: `notify_order_update`, `update_sold_count` (missing `SET search_path`). (Note: prior PR #23 pinned search_path on handle_new_user + review/chat triggers — these two were missed.)
- WARN `public_bucket_allows_listing` ×2: `products`, `reviews` buckets have broad SELECT → clients can list all files (not needed for URL access).
- WARN SECURITY DEFINER funcs executable by anon/authenticated ×many: mostly intended (create_order/cancel_my_order guard `auth.uid()` internally; is_admin/is_manager/is_staff return bool). Minor: trigger-functions (bump_support_conversation, notify_order_update, update_product_rating, prevent_profile_role_self_escalation, handle_new_user, update_sold_count) are also RPC-exposed — should be revoked from API.
- WARN `auth_leaked_password_protection` disabled (HaveIBeenPwned check off).

### Performance advisors
- WARN Multiple Permissive Policies ×120 — many tables have overlapping permissive RLS policies per role/action (each evaluated every query).
- WARN Auth RLS Init Plan ×21 — policies use bare `auth.uid()` instead of `(select auth.uid())` → re-evaluated per row.
- INFO Unindexed FKs ×7, Unused Index ×2.
- All are scale concerns; fine for demo, worth a cleanup pass.

### ✅ Positive confirmations (verified, no issue)
- `create_order` pricing is **server-authoritative** — recomputes unit price from `coalesce(sale_price, base_price)` per variant, ignores client money fields. Can't inflate/deflate totals from client.
- `profiles_prevent_role_self_escalation` trigger present — blocks users escalating own role.
- `on_review_guard` trigger (before insert/update) enforces purchase gate; `is_verified` server-computed.
- Payment idempotency: unique partial index `payments(order_id) where status='pending'`.
- Bloc-level race guards (requestId, _paidHandled, _loadRequestId) covered by passing tests.

## Live DB state (seed)
- **Accounts (4):** admin `hoangbavan4478+admin@gmail.com`; customer `hoangbavan4478+customer2@gmail.com`; manager `hoangbavan4478@gmail.com` + `hoangbavan4478+manager@gmail.com`. (All +alias of user's gmail.)
- **Orders (7):** pending·cod 1, pending·bank 2, confirmed·bank 3 (paid), delivered·cod 1. No processing/refunded rows (so F3 not currently triggered).
- **Catalog:** products 15, variants 87, categories 5, vouchers 2.
- **Never exercised e2e (0 rows):** reviews, chat_messages, wishlist_items, support_conversations, support_messages. These features have zero live data — untested end-to-end on this DB.

## Layer 3 — Interactive web (customer + manager) ✅
Unblocked by: set known test password (`BigStyleTest2026!`) on 3 alias accounts (+customer2, +manager, +admin) via `auth.users` bcrypt update (user-authorized); added `BIGSTYLE_TEST_{MANAGER,CUSTOMER}_*` dart-defines to the web launch config → debug-login buttons appear → one-tap login (Flutter web canvas can't accept DOM text input, so debug buttons are the only viable web login path).

**Customer (+customer2) — verified:**
- Login → Home renders: search, banner (Giảm 30%), category pills, featured/new grids, bottom nav w/ cart badge = 2 (matches DB). No console errors.
- Cart: 2 items w/ size + qty + delete; "Chọn tất cả" → subtotal 0đ→**20.000đ** (2×10.000đ, math correct); button enables "Mua hàng (2 sản phẩm)".
- Profile: name "Trần Thị Demo", email, role badge "Khách hàng", menu (orders/wishlist/support/staff-chat/store/logout). Logout → confirm dialog → login. ✅

**Manager (+manager) — verified:**
- Login → routes to Manager dashboard "Quản lý": Doanh thu hôm nay 0đ (correct — no orders today), Đơn chờ xác nhận 3, Tổng sản phẩm 15, **Khách hàng 0 (BUG F5)**. Quick actions + recent orders render.
- Orders screen: status filter chips (Tất cả/Chờ xác nhận/Đã xác nhận/Đang giao…); each order has "Đổi trạng thái" + "Chi tiết"; delivered ("Hoàn thành") order correctly shows only "Chi tiết" (state machine hides terminal transition). Order totals vary 11k–380k. ✅

**Data-quality note:** all catalog products display uniform **10.000đ** (likely test-junk pricing) while real order totals vary (11k/21k/40k/380k). Worth cleaning for demo realism.

## Layer 3b/4 — Admin + native (BLOCKED / deferred)
- **Admin:** app's login only reads MANAGER/CUSTOMER dart-defines (no admin debug button); Flutter web can't type into fields → admin UI must be tested on emulator (adb text input). Deferred.
- **Native (emulator):** `/dev/kvm` absent; `sudo modprobe kvm_amd` needs interactive auth (unavailable to agent). Without KVM the emulator is software-mode (unusably slow). **Blocked** until user runs `sudo modprobe kvm_amd` once (persist via `/etc/modules-load.d/kvm.conf`). Covers: maps, geolocator, image-picker, Google sign-in, SePay QR realtime, and end-to-end for the 5 zero-row features (reviews/wishlist/chat/support).

## Recommendations (feed into Task 3 big plan)
1. **Fix F1 voucher** — make `create_order` call `validate_voucher(p_promo_code, v_subtotal)` and apply the returned discount (single source of truth). HIGH.
2. **Decide F2 stock** — either decrement stock_qty in `create_order` with an availability check (reject oversell) or document backorder intent. MEDIUM.
3. **Fix F3 enum** — add `processing`/`refunded` to Dart `OrderStatus` (label + state machine) so DB truth renders correctly. MEDIUM.
3b. **Fix F5 dashboard customer count** — correct the manager "Khách hàng" stat query (currently returns 0). MEDIUM.
3c. **Clean test-junk pricing** — catalog products all 10.000đ; set realistic prices for demo. LOW.
4. Harden F4 (derive shipping server-side), pin search_path on the 2 flagged funcs, revoke API EXECUTE on trigger-only funcs, tighten public-bucket SELECT, enable leaked-password protection. LOW/security-hygiene.
5. RLS perf cleanup: wrap `auth.uid()` in `(select …)`, consolidate duplicate permissive policies, index the 7 FKs. Scale.
6. Exercise the 0-row features (reviews/wishlist/support/chat) end-to-end once login is unblocked.

## Unresolved (blocking Task 2 completion)
- Need login path for interactive test: (a) passwords for the 4 test accounts, or (b) the 4 BIGSTYLE_TEST_* dart-define values (rebuild web+emulator → debug buttons), or (c) authorize creating a fresh throwaway signup on prod + role-promote via MCP.
- Is F2 oversell intentional (backorder) or a bug?
- Is F1 voucher a known-incomplete stub or a regression?
