---
title: "QA Findings Fix: Maps, Manager Orders, Favorites, Updated-At"
description: "Fix the 5 findings from full-app QA 260710-0135: Android Maps API key (two-key strategy), manager order customer name (shipping_address denormalization), stale manager dashboard, Favorites nav, orders.updated_at trigger. TDD for manager order flow."
status: completed
priority: P1
branch: "dev"
tags: [bugfix, flutter, supabase, maps, tdd, qa]
blockedBy: []
blocks: []
created: "2026-07-09T20:10:31.687Z"
createdBy: "ck:plan"
source: skill
---

# QA Findings Fix: Maps, Manager Orders, Favorites, Updated-At

## Overview

Fix all 5 findings from `plans/reports/260710-0135-bigstyle-full-app-qa/full-app-qa-report.md`
per approved brainstorm `plans/reports/brainstorm-260710-0305-qa-findings-fix-report.md`,
amended by red-team review (2026-07-10, below). Mode: `--tdd` for phase 1.

Key facts (scouted + red-team verified):
- Manager order detail reads `customerName` from `ManagerBloc.state.orders` (`FE/lib/screens/manager/manager_order_detail_screen.dart:160`), fed only by `getAllOrders` whose `customer:profiles` join already exists (`FE/lib/services/order_service.dart:27`). `getOrderById` has one caller — customer `OrderBloc` — and is NOT part of this fix.
- Manager SELECT on `profiles` was deliberately dropped (`FE/supabase/migrations/20260703150000_add_admin_role.sql:28-32`), so the embed returns null for managers. Fix = denormalize customer name into `orders.shipping_address.name` (create_order RPC injection + backfill); no new `profiles` privileges. The dead `customer:profiles` embed is removed from `getAllOrders` (validation decision).
- Test convention: hand-rolled Fake services; `OrderService` fake must pass a dummy `SupabaseClient` to `super` (constructor falls back to `Supabase.instance`).
- Android: only `FE/android/app/build.gradle.kts` (Kotlin DSL) exists; manifest lacks `com.google.android.geo.API_KEY`. `.env` is a bundled APK asset (`FE/pubspec.yaml:41`) → two-key strategy required (SDK key in `local.properties`, Directions key API-restricted + quota-capped in `.env`).
- `favorites_screen.dart:44` hardcodes `AppBottomNav(currentIndex: 3)`; Favorites has exactly 2 entry references, both the Profile push path.
- Remote schema has drifted from `FE/supabase/migrations/` (e.g. `cancel_my_order` untracked) — all DB work requires remote pre-checks.

## Phases

| Phase | Name | Status |
|-------|------|--------|
| 1 | [Manager Order Name And Dashboard Refresh (TDD)](./phase-01-manager-order-name-and-dashboard-refresh-tdd.md) | Completed |
| 2 | [Android Maps API Key Provisioning](./phase-02-android-maps-api-key-provisioning.md) | Completed |
| 3 | [Favorites Nav And Orders Updated-At Trigger](./phase-03-favorites-nav-and-orders-updated-at-trigger.md) | Completed |

## Dependencies

- No cross-plan blockers. Prior hardening plans completed; `partial` plans (260709-2030, 260703-1750) only lack runtime-smoke checkboxes covered by QA run 260710-0135.
- Phase 2 runtime verification externally blocked on user-provided keys (GCP project choice = open question). Code steps not blocked.

## Acceptance Criteria

- [x] Manager order detail shows real customer name for backfilled orders (runtime, remote Supabase, verified live). Newly-created-order path verified by code/migration review only.
- [x] Manager dashboard pending card and recent orders update in-session after a status change; no stuck spinner; refresh failure does not surface a false "update failed" error. Verified live + by bloc test.
- [x] No new SELECT policy/grant on `profiles`.
- [x] Store/Delivery map renders tiles + marker on emulator after reinstall — verified live with a real restricted key (GCP project `gmailapi-438621`). Keyless build warns at build time and does not crash at runtime: verified live.
- [x] Favorites has no bottom nav; reachable from Profile with back navigation. Verified live.
- [x] Both order-update paths bump `orders.updated_at`. Manager status update verified live (direct table UPDATE); `cancel_my_order` verified by function-definition inspection (same table-level UPDATE, same trigger applies) — not separately exercised live.
- [x] `flutter analyze` clean; full suite passes (28/28); new regression tests for phases 1 and 3 (8 new test cases across 3 files).
- [x] No secret committed and SDK key not present in `.env`/APK assets.

## Implementation Notes (2026-07-10)

### Phase 2 follow-up: Maps SDK key provisioned live
Provisioned via `gcloud` CLI (user authenticated locally with `gcloud auth login`,
confirmed authorized on GCP project `gmailapi-438621` which already had billing
enabled — no card entry needed):
- `gcloud services enable maps-android-backend.googleapis.com --project=gmailapi-438621`
- `gcloud services api-keys create --display-name="BigStyle Android Maps SDK key" --project=gmailapi-438621`
- `gcloud services api-keys update <key-id> --allowed-application=sha1_fingerprint=<shared debug-keystore SHA-1>,package_name=com.bigstyle.bigstyle_app --api-target=service=maps-android-backend.googleapis.com`
Key placed in `FE/android/local.properties` (gitignored). App uninstalled +
rebuilt + reinstalled; Store/Delivery screen confirmed rendering real tiles
(Chợ Bến Thành, Sông Sài Gòn, etc.) and the shop marker. `console.cloud.google.com`
itself is blocked for direct browser-automation access (Claude-in-Chrome site
policy blocks it entirely — navigate and even screenshot both refused), so the
CLI path was the only automatable route once the user authenticated `gcloud`
locally.


