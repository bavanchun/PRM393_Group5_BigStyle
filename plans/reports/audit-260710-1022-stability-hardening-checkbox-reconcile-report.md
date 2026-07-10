# Stability Hardening — Checkbox Reconcile Audit

Date: 2026-07-10
Plan: `plans/260709-2030-bigstyle-stability-hardening/`
Method: code cross-ref (Grep/Read on `FE/`) + migration file + `flutter analyze` (clean) + `flutter test` (28 passed). No DB writes.

## Gate results
- `flutter analyze`: No issues found (4.8s).
- `flutter test`: All 28 tests passed.

## Item verdicts

| Phase / Item | Verdict | Evidence |
|---|---|---|
| P1 no `#914B34` hardcode in save path | done | detail save builds via `ManagerProductVariantFormRow.fromVariant` + `row.toVariant` using `resolvedColorHex`; residual `#914B34` only swatch-palette defaults (manager_product_detail_screen.dart:71-73,117; form/manager_product_variant_form_row.dart:56,77-83) |
| P1 existing variants preserve color_hex | done | product_service_test.dart "update product RPC payload preserves variant color_hex" (passes) |
| P1 VariantModel.colorHex required / toMap emits color_hex | done | variant_model.dart:26 (required), :62 (`'color_hex'`), :44 (fromMap) |
| P1 no caller signature changes / analyze | done | `updateProduct(ProductModel)` unchanged; analyze clean |
| P2 no delete-then-insert in Flutter client | done | product_service.dart:114-120 `updateProduct` calls `rpc('update_product_with_variants')` then `getProductById`; no delete/insert in path |
| P2 atomic RPC (auth+role+ownership, delete+reinsert one fn) | done | migration 20260709100000_update_product_with_variants_rpc.sql: `security definer`, role check (manager/admin), store-ownership check, delete (:106) + insert loop (:109-113) in one plpgsql fn |
| P2 remote DB applied | done (cross-report) | asserted in plan reconciliation via `260709-2231-...remote-data-android-smoke-report.md`; not independently DB-verified (migration file present) |
| P3 empty-items checkout guard | done | checkout_screen.dart:508 `if (items.isEmpty)` returns before `CheckoutPlaceOrder` (:518) |
| P3 error states in >=4 screens | done | AppErrorState/`error != null` in cart, orders, home, product_list screens |
| P3 notifications load once, not in build | done | notifications_screen.dart:12 StatefulWidget, :21-23 initState post-frame load |
| P4 runtime report created | done | reports/260709-android-full-flow-smoke-report.md + 260709-2205 report |
| P4 orders tab blank-tab risk resolved | done | full-flow report: orders tab PASS (6 orders render), detail PASS |
| P4 status update outcome visible (runtime) | open | full-flow report: "No status mutation performed"; only bloc-level manager_bloc_test covers update logic |
| P5 FE/test exists, flutter test passes | done | 14 test files under FE/test; 28 tests pass |
| P5 smoke matrix report + covers P1 & a P3 behavior | done | android smoke reports; product_service_test (P1), app_error_state_test + checkout_bloc_test (P3) |
| P6 product form files shrink materially | done | detail 1372->1007, create 1305->928, checkout 690->532 lines |
| P6 shared widgets bounded, no Supabase, no regression | done | form/manager_product_variant_form_row.dart, widgets/manager_product_variants_table.dart (StatelessWidget, no Supabase); tests+analyze pass |

## Final statuses (set honestly)

| Phase | Status |
|---|---|
| 1 Variant Color Edit Fix | completed |
| 2 Transactional Product Update | completed |
| 3 Checkout & Error-State Guards | completed |
| 4 Manager Order Runtime Verification | in-progress (status-mutation runtime unverified) |
| 5 Test Harness & Smoke Matrix | completed |
| 6 UI Modularization | completed |

Plan `status:` kept **partial** — Phase 4 status-update runtime path unverified and matching plan acceptance criterion left unchecked. `blocks:` field untouched.

## Notes / unresolved
- P2 remote migration apply relies on a cross-plan report claim; migration file exists in repo but live DB state not verified here (task forbids DB checks).
- P4 status-mutation on-device path is the only genuinely-open item; needs a manager account able to perform an allowed status transition at runtime.
