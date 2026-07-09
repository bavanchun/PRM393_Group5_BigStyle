---
phase: 1
title: Admin Smoke Baseline
status: completed
priority: P1
effort: 0.75d
dependencies: []
---

# Phase 1: Admin Smoke Baseline

## Overview

Establish real admin runtime truth before changing admin code. Verify an actual
admin account can reach `/admin`, load dashboard stats, list/search/filter users,
load categories, and expose the current invite-user failure safely.

## Requirements

- Functional: run app with a real admin session, capture pass/fail per admin tab.
- Functional: do not mutate production/demo data except an explicitly approved
  disposable invite attempt.
- Non-functional: write a report under this plan's `reports/` directory.

## Architecture

Current route flow:

`SplashScreen` -> `AuthBloc.CheckSessionEvent` -> `AuthSuccess(user)` ->
`user.role.name == 'admin'` -> `/admin` -> `AdminShell`.

Admin UI tabs:

- `AdminDashboardScreen` uses `AdminLoadDashboard`.
- `AdminUsersScreen` uses `AdminLoadUsers`, `AdminAddUser`,
  `AdminUpdateUserRole`, `AdminUpdateBrandName`.
- `AdminCategoriesScreen` uses category CRUD events.

## File Inventory

| Path | Action | Test impact |
|---|---|---|
| `FE/lib/screens/splash/splash_screen.dart` | Read only | Verify role route. |
| `FE/lib/screens/admin/admin_shell.dart` | Read only | Verify tab navigation. |
| `FE/lib/screens/admin/admin_dashboard_screen.dart` | Read only | Smoke dashboard load. |
| `FE/lib/screens/admin/admin_users_screen.dart` | Read only | Smoke list/search/filter/invite UI. |
| `FE/lib/screens/admin/admin_categories_screen.dart` | Read only | Smoke category list/toggle dialogs. |
| `plans/260710-0001-bigstyle-role-ops-hardening/reports/` | Create | Store admin smoke report. |

## Tests Before

- Run `flutter analyze`.
- Run `flutter test`.
- Record current branch and commit hash.

## Implementation Steps

1. Confirm real admin account exists in Supabase `profiles.role='admin'`.
2. If no admin session exists, create or request a durable admin test account.
3. Run app on emulator with debug test credentials if available.
4. Verify splash routes admin to `/admin`.
5. Smoke dashboard refresh and stats rendering.
6. Smoke users tab: list, search, role filter, brand edit dialog if available.
7. Smoke categories tab: list, edit dialog open/cancel, toggle only on disposable category or skip mutation.
8. Attempt invite-user only with a disposable email if approved; otherwise document expected current blocker from code.
9. Save report: `reports/admin-smoke-baseline.md`.

## Test Scenario Matrix

| Scenario | Priority | Expected |
|---|---|---|
| Admin login routes to shell | Critical | `/admin` opens, no fallback to customer/manager. |
| Dashboard loads | Critical | Stats render or explicit error state. |
| Users load/search/filter | Critical | Real users visible; filters do not crash. |
| Categories load | High | Categories visible; empty/error states understandable. |
| Invite user current path | High | Failure is captured; no service-role secret in app. |

## Refactor

None. This phase is observation-only.

## Tests After

- No code changes expected.
- If any code fix is required to unblock admin shell launch, stop and create a
  small fix commit before continuing with smoke.

## Regression Gate

```bash
cd FE
flutter analyze
flutter test
```

## Success Criteria

- [x] Admin account/session verified.
- [x] Admin dashboard runtime result documented.
- [x] Users tab runtime result documented.
- [x] Categories tab runtime result documented.
- [x] Invite-user baseline failure/success documented.
- [x] Report saved under plan `reports/`.

## Risk Assessment

- Risk: admin account unavailable. Mitigation: create durable QA admin account
  with explicit user approval.
- Risk: invite attempt sends real email. Mitigation: use disposable test email
  or skip mutation and document code-level blocker.

## Security Considerations

- Do not print or commit passwords.
- Do not read `.env`.
- Do not expose service-role key in Flutter.

## Dependency Map

Phase 1 feeds Phase 2 acceptance criteria. If admin smoke reveals additional
runtime blockers, record them but do not expand Phase 2 unless they block invite
security.
