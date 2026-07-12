# Red-Team Plan Review — Assumption Destroyer / Scope Auditor

Plan: `plans/260711-1905-flagship-ux-depth-customer-flow`
Reviewer posture: hostile skeptic; every finding carries file:line codebase evidence.
Verdict: **NOT ready to implement as written.** Two Critical contradictions/omissions in the Hero work (Phase 3) plus false premises in Phases 2/4 and a failing acceptance criterion.

---

## Finding 1 — CRITICAL — Phase 3 omits the 4th `ProductCard` call site (favorites)
**Where:** phase-03 "Related Code Files" (lines 31-34) + Implementation Steps 1-2.
**Claim:** heroTag plumbing touches only `home_screen.dart` and `product_list_screen.dart`.
**Evidence:** `ProductCard(` is instantiated at **4** sites, not 3:
- `FE/lib/screens/home/home_screen.dart:112`
- `FE/lib/screens/home/home_screen.dart:172`
- `FE/lib/screens/product_list/product_list_screen.dart:289`
- `FE/lib/screens/favorites/favorites_screen.dart:70` ← **not in the plan**

Phase 3 step 1 says "Add `heroTag` to `ProductCard`; wrap the card image in `Hero`."
**Failure scenario:** If `heroTag` is a required param, `favorites_screen.dart:70` fails to compile (missing arg). If the card wraps its image in `Hero` unconditionally and `heroTag` is null/absent at the favorites site, `Hero` with a null tag throws at runtime. Either way an out-of-scope screen breaks, and the plan never accounts for it. The plan must state heroTag is optional AND the Hero wrap is conditional on a non-null tag.

## Finding 2 — CRITICAL — Phase 3 internally contradicts itself and re-introduces the dup-tag crash it claims to prevent
**Where:** phase-03 Architecture (line 24) vs. Related Code Files (line 33) / Impl Step 2.
**Evidence:** Architecture mandates a context-unique tag `'product-${product.id}-${screen}-${section}-${index}'` specifically because home renders the same product in featured (`home_screen.dart:112`) and new-arrivals (`home_screen.dart:172`) — both pull from overlapping data (`state.featuredProducts` vs `state.products`), so a naive tag collides and Flutter asserts "multiple heroes share tag". But line 33 and Impl Step 2 literally instruct: `pass heroTag: 'product-${product.id}'` — the exact naive colliding tag.
**Failure scenario:** An implementer following Related Code Files/Impl Steps ships `'product-${id}'`, and the moment a product appears in both home grids the Hero assertion crashes the screen — the precise bug the phase's own risk section says is "RESOLVED." The phase carries both the fix and the bug; the wrong one is in the actionable section.

## Finding 3 — HIGH — Phase 2 greeting snippet won't compile and fails the plan's own `flutter analyze` gate
**Where:** phase-02 Architecture (line 23).
**Claim:** `'Xin chào, ${user.fullName?.split(' ').last ?? 'bạn'}'`.
**Evidence:**
- `AuthState.user` is `final UserModel? user;` — nullable (`FE/lib/blocs/auth/auth_state.dart:5`).
- `UserModel.fullName` is `final String fullName;` — **non-nullable** (`FE/lib/models/user_model.dart:9`).

The snippet dereferences nullable `user` with no guard (`user.fullName` → null-safety compile error on the guest/unauthenticated path where `user == null`, which phase-02's own risk note at line 51 admits happens), while applying `?.` to the non-nullable `fullName` (analyzer warning: unnecessary null-aware). The `?? 'bạn'` fallback guards the wrong operand (fullName can't be null; user can). This violates the plan-wide AC "flutter analyze = 0 new issues" (plan.md:70) and contradicts phase-02's stated risk "never render 'Xin chào, null'." Correct shape is `authState.user?.fullName.split(' ').last ?? 'bạn'`.

## Finding 4 — HIGH — Phase 4 fly-to-cart target assumes a product_detail app bar that does not exist; and the "wishlist heart on cards" premise is false
**Where:** phase-04 Architecture (lines 25-26).
**Claim:** "add a cart icon ... to the detail app bar and use it as the flight target"; "cards only have a wishlist heart, no quick-add."
**Evidence:**
- `product_detail_screen.dart` has **no `AppBar`/`SliverAppBar`** — grep for `AppBar` returns nothing. It renders a full-bleed carousel (`carouselHeight = screenHeight * 0.55`, line 57/106) with a `DraggableScrollableSheet` (line 179). There is no `appBar:` slot to "add a cart icon to."
- `product_card.dart` has **no** wishlist/favorite/heart widget — grep for `favorite|wishlist|heart` returns nothing; the card exposes only `onTap` (`product_card.dart:15,34`).

**Failure scenario:** The flight target must be built from scratch and positioned as an overlay over a full-bleed carousel + draggable sheet, where the target's global rect shifts with sheet drag and safe-area — none of which the phase addresses (it treats the icon as a drop-in app-bar action). The false "wishlist heart" premise also mis-describes the current card surface used to justify "detail-only for v1."

