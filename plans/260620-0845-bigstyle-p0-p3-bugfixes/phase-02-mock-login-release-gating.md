---
phase: 2
title: "Mock-login release gating"
status: completed
priority: P1
effort: "30m"
dependencies: [1]
---

# Phase 2: Mock-login release gating

## Overview
Remove the dev-only fake-login bypass from release builds so demo/production users cannot create fabricated sessions (`mock-user-id` / `mock-manager-id`) that then fail every real Supabase write.

## Requirements
- Functional: mock-login UI + event only available in debug/dev; in release builds it is gone.
- Non-functional: real OTP + Google flows untouched; `flutter analyze` clean.

## Key Insights (verified, file:line)
- `login_screen.dart:94, 355-405` — `_buildMockSection` renders two "quick login" buttons.
- `auth_bloc.dart:74-88` — `_onMockLogin` fabricates a `UserModel` (`mock-user-id`/`mock-manager-id`), emits `AuthSuccess` with no Supabase session.
- Downstream breakage: mock checkout sends `userId='mock-user-id'` into `orders` insert → FK/RLS fail (`checkout_screen.dart:219`, `order_service.dart:26`); order list empty (`orders_screen.dart:24`).
- Phase 1 already adds a runtime guard against `mock-` ids; this phase removes the surface entirely from release.

## Architecture
Gate by build mode using `kReleaseMode` (from `package:flutter/foundation.dart`):
- Wrap `_buildMockSection(...)` call so it renders only when `!kReleaseMode`.
- Optionally guard the `MockLoginEvent` handler likewise (no-op in release) for defense in depth.

## Related Code Files
- Modify: `lib/screens/login/login_screen.dart` (conditionally render mock section)
- Modify: `lib/blocs/auth/auth_bloc.dart` (optional: ignore `MockLoginEvent` in release)

## Implementation Steps
1. Use `/mobile-development` skill.
2. Import `package:flutter/foundation.dart` in login screen if not present.
3. Replace the unconditional `_buildMockSection()` usage at `login_screen.dart:94` with `if (!kReleaseMode) _buildMockSection()`.
4. (Defense in depth) in `_onMockLogin`, early-return when `kReleaseMode`.
5. `cd FE && flutter analyze` clean. Sanity: `flutter run --release` shows no quick-login buttons; debug still shows them.
6. Commit + PR via `/vchun-git prc`.

## Success Criteria
- [x] Quick-login buttons absent in release build, present in debug
- [x] `MockLoginEvent` is inert in release (optional but recommended)
- [x] Real OTP + Google login unaffected
- [x] `flutter analyze` clean (0 errors; 4 pre-existing info lints outside Phase 2)
- [x] ≥1 commit + PR via `/vchun-git prc`

## Risk Assessment
- **Low risk.** Pure conditional rendering. Only watch: ensure `kReleaseMode` import doesn't clash; keep dev convenience intact in debug.

## Security Considerations
- Eliminates a path that injects unauthenticated identities into an otherwise RLS-protected backend.
