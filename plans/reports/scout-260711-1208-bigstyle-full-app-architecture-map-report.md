# Scout Report — BigStyle Full App Architecture Map

**Date:** 2026-07-11 12:08 | **Branch:** `dev` | **Scope:** entire Flutter app + Supabase backend | **Method:** 4 parallel Explore agents (customer screens / manager+admin+routing / all blocs / services+models+DB)

**Purpose:** Ground a comprehensive test pass (all roles, flows, features, UI/UX) → then a big improvement plan.

---

## 0. Scale
158 Dart files, ~23K LOC. screens 51f/15.7K · blocs 55f/3.5K · services 14f/1.5K · models 16f/1.2K · widgets 10f/0.8K · config 8f/0.5K.

**CODEBASE.md is stale** — real app is bigger: 3 roles (customer/manager/**admin**), plus wishlist, reviews, vouchers, support-chat (human), SePay payment, delivery map — all shipped since that doc.

## 1. Architecture
- **Pattern:** BLoC (Event→Bloc→State), services wrap Supabase client. Wired in `main.dart` via MultiBlocProvider.
- **Backend:** Supabase (Postgres 17, project `agbnpqgxsppdrpbqoipo`, ACTIVE_HEALTHY). Auth, DB, Storage, Realtime, RLS + SECURITY DEFINER RPCs. No custom backend except Edge Fn `admin-invite-user`.
- **Routing:** OnGenerateRoute (string routes). Splash resolves role → `/admin` | `/manager` | `/home` | `/login`.

## 2. Roles & shells
| Role | Entry | Shell |
|---|---|---|
| Customer | `/home` | AppBottomNav (home, products, cart, orders, favorites/profile) |
| Manager | `/manager` | ManagerShell — 5 tabs: Dashboard, Products, Orders, Support, Profile |
| Admin | `/admin` | AdminShell — 4 tabs: Dashboard, Users, Categories, Profile |
| Shared | — | edit-profile, chat(AI), support-chat, notifications, delivery-map |

## 3. BLoC inventory (18)
**Customer core:** Auth (OTP + password + Google + confirm-pending), Cart (optimistic qty, reload-on-add), Checkout (server-authoritative totals via `create_order` RPC; COD vs bank-transfer paths), Payment (realtime + 3s poll, `_paidHandled` latch, cart-clear owned by CartBloc), Product (client-side filter/search/sort), ProductDetail (variant color/size), Order (load/detail/cancel via RPC), Review (purchase-gated eligibility, upsert, `_loadRequestId` race guard), Wishlist (optimistic toggle, mock-user skip), Notification (unread badge).
**Chat:** ChatBloc (AI bot, welcome msg, fire-and-forget save), SupportChatBloc (screen-scoped, per-thread realtime), SupportInboxBloc (app-scoped staff inbox, denormalized unread).
**Manager/Admin:** ManagerBloc (dashboard+orders+status update, requestId race guards), AdminBloc (users+categories+brand), ManagerProductBloc, ManagerCategoryBloc, ManagerVoucherBloc.

## 4. Services → tables (14)
Auth·profiles; Product·products/variants/categories (+products/avatars buckets); Order·orders/order_items (RPCs create_order, cancel_my_order); Payment·payments (realtime; SePay QR via SEPAY_BANK/ACC); Cart·cart/cart_items; Review·reviews (RLS+trigger gate); Voucher·vouchers (validate_voucher RPC); Chat·chat_messages (**Claude mock fallback if no key**); Support·support_conversations/messages (2 RPCs, realtime); Notification·notifications (auto via order trigger); Admin·profiles/categories (Edge Fn admin-invite-user); Category·categories; Wishlist·wishlist_items.

## 5. DB (16 tables, all RLS)
profiles, categories, products, product_variants, cart, cart_items, orders, order_items, payments, notifications, reviews, chat_messages, support_conversations, support_messages, wishlist_items, vouchers.
**RPCs (SECURITY DEFINER):** is_manager, is_staff, create_order (server-authoritative pricing+voucher), cancel_my_order, validate_voucher, update_product_with_variants, get_or_create_my_conversation, mark_conversation_read. **Triggers:** handle_new_user, notify_order_update, enforce_review_gate, update_product_rating, bump_support_conversation, force_support_message_defaults. **Buckets:** products(pub,5MB), avatars(priv,2MB), reviews(pub,5MB). **Realtime:** payments, support_messages, support_conversations.
**Live seed (from MCP):** products 15, product_variants 87, categories 5, orders/order_items/payments 7 each, profiles 4, cart/cart_items 2, notifications 7, vouchers 2; reviews/chat_messages/wishlist_items/support_* = 0.

## 6. Config / theme
Env: SUPABASE_URL, SUPABASE_ANON_KEY, GOOGLE_MAPS_API_KEY, GOOGLE_WEB_CLIENT_ID, CLAUDE_API_KEY (opt→mock), SEPAY_BANK/ACC. `AppConfig.flatShippingFee = 30000 VND` (single source, also hardcoded in seed SQL). Theme = Warm Terracotta v2 (primary #9A3F35 rust, bg #FBF6EF), Playfair+DM Sans, warm skeletons. Hardcode-color guard enforced at 0.

## 7. Test credentials / seed setup
`seed_demo_accounts_and_orders.sql` needs MANUAL steps: (0) sign up manager + 2 customer emails via app OTP, (1) `UPDATE profiles SET role='manager'`, (2) seed 3 demo orders (A confirmed+bank/paid, B delivered+cod/paid, C pending+bank → tests "Thanh toán lại"). Admin role set via SQL. Shipping addr hardcoded 12 Lê Lợi Q1 HCM.

## 8. Risk hotspots (for test targeting)
1. **Order status enum mismatch** — DB has 7 (…processing, refunded), Dart model 5. Deserialization/state-machine breaks if DB returns processing/refunded. **HIGH.**
2. **No stock decrement** on order → oversell possible. Intentional backorder or bug?
3. **Money integrity** — client no longer sends totals (good); verify can't inflate via price fields; shipping fee no negative/DoS.
4. **Payment races** — `_paidHandled` latch, cart clears exactly once; retry idempotent via unique pending index; cancelled order leaves lingering pending payment.
5. **Review gate** — RLS+trigger require delivered purchase; is_verified immutable; gate fail can silently no-op.
6. **Support chat scoping** — screen-scoped sub must cancel on thread switch (no leaked late msgs); denormalized unread can go stale.
7. **Manager store isolation** — products gated store_id=auth.uid(); reassignment orphans.
8. **Mock fallbacks silent** — Claude mock (no key) + SePay assertion (missing key crashes buildQrUrl).
9. **Stale customer name** — shipping_address JSONB snapshot, not profiles join.
10. **Realtime channel cleanup** — payment channels per-order; leak risk.

## 9. Testing surface (role × area)
- **Guest/Auth:** OTP send/cooldown/rate-limit/invalid/resend; password signup/signin/validation; Google; guest→login redirects (cart/fav/review/add-to-cart); splash session resolve; signout.
- **Customer:** home load/shimmer/error; product list filter(category/size/sale)/search/sort/empty; detail carousel/color/size/variant-mismatch/add-cart/buy-now/wishlist/share/reviews; cart select/qty/delete/edit/checkout-subset; checkout address(manual+GPS)/promo/COD+bank/place-order; payment QR/copy/check/auto-watch/re-pay; orders list/detail/timeline/delivery-route/review-button; favorites guest-gate/grid/empty; notifications; AI chat; support chat.
- **Manager:** dashboard stats/recent; orders filter+status-update(sheet)+notify; product CRUD+variants+image; category CRUD+soft-delete; voucher CRUD+toggle; support inbox→reply; profile+brand.
- **Admin:** dashboard revenue+6 stats; user search/role-change(confirm)/invite/brand; category add/edit/toggle/delete; profile.
- **Shared:** edit-profile avatar upload(2MB/avatars bucket); delivery-map GPS↔shop route/fee/permission-deny fallback.

## 10. Unresolved questions (carry into test/plan)
1. Order status: are `processing`/`refunded` ever emitted by manager UI/DB? If yes → model deserialization bug.
2. Stock: oversell intentional or missing inventory hold?
3. SePay webhook: is payment.status='success' write-back implemented & secured? (payments table has 0 rows beyond seed — realtime confirm untested live.)
4. `admin-invite-user` Edge Fn: atomic auth+profile create? response shape?
5. Review images[]: upload path exists? (upsertReview doesn't handle images.)
6. Pagination: product list all-at-once vs paged? No infinite scroll seen.
7. Wishlist/reviews/support all 0 rows live → never exercised end-to-end on this DB.
8. Web preview can't test maps/geolocator/image-picker/google-signin → needs real Android emulator for full coverage.
