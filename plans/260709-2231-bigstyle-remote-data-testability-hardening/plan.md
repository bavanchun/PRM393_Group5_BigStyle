---
title: "BigStyle Remote Data And Testability Hardening"
description: "Apply the pending Supabase RPC, repair remote seed ownership/images, create a clean customer test path, and rerun Android smoke for manager and customer flows."
status: completed
priority: P1
effort: "7h"
branch: "dev"
tags: [bugfix, supabase, database, auth, flutter, qa, critical]
blockedBy: [260709-2030-bigstyle-stability-hardening]
blocks: []
created: "2026-07-09T15:32:18.081Z"
createdBy: "ck:plan"
source: skill
---

# BigStyle Remote Data And Testability Hardening

## Overview

Plan to finish the remote Supabase/data blockers found during Android smoke:
apply the missing product-update RPC, assign seed products to the intended
manager, create a reliable customer test session, replace broken/external image
URLs, and rerun full Android smoke.

This is **remote-data + verification scope**, not a broad UI refactor. The
local app fixes from `260709-2030-bigstyle-stability-hardening` are assumed as
input. Current verified remote state:

- Project: `bigstyle-prm393`, ref `agbnpqgxsppdrpbqoipo`.
- `update_product_with_variants` RPC: missing.
- Products: 15 total, 15 with `store_id is null`.
- Product images: 15/15 products use Unsplash URLs.
- Profiles: main account is currently `manager`; `+manager` is manager but has
  no sign-in; `+customer2` is customer but has no sign-in.

## Locked User Decisions

- Seed catalog owner: assign the 15 seed products to
  `hoangbavan4478+manager@gmail.com`.
- Long-term QA accounts: use existing related accounts that already have data
  where possible; create missing dedicated test accounts/data when required.
- Avoid relying on personal Google account for repeatable QA unless explicitly
  approved for a one-off manual test.

## Scope Challenge

- **Existing code:** local migration for RPC already exists at
  `FE/supabase/migrations/20260709100000_update_product_with_variants_rpc.sql`;
  app already calls `ProductService.updateProduct()` RPC; create product already
  sets `store_id` for new products; manager UI and order flow are mostly
  working after config fix.
- **Minimum changes:** apply/verify remote RPC, run one controlled data update
  for seed ownership, provision one customer login path, update image URLs, then
  smoke test. Do not rewrite product forms or auth architecture in this plan.
- **Complexity:** touches Supabase DDL/data, auth/test account setup, seed data,
  and Android runtime. Deep mode justified, but phases remain sequential and
  narrow.
- **Selected scope:** HOLD SCOPE.

## Architecture Decisions

| Area | Decision | Rationale |
|------|----------|-----------|
| RPC deploy | Apply the existing local migration to remote, then verify via `pg_proc` and app edit smoke | Avoid duplicate migration design; local contract already matches app call |
| Product ownership | Assign all current seed products to `hoangbavan4478+manager@gmail.com`'s profile UUID | Makes manager product list/edit consistent with existing RLS and user-selected owner |
| Test accounts | Use related seeded accounts first; create missing long-term test accounts/data if current accounts cannot support repeatable smoke | Keeps QA stable across sessions |
| Customer testing | Prefer `hoangbavan4478+customer2@gmail.com` or a new dedicated customer test account/session; avoid personal Google account unless explicitly approved | Repeatable QA without privacy ambiguity |
| Image repair | Replace external/broken seed image URLs with stable Supabase Storage URLs or known-good URLs after HEAD audit | Stops runtime 404 and flaky demo assets |
| Verification | Every remote mutation gets before/after SQL count + Android screenshot/log check | Prevents data drift and confirms UX impact |

## Phases

