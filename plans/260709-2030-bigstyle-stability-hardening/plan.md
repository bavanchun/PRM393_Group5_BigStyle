---
title: "BigStyle Stability Hardening"
description: "Fix remaining BigStyle stability risks in priority order: manager variant color integrity, transactional product update, checkout/error guards, manager runtime verification, tests, then UI modularization."
status: partial
priority: P1
branch: "dev"
tags: [bugfix, refactor, flutter, supabase, data-integrity, tech-debt]
blocks: [260709-2231-bigstyle-remote-data-testability-hardening]
blockedBy: []
created: "2026-07-09T13:31:08.231Z"
createdBy: "ck:plan"
source: skill
---

# BigStyle Stability Hardening

## Overview

Deep implementation plan for the remaining non-trivial BigStyle risks after the
demo-fix and feature-gap work. User chose **all items**, in this priority:

1. Preserve manager-edited variant `color_hex`.
2. Make product update atomic enough to avoid losing variants.
3. Guard checkout against empty item sets and expose error states.
4. Runtime verify manager order workflow.
5. Add regression/smoke coverage.
6. Modularize oversized UI files only after behavior is protected.

**Stack:** Flutter/Dart + BLoC + Supabase/Postgres. App root: `FE/`.

**Important verified context**
- `flutter analyze` currently clean.
- No `FE/test` or `FE/integration_test` files currently exist.
- `ManagerProductDetailScreen` still hardcodes variant `colorHex: '#914B34'`.
- `ProductService.updateProduct` updates product, deletes all variants, then
  inserts new variants outside an explicit database transaction.
- `create_order` RPC already rejects empty item arrays server-side, but checkout
  can still send empty items and produce poor UX.
- Prior plan `plans/260703-1750-bigstyle-demo-fix-roadmap` is still marked
  `pending`, but its journal says phases 2-5 shipped. This plan supersedes
  remaining hardening work; no blocking dependency.

## Scope Challenge

- **Existing code:** BLoC/service/screen structure already exists; reuse
  `ManagerProductBloc`, `ProductService`, current Supabase migration pattern,
  `CartState`/`OrderState`/`ProductState` error fields, and current manager
  order screens.
- **Minimum changes:** fix data integrity first; do not redesign product forms
  before tests/smoke are in place. Avoid new services unless needed for RPC
  wrapper.
- **Complexity:** touches >8 files and database migration, so deep mode is
  justified. New abstractions should be limited to shared product form widgets
  in the modularization phase.
- **Selected scope:** HOLD SCOPE. Do all user-listed items in order, no adjacent
  delight features.

## Architecture Decisions

| Area | Decision | Rationale |
|------|----------|-----------|
| Variant color edit | Preserve real `color_hex` per variant row; add selected swatch hex state only if UI still needs product-global swatch | Fixes current overwrite without expanding color system |
| Product update atomicity | Prefer Supabase RPC `update_product_with_variants` using one DB transaction boundary | Prevents product saved / variants lost partial failure |
| Existing direct update method | Keep method name if possible; internally call RPC after migration | Reduces caller churn |
| Checkout empty items | UI guard before dispatch + keep RPC guard | Better UX + defense-in-depth |
| Error states | Use existing `error` fields first; avoid global error framework | KISS |
| Manager verify | Runtime smoke checklist before modularization | Confirms old blank-tab finding is gone or catches regression |
| Modularization | Extract shared product form components after behavior tests exist | Avoid unprotected large refactor |

## Phases

| Phase | Name | Status |
|-------|------|--------|
| 1 | [Variant Color Edit Fix](./phase-01-variant-color-edit-fix.md) | Done |
| 2 | [Transactional Product Update](./phase-02-transactional-product-update.md) | Done, DB applied |
| 3 | [Checkout And Error-State Guards](./phase-03-checkout-and-error-state-guards.md) | Done |
| 4 | [Manager Order Runtime Verification](./phase-04-manager-order-runtime-verification.md) | Blocked by no device/session |
| 5 | [Test Harness And Smoke Matrix](./phase-05-test-harness-and-smoke-matrix.md) | Done automated, runtime pending |
| 6 | [UI Modularization](./phase-06-ui-modularization.md) | Done automated, runtime smoke pending |

## Dependencies

```text
Phase 1 -> Phase 2 -> Phase 3 -> Phase 4 -> Phase 5 -> Phase 6
```

- Phase 1 before Phase 2: transactional update should preserve corrected
  variant color behavior.
- Phase 2 before broad tests: tests should lock the final atomic update contract,
  not the known unsafe direct-update behavior.
- Phase 5 before Phase 6: modularization touches large UI surfaces and needs
  regression coverage first.

## Cross-Plan Dependencies

