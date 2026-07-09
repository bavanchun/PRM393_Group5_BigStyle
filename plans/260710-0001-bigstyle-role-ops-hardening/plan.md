---
title: BigStyle Role Ops Hardening
description: >-
  Make admin operations production-safe, normalize revenue numbers, expand
  regression coverage, modularize the largest Flutter screens, and reconcile
  stale plan state.
status: in-progress
priority: P1
effort: 6d
branch: dev
tags:
  - bugfix
  - refactor
  - flutter
  - supabase
  - auth
  - database
  - qa
  - tech-debt
blockedBy: []
blocks:
  - 260703-1750-bigstyle-demo-fix-roadmap
  - 260709-2030-bigstyle-stability-hardening
created: '2026-07-09T17:01:19.150Z'
createdBy: 'ck:plan'
source: skill
---

# BigStyle Role Ops Hardening

## Overview

Deep TDD plan for the remaining role/ops hardening after customer and manager
critical smoke passed. Scope is intentionally limited to the six requested
items:

1. Smoke admin with a real admin account.
2. Move admin user invite to a Supabase Edge Function.
3. Normalize admin and manager revenue queries.
4. Expand tests for recently fixed critical flows.
5. Modularize manager product forms and checkout.
6. Sync stale plan statuses/checklists.

## Scope Challenge

| Question | Answer |
|---|---|
| Existing code | Admin shell/users/categories already exist; `sepay-webhook` provides an Edge Function pattern; manager/customer smoke reports already exist; product update RPC and checkout guard already shipped. |
| Minimum change set | Keep scope to admin invite security, revenue correctness, tests, modularization, and PM sync. Defer new features like FCM, multi-store maps, analytics dashboards, and voucher expansion. |
| Complexity | Touches >8 files and 5+ areas. Deep mode is justified. New abstractions allowed only for Edge Function wrapper, revenue helper, and extracted UI widgets/models. |
| Selected mode | HOLD SCOPE with `--deep --tdd`. |

## Cross-Plan Dependencies

| Relationship | Plan | Reason |
|---|---|---|
| Blocks | `260703-1750-bigstyle-demo-fix-roadmap` | This plan resolves remaining demo blockers around admin/manager revenue, runtime smoke, and stale checklist state. |
| Blocks | `260709-2030-bigstyle-stability-hardening` | This plan finishes deferred modularization and verification work from the partial stability plan. |

## Current Verified Baseline

| Area | Evidence |
|---|---|
| Roles | `UserRole { customer, manager, admin }` exists in `FE/lib/models/user_model.dart`. |
| Role routing | Splash routes `admin -> /admin`, `manager -> /manager`, others -> `/home`. |
| Admin provider | `AdminBloc(AdminService())` is registered in `FE/lib/main.dart`. |
| Admin risk | `AdminService.addUser()` calls `auth.admin.inviteUserByEmail` from the mobile client; this must move server-side. |
| Edge Function pattern | `FE/supabase/functions/sepay-webhook/index.ts` uses `Deno.serve`, env secrets, JSON responses. |
| Revenue mismatch | Admin revenue sums all orders; manager revenue logic exists but needs shared rule + tests. |
| Tests | Only 2 test files currently exist under `FE/test`; latest `flutter test` passed 3/3. |
| Oversized files | `manager_create_product_screen.dart` 1305 lines, `manager_product_detail_screen.dart` 1400 lines, `checkout_screen.dart` 758 lines. |

## Execution Strategy

Run phases sequentially. Each phase is independently commit-worthy and must end
with a regression gate.

| Phase | Name | Status |
|-------|------|--------|
| 1 | [Admin Smoke Baseline](./phase-01-admin-smoke-baseline.md) | Completed |
| 2 | [Secure Admin Invite Edge Function](./phase-02-secure-admin-invite-edge-function.md) | Completed |
| 3 | [Revenue Query Normalization](./phase-03-revenue-query-normalization.md) | Completed |
| 4 | [Regression Coverage Expansion](./phase-04-regression-coverage-expansion.md) | Completed |
| 5 | [Manager Product Form Modularization](./phase-05-manager-product-form-modularization.md) | Completed |
| 6 | [Checkout Modularization](./phase-06-checkout-modularization.md) | Completed |
| 7 | [Plan Sync And Final Verification](./phase-07-plan-sync-and-final-verification.md) | Pending |

## TDD Rules

- Write or update tests before behavior changes where possible.
- For refactors, first add golden/current-behavior widget or unit tests around
  the section being moved.
- Do not broaden functionality during modularization.
- Every phase must run at least:
  - `flutter analyze`
  - `flutter test`
- Edge Function phase must also run TypeScript/static checks where available,
  or a local request smoke through Supabase CLI if configured.

## Not In Scope

- New public admin analytics dashboard beyond existing cards.
- Replacing OTP/Google auth.
- New payment gateways.
- Large redesign of customer checkout UX.
- Deleting old plans; phase 7 only reconciles status/checklists and reports.

## Red Team Review

