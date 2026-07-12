---
phase: 1
title: "Foundation: Motion, Haptics & Feedback"
status: pending
priority: P1
dependencies: []
effort: "M"
---

# Phase 1: Foundation — Motion, Haptics & Feedback Primitives

## Overview

Build the thin shared layer every later phase consumes: motion tokens, a haptics helper, a press-feedback wrapper, a reusable skeleton, plus two cheap consistency fixes (cart touch targets, checkout inline validation). Apply the primitives across the 6 customer-flow screens.

## Requirements

- Functional: centralized `AppMotion` (durations + curves), `Haptics` helper, `PressableScale` wrapper, `AppSkeleton` widget; product_detail gains a skeleton; cart steppers ≥44px; checkout validates inline.
- Non-functional: DRY (one primitive, reused); zero new raw-color debt; built-in APIs only (no new dep required in this phase); no behavior/flow change.

## Architecture

- **`FE/lib/config/theme/app_motion.dart`** (new): implements the v2 motion spec from `docs/design-tokens-v2.md`.
  ```dart
  class AppMotion {
    AppMotion._();
    static const Duration fast = Duration(milliseconds: 150);
    static const Duration base = Duration(milliseconds: 250);
    static const Duration slow = Duration(milliseconds: 350);
    static const Curve entrance = Curves.easeOutCubic;   // v2 spec
    static const Curve standard = Curves.easeInOut;
    static const Duration stagger = Duration(milliseconds: 60); // per-item delay
  }
  ```
- **`FE/lib/utils/haptics.dart`** (new): thin wrapper over `HapticFeedback` so call sites read intent, not primitive.
  ```dart
  class Haptics {
    static void selection() => HapticFeedback.selectionClick();
    static void tap() => HapticFeedback.lightImpact();
    static void success() => HapticFeedback.mediumImpact();
  }
  ```
- **`FE/lib/widgets/pressable_scale.dart`** (new): wraps a child with a tap-down scale (0.97) + `AnimatedScale` using `AppMotion.fast`. Exposes `onTap`. Used to give cards/pills a physical press feel without per-widget boilerplate.
<!-- Updated: Red Team 2026-07-12 — M6: the two shimmers are NOT identical (home = bare card `:406-414`; product_list = structured image+2-line card `:326-360`), so a multi-variant primitive is speculative for 2-3 call sites. Simplify. -->
- **product_detail skeleton (the real gap):** the concrete gap is `product_detail_screen.dart:72–74` = a blank `CircularProgressIndicator`. **Reuse the existing product_list card shimmer shape** for the detail load state (carousel block + title/price/section lines). Only extract a shared `AppSkeleton` widget **if** a 3rd distinct consumer appears — otherwise copy the product_list shimmer directly (KISS; avoid premature `.box/.line/.card` abstraction for 2 divergent layouts). Use `AppColors.skeletonBase/skeletonHighlight`.

## Related Code Files

- Create: `FE/lib/config/theme/app_motion.dart`, `FE/lib/utils/haptics.dart`, `FE/lib/widgets/pressable_scale.dart` (+ `FE/lib/widgets/app_skeleton.dart` **only if** a 3rd consumer justifies it — M6)
- Modify:
  - `FE/lib/screens/home/home_screen.dart` — swap inline shimmer → `AppSkeleton`; wrap product cards/category pills in `PressableScale`
  - `FE/lib/screens/product_list/product_list_screen.dart` — shimmer → `AppSkeleton`; `PressableScale` on cards/chips
  - `FE/lib/screens/product_detail/product_detail_screen.dart` — add skeleton load state; replace ad-hoc `Duration(milliseconds: 200)` (lines 308, 514) with `AppMotion`; `Haptics.selection()` on size/color select
  - `FE/lib/screens/cart/cart_screen.dart` — stepper hit area 28→≥44px (`cart_screen.dart:281–294`); `Haptics.tap()` on qty change, `Haptics.success()`? no — `Haptics.selection()` on delete
  - `FE/lib/screens/checkout/checkout_screen.dart` — set `autovalidateMode: AutovalidateMode.onUserInteraction` on the **`Form(key: _formKey)` at `:429-430`** (NOT `:495`, which is the `_placeOrder()` submit-time `.validate()` guard — red-team M4); colored error borders via existing input theme
  - `FE/lib/widgets/product_card.dart`, `FE/lib/widgets/app_button.dart` — accept `PressableScale`/press states where they own the tap
- Delete: none

## Implementation Steps

1. Add `app_motion.dart`, `haptics.dart`, `pressable_scale.dart`, `app_skeleton.dart`.
2. Refactor home + product_list shimmer into `AppSkeleton`; verify visual parity.
3. Add product_detail skeleton (carousel block + title/price/section lines).
4. Replace literal animation `Duration`s in product_detail with `AppMotion.fast`/`base` + `entrance` curve.
5. Wrap product cards + category/filter chips in `PressableScale`.
6. Wire `Haptics` on: add-to-cart, size/color select (product_detail), qty +/- and delete (cart).
7. Fix cart stepper touch targets to ≥44px (keep 28px visual inside a 44px `InkResponse`/`GestureDetector`).
8. Enable inline validation on the checkout address form.

## Success Criteria

- [ ] 4 new primitive files exist and compile.
- [ ] home + product_list use `AppSkeleton` (no inline `Shimmer.fromColors` left); product_detail shows a skeleton on load.
- [ ] No literal `Duration(...)` remains in the 6 customer-flow screens' animation code (all via `AppMotion`).
- [ ] Cards/pills visibly scale on press; haptics fire on the wired actions (device test).
- [ ] Cart stepper hit area ≥44px; checkout shows inline validation as the user types.
- [ ] `flutter analyze` clean; customer-flow raw-color count still 0.

## Risk Assessment

- **Skeleton refactor changes layout** → snapshot before/after; keep shimmer geometry identical.
- **PressableScale swallowing scroll gestures** → use `onTapDown/onTapCancel`, not a gesture that competes with the parent `ListView`/`GridView` drag; test scroll still works.
- **Over-haptic** (buzzing on every micro-tap) → restrict to intentful actions only (add-to-cart, select, confirm, delete); no haptic on plain navigation.
