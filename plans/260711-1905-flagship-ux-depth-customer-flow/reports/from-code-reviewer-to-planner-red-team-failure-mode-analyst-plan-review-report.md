# Red-Team Plan Review — Failure Mode Analyst / Flow Tracer

Plan: `plans/260711-1905-flagship-ux-depth-customer-flow`
Reviewer posture: hostile. Every finding is traced to `FE/lib` source with file:line evidence.

## Verdict

The foundation (Phase 1) and S1 greeting/S4-search-reuse claims are mostly sound, but **two signature moments (S2 Hero, S3 fly-to-cart) are architecturally blocked by the current screen/BLoC structure** and will not work as written. The plan hand-waves the exact failure modes it lists as "risks." Do not start Phases 3–4 until the issues below are designed out.

---

## F1 — CRITICAL — S2 Hero has no destination during the push transition (flight silently no-ops)

- Phase 3 (S2), "Hero tag plumbing" / "Image provider parity"
- **Scenario:** User taps a card. Router pushes `ProductDetailScreen` via `MaterialPageRoute` (`app_router.dart:38-39`). On the new route's first frame `didChangeDependencies` dispatches `LoadProductDetail` (`product_detail_screen.dart:39-42`), whose handler emits `isLoading:true` then `await _productService.getProductById(...)` (`product_detail_bloc.dart:20-22`). While loading, the screen returns `Center(child: CircularProgressIndicator())` (`product_detail_screen.dart:72-73`) — the carousel, and therefore the Hero-tagged destination image, **is not in the tree**. Flutter collects both routes' Heroes at transition start; with the destination Hero absent for the full ~300ms transition, the shared-element flight does not happen (source hero just fades). On a real network the product is essentially never loaded within the transition window.
- **Why the plan's fix doesn't help:** Home passes only `product.id` as the route arg (`home_screen.dart:122-126`); no image URL reaches detail. Phase 1's skeleton (replacing the spinner) still has no image carrying the matching Hero tag. There is nothing to fly into.
- **Required design change:** thread the tapped `imageUrl` through route args and render that image (with the Hero tag) immediately behind the skeleton, before the async load resolves. Until that is in the plan, S2 is non-functional.
- Evidence: `product_detail_screen.dart:39-42,72-73`; `product_detail_bloc.dart:20-22`; `home_screen.dart:122-126`; `app_router.dart:38-39`.

## F2 — CRITICAL — S3 fly-to-cart fires independent of the async cart result and before the add-to-cart guards

- Phase 4 (S3), "Flight" / "Badge bounce + count" / "Haptic"
- **Scenario:** `_addToCart` bails out early on four paths before anything is added: not-logged-in → pushes `/login` (`product_detail_screen.dart:657-666`), no size (`:669-677`), no color (`:680-688`), no matching variant (`:701-709`). It only dispatches `CartAddItem` at `:711`, and the badge count is derived from `CartBloc` state (`app_bottom_nav.dart:22`) which updates **only after** the async Supabase round-trip resolves (the code itself waits on `cartBloc.stream...timeout(5s)` in `_buyNow`, `:760-764`). A fixed fast-duration flight + `Haptics.success()` will play a "successfully added" animation even when the add was aborted (redirected to login) or is still in flight / fails server-side. Badge "bounce + increment" will not be in sync with the landing flight.
- **Required design change:** trigger the flight only on the post-`:711` success return, and drive the badge pop off the actual `CartBloc` count-increase event (not a synchronous assumption). Fire the success haptic on cart confirmation, not on flight completion.
- Evidence: `product_detail_screen.dart:657-666,669,680,701,711,760-764`; `app_bottom_nav.dart:22`.

## F3 — HIGH — DraggableScrollableSheet is z-ordered ABOVE the carousel; the Hero lands partly clipped