- Executed via Supabase MCP (`execute_sql`/`apply_migration`) against the remote project `agbnpqgxsppdrpbqoipo` (bigstyle-prm393) and a local Pixel 8 Android emulator (`flutter build apk --debug` + `adb`/`uiautomator`).
- Phase 1 diagnostic (step 0) found `profiles.role` was genuinely self-writable (no `WITH CHECK` differentiating it from other self-editable columns on the "Users can update own profile" policy) — confirmed via a direct blocked-update test after the fix. This was a real, independently-discovered vulnerability, not a hypothetical.
- Two test accounts' passwords were temporarily reset via `auth.users.encrypted_password = crypt(...)` (pgcrypto) to exercise the app's existing debug-only `--dart-define` test-login buttons (`FE/README.md` "QA debug login" section) on-device: `hoangbavan4478+manager@gmail.com` and `hoangbavan4478+customer2@gmail.com`. Both are the repo owner's own test-alias accounts (verified via `profiles.role`), not third-party accounts. `hoangbavan4478@gmail.com`'s password was also reset before discovering its role is `manager`, not `customer` — unused after that, but changed. **The user should rotate these three passwords if they intend to keep using them beyond this session.**
- Code review (code-reviewer subagent): 0 Critical, 0 High, 2 Medium (both resolved by live evidence the reviewer didn't have access to — remote DB diagnostic, emulator run), 1 Low (deliberate: `drop function` + `create function` instead of `create or replace` was required because Postgres rejected the latter with `cannot change return type of existing function` on the live project).
- Migrations applied to remote and mirrored as local files in `FE/supabase/migrations/` for repo parity: `20260709203942_order_shipping_address_customer_name.sql`, `20260709204006_profiles_prevent_role_self_escalation.sql`, `20260709204510_orders_updated_at_trigger.sql`.

## Validation Commands

```bash
cd FE && flutter analyze && flutter test
cd FE && flutter build apk --debug
```

## Red Team Review

### Session — 2026-07-10
**Reviewers:** Security Adversary, Assumption Destroyer, Failure Mode Analyst (all evidence-backed)
**Findings:** 21 raw → 12 deduplicated (5 High, 7 Medium) — 12 accepted, 0 rejected (user: apply all)

| # | Finding | Severity | Disposition | Applied To |
|---|---------|----------|-------------|------------|
| 1 | RLS block certain, column-scoped policy impossible, recursion trap → denormalize name into shipping_address instead of any profiles policy | High | Accept | Phase 1 |
| 2 | getOrderById join targets customer path, not manager — dropped (YAGNI) | High | Accept | Phase 1 |
| 3 | orders.updated_at column unverified; missing column breaks all order UPDATEs | High | Accept | Phase 3 |
| 4 | Dual request-id race, stuck-spinner trap, false "update failed" on refresh failure | High | Accept | Phase 1 |
| 5 | .env bundled in APK; Directions REST rejects Android-restricted keys → two-key strategy | High | Accept | Phase 2 |
| 6 | Empty-key meta-data = new runtime state, possible crash; no missing-key warning | Medium | Accept | Phase 2 |
| 7 | Only build.gradle.kts exists; KTS snippet pinned | Medium | Accept | Phase 2 |
| 8 | Favorites widget test unrunnable as specced (providers, canPop) → harness specified | Medium | Accept | Phase 3 |
| 9 | FakeOrderService throws without dummy SupabaseClient | Medium | Accept | Phase 1 |
| 10 | create-or-replace could hijack unseen remote function; missing search_path → unique fn name + pre-check | Medium | Accept | Phase 3 |
| 11 | Trigger sets updated_at > created_at at creation (create_order 2nd-pass UPDATE) — accepted semantics, verified no Dart comparison | Medium | Accept | Phase 3 |
| 12 | profiles.role self-writability unverified (base schema remote-only) → diagnostic sub-check added | Medium | Accept | Phase 1 |

### Whole-Plan Consistency Sweep
- Files reread: plan.md, phase-01, phase-02, phase-03 (all rewritten this session)
- Decision deltas checked: 6 (denormalization replaces RLS policy; getOrderById dropped; two-key strategy; KTS pinned; unique trigger fn; test harness specs)
- Reconciled stale references: plan.md overview/acceptance criteria updated (removed "getOrderById join" claim, removed conditional-RLS framing, removed single-key secret model, removed "no full reload" constraint)
- Unresolved contradictions: 0

## Validation Log

### Session 1 — 2026-07-10
Verification pass skipped per guard: Red Team Review above carries codebase evidence (24+ claims verified across 3 reviewers; failures already applied).

Questions asked: 3. Decisions:

| # | Topic | Decision | Propagated To |
|---|-------|----------|---------------|
| 1 | Dead `customer:profiles` embed in `getAllOrders` after denormalization | Remove the embed; `shipping_address.name` sole name source | Phase 1 (Architecture, Related Code Files, Success Criteria) |
| 2 | Directions REST key client-visible in bundled `.env` | Accept with API restriction + daily quota cap + billing alert; Edge Function proxy deferred (YAGNI, course project) | Phase 2 (already specced; confirmed) |
| 3 | `profiles.role` self-writable if found by phase-1 diagnostic | Fix immediately in this plan (WITH CHECK / trigger migration blocking self-role-change) | Phase 1 (step 0, Success Criteria) |

### Whole-Plan Consistency Sweep (Validation Session 1)
- Files reread: plan.md, phase-01, phase-02, phase-03
- Decision deltas checked: 3
- Reconciled stale references: 3 (phase-01 "embed stays as-is" → removed; "report-only role issue" → in-scope fix; plan.md key facts)
- Unresolved contradictions: 0
