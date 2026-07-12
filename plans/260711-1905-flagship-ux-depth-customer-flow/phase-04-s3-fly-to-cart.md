---
phase: 4
title: "S3: Add-to-Cart Confirmation (badge pop + haptic)"
status: completed
priority: P2
dependencies: [1]
effort: "S"
---

# Phase 4: S3 — Add-to-Cart Confirmation (badge pop + haptic)

<!-- Updated: Red Team 2026-07-12 — DOWNGRADED from OverlayEntry fly-to-cart arc.
     Reasons (all codebase-verified):
       H1: product_detail has NO app bar — full-bleed carousel (product_detail_screen.dart:105-108)
           + floating CircleAvatars (:109-178) + DraggableScrollableSheet (:179). The validated
           "detail app-bar cart icon" flight target does not exist.
       C3: _addToCart bails before adding on 4 paths (not-logged-in :657-666, no size :669,
           no color :680, no variant :701) and only dispatches CartAddItem at :711; cart count
           updates only after an async Supabase round-trip (:760-764). A fixed-duration arc +
           success haptic would fire "added" even on aborted/failed adds.
       H2: AppBottomNav is a per-screen StatelessWidget (app_bottom_nav.dart:8) — a shared
           GlobalKey collides while two instances are mounted during a page transition; and the
           badge only exists when count>0 (:69-84), so the 0->1 first-add has no stable rect.
     User decision: keep only the badge scale-pop + success haptic (≈90% of the "added" delight,
     near-zero risk). The Bézier OverlayEntry arc + new detail cart icon are CUT. -->

## Overview

Give add-to-cart a legible, tactile confirmation: the existing cart badge **scale-pops** when the count actually increases, plus a success **haptic** — gated on the real (async) add-success, not the tap. No overlay flight, no new navigation control.

## Requirements

- Functional: when a `CartAddItem` succeeds and `CartBloc` count increases, the bottom-nav cart badge animates a scale pop; `Haptics.success()` fires. On an aborted/failed add (not-logged-in / missing size|color / no variant / async failure), **no** success feedback plays.
- Non-functional: pop is driven by a real count-increase signal (not a fixed timer); no `GlobalKey` on the per-screen bottom nav; no behavior change to `AppBottomNav`'s other four tabs.

## Architecture

- **Trigger source (fixes C3):** feedback must key off the actual cart mutation, not the button tap. Detail already waits on `cartBloc.stream…timeout` after dispatching `CartAddItem` (`product_detail_screen.dart:711,760-764`). Fire `Haptics.success()` only on the success branch of that existing wait (i.e. after the count actually rises), never before the `_addToCart` guards pass.
- **Badge pop (fixes H2):** convert the cart-icon area of `AppBottomNav` to a small `StatefulWidget` with a single `AnimationController` (`AppMotion.fast`, slight overshoot). Detect count-increase by comparing the previous vs current `CartBloc` count inside its `BlocConsumer`/`didUpdateWidget`; play the pop only on increase. **No `GlobalKey`** (avoids the cross-transition collision) — the animation is local to the badge widget. Handle the 0→1 case: when the badge first appears, play the pop on its first build-with-count>0.
- **Shared-surface caution (H2):** `AppBottomNav` is rendered by home, product_list, cart, orders, **and profile** (profile is out of scope). Keep the change additive and behavior-neutral for the count-unchanged case; smoke-test all five tabs.

## Related Code Files

- Create: none (arc widget cut).
- Modify:
  - `FE/lib/widgets/app_bottom_nav.dart` — extract the cart icon+badge into a small stateful widget with the scale-pop controller; drive pop off count-increase (`app_bottom_nav.dart:69-84`).
  - `FE/lib/screens/product_detail/product_detail_screen.dart` — add `Haptics.success()` on the existing add-success branch only (`:760-764`), after the `:657-711` guards.
- Delete: none.

## Implementation Steps

1. Extract `_CartTab` (stateful) inside `app_bottom_nav.dart` with an `AnimationController` + `ScaleTransition` around the badge.
2. Compare prev/current `CartBloc` count; play the pop only when it increases (incl. 0→1 first appearance).
3. In product_detail, fire `Haptics.success()` on the real add-success branch (after the async wait), not on tap.
4. Smoke-test all 5 tabs that mount `AppBottomNav` (home, product_list, cart, orders, profile) for regressions.

## Success Criteria

- [x] Badge scale-pops **only** when cart count actually increases (incl. first 0→1).
- [x] `Haptics.success()` fires only on a real successful add — never on aborted/failed adds (not-logged-in, missing size/color, async failure).
- [x] No `GlobalKey` on `AppBottomNav`; no assertion during page transitions.
- [x] All 5 tabs using `AppBottomNav` unaffected; `flutter analyze` clean.

## Risk Assessment

- **Double-pop / missed pop on rebuild** → compare counts explicitly; play only on strict increase; guard against `BlocBuilder` rebuilds that don't change the count.
- **Profile/other tabs regressions** (shared widget) → additive stateful extraction only; smoke-test all 5 hosts.
- **Haptic on failed add** → hook strictly the success branch of the existing async wait, downstream of every `_addToCart` guard.
