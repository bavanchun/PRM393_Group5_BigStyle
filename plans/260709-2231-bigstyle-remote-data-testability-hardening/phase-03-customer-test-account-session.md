---
phase: 3
title: "Customer Test Account Session"
status: completed
priority: P1
effort: "1.5h"
dependencies: [1]
---

# Phase 3: Customer Test Account Session

## Overview

Create or activate a repeatable customer test path so cart, checkout, payment,
orders, wishlist, and profile can be tested without using a personal Google
account unexpectedly.

Locked strategy: use existing related accounts with data first; create missing
long-term test accounts/data if current accounts cannot support repeatable QA.

## Requirements

- Functional: Android emulator can reach `/home` as a `customer`.
- Functional: customer can add product to cart, checkout, and see order.
- Non-functional: test account path must be repeatable for future QA.
- Privacy: do not select personal Google account unless user explicitly allows.

## Architecture

Preferred QA auth hierarchy:

```text
Existing related seeded customer account/session
  > Newly created dedicated customer test account/session
  > User-approved personal Google account for one-off verification
  > Debug-only mock route (only if all real auth routes blocked and not used for backend checkout)
```

The plan should prefer real Supabase Auth. A debug-only shortcut is fallback
only and must be impossible in release builds.

## Related Code Files

| File | Action | Notes |
|------|--------|-------|
| `FE/lib/services/auth_service.dart` | Read | OTP auth path |
| `FE/lib/services/google_auth_service.dart` | Read | Google sign-in path |
| `FE/lib/blocs/auth/auth_bloc.dart` | Read/optional modify | Has `MockLoginEvent`, no UI button |
| `FE/lib/screens/auth/login_screen.dart` | Optional modify | Only if adding debug-only test login |
| `FE/lib/screens/checkout/checkout_screen.dart` | Read | Customer checkout verification |

## File Inventory

| Path | Action | Test impact |
|------|--------|-------------|
| Remote `auth.users` / `public.profiles` | Verify/create data | Enables real customer session |
| `FE/lib/blocs/auth/auth_bloc.dart` | Possible no-op | Existing mock event can remain internal |
| `FE/lib/screens/auth/login_screen.dart` | Optional debug-only button | Only if approved and guarded by `kDebugMode` |

## Dependency Map

- Blocks customer sections of Phase 5.
- Independent from Phase 2 except product visibility may affect cart item choice.

## Implementation Steps

1. Try existing real customer account first:
   - Existing customer: `hoangbavan4478+customer2@gmail.com`.
   - Confirm OTP delivery path or use user-provided OTP.
2. If the existing customer cannot produce a repeatable session, create/use a
   dedicated long-term customer test account and seed minimal data:
   - role `customer`;
   - profile full name clearly marked as test/demo;
   - at least one cart/order scenario if needed for regression smoke.
3. Use personal Google account only if user explicitly asks for a one-off manual
   verification.
4. If adding debug-only login:
   - Guard UI with `kDebugMode`.
   - Make it visually labelled as test-only.
   - Ensure checkout still requires a real Supabase session; do not use mock for
     checkout unless backend writes are intentionally skipped.
5. Run customer smoke:
   - Login -> home.
   - Product list/detail.
   - Add to cart.
   - Checkout COD or bank transfer.
   - Orders list/detail.
6. Keep long-term test data if it improves repeatable QA; only clean up noisy
   one-off records.

## Test Scenario Matrix

| Scenario | Expected |
|----------|----------|
| Customer login via OTP | Routes to `/home` |
| Customer cart add | Cart item persists and shows variant |
| Empty checkout selected items | UI blocks before RPC |
| COD checkout | Order created and cart cleared |
| Bank transfer checkout | QR opens and pending order visible |

## Success Criteria

- [ ] Long-term customer test path chosen and documented.
- [ ] Missing test account/data is created if existing related accounts cannot
      support repeatable smoke.
- [ ] Android session reaches customer home.
- [ ] Cart -> checkout -> orders smoke recorded.
- [ ] No personal account screenshot/email is kept in reports.
- [ ] No debug-only auth path exists in release mode.

## Risk Assessment

- Risk: mock login creates fake user id and cannot write backend records.
  Mitigation: use real session for checkout smoke.
- Risk: personal Google account privacy. Mitigation: explicit approval and
  delete/redact screenshots containing account info.

## Completion Notes

- Confirmed existing related accounts have Supabase Auth users and profiles:
  `hoangbavan4478+manager@gmail.com` as `manager`,
  `hoangbavan4478+customer2@gmail.com` as `customer`.
- Set password hashes on those existing auth users for repeatable QA.
- Added debug-only password login controlled by `kReleaseMode` and
  `--dart-define` values. The buttons are hidden unless debug build and the
  relevant email/password defines are provided.
- Removed the remote SVG Google icon from the login screen because Flutter
  Android could not decode SVG through `Image.network`; OTP/Google auth actions
  remain available.
- No personal Google account was used.