| Finding | Decision |
|---|---|
| Moving invite to Edge Function can accidentally expose service-role behavior to any authenticated user. | Phase 2 requires server-side role check using caller JWT before service role invite. |
| Revenue rules can diverge again between AdminService and ManagerDashboardStats. | Phase 3 creates a shared documented rule and tests both admin + manager calculations. |
| Modularization can silently change form behavior. | Phases 5-6 are TDD refactor phases: tests before extraction, no UX changes unless needed to preserve existing behavior. |
| PM sync can falsely mark old plan items complete. | Phase 7 requires evidence mapping from commit/report/test to each checkbox; ambiguous items stay unchecked with note. |

## Validation Log

### Verification Results

- 2026-07-10 Phase 1 admin smoke: PASS. Real remote admin QA account routes to
  `/admin`; dashboard, users/search/filter, categories, and profile tabs render
  remote data. Invite mutation skipped and current mobile
  `auth.admin.inviteUserByEmail` path documented as Phase 2 blocker. Report:
  `plans/260710-0001-bigstyle-role-ops-hardening/reports/admin-smoke-baseline.md`.
- 2026-07-10 Phase 2 admin invite: PASS with provider caveat. Flutter now calls
  `admin-invite-user` Edge Function, function verifies caller admin role before
  service-role invite, unit/Bloc tests cover success and failure, and function
  is deployed with JWT verification enabled. Runtime invite success is blocked
  by the mail provider testing-recipient policy; validation/auth smoke passes
  and failed invite leaves no auth/profile row. Report:
  `plans/260710-0001-bigstyle-role-ops-hardening/reports/admin-invite-edge-function.md`.
- 2026-07-10 Phase 3 revenue normalization: PASS. Admin all-time revenue and
  manager today revenue now share the recognized-status rule
  `confirmed|shipping|delivered`; pending/cancelled/refunded are excluded.
  Report:
  `plans/260710-0001-bigstyle-role-ops-hardening/reports/revenue-query-normalization.md`.
- 2026-07-10 Phase 4 regression coverage: PASS. Added/administered targeted
  tests for admin invite, recognized revenue, checkout empty guard/COD success,
  and product update variant color payload. `flutter test --coverage` passed
  with 13 tests and LCOV line coverage 21.62%. Report:
  `plans/260710-0001-bigstyle-role-ops-hardening/reports/regression-coverage-expansion.md`.
- 2026-07-10 Phase 5 manager product form modularization: PASS. Extracted the
  duplicated create/edit variant table into a shared row model and widgets,
  preserving edit variant `colorHex` behavior with unit/widget tests. Create
  screen reduced from 1305 to 928 lines; edit screen reduced from 1400 to 1007
  lines. Report:
  `plans/260710-0001-bigstyle-role-ops-hardening/reports/manager-product-form-modularization.md`.
- 2026-07-10 Phase 6 checkout modularization: PASS. Extracted address, item
  list, payment selector, voucher field, and price summary widgets while
  keeping selected-item collection, route args, BLoC listener side effects, and
  `_placeOrder()` in the parent. Checkout screen reduced from 758 to 532 lines.
  Report:
  `plans/260710-0001-bigstyle-role-ops-hardening/reports/checkout-modularization.md`.

- Tier: Full (7 phases)
- Claims checked: 21
- Verified: 21
- Failed: 0
- Unverified: 0

Key verified claims:
- `AdminService.addUser()` path exists and uses admin invite API.
- Existing Edge Function pattern exists at `FE/supabase/functions/sepay-webhook/index.ts`.
- `AdminBloc` events/state exist for dashboard/users/categories.
- `OrderService.getDashboardStats()` and `ManagerDashboardStats.fromRows()` exist.
- Oversized UI files exist and exceed 700 lines.
- Existing tests are limited to product variant mapping and app error widget.

### Whole-Plan Consistency Sweep

- Files reread: `plan.md`, all 7 phase files after creation.
- Decision deltas checked: Edge Function role gate, shared revenue rule, tests-first modularization, plan sync evidence rule.
- Reconciled stale references: 0 after phase file creation.
- Unresolved contradictions: 0.

## Success Criteria

- [ ] Admin real-account smoke report exists and covers dashboard/users/categories/invite path.
- [ ] Admin invite no longer calls `auth.admin.*` directly from Flutter.
- [ ] Admin and manager revenue use one documented business rule and covered tests.
- [ ] Regression tests cover auth debug guard, checkout guard/cart clear, product RPC mapping, admin invite service failure/success boundaries, and revenue calculations.
- [x] Manager product form and checkout are split into focused widgets/helpers with no behavior regression.
- [ ] Old pending/partial plan checklists are reconciled with evidence.
- [ ] `flutter analyze` and `flutter test` pass.

## Cook Handoff

Recommended command after review:

```bash
/ck:cook /Users/vchun/Codes/FPT/PRM393/BigStyle/PRM393_Group5_BigStyle/plans/260710-0001-bigstyle-role-ops-hardening/plan.md --tdd
```

## Unresolved Questions

None for planning. During cook, admin smoke needs an admin account/session or approval to create one in Supabase.