| Relationship | Plan | Status | Decision |
|--------------|------|--------|----------|
| Related, not blocking | `plans/260703-1750-bigstyle-demo-fix-roadmap` | pending but mostly shipped per journal | This plan supersedes remaining hardening; no frontmatter dependency |
| Historical source | `docs/ux-flow-audit.md` | audit doc | Use only after code re-verification because many findings are stale |
| Historical source | `plans/260703-2142-app-feature-gap-closure` | completed | Confirms avatar/map/voucher/order-cancel work already shipped |

## Acceptance Criteria

- [x] Manager edit preserves each variant `color_hex`; no silent reset to
      `#914B34`.
- [x] Product update is atomic: failure inserting variants cannot leave product
      with deleted/missing variants.
- [x] Checkout refuses empty item sets before dispatch and shows actionable
      message.
- [x] Cart/orders/home/product/notification error states no longer present
      network failures as empty content.
- [ ] Manager order list, detail, and status update pass runtime smoke on a real
      manager account.
- [x] Flutter test harness exists with targeted unit/widget tests for fixed
      behaviors.
- [x] Oversized product form screens are modularized with no behavior change and
      analyzer/tests still pass.

## Validation Commands

Run from `FE/` unless noted:

```bash
flutter analyze
flutter test
flutter test --coverage
```

Manual/runtime:

```text
Customer: login -> cart -> checkout selected items -> COD -> orders -> detail
Customer: bank transfer pending -> pay-again -> payment QR opens
Manager: login -> orders tab -> filter -> detail -> update status -> list refresh
Manager: edit product variants -> save -> reopen -> color_hex unchanged
```

## Red Team Review

### Findings Applied Inline

| Severity | Finding | Plan response |
|----------|---------|---------------|
| Critical | A delete-then-insert variant update can corrupt product data if any insert fails | Phase 2 requires RPC transaction boundary and failure test |
| High | Fixing edit color before transaction can still be lost by later refactor | Phase order makes Phase 2 preserve Phase 1 behavior |
| High | Modularizing 1300-line screens without tests is high regression risk | Phase 6 depends on Phase 5 |
| Medium | Existing audit has stale findings; blindly planning all old issues wastes time | Plan scopes only re-verified current risks |
| Medium | Runtime manager order issue may be data/session artifact | Phase 4 is diagnose-and-verify, not blind rewrite |

### Whole-Plan Consistency Sweep

- Files reread target: `plan.md`, all `phase-*.md`.
- Decision deltas checked: phase order, RPC preference, test-before-refactor,
  stale audit handling.
- Reconciled stale references: old splash/cart/order-detail P0/P1 findings are
  not included as active work.
- Unresolved contradictions: 0.

## Validation Log

### Verification Results

- **Tier:** Full (6 phases)
- **Claims checked:** 18
- **Verified:** 18
- **Failed:** 0
- **Unverified:** 0

Verified facts:
- `ManagerProductDetailScreen` hardcodes `colorHex: '#914B34'`.
- `ProductService.updateProduct` updates product, deletes variants, inserts
  variants sequentially.
- `VariantModel` maps `color_hex`.
- `CheckoutScreen._placeOrder` builds items from cart/selected ids before
  dispatch.
- `create_order` RPC checks `jsonb_array_length(p_items) = 0`.
- `NotificationsScreen` dispatches `NotificationLoad` inside `build`.
- `CartState`, `OrderState`, `ProductState`, `NotificationState` already have
  `error` fields.
- No current `FE/test` or `FE/integration_test` files found.

### Validation Decisions

- Do all seven requested work items.
- Prioritize data integrity before UX polish.
- Prefer minimal code churn until tests exist.
- Defer broad design-system cleanup unless it directly supports modularization.

### 2026-07-10 Reconciliation

- Product update RPC was applied/verified in
  `plans/260709-2231-bigstyle-remote-data-testability-hardening/reports/260709-remote-data-android-smoke-report.md`.
- Product variant UI extraction completed in
  `plans/260710-0001-bigstyle-role-ops-hardening/reports/manager-product-form-modularization.md`.
- Checkout section extraction completed in
  `plans/260710-0001-bigstyle-role-ops-hardening/reports/checkout-modularization.md`.
- Final automated gates passed in
  `plans/260710-0001-bigstyle-role-ops-hardening/reports/pm-role-ops-hardening-completion.md`.
- Manager order status mutation remains unchecked because the latest final phase
  did not rerun that runtime path after UI refactors.

### Whole-Plan Consistency Sweep

- Files reread: `plan.md`, six phase files.
- Decision deltas checked: 4.
- Reconciled stale references: 0 after writing.
- Unresolved contradictions: 0.

## Out of Scope

- New payment provider.
- Push notifications/FCM.
- Full redesign of manager product UX.
- Replacing BLoC/state architecture.
- Broad package upgrades beyond what a fix requires.
- Production deployment.

## Next Step

Recommended implementation command after review:

```bash
/ck:cook /Users/vchun/Codes/FPT/PRM393/BigStyle/PRM393_Group5_BigStyle/plans/260709-2030-bigstyle-stability-hardening/plan.md
```
