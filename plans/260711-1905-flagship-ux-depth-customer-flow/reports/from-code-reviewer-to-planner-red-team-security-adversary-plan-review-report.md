# Red-Team Plan Review — Security Adversary / Fact Checker

Plan: `plans/260711-1905-flagship-ux-depth-customer-flow`
Scope attacked: S5 (phase-06) checkout money path, S4 (phase-05) search query, S1 (phase-02) PII greeting.
Verdict: money path is structurally safe, but the plan contains **factual line/route errors and inverted null-safety** that will cause defects if implemented literally.

---

## F1 — S1 greeting snippet has INVERTED null-safety; will NPE for guests (Critical)
Evidence:
- `lib/blocs/auth/auth_state.dart:5` → `final UserModel? user;` (nullable). `auth_state.dart:13` shows `isAuthenticated => user != null` — user IS null for guest/initial/unauthenticated.
- `lib/models/user_model.dart:9` → `final String fullName;` (NON-nullable; `user_model.dart:62` defaults to `''`).
- Plan `phase-02:23`: `'Xin chào, ${user.fullName?.split(' ').last ?? 'bạn'}'`.

The snippet guards the WRONG field. `fullName?` is dead null-aware code (field can't be null → `?? 'bạn'` never fires; `flutter analyze` will warn "unnecessary ?."). Meanwhile `user` itself is unguarded — on the guest/unauthenticated home render `user` is null and `user.fullName` throws. The plan's risk note ("never render Xin chào, null") does not match its own code. Fix: `authState.user?.fullName` and handle empty-string, e.g. `final name = (authState.user?.fullName ?? '').trim(); final label = name.isEmpty ? 'bạn' : name.split(' ').last;`

## F2 — S1 empty-name renders "Xin chào, " not the intended fallback (High)
Evidence: `user_model.dart:62` → `fullName: map['full_name'] ?? ''`. A profile row with null/blank name yields `fullName == ''`; `''.split(' ').last == ''`. Result: greeting shows a trailing comma with no name. The `?? 'bạn'` fallback in `phase-02:23` cannot catch this because the value is `''`, not `null`. Plan must specify empty-string handling, not null handling.

## F3 — S5 misidentifies the AlertDialog line span (End boundary wrong) (High)
Evidence: `checkout_screen.dart:339` is `showDialog(`; the statement does not close until `checkout_screen.dart:378` (`);`). Lines 370–378 contain the `Navigator.pop` + `pushReplacementNamed` + closing braces.
Plan `phase-06:24,39` repeatedly says "Replace the AlertDialog at `checkout_screen.dart:339–369`". Replacing only 339–369 leaves orphaned closing lines 370–378, producing a syntax break or a dangling half-widget. The real range to replace is **339–378**. This is the single highest-risk instruction in the phase because it sits one block below the cart-clear loop.

## F4 — S5 cites the wrong continue-route `/orders`; real target is `/order-detail` (High)
Evidence: `checkout_screen.dart:369–372` → `pushReplacementNamed('/order-detail', arguments: state.orderId)`. Plan `phase-06:27` says continue "→ existing `pushReplacementNamed('/orders'...)`". Both routes exist (`app_router.dart:48` `/orders`, `:50` `/order-detail`), so an implementer taking the plan literally would silently repoint COD success from the order-detail screen to the orders-list screen — a behavior change the phase explicitly forbids ("visual-only change"). The plan claims "SePay branch untouched / only presentation" but its own copy would alter post-COD navigation.

## F5 — Money path is structurally safe from double-fire / cart-skip (verification, not a defect) (Informational)
Evidence:
- Order creation is bloc-side, gated by an explicit event: `checkout_bloc.dart:47` `on<CheckoutPlaceOrder>`, RPC call at `:91–99`, `isSuccess:true` emitted once at `:124–131`. The widget listener only *reads* states; it cannot create an order.
- `_onPlaceOrder` resets `isSuccess/awaitingPayment:false` at entry (`checkout_bloc.dart:61–68`), so a new order can't inherit a stale success flag.
- COD vs QR are mutually exclusive branches on distinct flags: `checkout_screen.dart:316` (`awaitingPayment`) vs `:329` (`isSuccess`); the bloc sets exactly one (`:127` COD, `:174` QR).
Conclusion: an S5 edit confined to the `showDialog` at 339–378 **cannot** double-fire order creation, alter money fields (server-authoritative per `checkout_bloc.dart:88–90`), or touch the QR branch — **provided F3's end boundary is respected**. If the implementer instead miscuts and deletes the cart-clear loop (`checkout_screen.dart:335–337`) or the QR branch, that guarantee breaks. Recommend the plan pin the exact replace range and add a diff assertion that lines 316–338 are byte-identical post-edit.

## F6 — S4 `ilike` is injection-safe but LIKE metacharacters are un-escaped (Medium)
Evidence: `product_service.dart:38` → `query = query.ilike('name', '%$searchQuery%')`. The postgrest-dart client sends the pattern as a bound filter *value* (not concatenated SQL), so SQL injection and RLS bypass are not possible here — the select still runs under the caller's RLS. However `$searchQuery` is interpolated into a LIKE pattern with **no escaping of `%` / `_`**. A user typing `%` matches the entire catalog; `_` matches any single char. This is a correctness + minor perf/data-scope quirk (search returns everything on a one-char input), not a security breach. If the plan wants exact-substring semantics it should escape `%`, `_`, and `\` before interpolation. Also flag: values containing PostgREST reserved chars (`,` `(` `)`) are edge-case-sensitive; confirm the dart client encodes them (it does for a single `.ilike`, but worth a debounce-era test with `a,b`).

## F7 — S4 has no min-query-length / whitespace guard; empty or `%` query dumps catalog (Medium)
Evidence: `product_service.dart:37` only checks `searchQuery.isNotEmpty`. A whitespace-only or single-`%` debounced keystroke passes the guard and returns `.order('created_at')` over all products (`:41`). Combined with the 250–300ms debounce in `phase-05:26`, rapid typing through `%`/spaces issues full-table reads. Plan should specify a trimmed min-length (>=2) client gate before calling `getProducts`.

## F8 — Plan's "do NOT touch cart-clear" preserves a latent guest cart-clear bug (Medium)
Evidence: `checkout_screen.dart:334` wraps the removal loop in `if (userId != null)` but `userId` is never read inside the loop (`:335–337` iterate `_selectedIds` and dispatch `CartRemoveItem`). For any COD success where `authState.user?.id` is null, the ordered items are NOT removed from the cart even though the order was placed — the user sees already-purchased items still in cart. Phase-06's "do NOT touch cart-clear" directive intentionally freezes this. If auth is guaranteed at checkout this is dormant; the plan should state that assumption explicitly rather than leaving the dead `userId` guard unexamined. Not S5's job to fix, but the planner should record it as a known-accepted risk, not silence.

---

## Unresolved questions for the planner
1. Is checkout reachable by an unauthenticated/guest user? If yes, F1 (NPE) and F8 (cart not cleared) are both live Critical/High, not dormant.
2. Does S5 intend to keep the destination as `/order-detail` (current) or move to `/orders`? The plan text and code disagree — pick one and correct `phase-06:27`.
3. S4: exact-substring or wildcard-tolerant search intent? Determines whether F6 escaping is required.
