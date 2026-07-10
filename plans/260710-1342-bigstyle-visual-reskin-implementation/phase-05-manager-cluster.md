---
phase: 5
title: "Manager Cluster"
status: pending
effort: "L (2 days, 9 screens, highest-debt cluster)"
priority: P1
dependencies: [4]
---

# Phase 5: Manager Cluster

## Overview

Manager is 9/9 screens at zero shared-widget use (Phase 1) — every screen here needs both a token migration AND a shared-component adoption pass, not just a color swap. Highest-debt cluster in the whole app (manager alone held ~78 of the audit's ~195 screens-only hardcode-hit lines; the guard script's occurrence-level baseline runs higher — use its live output). <!-- Updated: Red Team Session 1 -->

## Screens (effort tags from Phase 4 cluster table)

| Screen | File | Effort | Findings source |
|---|---|---|---|
| ManagerProductList | `FE/lib/screens/manager/products/manager_product_list_screen.dart` | **L** | `phase-04-gap-findings-manager.md` |
| ManagerProductDetail | `FE/lib/screens/manager/products/manager_product_detail_screen.dart` (+ companion widgets `manager_product_variants_table.dart`, `manager_product_variant_table_cells.dart` — contain guard violations, in scope) <!-- Updated: Red Team Session 1 - companion files were unowned by any phase --> | **L** — inherits ManagerCreateProduct's findings too (`M34`, heavily shared code — see step 2) | same |
| ManagerCreateProduct | `FE/lib/screens/manager/products/manager_create_product_screen.dart` | **L**, inherited (never visually captured — see Phase 0) | Phase 1 code metrics + inherited from ManagerProductDetail |
| ManagerDashboard | `FE/lib/screens/manager/manager_dashboard.dart` (+ `manager_dashboard_widgets.dart`) | M — closes `M6` via `StatusBadge` | `phase-04-gap-findings-manager.md` |
| ManagerOrders | `FE/lib/screens/manager/manager_orders_screen.dart` (+ `manager_order_card.dart`) | M | same |
| ManagerOrderDetail | `FE/lib/screens/manager/manager_order_detail_screen.dart` | M | same |
| ManagerProfile (inline) | `FE/lib/screens/manager/manager_shell.dart:55` (`_ManagerProfileScreen`) | M — closes `M2` (`Colors.grey` → `textSecondary`) | same |
| ManagerCategoryList | `FE/lib/screens/manager/categories/manager_category_list_screen.dart` (+ `manager_category_edit_sheet.dart`) | M | same |
| ManagerVoucherList | `FE/lib/screens/manager/vouchers/manager_voucher_list_screen.dart` (+ `manager_voucher_edit_sheet.dart`) | **L** — FAB-contrast finding, re-verify with real tool | same |

## Pre-condition

ManagerCreateProduct was never visually captured (blocked by the FAB tap-target finding during audit). Phase 0's human-tap check determines the path <!-- Updated: Red Team Session 1 - the occlusion hypothesis is contradicted by code: the FAB is a Scaffold-level floatingActionButton, which list items cannot occlude; likeliest verdict is adb-capture artifact -->: if the tap works by hand, Phase 0 already delta-captured this screen and the "inherited from ManagerProductDetail" placeholder grade is replaced by a real one. If Phase 0 diagnosed a real trivial bug, step 1 fixes it here; if non-trivial, migrate blind and flag `unverified`.

## Implementation Steps

