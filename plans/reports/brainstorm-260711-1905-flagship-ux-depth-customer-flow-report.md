# Brainstorm — Flagship UX-Depth Pass (Customer Shopping Flow)

- **Date:** 2026-07-11 · **Project:** BigStyle (Flutter/BLoC + Supabase) · **Branch:** dev
- **Mode:** brainstorm (advisory — no code changes) · **Handoff target:** `/ck:plan`
- **Scope this round:** customer shopping flow only (home → product_list → product_detail → cart → checkout → orders)
- **Out of scope:** manager/admin/guest surfaces; brand/visual reskin (frozen); navigation architecture rewrite.

## 1. Problem Statement

A full **visual reskin** ("Warm Terracotta v2") shipped 2026-07-10 — tokens/fonts/shapes are in code and the customer flow has **0 raw-color debt**. The remaining gap is the **interaction/UX layer** the reskin did not touch. User wants a **flagship-level UX-depth** upgrade — "thật đẹp thật xịn, đặc biệt UX" — focused on the demo-visible customer flow, with **selective flow changes allowed**.

Re-running a generic full-app audit was explicitly rejected as duplicate work; this round builds *on top of* the completed visual layer.

## 2. Current-State Findings (scout-verified, customer flow)

| # | Gap | Evidence |
|---|-----|----------|
| 1 | **No motion system** — no duration/curve tokens; ad-hoc 200ms linear. Tokens-v2 *specced* easeOutCubic 250–300ms but it was never coded. | `app_theme/app_spacing` (no motion); `product_detail_screen.dart:308,514` |
| 2 | **No Hero transition** list→detail — disjointed screen change | grep `Hero` = 0 |
| 3 | **Zero haptics** in the entire app | no `HapticFeedback.*` |
| 4 | **Product detail = blank spinner** (no skeleton), inconsistent with list shimmer | `product_detail_screen.dart:72–74` |
| 5 | Home **fake search bar** + **static "Xin chào!" greeting** (AuthBloc user unused) | `home_screen.dart:225–236,260–283` |
| 6 | Cart stepper buttons **28×28px** (< 44 target); no swipe-to-delete | `cart_screen.dart:281–294` |
| 7 | Checkout **no inline validation** — errors only on submit | `checkout_screen.dart:495` |
| 8 | No tap-down feedback on cards/pills; offline not distinguished from error | multiple screens |

**Good baseline (keep):** state coverage decent (loading/error/empty mostly present); shimmer on home + list; customer-flow token debt = 0 (do not regress).

## 3. Locked Decisions (this session)

- **Focus:** UX-depth = interaction + states + motion (not a re-audit).
- **Flow changes:** allowed selectively where UX clearly needs (real search, personalized home).
- **Priority surface:** customer shop flow first (demo path).
- **Ambition:** flagship / delight.
- **Approach:** **C — Hybrid** (thin shared foundation + choreographed signature moments).
- **Signature moments:** all five — **S1 + S2 + S3 + S4 + S5**.

## 4. Design — Two Layers

### Layer 1 — Baseline UX System (build once, apply across all 6 screens · DRY)

| Primitive | What | Approach (built-in, no heavy deps) | Touchpoints |
|-----------|------|-----------------------------------|-------------|
| `app_motion.dart` | Motion tokens implementing the v2 spec | `Duration` fast150/base250/slow350 + `Curves.easeOutCubic` entrance, standard exit | new theme file; replace literal `Duration(...)` in flow |
| `AppSkeleton` | Reusable shimmer (card/line/block variants) | Extract inline `Shimmer.fromColors` → `widgets/app_skeleton.dart`, reuse existing `skeletonBase/Highlight` tokens; **add skeleton to product_detail** | home, list (refactor), product_detail (new) |
| `Haptics` helper | selection / light-impact / success | Thin wrapper over `HapticFeedback.*` | add-to-cart, size/color select, checkout confirm, delete |
| `PressableScale` | Tap-down scale (0.97) + opacity | `GestureDetector` + `AnimatedScale` wrapper | ProductCard, category pills, order cards |
| Touch-target fix | Cart stepper ≥44px hit area | Wrap 28px visual in 44px `GestureDetector`/`InkResponse` | cart |
| Inline validation | Real-time field feedback | `autovalidateMode: onUserInteraction` + colored border/error text | checkout |

### Layer 2 — Signature Moments (the delight budget, on the demo path)

