---
phase: 2
title: "Splash & Auth Unblock"
status: pending
priority: P0
dependencies: []
effort: "S"
---

# Phase 2: Splash & Auth Unblock

## Overview

Fix the P0 splash hang so a logged-out / first-launch user actually reaches `/login`. Independent of all other phases — ship first as a fast, high-severity win. Fixes G1, G2, G3, G4 (G5 optional).

## Requirements

- Functional: cold start with no session → navigates to `/login`; with session → `/home` or `/manager` by role; auth-check failure → error UI with retry (not an infinite spinner).
- Non-functional: no navigation after `dispose`; navigate exactly once.

## Architecture

**Root cause (verified):** `AuthBloc` starts at `super(const AuthInitial())` (`auth_bloc.dart:14`). `AuthState.props => [user, error]` (`auth_state.dart:16`); `AuthInitial` adds no fields → identical props `[null, null]` to the initial state. When `_onCheckSession` finds `user==null` it emits `const AuthInitial()` again (`auth_bloc.dart:32`) → Equatable dedupes → **no transition** → `BlocListener` in splash never fires → spinner forever. No `try/catch` (`auth_bloc.dart:24-34`) so a thrown `getCurrentUser()` also emits nothing → same hang.

**Fix design:** introduce a distinct `AuthUnauthenticated` state (or `AuthError`) so the transition is observable, and wrap the check in try/catch.

## Related Code Files

- Modify: `FE/lib/blocs/auth/auth_state.dart` — add `AuthUnauthenticated` (and reuse `AuthError` for failures).
- Modify: `FE/lib/blocs/auth/auth_bloc.dart:24-34` — `_onCheckSession`: try/catch; emit `AuthUnauthenticated` when `user==null`, `AuthError` on exception.
- Modify: `FE/lib/screens/splash/splash_screen.dart:24-37,82-85` — listen for `AuthUnauthenticated` → `/login`; navigate-once guard; `if (!mounted) return;` before context use; optional error+retry UI.
- Reference: `login_screen.dart:54-57` (same role-routing pattern to mirror).

## Implementation Steps

1. Add `class AuthUnauthenticated extends AuthState { const AuthUnauthenticated(); }` to `auth_state.dart` (distinct props from `AuthInitial` — since both are propless, differentiate by runtime type via a discriminator field or rely on `is` checks in listener; simplest: give `AuthState` a subclass check in the listener rather than props equality). Confirm Equatable treats different subclasses as unequal — it does when `runtimeType` differs (Equatable compares `runtimeType` first), so a new subclass is sufficient.
2. `_onCheckSession`: wrap `getCurrentUser()` in try/catch. `user != null` → `AuthSuccess(user)`; `user == null` → `AuthUnauthenticated()`; on throw → `AuthError('<message>')`.
3. Splash `BlocListener`: on `AuthSuccess` route by role (`/manager` vs `/home`), on `AuthUnauthenticated` → `/login`, on `AuthError` → show retry UI (re-dispatch `CheckSessionEvent`).
4. Guard navigation: a `bool _navigated` flag or `listenWhen`; wrap the delayed callback body with `if (!mounted) return;` (`splash_screen.dart:26-36`). Keep or drop the 1500ms delay — if kept, still guard `mounted`.
5. `flutter analyze` clean.

## Success Criteria

- [ ] Cold start, no session → `/login` within ~1.5s (no hang).
- [ ] Cold start with customer session → `/home`; manager session → `/manager`.
- [ ] Simulated `getCurrentUser()` failure → error UI + working retry (not infinite spinner).
- [ ] No "used after dispose" / navigation-after-unmount errors.
- [ ] `flutter analyze` clean.

## Risk Assessment

- **Equatable subclass equality:** verify empirically that adding a propless `AuthUnauthenticated` produces a real transition from `AuthInitial` (Equatable compares `runtimeType` before props, so it should). If not, add a discriminator field or a nonce. This is the one subtle point — test it.
- **Regression:** existing `AuthSuccess` / login flow must be untouched; only the `user==null` branch changes. Manager routing already relies on `AuthSuccess` — keep that path identical.
