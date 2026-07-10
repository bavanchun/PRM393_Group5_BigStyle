# Red-Team Plan Review — BigStyle Visual Reskin Implementation

**Reviewer role:** Assumption Destroyer / Scope Auditor
**Plan:** `plans/260710-1342-bigstyle-visual-reskin-implementation/` (8 files, Phases 0-7)
**Verified against:** HEAD == pinned SHA `6e77ccf` (no drift; all citations are current-tree facts)
**Date:** 2026-07-10

---

## Finding 1: The hardcode-guard gate can NEVER pass repo-wide as specified — 13 widget hardcode lines have no owner

- **Severity:** Critical
- **Location:** Phase 1 "Overview" + step 6; Phase 2 "Requirements" (non-functional); Phase 7 "Success Criteria" (repo-wide guard pass)
- **Flaw:** Three phases contradict each other. Phase 1 claims 8 of 10 shared widgets are "fully token-driven." Phase 2 mandates "no other shared widget touched (the other 8 are token-swap-only per Phase 4)." Phase 7 requires "hardcode-guard passes repo-wide... zero violations across all of `FE/lib/screens` + `FE/lib/widgets`." But 4 of the 8 "fully token-driven" widgets contain `Colors.*` literals that the plan's own guard regex flags, and no phase (1-7) is authorized to edit them.
- **Failure scenario:** Implementer reaches Phase 7 closeout, runs the guard, gets 13 violations in widget files that Phase 2 explicitly forbade touching. Either the final gate is waived (plan "completes" with a red gate), or the implementer scope-creeps into forbidden files with no design guidance (what token replaces `Colors.black.withValues(alpha: 0.06)` shadows? None exists).
- **Evidence:** Guard regex run against `FE/lib/widgets`:
  - `app_bottom_nav.dart:29,40,41,47` (`Colors.black` shadow, `Colors.transparent` ×3)
  - `manager_bottom_nav.dart:22,33,34,40` (same pattern)
  - `app_card.dart:38,43` (`Colors.black` shadows)
  - `app_button.dart:34` (`Colors.white` — a genuine token bypass in a "token-driven" widget), `:95` (`Colors.transparent`)
  - `product_card.dart:67` (`Colors.white`) — not covered by Phase 2's radii-only scope for this file
- **Suggested fix:** Either (a) add an explicit allowlist to the guard (`Colors.transparent`, shadow `Colors.black.withValues` — document the rationale), or (b) add a widget-cleanup step to Phase 2 with token guidance for shadows/transparent, and correct the "8 fully token-driven" claim to "8 need no *palette* changes" — which is a different, weaker claim.

## Finding 2: Guard regex has a permanent blind spot — mixed hardcode+AppColors lines are invisible, and the per-file checklists inherit the same blindness

