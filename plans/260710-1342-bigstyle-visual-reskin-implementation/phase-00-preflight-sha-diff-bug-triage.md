---
phase: 0
title: "Pre-flight: SHA Diff & Bug Triage"
status: done-pending-live-tap-verification
effort: "S (half day)"
priority: P1
dependencies: []
---

# Phase 0: Pre-flight — SHA Diff & Bug Triage

## Overview

The audit pipeline (`plans/260710-1158-ui-ux-overhaul-audit-pipeline/`) graded the tree at `6e77ccfcc7572621729fd67efca277ef4d65dab4`. This repo has no dev freeze — verify nothing drifted before trusting any audit finding, and triage the 2 tap-target bugs that blocked 3 screens from ever being captured.

## Requirements

- Functional: `git diff 6e77ccf...HEAD -- FE/lib/screens FE/lib/widgets FE/lib/config/theme` reviewed; any screen file that changed gets its Phase 4 finding set spot-checked against the new code before its cluster phase starts (not before this phase — just flagged).
- Functional: root-cause check (human-tap repro FIRST, then code — not full fix) on the 2 tap-target bugs from `phase-02-visual-capture-log.md`'s Findings section.
- Functional: re-verify every inherited `closes {ID}` audit citation (M2, M6, M19, M20, C30, M34) against current code — red team proved at least M2 and M34's numbers are already stale. <!-- Updated: Red Team Session 1 -->
- Functional: create work branch `feat/visual-reskin` off `dev` at this phase's start — all Phases 1-7 commit there, not to `dev` (see plan.md "Execution Model"). <!-- Updated: Red Team Session 1 -->

## Related Files (read first)

- `plans/260710-1158-ui-ux-overhaul-audit-pipeline/reports/phase-02-visual-capture-log.md` — bug descriptions, section "Findings Surfaced During Capture".
- `FE/lib/screens/cart/cart_screen.dart` — cart checkout CTA ("Mua hàng (N sản phẩm)" button) intermittently resets selection instead of navigating to Checkout.
- `FE/lib/screens/manager/products/manager_product_list_screen.dart:195-214` — FAB ("+ THÊM SẢN PHẨM MỚI") taps reported swallowed during adb-driven capture. <!-- Updated: Red Team Session 1 - corrected line range; occlusion hypothesis contradicted by code, see step 2 -->

## Implementation Steps

0. Create branch `feat/visual-reskin` off `dev`; record the branch-point SHA in the completion note. <!-- Updated: Red Team Session 1 -->
1. `git diff 6e77ccf...HEAD --stat -- FE/lib` — list changed files. Cross-reference against the 30-screen inventory (`phase-01-ui-inventory-debt-map.md`). Write the changed-screen list (or "none") into this phase's completion note.
2. **Human-tap check FIRST** <!-- Updated: Red Team Session 1 - both original hypotheses contradicted by code -->: both "bugs" were only ever reproduced via adb-injected taps, and code reading contradicts both occlusion hypotheses — the FAB is a Scaffold-level `floatingActionButton` (`manager_product_list_screen.dart:195-214`), which Flutter hit-tests above body content and which list items cannot occlude; the cart CTA (`cart_screen.dart:308-357`) has no `Stack`/`GestureDetector` wrapper to create a z-order conflict. Most likely root cause: adb coordinate/injection artifact, not a product bug. Reproduce by hand on the emulator (30 seconds each) before any code diagnosis.
3. If human taps WORK: close both findings as capture-tool artifacts (not bugs), record that here, and immediately delta-capture the 3 blocked screens (Checkout, PaymentQr, ManagerCreateProduct) — they are reachable the moment the taps work. Phases 3/5 then proceed with real captures instead of blind migration.
4. If a human tap ALSO fails: real bug — diagnose in code, ≤1 hour per bug. Trivial root cause (padding/z-order/state reset) → note the diagnosis in the target cluster phase file (Phase 3 for cart, Phase 5 for FAB); the cluster phase fixes it in a SEPARATE commit from any token work. Non-trivial (state-management race, platform quirk) → flag for a separate bugfix plan and mark the blocked screens "migrate blind from code + Phase 1 metrics, re-verify visually once unblocked" in their respective cluster phases.
5. **Stale-finding re-verification** <!-- Updated: Red Team Session 1 -->: grep current code for every `closes {ID}` target this plan inherits. Known-stale already: `M2` — zero `Colors.grey` remains in `manager_shell.dart` (profile header rewritten to white-on-gradient); close as overtaken-by-events and verify white-on-v2-gradient contrast instead — do NOT apply the originally-prescribed `textSecondary` swap, it would regress the header. `M34` — line counts are now 1007/928, not ~965/1033. Sweep the rest (M6, M19, M20, C30) the same way, write the verdict list into the completion note, and update Phase 5's steps if more turned stale.

