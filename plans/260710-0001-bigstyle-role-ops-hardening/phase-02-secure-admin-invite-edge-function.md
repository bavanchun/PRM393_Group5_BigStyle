---
phase: 2
title: "Secure Admin Invite Edge Function"
status: completed
priority: P1
effort: "1d"
dependencies: [1]
---

# Phase 2: Secure Admin Invite Edge Function

## Overview

Move admin user invitation out of the Flutter client and into a Supabase Edge
Function that uses service role only after verifying the caller is an admin.

## Requirements

- Functional: admin can invite user with email, full name, role, optional brand name.
- Functional: Flutter calls an Edge Function, not `auth.admin.*`.
- Functional: non-admin caller receives 403.
- Non-functional: no service-role secret in app code, logs, or docs.

## Architecture

Proposed flow:

`AdminUsersScreen` -> `AdminBloc.AdminAddUser` -> `AdminService.addUser()` ->
`supabase.functions.invoke('admin-invite-user', body)` ->
Edge Function validates caller JWT -> service-role invite -> profile update.

Server checks:

1. Parse caller `Authorization: Bearer <jwt>`.
2. Use anon/client JWT client to get current user or query `profiles`.
3. Verify caller profile role is `admin`.
4. Validate request body.
5. Use service-role client to invite email and update `profiles`.

## File Inventory

| Path | Action | Test impact |
|---|---|---|
| `FE/supabase/functions/admin-invite-user/index.ts` | Create | Edge Function unit/local request smoke. |
| `FE/lib/services/admin_service.dart` | Modify | Replace direct admin API call. |
| `FE/lib/blocs/admin/admin_bloc.dart` | Modify | Preserve success/error state semantics. |
| `FE/lib/screens/admin/admin_users_screen.dart` | Modify if needed | Add brandName payload; keep validation. |
| `FE/test/blocs/admin_bloc_test.dart` or service test | Create | Mock success/failure boundaries. |
| `FE/supabase/functions/sepay-webhook/index.ts` | Read only | Reuse response/env patterns. |

## Tests Before

- Add failing test that `AdminService.addUser()` uses function invocation wrapper
  or injected client seam instead of direct `auth.admin`.
- Add Bloc test: `AdminAddUser` emits loading -> success on service success.
- Add Bloc test: `AdminAddUser` emits loading -> error on service failure.

## Implementation Steps

1. Create `admin-invite-user` Edge Function following `sepay-webhook` style.
2. Implement strict JSON validation:
   - email has basic valid shape
   - fullName non-empty
   - role in `customer|manager|admin`
   - brandName optional string
3. Verify caller role using the request JWT before service-role invite.
4. Invite user via `supabase.auth.admin.inviteUserByEmail`.
5. Update profile with `full_name`, `role`, and optional `brand_name`.
6. Return minimal JSON: user id, email, role.
7. Update Flutter `AdminService.addUser()` to call the function.
8. Keep UI text and existing events unless tests require a tiny state addition.
9. Document deploy/secrets command in phase report, not in code comments.

## Test Scenario Matrix

| Scenario | Priority | Expected |
|---|---|---|
| Admin invites customer | Critical | Function returns 200; profile role updated. |
| Admin invites manager with brand | Critical | Function returns 200; brandName saved. |
| Customer calls function | Critical | 403, no invite. |
| Missing/invalid JWT | Critical | 401, no invite. |
| Invalid role/email | High | 400 with safe error. |
| Duplicate email | High | Clear error surfaced in AdminBloc. |

## Refactor

- Keep `AdminEvent.AdminAddUser` shape unless brandName UI path is already
  present and safe to wire.
- Add a small function-invocation seam to `AdminService` only if tests need it.

## Tests After

- Add Edge Function local request smoke if Supabase CLI is configured.
- Add service/Bloc tests for function success/failure.
- Add static scan: no `auth.admin.inviteUserByEmail` in `FE/lib`.

## Regression Gate

```bash
cd FE
flutter analyze
flutter test
rg -n "auth\\.admin|SERVICE_ROLE|service_role" lib
```

## Success Criteria

- [x] Flutter no longer calls `auth.admin.inviteUserByEmail`.
- [x] Edge Function verifies caller is admin before service-role action.
- [x] Admin invite success and failure covered by tests.
- [x] Runtime admin invite smoke passes with disposable email or documented skip.
- [x] No service-role key appears in repo.

## Risk Assessment

- Risk: function deployed with `verify_jwt=false` by mistake. Mitigation: function
  still manually validates `Authorization` and role.
- Risk: service-role behavior overexposed. Mitigation: only invite and profile
  update allowed; no arbitrary table mutation.

## Security Considerations

- Service role only in Edge Function runtime env.
- Do not return provider tokens or invite links in logs.
- Rate-limit later if this becomes public admin tooling; not required now.

## Dependency Map

Depends on Phase 1 baseline. Phase 4 tests should include this service/Bloc path.
