---
phase: 2
title: "S1: Personalized Home + Staggered Entrance"
status: completed
priority: P1
dependencies: [1]
effort: "S"
---

# Phase 2: S1 — Personalized Home + Staggered Entrance

## Overview

Turn the static home header into a personalized greeting (real name + avatar) and make the page assemble itself with a gentle staggered fade/slide on load. First-impression signature moment. Also closes old audit finding C2 (static greeting).

## Requirements

- Functional: greeting reads the authenticated user; avatar shows the user's photo (fallback initial); home sections animate in sequentially on first load.
- Non-functional: no jank on mid-range devices; respects reduced-motion; uses `AppMotion` tokens.

## Architecture

<!-- Updated: Red Team 2026-07-12 — C4 null-safety (guest NPE + analyze fail), M7 stagger vs staged async data -->
- **Greeting/avatar (C4 — fix inverted null-safety):** `AuthState.user` is nullable `UserModel?` (`auth_state.dart:5`) but `UserModel.fullName` is **non-nullable** `String` defaulting to `''` (`user_model.dart:9,62`). The naive `user.fullName?.split(...) ?? 'bạn'` guards the WRONG side — it derefs a possibly-null `user` (NPE on the guest path) and the `?.`/`?? 'bạn'` is dead code that never fires for an empty name. **Correct:** read via a builder that exposes `authState.user`, then:
  ```dart
  final name = authState.user?.fullName.trim() ?? '';
  final label = name.isEmpty ? 'Xin chào!' : 'Xin chào, ${name.split(' ').last}';
  ```
  (guards `user` null AND empty-string name). Replace hardcoded `'Xin chào!'` (`home_screen.dart:225-236`); the greeting currently sits in a plain method outside any auth builder (`:218-257`) — wrap it in `BlocBuilder<AuthBloc, AuthState>` or read the bloc explicitly. Avatar via `CircleAvatar` with initial fallback when `avatarUrl` null.
- **Staggered entrance (M7 — trigger on loaded data, not mount):** home body is one `BlocBuilder<ProductBloc>` (`home_screen.dart:36`); `initState` fires 3 async loads (`:26-28`) and categories/featured/products render as data trickles in (`:60,:86-97,:146-157`). A mount-time `_entered` flag would stagger the **shimmer**, then real content pops in un-animated. **Fix:** drive the entrance off the *loaded* state per section (animate when that section's data first arrives), not on mount. Wrap each section (banner, category row, featured, new-arrivals) in a reusable built-in `StaggeredEntrance` (fade + 12px slide-up; `TweenAnimationBuilder`; delay `index * AppMotion.stagger`; curve `AppMotion.entrance`; duration `AppMotion.base`), each latched once so it doesn't replay on later `ProductBloc` rebuilds.

## Related Code Files

- Create: `FE/lib/widgets/staggered_entrance.dart`
- Modify: `FE/lib/screens/home/home_screen.dart` (greeting `225–236`, section wrapping, avatar)

## Implementation Steps

1. Wire greeting + avatar to `authState.user` with the null-AND-empty-safe fallback above; wrap in an AuthBloc builder.
2. Build the built-in `StaggeredEntrance` widget.
3. Wrap home sections; trigger each section's entrance on its data-loaded state (not mount); latch once.
4. Verify guest/mock user (null / `mock-*` id) shows `'Xin chào!'`, never a crash or "Xin chào, ".
5. Verify with `MediaQuery.disableAnimations` (reduced motion) → entrance collapses to instant.

## Success Criteria

- [x] Greeting shows the real user's name; avatar shows photo or initial fallback.
- [x] Home sections fade/slide in sequentially on load, once per mount.
- [x] Reduced-motion users get instant layout (no animation).
- [x] No replay on unrelated BLoC rebuilds; `flutter analyze` clean.

## Risk Assessment

- **Null/guest user** → explicit fallback copy; never render "Xin chào, null".
- **Entrance replays on data refresh** → one-shot flag; separate the entrance trigger from `ProductBloc` state changes.
- **Perceived slowness** if stagger too long → cap total sequence < ~500ms.