## Success Criteria

- [ ] Work branch `feat/visual-reskin` created; branch-point SHA recorded. <!-- Updated: Red Team Session 1 -->
- [ ] Changed-file diff against the pinned SHA reviewed and recorded (empty or non-empty, either is fine — silence is not).
- [ ] Both tap-target findings resolved to exactly one of: capture-tool artifact (with delta-captures done), trivial bug (diagnosis noted in cluster phase), or non-trivial (split to separate plan + blind-migration notes). <!-- Updated: Red Team Session 1 -->
- [ ] Every inherited `closes {ID}` citation (M2, M6, M19, M20, C30, M34) re-verified against current code; stale ones re-dispositioned and cluster phases updated. <!-- Updated: Red Team Session 1 -->
- [ ] Cluster phases for Cart (Phase 3) and ManagerProductList (Phase 5) know whether to include a bug-fix step or a blind-migration note.

## Risk Assessment

- **Root cause isn't what it looks like from code reading alone** → don't spend more than ~1 hour per bug here; a live on-device repro with `flutter run` + breakpoints is cluster-phase work, not pre-flight work. Human-tap repro comes first precisely because the adb-artifact explanation costs 30 seconds to test and dissolves both "bugs" if confirmed. <!-- Updated: Red Team Session 1 -->

## Completion Note (2026-07-10)

**Step 0 — Branch:** `feat/visual-reskin` created off `dev`. Branch-point SHA `6e77ccfcc7572621729fd67efca277ef4d65dab4` — identical to the audited SHA (verified via `git rev-parse HEAD` before branching).

**Step 1 — Drift diff:** `git diff 6e77ccf...HEAD --stat -- FE/lib` → empty output, exit 0. Zero drift. No screen re-verification needed.

