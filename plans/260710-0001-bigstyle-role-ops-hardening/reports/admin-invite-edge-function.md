# Admin Invite Edge Function

Date: 2026-07-10
Branch: `dev`
Supabase project: `bigstyle-prm393`

## Summary

Admin invite has been moved out of Flutter client code and into a Supabase Edge
Function named `admin-invite-user`.

Remote deploy:

- Function: `admin-invite-user`
- Active version: `5`
- JWT verification: enabled

## Code Changes

- `FE/lib/services/admin_service.dart`
  - Replaced direct mobile `auth.admin.inviteUserByEmail` with
    `supabase.functions.invoke('admin-invite-user')`.
  - Added an injectable function invocation seam for tests.
  - Added safe error extraction from function responses.
- `FE/lib/blocs/admin/admin_bloc.dart`
  - Forwards `AdminAddUser.brandName` to the service.
- `FE/lib/screens/admin/admin_users_screen.dart`
  - Shows a brand-name field for manager invites and sends it through
    `AdminAddUser.brandName`.
- `FE/supabase/functions/admin-invite-user/index.ts`
  - Verifies caller JWT.
  - Looks up caller profile and requires `role = admin`.
  - Validates email, full name, role, and optional brand name.
  - Rejects duplicate profile email before invite to avoid role/brand overwrite.
  - Rejects invalid non-object JSON bodies through the normal 400 path.
  - Maps provider failures to safe client-facing errors.
  - Uses service-role runtime credentials only inside the Edge Function.
  - Invites the user and upserts the profile with role and optional brand.
- `FE/test/services/admin_service_test.dart`
  - Covers function invocation payload and failure mapping.
- `FE/test/blocs/admin_bloc_test.dart`
  - Covers `AdminAddUser` success, failure, and brand name passthrough.

## Verification

- `deno fmt FE/supabase/functions/admin-invite-user/index.ts`: PASS.
- `cd FE && flutter analyze`: PASS, no issues.
- `cd FE && flutter test`: PASS, 7 tests.
- Static scan: `auth.admin` no longer appears in `FE/lib`; it only remains in
  the Edge Function backend.
- Deployed Edge Function via Supabase connector with `verify_jwt=true`.

## Runtime Smoke

Admin-authenticated validation smoke:

- Request: admin JWT + invalid email payload.
- Result: HTTP 400, response `invalid email`.
- Meaning: deployed function receives authenticated admin calls and executes
  validation after auth/role checks.
- Invalid body smoke: admin JWT + `null` body returns HTTP 400,
  `invalid json`.
- Duplicate smoke: admin JWT + existing manager profile email returns HTTP 409,
  `duplicate email`, before invite mutation.

Invite mutation smoke:

- Request: admin JWT + dedicated invite-smoke QA alias.
- Result: HTTP 400, response `invite delivery failed`.
- Supabase Auth log root cause: project mail provider is in testing mode and
  only sends to the owner mailbox, so invite email delivery to the alias is
  blocked by provider policy.
- Follow-up query confirmed no auth/profile row was left for the failed invite
  alias.

This means the app/backend path is deployed and protected, but full invite
success requires either verifying the sending domain/provider or using an
allowed recipient exactly matching the mail provider policy.

## Security Notes

- No service-role key is present in Flutter code.
- Function requires a valid caller JWT and checks `profiles.role = admin` before
  service-role invite.
- Function does not return invite links, tokens, provider secrets, or raw
  service-role details.

## Unresolved Questions

None.