- **Severity:** High
- **Location:** Phase 1 "New: Hardcode Guard" (the `grep -v 'AppColors'` filter); Phase 3 step 2, Phase 4 step 1, Phase 5 step 7, Phase 6 step 1 (counts-as-checklist instruction)
- **Flaw:** `AppColors.primary` itself matches `Colors\.[A-Za-z]+` (substring), so the script pipes through `grep -v 'AppColors'` — which also discards any line containing BOTH a real hardcode and an AppColors ref (ternaries). 6 such lines exist today. Because every per-file count the plan cites was derived with the same filter, the "use the count as your checklist" instruction guarantees 5 screens each finish one hardcode short while the guard shows green.
- **Failure scenario:** Phase 5 success criterion says "Manager cluster's hardcode count (baseline ~78) drops to 0 per the hardcode-guard script" and "M20 closed." Implementer clears 28 flagged lines in ManagerProductList, guard reports 0 — but `manager_product_list_screen.dart:457` still reads `color: isHidden ? Colors.grey : AppColors.primary,` — a `Colors.grey` hardcode that is literally part of M20's subject matter ("Colors.green/grey/black/white hardcode lẫn token", `docs/ux-flow-audit.md:225`). M20 gets marked closed with its hardcode still in the tree.
- **Evidence:** The 6 guard-invisible lines (all confirmed to contain a live hardcode after stripping `AppColors.*` refs):
  - `FE/lib/screens/chat/chat_screen.dart:228` — `Colors.white`
  - `FE/lib/screens/admin/admin_users_screen.dart:138` — `Colors.white`
  - `FE/lib/screens/manager/products/manager_product_list_screen.dart:457` — `Colors.grey`
  - `FE/lib/screens/product_list/product_list_screen.dart:216` — `Colors.transparent`
  - `FE/lib/screens/product_detail/product_detail_screen.dart:538` — `Colors.white`
  - `FE/lib/widgets/size_selector.dart:47` — `Colors.white` (this one is incidentally fixed by Phase 2's tonal rework)
- **Suggested fix:** Change the filter from line-exclusion to token-stripping: `sed 's/AppColors\.[A-Za-z0-9_]*//g'` before the regex match (or use `grep -P '(?<!App)Colors\.'`). Add the 5 screen-side mixed lines explicitly to their cluster checklists (Chat is really 8 not 7, AdminUsers 6 not 5, ManagerProductList 29 not 28, ProductList 9 not 8, ProductDetail 8 not 7).

## Finding 3: Guard script silently false-passes when run from the wrong directory — and its stated baseline (195) is wrong for its own scope

- **Severity:** High
- **Location:** Phase 1 "New: Hardcode Guard" (script body + placement) and step 4 ("195 hardcode-hit lines per Phase 1 audit recount")
- **Flaw:** Two independent defects. (1) The script is to live at `FE/scripts/check_hardcoded_colors.sh` (an existing convention: `FE/scripts/setup.sh`, `FE/scripts/sepay-simulate-payment.sh`) but greps repo-root-relative paths `FE/lib/screens FE/lib/widgets`. Run from `FE/` — the natural CWD for every other Flutter command in this plan — grep errors go to stderr, `$hits` captures empty stdout, and the script **exits 0: a green gate that scanned nothing**. (2) The claimed baseline is wrong for the script's scope: 195 is the screens-only count; the script scans screens+widgets, which yields **208** (and 214 counting the 6 blind-spot lines from Finding 2).
- **Failure scenario:** Guard is wired as the pre-PR check, run from `FE/` alongside `flutter analyze`. It passes on day one against a tree that demonstrably has 208 violations. Every subsequent "hardcode-guard passes for this cluster's files" success criterion (Phases 3-7) is vacuously satisfiable.
- **Evidence:** Script body at phase-01 file lines 60-70 (`hits=$(grep -rn ... FE/lib/screens FE/lib/widgets ...)`; empty `hits` → `exit 0`, no existence check on the dirs). Recount: `FE/lib/screens` = 195 lines, `FE/lib/screens + FE/lib/widgets` = 208 lines, both with the plan's exact regex+filter. Existing scripts confirmed at `FE/scripts/`.
- **Suggested fix:** Anchor paths to the script location (`cd "$(dirname "$0")/.."; grep ... lib/screens lib/widgets`) and fail hard if the target dirs don't exist. Correct the baseline to 208 (guard scope) and note 195 = screens-only.

## Finding 4: M2 is a phantom target — `Colors.grey` no longer exists in `manager_shell.dart`, and "closing" it as written would create a contrast bug

- **Severity:** High
- **Location:** Phase 5, screen table row "ManagerProfile (inline)" + step 6 + success criterion "`M2` ... closed"
- **Flaw:** Phase 5 step 6 instructs: "ManagerProfile (inline class): `Colors.grey` → `AppColors.textSecondary` (closes M2)." There is no `Colors.grey` anywhere in `manager_shell.dart` — the profile header was rewritten (terracotta gradient + white text) since M2 was filed against `manager_shell.dart:79`. The plan inherited "M2 still open" from the feeder inventory (`phase-01-ui-inventory-debt-map.md` rows 41, 67) without verifying, even though Phase 0's entire purpose is stale-finding detection — and Phase 0's diff can't catch this because the staleness predates the pinned SHA (the audit doc itself was wrong at audit time).
- **Failure scenario:** Implementer greps for `Colors.grey`, finds nothing, and either burns time hunting, or "closes M2" by converting the email text `Colors.white.withValues(alpha: 0.8)` (`manager_shell.dart:113`) to `AppColors.textSecondary` — dark warm-grey text (`#746159` in v2) on the terracotta gradient header: a brand-new WCAG failure introduced by following the plan literally.
- **Evidence:** `grep -n 'Colors.grey' FE/lib/screens/manager/manager_shell.dart` → zero hits. Full `Colors.*` inventory of the file: only `Colors.white` variants at :81,91,104,113,124,129,141 (all on the gradient header). Original finding: `docs/ux-flow-audit.md:189` ("M2 ... `Colors.grey` cho email ... manager_shell.dart:79").
- **Suggested fix:** Re-state Phase 5 step 6 as: "M2's original hardcode is already gone; verify the profile header's white-on-gradient text meets AA against the *v2* gradient (`#9A3F35`→`#742E28`) and close M2 as overtaken-by-events." Do not prescribe a textSecondary substitution.

## Finding 5: No replacement token exists for `Colors.white` — 94 of the 195 screen hardcode lines (~48%) have nowhere to go

- **Severity:** High
- **Location:** Phase 1 "Token Table" (frozen, no on-primary token); Phases 3-7 "hardcode → token" steps; Phase 5/7 "drops to 0" success criteria
- **Flaw:** The single largest hardcode class is `Colors.white` used as text/icon color on primary-filled surfaces (AppBars, FABs, gradient headers, buttons) — 94 lines in `FE/lib/screens` alone. Neither v1 `app_colors.dart` nor the frozen v2 table defines an `onPrimary`/`textOnPrimary` token; the only white token is `surface`, which is semantically a background role. The plan repeatedly orders "replace `Colors.*` with `AppColors.*` tokens" and "count drops to 0" without ever saying what `Colors.white` maps to. Phase 2's risk note authorizes additive *spacing* constants; nothing authorizes additive *color* constants.
- **Failure scenario:** Five different cluster passes make five different ad-hoc choices: some use `AppColors.surface` as a text color, some invent a new constant, some leave `Colors.white` and eat the guard failure. The reskin's core deliverable — one consistent token system — fragments during its own rollout.
- **Evidence:** `grep -rn 'Colors\.white' FE/lib/screens | grep -v AppColors | wc -l` → 94. `FE/lib/config/theme/app_colors.dart:6-20` — 14 constants, no on-primary role. `docs/design-tokens-v2.md:16` documents "white-on-primary 6.70:1 (button text)" as an approved *usage* but the table defines no *token* for it.
- **Suggested fix:** Add one plan-level decision to Phase 1: introduce `AppColors.onPrimary = Color(0xFFFFFFFF)` (an alias, not a palette change — does not violate the frozen table) and state the mapping rule "white-on-colored-fill → `onPrimary`" once, before any cluster starts.

## Finding 6: `product_card.dart` has 4 raw radii, not 3 — Phase 2's checklist and its success criterion contradict each other

- **Severity:** Medium
- **Location:** Phase 2 "Related Files" (`product_card.dart:38,62,87 — 3 raw BorderRadius.circular(N) literals`) + success criterion "zero raw `BorderRadius.circular(literal)`"
- **Flaw:** There are 4 literal radii: lines 38 (16), 62 (4), 87 (3), and **122 (3)** — the plan missed line 122. An implementer working the enumerated list fixes 3 and believes the file done; the success criterion says zero literals. One of them loses.
- **Failure scenario:** The 4th radius survives Phase 2; nothing re-checks it (radii aren't caught by the color-guard regex), and the "zero raw radii" box gets ticked off the 3-site list.
- **Evidence:** `grep -n 'BorderRadius.circular' FE/lib/widgets/product_card.dart` → `38:`, `62:`, `87:`, `122:`. (Also note `product_card.dart:67` `Colors.white` — unowned by Phase 2's radii-only scope; see Finding 1.)
- **Suggested fix:** Correct the enumeration to 4 sites (:38,62,87,122) and make the criterion's verification a grep, not the list.

## Finding 7: M34's "~90% shared / ~965/1033 lines" is stale and contradicts the plan's own feeder inventory

- **Severity:** Medium
- **Location:** Phase 5, screen table row "ManagerProductDetail" + step 2 ("share ~90% of their code (~965/1033 lines, old-audit finding)")
- **Flaw:** The plan quotes the old `ux-flow-audit.md` numbers as present-tense fact. Actual current line counts: `manager_product_detail_screen.dart` = **1007**, `manager_create_product_screen.dart` = **928**. Neither file is 965 or 1033 lines. The plan's own Phase-1 feeder already had the correct numbers (inventory rows 2-3: 1007 / 928) — the plan cherry-picked the older, wrong source. The files have visibly diverged since M34 was filed, so the "apply the same diff pattern to the second file" strategy in step 2 will hit mismatches the plan promises won't exist.
- **Failure scenario:** Implementer migrates ManagerProductDetail, then mechanically replays the diff onto ManagerCreateProduct expecting ~90% overlap; the ~79-line structural divergence (plus whatever drifted inside shared sections) produces misapplied hunks in the two highest-debt files in the app — with no visual capture available for ManagerCreateProduct to catch it (per Phase 0/5 pre-conditions).
- **Evidence:** `wc -l` → 1007 / 928. Stale source: `docs/ux-flow-audit.md:241`. Correct feeder: `plans/260710-1158-ui-ux-overhaul-audit-pipeline/reports/phase-01-ui-inventory-debt-map.md` rows 2-3.
- **Suggested fix:** Replace the stale numbers with 1007/928, and re-verify actual overlap (diff the two files) before committing to the replay-the-diff strategy in step 2.

## Finding 8: Font-swap risk mitigation is factually wrong — `flutter pub get` does not download fonts, and an offline demo silently loses the entire typography reskin

- **Severity:** Medium
- **Location:** plan.md "Risk Assessment" ("Font swap cost ... one-time asset cache, not recurring; no mitigation needed beyond normal `flutter pub get` / asset warm-up")
- **Flaw:** `google_fonts` (^6.2.1, `FE/pubspec.yaml:17`) fetches font binaries **at runtime over HTTP** on first render and caches per-device. `flutter pub get` downloads the Dart package only. On a fresh install or wiped emulator with no network, every `GoogleFonts.cormorant()`/`.montserrat()` call silently falls back to the platform default — the typography half of the reskin vanishes exactly in the scenario a course-project demo is most exposed to (campus Wi-Fi, fresh AVD, grader's device).
- **Failure scenario:** Demo day, fresh emulator, flaky network: app renders in Roboto. No error, no crash, nothing in `flutter analyze` — the failure mode is invisible to every QA gate this plan defines.
- **Evidence:** `FE/pubspec.yaml:17` (`google_fonts: ^6.2.1`); no font assets bundled (no `fonts:` section usage for these families); `google_fonts` documented runtime-fetch behavior. All 15+ styles in `FE/lib/config/theme/app_typography.dart:7-109` route through `GoogleFonts.*` calls.
- **Suggested fix:** Bundle the two families as local assets (google_fonts supports asset-first resolution) or add an explicit demo-device warm-up step to the Phase 7 closeout. Delete the `flutter pub get` claim.

## Finding 9: Phase 7's own numbers contradict each other — Login (18) is the *highest* hardcode count in the customer/guest set, not "2nd-highest after DeliveryMap"

- **Severity:** Medium
- **Location:** Phase 7, step 1 ("18 hardcode-lines per Phase 1, the 2nd-highest in the customer/guest set after DeliveryMap")
- **Flaw:** DeliveryMap has 14 hardcode lines; Login has 18. 18 > 14 — the sentence inverts its own cited numbers. Trivial in isolation, but it demonstrates the plan transcribes feeder numbers without arithmetic sanity-checking, which is the same failure mode behind Findings 3 and 7. It also underplays Login's rank: it is tied-for-2nd in the *entire 30-screen inventory* (behind ManagerProductList's 28, tied with ManagerCreateProduct's 18) while being scheduled last at P3 with "S/M, half day" for the cluster.
- **Failure scenario:** Effort budgeting for Phase 7 anchors on "2nd after DeliveryMap" framing; Login's 18-line sweep plus 6 findings plus contrast re-check overruns the half-day cluster estimate.
- **Evidence:** Guard-regex recount: `login_screen.dart` = 18, `delivery_map_screen.dart` = 14. Inventory concurs (`phase-01-ui-inventory-debt-map.md` rows 4-5: Login 18 / DeliveryMap 14).
- **Suggested fix:** Correct the sentence; re-check the half-day estimate for a 429-line T3 screen with 6 open findings.

---

## Verification Results

**Claims sampled: 31 — Verified: 24 | Failed: 6 | Partial: 1**

| # | Claim | Verdict | Evidence |
|---|---|---|---|
| 1 | Phase 1 v1 color table (all 14 values, e.g. primary `#C4517A`, textHint `#A0A0A0`) | VERIFIED | `FE/lib/config/theme/app_colors.dart:6-20` |
| 2 | Theme file line counts: colors 21 / typography 113 / spacing 17 / theme 150 | VERIFIED | `wc -l` exact match, all 4 |
| 3 | Spacing scale 4/8/12/16/24/32/48 + 5 radii at v1 values 16/12/24/12/20 | VERIFIED | `app_spacing.dart:4-16` |
| 4 | `google_fonts` already covers both fonts, no new dependency | VERIFIED (dep) | `FE/pubspec.yaml:17` `^6.2.1`; but see Finding 8 for the runtime-fetch caveat |
| 5 | app_typography weight/style demands compatible with Cormorant/Montserrat | VERIFIED | `app_typography.dart:7-109` — w400-w700 only, no italics; Cormorant ships 400-700 per `docs/design-tokens-v2.md:37` |
| 6 | Widgets total = 10 files | VERIFIED | `ls FE/lib/widgets` = 10 |
| 7 | "8 of 10 shared widgets fully token-driven / token-swap-only" | **FAILED** | 13 `Colors.*` lines in 5 widgets incl. 4 of the claimed 8: `app_bottom_nav.dart:29,40,41,47`, `manager_bottom_nav.dart:22,33,34,40`, `app_card.dart:38,43`, `app_button.dart:34,95` (Finding 1) |
| 8 | `section_header.dart` uses `Theme.of(context)` pattern | VERIFIED | `section_header.dart:20,26-28` |
| 9 | `size_selector.dart:37-47` solid-fill primary + white selected state | VERIFIED | `:37` (`AppColors.primary` fill), `:47` (`Colors.white` text) |
| 10 | `product_card.dart` has 3 raw radii at :38,62,87 | **FAILED** | 4 raw radii — 4th at `:122` (Finding 6) |
| 11 | Per-file hardcode counts (14 files: PD 7, Home 8, PL 8, EP 4, Chat 7, DM 14, Login 18, Splash 7, MPL 28, MPD 20, MCP 18, AD 12, AU 5, AC 5) | VERIFIED* | All 14 match exactly under the plan's regex+filter. *But the filter itself undercounts 5 files by 1 (Finding 2) |
| 12 | "195 hardcode-hit lines" as guard baseline | **FAILED** | 195 = screens-only; guard scope (screens+widgets) = 208; +6 filter-invisible = 214 (Findings 2, 3) |
| 13 | Manager ~78 hardcode lines | VERIFIED | Exactly 78 (`FE/lib/screens/manager` recursive) |
| 14 | M34 "~90% shared, ~965/1033 lines" | **FAILED** | Actual 1007/928 (`wc -l`); plan's own feeder inventory rows 2-3 already said 1007/928 (Finding 7) |
| 15 | M2 = `Colors.grey` in manager_shell profile, still open | **FAILED** | Zero `Colors.grey` in `manager_shell.dart`; header rewritten to white-on-gradient (Finding 4) |
| 16 | M19 pink AppBar still open on MPD + MCP | VERIFIED | `manager_product_detail_screen.dart:305`, `manager_create_product_screen.dart:242` — both `AppColors.primary` |
| 17 | M20 exists with claimed meaning | VERIFIED (partial) | `docs/ux-flow-audit.md:225`; but audit line refs (:142,198,231,321,395-420) are stale — current grey/white hits at :150,209,212,223,238,294,337,342,457; and Phase 5 never names M20 in a step, only in success criteria; the :457 instance is guard-invisible (Finding 2) |
| 18 | C30 (order_detail badge, ✅-fixed base + residual), C42 (chat green dot ✅), C45 (ship-fee table, open), G16 (otp focus, open) | VERIFIED | `docs/ux-flow-audit.md:145,165,168,52` — meanings match plan usage |
| 19 | `manager_shell.dart:55` `_ManagerProfileScreen` / `admin_shell.dart:83` `_AdminProfileScreen` | VERIFIED | Class declarations at :55 and :83 exactly |
| 20 | `profile_screen.dart:128` links to DeliveryMap (customer screen, no delivery role) | VERIFIED | `pushNamed('/delivery-map')` at ~:128 |
| 21 | MPL FAB block at :196-207 | VERIFIED | `FloatingActionButton.extended` at :195-214 |
| 22 | Checkout "+ 5 files in checkout/widgets/" | VERIFIED | 5 files in `FE/lib/screens/checkout/widgets/` |
| 23 | AdminUsers 671 LOC | VERIFIED | `wc -l` = 671 |
| 24 | Cluster totals 8+7+9+4+2 = 30, no screen dropped vs inventory | VERIFIED | All 30 inventory rows map 1:1 to a cluster table row; no orphans, no double-counts |
| 25 | `.withOpacity` cleanup already done, 0 repo-wide | VERIFIED | `grep -rn '\.withOpacity(' FE/lib` = 0 |
| 26 | v2 token values in Phase 1 table match frozen `docs/design-tokens-v2.md` | VERIFIED | doc lines 16-29 — all 14 hexes, both fonts, all 5 radii match |
| 27 | 6.70:1 white-on-v2-primary precomputed claim (Phase 6 step 2) | VERIFIED (doc-level) | `docs/design-tokens-v2.md:16` — the number is in the doc as claimed (real-tool re-check still required per plan, correctly) |
| 28 | Status-badge tonal rule exists in tokens doc | VERIFIED | `docs/design-tokens-v2.md:31,68` |
| 29 | `FE/scripts/` convention exists | VERIFIED | `setup.sh`, `sepay-simulate-payment.sh` — but script's repo-root-relative grep paths break from that CWD (Finding 3) |
| 30 | AdminShell NavigationBar inline, not a shared widget | VERIFIED | `admin_shell.dart:51-73` inline `NavigationBar`; `manager_bottom_nav.dart` is the shared counterpart |
| 31 | "Login 18 = 2nd-highest in customer/guest set after DeliveryMap" | **FAILED** | 18 > 14 — Login is the highest in that set (Finding 9) |
| 32 | StatusBadge has no existing duplicate (scope-auditor check) | VERIFIED | No badge/chip widget class in `FE/lib/widgets/`; new component justified, no parallel reimplementation |

**Failed claims:** #7 (8-of-10 token-driven), #10 (3 radii), #12 (195 baseline), #14 (965/1033), #15 (M2 open), #31 (Login rank). **Partial:** #17 (M20 refs stale, step-ownership missing).

## Unresolved Questions

1. What token replaces the 94 `Colors.white`-on-primary usages? (Finding 5 — needs a planner decision before Phase 3 starts.)
2. Should `Colors.transparent` and shadow `Colors.black.withValues(...)` count as violations at all? The guard's answer determines whether Finding 1 is fixed by allowlist or by widget edits.
3. Is M2 formally closed as overtaken-by-events, or does the planner want an AA re-check of the white-on-v2-gradient header as its replacement acceptance test?