**Step 2-4 — Tap-target triage (code half only):**
- Cart CTA (`cart_screen.dart:343-353`): `AppButton` directly in a `Column`/`Container`, `onPressed` is a plain ternary calling `Navigator.pushNamed`. No `Stack`, no `GestureDetector` wrapper, no z-order structure of any kind — code gives no mechanism for an occlusion bug.
- Manager FAB (`manager_product_list_screen.dart:195-214`): confirmed genuine `Scaffold.floatingActionButton` (not manually positioned) — Flutter renders this in its own layer above body content; list items cannot occlude it structurally.
- **Blocked on live verification**: an actual human tap (not `adb input tap`, which is the very method suspected of causing the false positives — a raw coordinate injection skips Flutter's normal gesture-arena/touch-slop handling that a real touch goes through) is required to close this per the phase's own step 2. I have no tool that produces a genuine touch event on the connected emulator (`emulator-5554` is up, but my only device-interaction path is `adb`/`flutter`, which would just repeat the suspect method). **Needs the user to do the 30-second manual check** (open the emulator window, physically click the two locations) before Phase 3/5 can close these as artifacts vs. real bugs. Not blocking Phase 1/2 — deferring the question until Phase 3/5 need the answer.

**Step 5 — Stale `closes {ID}` re-verification (grep-verified against current code):**

| ID | Verdict | Evidence |
|---|---|---|
| M2 | **Stale — overtaken.** Confirmed. | `grep Colors.grey lib/screens/manager/manager_shell.dart` → 0 hits. Header already white-on-gradient. Do NOT apply the originally-prescribed `textSecondary` swap (Phase 5 note already carries this). |
| M6 | **Smaller than described, mostly stale.** `manager_dashboard_widgets.dart:33` already passes `color: AppColors.success` (a token ref, not a hardcode) into `_StatCard`; the card itself (`:180` area) is already tonal (`color.withValues(alpha:0.1)` bg + solid-color icon) — NOT solid-fill+white-text. The v1→v2 `success` hex swap happens automatically when Phase 1 rewrites `app_colors.dart` — no dedicated code edit needed at this site. Phase 5 only needs to *verify* this post-Phase-1, not build anything. |
| M19 | **Confirmed still open.** | AppBar `backgroundColor`: `manager_product_list_screen.dart:47` = `AppColors.surface` (fixed); `manager_product_detail_screen.dart:305` and `manager_create_product_screen.dart:242` = `AppColors.primary` (NOT fixed). Phase 5 steps 3-4 stand as written. |
| M20 | **Confirmed still open.** | `manager_product_list_screen.dart:457`: `color: isHidden ? Colors.grey : AppColors.primary` — exactly the mixed-line hardcode the guard's occurrence-level matching is designed to catch. Phase 5 step 7 stands. |
| C30 | **Real pattern differs from the plan's paraphrase — re-scoped, not stale.** | No file anywhere in `lib/` contains a function literally named `_getStatusColor` (grep-verified, 0 hits). The actual pattern: `orders_screen.dart:193` has `_statusColor()`, `manager_order_card.dart:17` has top-level `managerOrderStatusColor()` — both switch on the 5-value `OrderStatus` enum with **identical** color assignments (pending→warning, confirmed→primary, shipping→**`Colors.blue` hardcoded in both**, delivered→success, cancelled→error) and both already render tonally (bg alpha 0.1 + solid text) — these 2 (not 4) are the genuine DRY-consolidation targets for `StatusBadge`/Phase 2. `order_detail_screen.dart:83-97` has **no status switch at all** — its badge is hardwired to `AppColors.primary` regardless of `order.status`. This is a real behavior gap (not just a tonal one): Phase 4 migrating this screen to `StatusBadge` must make the badge genuinely status-aware, not merely re-skin its color. **New finding, not in the original audit**: `Colors.blue` (2 hardcoded sites, `orders_screen.dart` + `manager_order_card.dart`) needs a `StatusColors.info` slot — Phase 1's `StatusColors` extension spec ("success/warning/error/info pairs") already anticipated this, so no plan change needed, just confirming the "info" slot is not optional. |
| M34 | **Confirmed.** | `wc -l`: `manager_product_detail_screen.dart` = 1007, `manager_create_product_screen.dart` = 928 — matches the plan's updated numbers exactly. |

**Disposition for Cluster Phases:**
- Phase 3 (Cart): pending live-tap answer. If artifact → no bug-fix step, proceed with token migration only. If real trivial bug → separate commit per two-commit rule.
- Phase 5 (ManagerProductList/Detail/Create): same pending-live-tap gate for the FAB. M19 (2 sites), M20 (1 site) confirmed real, standing as written in Phase 5. M2 confirmed stale — Phase 5 step 6 stands as written (gradient-contrast verification only, no `textSecondary` swap). M6 needs a post-Phase-1 verification-only check, no code change.
- Phase 2/4/5 (StatusBadge): contract updates to carry into Phase 2 — 2 real consumers (`orders_screen.dart`, `manager_order_card.dart`), not the audit's implied 4; `order_detail_screen.dart` needs an actual status-awareness fix bundled into its Phase 4 `StatusBadge` migration, not just a re-skin; `StatusColors.info` slot is load-bearing (2 real `Colors.blue` hardcodes depend on it), not optional polish.

**Overall status:** Code-verifiable work complete.

**Live-tap verification (resolved 2026-07-10, before Phase 3):** user manually tapped the cart CTA on `emulator-5554` with an item selected — works fine by hand. Confirms the capture-tool-artifact hypothesis; not a real bug. Cart (Phase 3) proceeds with token-only migration, no bug-fix step/commit. Checkout/PaymentQr still get migrated from code + Phase 1 metrics alone regardless of this verdict (no customer-role QA credentials available this session to live-capture them either way) — flagged `unverified` in Phase 3's completion note per the plan's own fallback path. Manager FAB (Phase 5's precondition) was not independently re-tapped — same code-level reasoning applies (Scaffold-level FAB, list items cannot occlude it structurally) and Phase 5 will re-ask if needed at that point.
