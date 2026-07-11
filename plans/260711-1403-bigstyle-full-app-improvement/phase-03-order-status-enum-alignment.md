---
phase: 3
title: "Order-status enum alignment"
status: pending
effort: ""
---

# Phase 3: Order-status enum alignment

> ⚠️ **RED-TEAM OVERRIDE.** (RT-13) Before shipping: `grep` EVERY `switch (…OrderStatus…)` site — any with a `default:` clause will silently swallow the 2 new values and `flutter analyze` will NOT warn. Audit each. Keep the `orElse` in `order_model.dart:162` but add an assert/log so future unknowns are visible, not silent. (RT-14) Add `processing`/`refunded` as **renderable, read-only, `isCancellable=false`**; do NOT wire manager transitions. <!-- Updated: Validation V2 — DECIDED: read-only, NOT manager-settable; exclude both from manager nextStatuses (they arrive via webhook/admin/SQL). --> (RT-9) No DB migration (enum already has all 7 — verified); this is a pure Dart-model bug.

## Overview
Fix F3 (MED): DB enum `order_status` has 7 values (…`processing`, `refunded`) but Dart `OrderStatus` has 5; `OrderModel.fromMap` uses `orElse: () => OrderStatus.pending`, so `processing`/`refunded` orders silently render as "Chờ xác nhận". Align the Dart enum to the DB truth.

## Requirements
- Functional: `processing` and `refunded` orders render their true label + color; `fromMap` round-trips all 7; state machine + cancellable gate remain correct.
- Non-functional: no crash on unknown; keep existing status labels/colors stable.

## Architecture
Add `processing` (after confirmed) and `refunded` to `OrderStatus` enum. Extend `label`, `nextStatuses`, `isActive`, `happyPath` (decide: processing between confirmed and shipping). Add StatusColors entries. Decide manager-settable transitions — see open question (may be webhook/admin-only; if so, keep them out of manager `nextStatuses` but still renderable). Keep `orElse` fallback as a last-resort guard but now all real DB values map explicitly.

## Related Code Files
- Modify: `FE/lib/models/order_status.dart` (enum + label + nextStatuses + isActive/happyPath), `FE/lib/config/theme/status_colors.dart` (add processing/refunded colors).
- Verify: `FE/lib/models/order_model.dart` (fromMap firstWhere), manager order status-update UI (`FE/lib/screens/manager/…`, `FE/lib/blocs/manager/manager_bloc.dart`).
- Tests: `FE/test/models/order_status_cancellable_test.dart`, add a fromMap-parses-all-7 test.

## Implementation Steps (TDD)
1. Failing tests: `OrderStatus` parses `'processing'`/`'refunded'` to distinct values with correct labels; `isCancellable` false for both; state-machine transitions match intended graph.
2. Extend the enum + label + nextStatuses + StatusColors.
3. Confirm manager UI only offers legal transitions (per open question decision) and renders processing/refunded read-only if not manager-settable.
4. Run full suite; ensure no exhaustive-switch breakage (Dart switch on enum must handle new values — analyze will catch).

## Success Criteria
- [ ] `processing`/`refunded` render true label + color (not pending).
- [ ] `fromMap` maps all 7 DB values explicitly; `flutter analyze` 0 (all switches exhaustive).
- [ ] Cancellable gate + state machine tests green.

## Risk Assessment
- Adding enum values makes existing exhaustive `switch` statements incomplete → `flutter analyze` flags them; fix each. No DB migration needed (enum already has the values). Manager transition semantics depend on open question — default to read-only for processing/refunded until confirmed.