- Phase 3 (S2), "Back flight" / Risk "Sheet clipping"
- **Scenario:** In the detail `Stack`, the carousel `SizedBox` is the first child (drawn below, `:105-108`) and the `DraggableScrollableSheet` is a later child (drawn above, `:179`) with an opaque rounded `Container` background (`:185-191`). `initialChildSize` ≈ `(screenHeight - 0.55*screenHeight + 20)/screenHeight` covers the lower ~45% of the screen while the carousel spans 0–55%, so the bottom ~10% of the carousel sits behind the sheet. When the Hero flight completes, the flying image is replaced by the real carousel widget, whose lower strip is occluded by the opaque sheet → visible seam/clip exactly where the plan says it must not clip.
- **Why the plan's fix is empty:** phase-03 says "ensure carousel sits above the sheet's clip during flight" — but the existing z-order is the opposite (carousel below sheet). No concrete reordering or clip fix is specified.
- Evidence: `product_detail_screen.dart:103-108,179-191`.

## F4 — HIGH — Fly-to-cart target is a "detail app bar" that does not exist; overlay/ticker disposal is unowned

- Phase 4 (S3), "Target resolution" + Steps 1-2/5
- **Scenario:** `product_detail_screen` has **no `AppBar`**. The back button and actions are `Positioned` `CircleAvatar`s inside the `Stack` (`:109-178`) and the bottom bar is `bottomNavigationBar: _buildBottomBar()` (`:254`). The plan repeatedly says the target is "the detail app bar" (phase-04:25-26; plan.md:38,90) — that anchor is fictional; implementers will hunt for an AppBar that isn't there. Separately, `runFlight(context, image, from, to)` is described as a free function/helper (phase-04:23) with no State lifecycle. The `OverlayEntry` is inserted into the root Navigator overlay, which **survives the screen pop**; if the `AnimationController`'s vsync is the (now disposed) screen State, a mid-navigation flight ticks after dispose (throws) and/or `whenComplete` never runs → leaked overlay. "Remove entry in whenComplete and on dispose" has no `dispose` to hook into.
- **Required design change:** name the real target (a `Positioned` cart icon added to the top-right `Row`, `:126-178`), and give the flight a concrete owner with a real `dispose`/vsync (e.g., an overlay-scoped controller cancelled on route pop).
- Evidence: `product_detail_screen.dart:109-178,254`; plan phase-04:23,25-26.

## F5 — HIGH — GlobalKey on a per-screen StatelessWidget bottom nav collides during route transitions

- Phase 4 (S3), Step 2 "Attach GlobalKey to the bottom-nav cart icon"
- **Scenario:** `AppBottomNav` is a `StatelessWidget` (`app_bottom_nav.dart:8`) instantiated fresh inside each screen's `Scaffold` (`home_screen.dart:199`, `product_list_screen.dart:90`). During a push/pop transition the outgoing and incoming screens are mounted simultaneously, so two `AppBottomNav` instances live at once. A single (static) `GlobalKey` on "the cart icon" is then attached to two elements → GlobalKey-uniqueness assertion crash. Also, the badge scale-pop needs an `AnimationController`, which requires converting `AppBottomNav` to `StatefulWidget` with a `TickerProvider` — not accounted for in the plan.
- Evidence: `app_bottom_nav.dart:8,68-88`; `home_screen.dart:199`; `product_list_screen.dart:90`.

## F6 — MEDIUM/HIGH — S1 staggered entrance is driven at mount time, before the multi-stage async data exists

- Phase 2 (S1), "Staggered entrance" + Risk "Entrance replays on data refresh"
- **Scenario:** The whole home body is one `BlocBuilder<ProductBloc>` (`home_screen.dart:36`). `initState` fires three separate async events (`:26-28`), and sections render conditionally as data trickles in: categories sliver only `if (state.categories.isNotEmpty)` (`:60`), featured grid gated on `state.isLoading` (`:86-97`), products grid likewise (`:146-157`). A one-shot `_entered` flag set in `initState` starts the stagger while `isLoading==true` — so it animates the **shimmer**, and when real content replaces the shimmer there is either no entrance or a second animation. Categories arrive on their own emission and pop in un-staggered. The plan's "ensure shimmer→loaded doesn't replay awkwardly" is exactly the unsolved bug.
- **Required design change:** trigger the stagger off the loaded-content state (per section), not off mount; or animate stable section shells that exist in both shimmer and loaded states.
- Evidence: `home_screen.dart:26-28,36,60,86-97,146-157`.

## F7 — MEDIUM — Phase 6 misstates the COD-success destination (`/orders` vs `/order-detail`) and ignores success-surface controller/timer lifecycle

