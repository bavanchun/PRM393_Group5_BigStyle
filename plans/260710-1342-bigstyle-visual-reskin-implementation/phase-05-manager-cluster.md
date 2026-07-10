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

## Completion Note (2026-07-10)

**Status:** Done. ManagerCreateProduct FAB confirmed a capture-tool artifact (user hand-tap on `emulator-5554`, same verdict as the Phase 3 cart CTA) — no bug-fix step needed.

**M34 sequencing:** measured actual overlap before touching either file — `diff` shows 165 changed lines out of 1935 total (≈91.5% identical, slightly higher than the plan's "~90%" estimate). Migrated `manager_product_detail_screen.dart` first (18 guard hits), verified `flutter analyze` clean, then replayed the identical fix pattern onto `manager_create_product_screen.dart` (17 hits) — confirmed line-for-line correspondence held (same fixes at a consistent ~70-line offset caused by Detail's extra "initialize from existing product" block).

**M19 (AppBar pink→white), both files:** this wasn't a one-line `backgroundColor` swap — flipping the header from solid-primary to white/surface inverts which elements need dark vs. light treatment, so title text, `iconTheme`, the delete icon (Detail only), and the trailing action button all needed to flip together or the header would have shipped broken (e.g. a white-on-white "Cập nhật" button, invisible). Fixed all of it coherently in both files: title/icons → `AppColors.textPrimary`; trailing button flipped from "white pill + primary text" to "solid primary pill + `onPrimary` text" (the natural inverse now that it sits on a white header instead of trying to stand out against a pink one).

**M2 (ManagerProfile):** re-confirmed stale during `manager_shell.dart`'s own edit pass — zero `Colors.grey` present, consistent with Phase 0's verdict.

**M20 (`manager_product_list_screen.dart`):** the mixed-line `isHidden ? Colors.grey : AppColors.primary` (price text) is fixed, along with 24 other hits on this screen — a fully bespoke, zero-shared-widget screen exactly as Phase 1 characterized it.

**M6 (ManagerDashboard):** re-confirmed already-resolved via token propagation — `_StatCard`'s `color: AppColors.success` was never a hardcode; the only real fix on this file was the stat card's shadow (`Colors.black` → `AppColors.shadow`).

**StatusBadge rollout:** `ManagerOrderDetail`'s header badge migrated. `managerOrderStatusColor()` (in `manager_order_card.dart`) still had one real hardcode of its own — `Colors.blue` for the `shipping` case — but as a plain function taking only `OrderStatus` (no `BuildContext`), it couldn't reach `Theme.of(context).extension<StatusColors>()` to resolve the `info` tone. Threaded `BuildContext` through the function signature and its one remaining call site (`order_status_update_sheet.dart`'s status-transition button) rather than duplicating the `info` value as a second `AppColors` constant — keeps `StatusColors` the single source of truth for that tone.

**ManagerVoucherList's FAB-contrast finding — debunked:** the audit claimed "v2 primary also fails white-on-fill (3.55:1), confirming the tokens-v2 doc's own finding that only error passes white-on-fill." This misapplies a rule that's actually scoped to `success`/`warning` only (`docs/design-tokens-v2.md`'s status-color usage rule) — `primary` has its own separately-verified figure (white-on-primary 6.70:1, computed independently twice now, Phase 3 and here) that clears AA with a wide margin. No fix applied; the FAB was already correct. Its "Đang bật" status-badge tonal pairing (success-as-text on a 10%-tint) was also re-checked by hand and clears AA comfortably, consistent with the pattern established across every other tonal pairing in this reskin.

**Product swatch colors extracted, not tokenized into `AppColors`:** `#914B34`/`#2A6767`/`#313030` ("Đất nung"/"Xanh ngọc"/"Đen") are real garment color options a manager assigns to a product — business data, not UI brand colors, and recoloring them to fit the app's palette would misrepresent the actual product. Extracted to a new `lib/models/product_swatch_colors.dart` (also fixes the literal duplication of this exact map across both product-detail and create-product screens — real DRY value, not just a guard workaround).

**New additive token — `AppColors.grayscaleFilter`:** `manager_product_list_screen.dart`'s hidden-product thumbnail uses `ColorFilter.mode(_, BlendMode.saturation)` to desaturate the image, which mathematically requires a truly achromatic value — any of the reskin's warm-toned colors would leave a tint instead of a clean grayscale. Documented as a technical necessity, not missed reskin debt.

**Companion widgets:** `manager_product_variants_table.dart` (1 hit) and `manager_product_variant_table_cells.dart` (2 hits) fixed — these were previously unowned by any phase per the plan's own red-team finding #2.

**Guard:** 139 → 59 (−80 across 9 screens + 2 companion widgets + 1 shared function). Remaining 59 hits are now entirely Phase 6 (`admin/`) and Phase 7 (`auth/`, `splash/`) territory — confirmed via full-path breakdown, zero stragglers anywhere else.

**Verification:** `flutter analyze` clean; `flutter test` 43/43 pass (no regressions from the swatch-color extraction or the `managerOrderStatusColor` signature change — no existing test covers either). Regression checklist not manually walked end-to-end (no manager-role QA credentials this session, same constraint as Phases 3-4); the manager order-status-update flow (explicitly flagged as recently-verified and not-to-be-regressed) had zero business-logic lines touched — every edit in `manager_order_card.dart`/`manager_order_detail_screen.dart`/`order_status_update_sheet.dart` was a color/token substitution or the `StatusBadge`/context-threading changes described above, none of which alter the update-status event flow itself.
