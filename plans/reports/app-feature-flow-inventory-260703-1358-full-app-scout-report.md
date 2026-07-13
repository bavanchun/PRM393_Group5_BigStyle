# BigStyle — Feature & Flow Inventory (full-app scout)

- Date: 2026-07-03 · Stack: Flutter + flutter_bloc + Supabase · ~13.5k LOC, 101 dart files
- 27 screens · 12 bloc groups · 9 services · 11 models · Vietnamese UI · bigsize apparel (M–5XL)

## Architecture
- `main.dart` → dotenv + Supabase init → `MultiRepositoryProvider` + `MultiBlocProvider` (12 blocs app-wide) → `MaterialApp(onGenerateRoute: AppRouter)`.
- Pattern: screen → BloC (event/state, Equatable) → Service → Supabase. Models map snake_case tables.
- Two shells: customer (`AppBottomNav`) + manager (`ManagerShell` IndexedStack + `ManagerBottomNav`).
- Role gating = client-side only (`user.role.name == 'manager'` at login/splash). No route guard; RLS is server-side (is_manager()).

## Domains & features

### 1. Auth + Profile + Shell
- Email OTP (6-digit code), Google sign-in (idToken → Supabase), debug quick-login (customer/manager mock, hidden in release).
- Splash session bootstrap (`CheckSessionEvent`, 1.5s) → role route.
- Profile view (avatar/role/menu), edit (name/phone/address; avatar picker NOT wired), logout (confirm).
- `AuthService.userStream` (onAuthStateChange) defined but NOT consumed — auth polled imperatively.

### 2. Catalog + Cart + Checkout + Wishlist
- Home feed: hero banner (static), category strip, featured (max 4) + new grids, shimmer.
- Product list: live search, filter chips (category/size/new/sale), sort sheet. In-memory filter. No body_type_fit filter.
- Product detail (811 lines): image carousel, color/size selector, variant resolution, reviews, size guide. Share = no-op. "Thêm giỏ" + "Mua ngay".
- Cart: qty +/- , remove, subtotal → checkout. Promo/discount columns unused.
- Checkout: address + note → place order → order+order_items, clear cart → `/orders`. **Shipping hardcoded 30k** (distance-tier logic in bloc = dead code). No payment step (COD-style).
- Wishlist: shared productIds set, optimistic toggle, auth-guarded.
- Reviews: 1 per user/product, rating + size_feedback + comment, upsert; updates product avg via trigger.

### 3. Orders + Delivery + Notifications + Chat
- Orders: list (own, newest-first, status badge), detail (items + price breakdown + address). 7-state OrderStatus enum.
- Delivery map (`/delivery-map`): Google Maps + geolocator + Directions polyline + distance/fee/time bottom sheet. **No in-app entry point** (route exists, unlinked). Shop location + fee tiers hardcoded. Some buttons stub.
- Notifications: list, mark-read, unread count. Model has NO type field (order_update/promotion categorization absent).
- Chat (AI): Claude API (`claude-sonnet-4-6`, Vietnamese fashion bot) + product RAG from Supabase; mock fallback when no key. History in chat_messages.

### 4. Manager (admin)
- Dashboard: 4 stat cards (revenue/pending/products/customers), recent orders. Quick actions (add product/category/promo) = "coming soon" stubs.
- Product CRUD: FULLY implemented — list (search/filter), create (images upload, variants + body-measurement ranges, sizing table), edit/delete. **Category hardcoded** (not persisted from DB).
- Order management: view all + status filter chips → shared OrderDetailScreen (read-only). **`updateOrderStatus` has NO caller** — manager cannot change status, no notification trigger.
- No category mgmt / promotions / customer mgmt (stubs/absent). Pagination arrows dead.

## What's REAL vs STUB/GAP

| Working end-to-end | Stub / dead / gap |
|---|---|
| OTP + Google login | Manager order status change (no caller) |
| Browse catalog, search/filter/sort | Payment integration (none, COD-style) |
| Product detail + variants | Shipping distance tiers (hardcoded 30k) |
| Cart CRUD | Promo code redemption (cols unused) |
| Checkout → create order | Delivery map (unlinked, hardcoded shop) |
| Wishlist | Share button (no-op) |
| Reviews (rating/size feedback) | Profile avatar picker (UI only) |
| AI chat (+ mock fallback) | Notification types (no enum) |
| Manager product CRUD | Category mgmt, promotions, customer mgmt |
| Manager dashboard stats | Quick-action cards (coming soon) |
| Order list/detail (customer + manager) | List pagination controls |

## Data model (Supabase, 11 tables)
profiles · categories · products · product_variants · cart · cart_items · orders · order_items · payments (unused in FE) · notifications · reviews · chat_messages · wishlist_items (migration). RLS via is_manager(). Storage buckets: products/avatars/reviews.

## Key cross-cutting notes
- Two overlapping catalog blocs: `ProductBloc.ProductLoadDetail` vs `ProductDetailBloc.LoadProductDetail` (both fetch by id).
- Payment table exists in schema but no payment_service / payment fields used → payments not implemented.
- Order status→notification trigger exists in DB (on_order_status_change) but FE never changes status, so never fires.

## Unresolved questions
- Payments: intentionally COD-only for scope, or unfinished? (schema has payments table + methods cod/vnpay/momo)
- Delivery map: meant to link from order detail? Currently orphaned route.
- Manager order status change: planned feature not wired — priority?
- Notification type categorization: DB trigger writes type=order_update but model drops it — intended?