- Phase 6 (S5), "Success moment"
- **Scenario:** The real COD-success CTA is `Navigator...pushReplacementNamed('/order-detail', arguments: state.orderId)` inside a `showDialog` from the `BlocConsumer` listener (`checkout_screen.dart` ~`:367-371`). The plan asserts it is `pushReplacementNamed('/orders'...)` at `checkout_screen.dart:369` (phase-06:27). The router has distinct `/orders` (`app_router.dart:48`) and `/order-detail` (`:50`). An implementer following the plan text verbatim will regress navigation (drop the `orderId` arg and land on the list instead of the placed order). Also, the animated success surface needs an `AnimationController` + auto-advance `Timer`; if shown via `showDialog` (barrierDismissible:false) and the user backs out mid-animation, an uncancelled timer/controller fires `setState`/navigation after dispose. The plan does not specify this lifecycle.
- Evidence: `checkout_screen.dart:329-371`; `app_router.dart:48,50`; plan phase-06:27.

## F8 — MEDIUM — S4 duplicates search plumbing that already exists (DRY / scope creep)

- Phase 5 (S4), "Query path" / Create `blocs/search/`
- **Scenario:** `ProductBloc` already has a `SearchProducts` event and a `filteredProducts` state, and `product_list_screen` already has a live search bar wired to them (`product_list_screen.dart:169,180,182` dispatch `SearchProducts`; `:251` renders `state.filteredProducts`), all backed by `getProducts(searchQuery:)` `ilike` (`product_service.dart:18,37-38`). Phase 5 proposes a NEW `SearchBloc` + `/search` screen, reimplementing the same debounce/query/results path in parallel. This is the "parallel reimplementation of existing utilities" risk. Prefer reusing `ProductBloc.SearchProducts` (the plan lists this only as an "optional" aside).
- Evidence: `product_list_screen.dart:145-184,251`; `product_service.dart:18,37-38`.

## F9 — LOW/MEDIUM — S1 greeting fallback never triggers for empty names; `?.` is redundant; AuthBloc not yet wired into home

- Phase 2 (S1), "Greeting/avatar"
- **Scenario:** `UserModel.fullName` is a non-nullable `String` defaulting to `''` (`user_model.dart:9,62`). The plan's snippet `user.fullName?.split(' ').last ?? 'bạn'` (phase-02:23): the `?.` is a redundant null-aware on a non-nullable field (analyzer warning), and for an empty-name user `''.split(' ').last == ''` → greeting renders "Xin chào, " with no name, because `?? 'bạn'` only fires on null, never on `''`. Guard on `isEmpty`, not null. Also `home_screen` currently imports no `AuthBloc` and the greeting lives in a plain method `_buildHeader` (`:218-257`) outside any auth `BlocBuilder` — the plan must add the provider read/rebuild path.
- Evidence: `user_model.dart:9,62`; `home_screen.dart:218-257` (no auth import).

---

## Minor / watch items

- **Nested tap handlers:** `ProductCard` already owns its tap via an outer `GestureDetector(onTap:)` (`product_card.dart:33-34`). Wrapping it in `PressableScale` (Phase 1) adds a second tap/onTapDown handler around the same subtree; define which layer owns `onTap` to avoid double-fire and scroll-drag competition (Phase 1 risk notes scroll only).
- **Line drift:** `product_service` search is at lines 18/37-38, not 16/38 as cited (harmless).
- **CartState duplication:** `AppBottomNav` recomputes the count via `items.fold` (`app_bottom_nav.dart:22`) while `CartState.totalQuantity` already exists (`cart_state.dart:16`) and is used elsewhere (`product_list_screen.dart:105`). Not in scope, but relevant if Phase 4 touches the badge.

## Unresolved questions for the planner

1. S2: will you pass the tapped `imageUrl` through route args and render a Hero-tagged placeholder before load, or is S2 downgraded? Without it, F1 blocks the whole moment.
2. S3: what is the true flight source — the carousel image or the bottom "Thêm vào giỏ" button (`:585`)? And does the flight wait for `CartBloc` confirmation (F2)?
3. S3: confirm the target is a `Positioned` icon in the detail `Stack`, not an "app bar" (F4).
4. S4: reuse `ProductBloc.SearchProducts` or accept the parallel `SearchBloc` and justify (F8)?
