---
phase: 6
title: "Manager Admin UX Polish"
status: done
effort: "medium"
---

# Phase 6: Manager Admin UX Polish

## Overview

Bring Manager + Admin surfaces to the polish bar the customer flow reached in
PR #33. Audit-driven, not vibes: sweep every screen for state coverage and
token consistency first, then fix in one batch.

## Requirements

- Functional: every Manager/Admin screen has explicit empty, error, and loading states; failed network ops show retry affordance.
- Non-functional: visual consistency with `docs/design-tokens-v2.md`; hardcode-color guard stays 0; motion reuses existing primitives from flagship work (no new animation framework).

## Related Code Files

- Audit scope: `FE/lib/screens/manager/**` (incl. categories/products/vouchers/support subdirs), `FE/lib/screens/admin/**` (shell, dashboard, users, categories)
- Likely modify: those screens + shared widgets in `FE/lib/widgets/` (empty-state/error-state components — check for existing ones from customer flow before creating new)
- Reference: motion/haptic/feedback primitives added by flagship plan `260711-1905-flagship-ux-depth-customer-flow`

## Implementation Steps

1. Audit sweep: per screen, record state coverage (loading/empty/error/offline), token violations, motion gaps → checklist appended to this file (no separate report).
2. Reuse-first: identify customer-flow empty/error/skeleton components; extract to shared widgets only if not already shared.
3. Fix batch A — Manager screens (dashboard, orders, products, categories, vouchers, support).
4. Fix batch B — Admin screens (dashboard, users, categories).
5. Offline handling: consistent snackbar/retry on network failure (match customer flow behavior).
6. Motion parity where cheap: entrance/stagger on lists using existing primitives; skip anything requiring new dependencies.
7. Gate: `flutter analyze` 0, `flutter test` xanh, hardcode-color guard 0; manual walkthrough of every audited screen.

## Success Criteria

- [x] Audit checklist complete (all Manager/Admin screens enumerated) <!-- 2 parallel audit agents covered all 19 manager files (shell/dashboard/orders/products cluster/categories/vouchers/support) + 4 admin files — see Audit Checklist appendix below -->
- [x] 0 screens missing empty/error/loading states <!-- every gap found got a loading/empty/error+retry branch; confirmed via code-reviewer trace of actual state-machine paths (not just structural presence) -->
- [x] 0 hardcoded colors introduced; tokens-v2 respected <!-- check_hardcoded_colors.sh exit 0 (was already 0 pre-phase — grep confirmed zero raw hex in manager scope, all drift was typography/shape not color); ~90 raw TextStyle literals across manager+admin converted to AppTypography; 4 modal sheets' hardcoded Radius.circular(16) corrected to AppSpacing.bottomSheetRadius (28, per design-tokens-v2) -->
- [x] Offline/retry behavior consistent with customer flow <!-- code-reviewer found 2 real inconsistencies post-fix-pass (admin dashboard leaking cross-tab errors; manager products destroying a loaded list on background-refresh failure) — both fixed, see Code Review section below -->
- [x] Analyze/test/color gates pass <!-- flutter analyze 0, flutter test 140/140 (no new tests this phase — UI/state-handling polish on existing screens, not new business logic), check_hardcoded_colors.sh exit 0 -->

Note: plan's own gate step 7 ("manual walkthrough of every audited screen") is a live-device observation step, not performed this session — deferred to `plans/260712-1644-bigstyle-product-completeness` Phase 1, matching this roadmap's established pattern. Everything else in this phase is code-complete and reviewed via static analysis + concrete state-machine tracing (code-reviewer read the actual bloc/state definitions, not just the widget code, for every judgment call below).

### Code review (code-reviewer subagent)
4 judgment calls from the 3 parallel fix agents were independently re-verified against actual bloc/state source (not taken at face value) — 3 sound, 1 partially wrong (see Finding 2). 3 new findings, all fixed:
1. **High (fixed)** — `admin_dashboard_screen.dart`'s error-toast listener had no gate on which tab's error it was reacting to. `AdminBloc` is one app-wide instance and `AdminShell` keeps all 4 admin tabs mounted simultaneously (`IndexedStack`), sharing one `error` field — a Users/Categories action failing could pop a wrongly-attributed SnackBar onto whatever tab happened to be visible. Fixed by gating `listenWhen` on `current.dashboardStats.isNotEmpty` (own-concern-loaded check) — note `dashboardStats` is a non-nullable `Map` defaulting to `{}`, not nullable like the sibling `manager_dashboard.dart` pattern assumed, so the gate condition had to be adapted, not copied verbatim.
2. **High (fixed)** — `manager_product_list_screen.dart` had no persisted local cache (unlike every sibling list screen touched this phase), so a background-refresh failure — e.g. the auto-reload `ManagerProductBloc` dispatches after every successful create/update/delete — replaced an already-successfully-shown product list with a full-screen error card, right after the user's own edit succeeded. Fixed by adding a `_lastLoadedProducts` cache mirroring `manager_category_list_screen.dart`'s `_categories` pattern: the full `AppErrorState` now only shows when nothing has ever loaded; a background failure with an existing list shows a toast and keeps the list on screen.
3. **Medium (fixed)** — `manager_order_detail_screen.dart`'s `_loadPayment()` had no reentrancy guard; a rapid double-tap on the new retry button could start two overlapping fetches that resolve out of order, leaving the error card showing even after a later call already succeeded (self-healing on next tap, narrow blast radius — local `setState` on a read-only info panel, not shared bloc state). Fixed with a `_paymentLoadInFlight` guard.
4. **Low (fixed)** — `manager_create_product_screen.dart` / `manager_product_detail_screen.dart` showed both a SnackBar and the new inline retry banner simultaneously on a category-load failure — redundant, inconsistent with the de-dup discipline applied everywhere else in this same phase. Removed the SnackBar, kept the banner.

Sound judgment calls (verified, not just trusted): categories/vouchers screens' non-null-cache gating (traced actual sum-type state shape — correct); admin_users_screen's unconditional success-toast (traced `AdminState.copyWith` — a value-equality gate would have wrongly suppressed two different back-to-back successes sharing the same message text); manager_product_list_screen's original SnackBar-removal *reasoning* (that `ManagerProductError` never carries a list — true) but the *conclusion* (no regression) was wrong, see Finding 2.

### Audit Checklist (condensed — full per-file detail was in the 2 audit agents' reports, not preserved verbatim here per the plan's "no separate report" instruction)

**Manager** (19 files): shell (typography only), dashboard (error+retry added, empty-state icon added), orders (AppErrorState + de-duped listener + empty icon), order-detail payment section (error+retry+reentrancy-guard added), order-status-update-sheet + refund-decision-sheet (sheet radius token only, otherwise already OK), categories list+edit (AppErrorState + de-duped listener; edit sheet already OK bar radius/typo), vouchers list+edit (same as categories), support inbox (error was silently dropped by the bloc-state-not-read bug — now wired to AppErrorState + retry + empty icon), products list (AppErrorState + persisted-cache fix per Finding 2), product detail + create (category-load retry banner added, duplicate SnackBar removed per Finding 4), variants table + table cells (typography only, presentational/no state to cover).

**Admin** (4 files + bloc): shell (typography only), dashboard (error-toast added with own-concern gate per Finding 1, typography), users (AppErrorState + retry + de-duped listener, typography), categories (same as users), `admin_bloc.dart` (corrupted CJK-character string fixed).

## Risk Assessment

- Scope creep into redesign → polish only; layout changes need separate plan.
- Shared-widget extraction could regress customer screens → run full test suite + visual spot-check of customer flow after extraction.