1. If Phase 0 diagnosed a real, trivial manager-FAB bug: fix it in a **separate commit** from any token work (same two-commit rule as Phase 3). <!-- Updated: Red Team Session 1 -->
2. **`M34` sequencing**: ManagerCreateProduct and ManagerProductDetail share the bulk of their code (now 1007/928 lines — the audit's "~965/1033, ~90%" numbers are stale; **diff the two files first** to measure today's real overlap before committing to a replay-the-same-diff strategy). Migrate ManagerProductDetail first, then apply the same diff pattern to ManagerCreateProduct — don't migrate both independently and risk further divergence. <!-- Updated: Red Team Session 1 - stale numbers corrected; ProductFormBody extraction removed from this step, see Follow-ups -->
3. ManagerProductList: fix `M19`'s AppBar-color issue is already done on this screen (old audit) — verify it stayed fixed through the v2 swap (AppBar should use `surface`/white per the original fix, now with v2's `surface` value, still `#FFFFFF`, unchanged — should be a no-op verification, not new work).
4. ManagerProductDetail + ManagerCreateProduct: apply the SAME AppBar fix (`M19`'s pink→white pattern) — Phase 4 confirmed this is still open on both (list screen was the only one fixed originally).
5. Wire `StatusBadge` (Phase 2) into ManagerOrders/ManagerOrderDetail's status displays (consolidating their `_getStatusColor` maps). **`M6` is a one-line token swap on ManagerDashboard's stat card (`manager_dashboard_widgets.dart:33,180`), not a badge conversion** — do it as part of step 7's sweep. <!-- Updated: Red Team Session 1 -->
6. ManagerProfile (inline class): per Phase 0's stale-finding verdict, `M2` is **overtaken by events** — no `Colors.grey` remains in `manager_shell.dart` (header rewritten to white-on-gradient). Do NOT apply the originally-prescribed `textSecondary` swap (it would regress the header); instead verify white-on-v2-gradient contrast with a real AA tool and record the measurement. <!-- Updated: Red Team Session 1 -->
7. Per-screen hardcode → token sweep. **Checklist = live guard-script output filtered to this cluster** (including the companion widget files); audit counts (ManagerProductList 28, ManagerProductDetail 20, ManagerCreateProduct 18 — the 3 highest-debt screens in the inventory) are context only — they miss mixed lines like `manager_product_list_screen.dart:457` (`Colors.grey` in a ternary, which is `M20`'s hardcode — closing M20 requires THIS line, invisible to the old count). <!-- Updated: Red Team Session 1 -->
8. ManagerVoucherList: re-check its FAB-contrast finding with a real WCAG tool before accepting/rejecting.
9. `flutter analyze` per screen; `flutter test` at cluster end.

## Follow-ups (explicitly NOT in this plan's scope) <!-- Updated: Red Team Session 1 - moved out of the step list so "if time allows" can't leak into scope -->

- `ProductFormBody` extraction (`M34`'s architectural recommendation): flag as a follow-up plan; a parallel diff applied twice is this plan's accepted, lower-risk substitute.

## Regression Checklist

- [ ] ManagerProductList/Detail/Create: full CRUD flow (create, view detail, edit) unchanged; the `ManagerProductDetailScreen` dirty-form-on-open quirk (noted during Phase 2 capture, not a token issue) is NOT this plan's job to fix — don't accidentally fix or worsen it while touching the form code, note if you observe it.
- [ ] ManagerDashboard: revenue/order-count stats, pending-order navigation shortcut all function identically.
- [ ] ManagerOrders/OrderDetail: status filter, status-update flow (verified live in a prior session per `stability-hardening` phase 4) — do NOT regress this, it was recently proven working end-to-end.
- [ ] ManagerProfile: edit-profile link, logout unchanged.
- [ ] ManagerCategoryList/VoucherList: create/edit sheet open-close, list refresh unchanged.

## Success Criteria

- [ ] All 9 screens migrated (ManagerCreateProduct verified live if Phase 0 unblocked it, otherwise clearly flagged inherited/unverified).
- [ ] `M6`, `M19` (both file instances), `M20` (including the mixed-line `:457` hardcode) closed — verify against `docs/ux-flow-audit.md`'s original descriptions, not just "token swapped." `M2` re-dispositioned per Phase 0's verdict (overtaken-by-events, gradient-contrast measurement recorded). <!-- Updated: Red Team Session 1 -->
- [ ] Manager cluster's guard-script count (baseline recorded at Phase 1; audit's "~78" is context) drops to 0 non-allowlisted occurrences, companion widget files included. <!-- Updated: Red Team Session 1 -->
- [ ] `flutter analyze` + `flutter test` clean; no regression to the recently-verified manager order-status-update flow.

## Risk Assessment

- **This cluster touches the most recently-verified live flow in the whole app** (manager order status update, `stability-hardening` phase 4, verified same-day as this audit) → extra care not to regress it; the QA net explicitly calls this out above, don't treat it as just another checklist item.
- **`M34` code-duplication refactor temptation** → `ProductFormBody` extraction is a follow-up plan, full stop (see Follow-ups above); this plan's scope is visual migration, not architecture cleanup — a parallel diff applied twice is the accepted, lower-risk substitute. <!-- Updated: Red Team Session 1 -->