| Phase | Name | Status |
|-------|------|--------|
| 1 | [Remote RPC Apply And Verification](./phase-01-remote-rpc-apply-and-verification.md) | Completed |
| 2 | [Seed Product Ownership](./phase-02-seed-product-ownership.md) | Completed |
| 3 | [Customer Test Account Session](./phase-03-customer-test-account-session.md) | Completed |
| 4 | [Product Image URL Repair](./phase-04-product-image-url-repair.md) | Completed |
| 5 | [Full Android Smoke Verification](./phase-05-full-android-smoke-verification.md) | Completed |

## Dependencies

```text
Phase 1 -> Phase 2 -> Phase 3 -> Phase 4 -> Phase 5
```

- Phase 1 before Phase 2: seed ownership should rely on final RPC/RLS contract.
- Phase 2 before manager edit smoke: manager product list must show products.
- Phase 3 before customer smoke: checkout/cart/orders require customer session.
- Phase 4 before final smoke: broken images should be removed before visual QA.
- Phase 5 validates the whole result on emulator.

## Cross-Plan Dependencies

| Relationship | Plan | Reason |
|--------------|------|--------|
| Blocked by | `260709-2030-bigstyle-stability-hardening` | This plan applies/verifies the local RPC and runtime fixes from that plan on remote Supabase |
| Historical source | `plans/260709-2030-bigstyle-stability-hardening/reports/260709-android-full-flow-smoke-report.md` | Runtime evidence for current blockers |

## Acceptance Criteria

- [x] Remote Supabase has `public.update_product_with_variants`.
- [x] Manager can see 15 seed products in product tab.
- [x] Manager edit product no longer fails because of missing RPC or product ownership.
- [x] Dedicated customer account/session can run cart -> checkout -> orders smoke.
- [x] No product image URL in active seed catalog returns HTTP 404.
- [x] Android smoke report covers login, manager product edit, manager orders, customer cart/checkout/orders.

## Validation Commands

```bash
cd FE
flutter analyze
flutter test
flutter run -d emulator-5554
```

Supabase verification is via MCP/SQL against project `agbnpqgxsppdrpbqoipo`;
do not read or print `.env` secrets.

## Red Team Review

- **Data safety:** Do not run broad updates without pre-count and post-count.
  Ownership update should target only current seed set (`store_id is null`) or
  explicitly named product ids.
- **Auth privacy:** Do not choose personal Google account in emulator without
  explicit user approval.
- **Migration safety:** Applying RPC is DDL; use migration mechanism or exact
  migration SQL, then verify advisors for SECURITY DEFINER/search_path issues.
- **Demo risk:** Implementation must use `hoangbavan4478+manager@gmail.com` for
  seed ownership; using the currently signed-in main account would contradict
  the locked user decision.

## Validation Log

- Verified local RPC migration exists:
  `FE/supabase/migrations/20260709100000_update_product_with_variants_rpc.sql`.
- Verified app caller exists: `FE/lib/services/product_service.dart`.
- Verified remote blockers by SQL on 2026-07-09:
  RPC missing; 15/15 products `store_id is null`; 15/15 products use Unsplash.
- User locked seed owner and test-account strategy after initial plan:
  `hoangbavan4478+manager@gmail.com` owns seed catalog; create missing
  long-term test accounts/data when needed.
- Completed remote execution on 2026-07-09:
  RPC applied and grant-repaired; 15 seed products assigned to `+manager`;
  repeatable debug-only real Supabase login added; two image URLs returning 404
  repaired; Android manager/customer smoke passed.
- Reports:
  `reports/260709-remote-data-android-smoke-report.md` and
  `../reports/260709-2309-bigstyle-remote-data-testability-validation.md`.
- Final gates after reviewer fix:
  `git diff --check`, `flutter analyze`, and `flutter test` all passed.

### Whole-Plan Consistency Sweep
- Files reread: `plan.md`, five phase files after scaffold.
- Decision deltas checked: remote scope, manager ownership locked to
  `+manager`, customer privacy boundary, long-term QA account strategy, image
  URL source.
- Reconciled stale references: converted unresolved ownership/customer-account
  questions into locked decisions.
- Unresolved contradictions: 0.

## Unresolved Questions

None.