- **S1 — Home personalized + staggered entrance.** Read `AuthBloc.state.user` → "Xin chào, {tên}" + real avatar; sections fade/slide in sequentially on load (interval-delayed `AnimatedOpacity`/`SlideTransition`, or a small reusable `StaggeredEntrance`). Replaces static greeting. *(also closes old finding C2)*
- **S2 — Hero list→detail.** `Hero(tag: 'product-${id}')` on the list card image and the detail carousel's first image; coordinate a fade of detail content. Perceived-speed + continuity. Guard: unique tags, same `ImageProvider` both ends, handle back flight.
- **S3 — Fly-to-cart.** On add-to-cart, animate a snapshot of the product image along a curved path (via `OverlayEntry` + `RenderBox` global coords) into the bottom-nav cart badge; badge bounces + count animates; success haptic. Reusable `CartFlyAnimation`. Replaces the current snackbar-only feedback.
- **S4 — Real search** *(feature-ish, largest effort)*. Turn the fake search bar into a working search screen (autofocus input → query existing `ProductService` via Supabase `ilike` / client filter), animated results; v1 keeps recent-searches minimal or deferred. Nav structure unchanged (adds a search route).
- **S5 — Checkout success delight.** Replace the flat COD dialog with an animated success moment (CustomPainter checkmark draw + scale + success haptic), then continue to orders. No Lottie dependency.

## 5. Approaches Evaluated

| | Pros | Cons | Verdict |
|---|------|------|---------|
| **A. Foundation-first** | Max consistency, DRY, low risk | Wow spread thin, few demo highlights | rejected |
| **B. Signature-first** | Max demo wow | Inconsistent (polished vs plain screens), one-off code | rejected |
| **C. Hybrid** ✅ | Consistent baseline *and* biased delight; reusable primitives; matches "UX-depth" + "flagship" | Slightly more upfront (foundation before moments) | **chosen** |

## 6. Implementation Considerations & Risks

- **Zero new heavy deps** targeted — Hero/AnimatedX/HapticFeedback/CustomPainter/Overlay are all built-in. `shimmer` already present. `flutter_animate` is **optional** convenience for staggering, not required; **no Lottie**.
- **Hero glitching** with `CachedNetworkImage` mid-load → ensure identical image provider + placeholder both ends; test back-navigation flight.
- **Fly-to-cart positioning** across devices/safe-area/scroll → use `RenderBox.localToGlobal`, place a `GlobalKey` on the cart badge; verify on the emulator.
- **S4 scope creep** — cap v1: query + animated results only; no facets/history persistence unless cheap. Biggest single risk to the deadline.
- **Do not regress** the 0-token-debt state; keep the reskin plan's hardcode-guard grep gate.
- **Demo-deadline ordering** — foundation + S1/S2/S3 land first (highest wow-to-effort, all on the core path); S4/S5 after.
- **Performance** — staggered/implicit animations are cheap; watch home rebuild cost; prefer implicit over `AnimationController` per codebase convention.

## 7. Success Criteria / Acceptance

- Every interactive element in the 6 screens has press feedback + uses `AppMotion` tokens (no literal `Duration` in flow code).
- product_detail shows a skeleton at parity with list; no blank-spinner load.
- Haptics fire on add-to-cart, size/color select, checkout confirm.
- All cart tap targets ≥ 44×44.
- Checkout has inline field validation.
- S1–S5 all demoable on device.
- `flutter analyze` = 0 new issues; `flutter test` passes; customer-flow raw-color count stays 0.

## 8. Suggested Phase Skeleton (for `/ck:plan`)

1. **Foundation** — `app_motion.dart`, `Haptics`, `PressableScale`, `AppSkeleton` (extract + product_detail), cart 44px, checkout inline validation; apply across flow.
2. **S1** — Home personalization + staggered entrance.
3. **S2** — Hero list→detail.
4. **S3** — Fly-to-cart overlay + badge bump.
5. **S4** — Real search screen.
6. **S5** — Checkout success + **QA/regression gate** (`flutter analyze`/`test`, per-screen interaction checklist, hardcode-guard).

Order = demo-visibility-first, so partial completion still upgrades what graders see.

## 9. Next Steps

- Hand this report to `/ck:plan` (default mode) to author the phased implementation plan.
- Reskin brand/tokens remain frozen — not reopened.

## 10. Unresolved Questions

1. **S4 recent-searches persistence** — in-memory v1, or wire `shared_preferences` now? (affects effort)
2. **Offline state** — add a distinct offline vs. error affordance this round, or defer? (not in the 5 signatures; low demo value)
3. **`flutter_animate` dependency** — allow it for cleaner staggering/choreography, or strictly built-in only?