## Finding 5 — MEDIUM — "Customer flow = 0 raw-color debt" is false; the Phase 6 grep gate would fail today
**Where:** plan.md:19, 28; Acceptance Criteria (plan.md:70); phase-06 hardcode guard (line 32).
**Evidence:** Raw `Colors.*` still present in customer-flow screens:
- `FE/lib/screens/product_detail/product_detail_screen.dart:625` — `color: Colors.transparent`
- `FE/lib/screens/product_detail/size_guide_sheet.dart:15` — `backgroundColor: Colors.transparent`

Phase-06's gate greps `Colors.*`/`0xFF` and asserts count 0. These two hits would fail it.
**Failure scenario:** The AC "raw-color count stays 0" is already violated at plan start. Either the claim is stale, or the gate needs a documented `Colors.transparent` allowlist — neither is stated. (The cart_item_edit_screen `newColors`/`_uniqueColors` matches are false positives — variable names, not the `Colors` class.)

## Finding 6 — MEDIUM — Phase 6 mis-states the COD-success destination route
**Where:** phase-06 Architecture (line 27): "existing `pushReplacementNamed('/orders'...)` (`checkout_screen.dart:369`)" and "continues to orders."
**Evidence:** `checkout_screen.dart:369` actually calls `Navigator.of(context).pushReplacementNamed('/order-detail', ...)` — it opens the just-placed order's **detail**, not the orders **list**. Both routes exist (`app_router.dart:48` `/orders`, `:50` `/order-detail`), so it is not a crash, but the plan's described post-success flow and success criteria ("continues to orders") are wrong and will mis-set the QA regression expectation.

## Finding 7 — MEDIUM — Phase 1 anchors the checkout inline-validation edit at the wrong line
**Where:** phase-01 Related Code Files (line 54): `autovalidateMode: AutovalidateMode.onUserInteraction` on the address form (`checkout_screen.dart:495`).
**Evidence:** `checkout_screen.dart:495-496` is inside `void _placeOrder()` — an imperative `if (!_formKey.currentState!.validate()) return;`. The `Form(key: _formKey)` widget, where `autovalidateMode` must actually be set, is at `checkout_screen.dart:429-430`. An implementer following `:495` edits the submit handler, not the Form. Wrong anchor.

## Finding 8 — MEDIUM — Phase 4 badge scale-pop has no stable target on the 0→1 first add
**Where:** phase-04 Architecture (line 29): drive a badge scale-pop via previous-count compare.
**Evidence:** `app_bottom_nav.dart:69-84` renders the `Badge` **only when `cartCount > 0`**; at count 0 the item is a plain `Icon(Icons.shopping_bag_outlined)`. On the first add (0→1) the `Badge` widget is newly created — there is no prior Badge instance to "pop," and a `GlobalKey` attached to the icon subtree jumps between two structurally different branches (plain Icon vs Badge-wrapped) across the transition. The "previous-count compare" pop lacks a stable target exactly on the demo's first add-to-cart. Unaddressed edge.

## Finding 9 — MEDIUM — Phase 6 `Duration(` grep gate will false-fail on non-animation Durations
**Where:** phase-06 motion-token guard (line 33): grep the 6 screen dirs for literal `Duration(` → "should be none."
**Evidence:** `product_detail_screen.dart` contains non-animation Durations that this unscoped grep matches: `:718` `duration: Duration(seconds: 2)` (SnackBar) and `:764` `.timeout(const Duration(seconds: 5))` (network timeout). Phase-01's criterion scopes to "animation code," but the Phase-06 gate is unscoped and would flag these legitimate uses, failing the gate or forcing noise-suppression. The guard needs to target animation Durations only.

---

## Correctly verified (no defect)
- `ProductService.getProducts()` has `searchQuery` (`product_service.dart:18`) doing `query.ilike('name', '%$searchQuery%')` (`:38`). Plan's `:16,38` anchor is accurate (16 = method start). Phase-05 "reuse, no new method" is sound.
- Home renders `ProductCard` in featured (`home_screen.dart:112`) and new-arrivals (`:172`) — confirmed; the dup-tag risk is real (see Finding 2).
- `AuthState.user` is nullable `UserModel?`; home greeting is static `'Xin chào!'` (`home_screen.dart:226`). Confirmed.
- `_addToCart` at `product_detail_screen.dart:650`; blank `CircularProgressIndicator` at `:73`; animation `Duration(milliseconds:200)` at `:308,:514`. Confirmed.
- Cart stepper `_miniButton` is 28×28 (`cart_screen.dart:283-287`). Confirmed.
- Checkout COD success is an `AlertDialog` in the `isSuccess` branch (`checkout_screen.dart:~339-369`); SePay/COD mutual exclusivity comment present. Confirmed.
- Detail carousel already uses `Image.network` (`:282`), same provider as the card (`product_card.dart:46`) — Phase 3's decoder-swap concern is already moot.

## Unresolved questions for the planner
1. Is `heroTag` optional with a conditional Hero wrap (Finding 1)? If yes, favorites is safe but the Hero-pair logic must tolerate absent tags.
2. Does the acceptance criterion treat `Colors.transparent` as debt (Finding 5)? If allowlisted, document it in the gate.
3. Is the intended post-COD-success destination `/order-detail` (current behavior) or `/orders` (Finding 6)? The plan should match code or the change should be explicit.
