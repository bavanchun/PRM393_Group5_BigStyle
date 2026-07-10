# Red-Team Plan Review — Scope & Complexity Critic / Contract Verifier

Plan: `plans/260710-1342-bigstyle-visual-reskin-implementation/` (8 phase files)
Reviewer lens: YAGNI enforcer + shared-contract verifier. Course project (FPT PRM393), demo deadline. Verified at HEAD == pinned SHA `6e77ccf` (zero drift), so every count mismatch below is an audit/plan error, not repo drift.

Respected user-locked decisions: visual-only reskin, Warm Terracotta palette, demo-visibility-first cluster order, 3 roles + guest. No finding below reverses any of them.

---

## Finding 1: Phase 2's centerpiece fix targets a dead widget — `size_selector.dart` has ZERO importers

- **Severity:** Critical
- **Location:** Phase 2, sections "Related Files" and "Implementation Steps" step 1; also plan.md Acceptance Criteria ("`size_selector.dart` + `product_card.dart` reworked")
- **Flaw:** Phase 2 claims `size_selector.dart:37-47` is the "Phase 4 code-confirmed root cause of ProductDetail/CartItemEdit tonal-violation findings." Grep proves the widget is orphaned: `grep -rn "size_selector" FE/lib --include="*.dart"` returns **zero** import sites. ProductDetail re-implements the selector inline (`_buildSizeSelector`, `FE/lib/screens/product_detail/product_detail_screen.dart:504-550`, with the actual solid-fill violation at :529 `color: isSelected ? AppColors.primary : ...` and :538 `Colors.white` text). CartItemEdit uses stock `ChoiceChip` (`FE/lib/screens/cart/cart_item_edit_screen.dart:239-247`) — theme-driven, not the shared widget.
- **Failure scenario:** Implementer reworks the orphan file, Phase 2 success criterion "`size_selector.dart` selected state is tonal" passes, `flutter analyze` passes, phase marked done. On the demo device ProductDetail's size chips are still solid-terracotta+white — the exact finding the phase exists to close stays open, discovered (or not) during grading.
- **Evidence:** `FE/lib/widgets/size_selector.dart` (no importers repo-wide); `FE/lib/screens/product_detail/product_detail_screen.dart:504-550`; `FE/lib/screens/cart/cart_item_edit_screen.dart:239`.
- **Suggested fix:** Retarget Phase 2 step 1 at `product_detail_screen.dart:504-550` (either migrate the inline block to tonal in place, or make ProductDetail actually import the shared widget and fix it there — one, not both). Delete or explicitly quarantine the orphan `size_selector.dart` so the hardcode-guard doesn't count dead code. CartItemEdit's `ChoiceChip` styling comes from `ThemeData.chipTheme` — that's a Phase 1 theme-file concern, not a widget rework.

## Finding 2: `StatusBadge` is premature abstraction — claimed consumers are already tonal, and the enum can't express the actual status domain

- **Severity:** High
- **Location:** Phase 2, sections "New Component: StatusBadge" and "Consumers to migrate"; Phase 4 step 2; Phase 5 step 5
- **Flaw:** Three-part failure of the "closes ~13 findings" claim (inherited from the audit, never code-verified):
  1. The flagship consumer sites **already implement the tonal pattern** the component exists to enforce: `orders_screen.dart:102-118` (tint bg `withValues(alpha: 0.1)` + full-strength text), `order_detail_screen.dart:83-97`, `manager_order_card.dart:101-107` (with shared helper `managerOrderStatusColor` at :17), `manager_order_detail_screen.dart:143-151`, `manager_dashboard_widgets.dart:180`.
  2. The proposed `enum BadgeStatus { success, warning, error, info }` cannot represent the real 5-value `OrderStatus` domain: `orders_screen.dart:193-206` maps confirmed→`AppColors.primary` and shipping→`Colors.blue`. Neither "primary" nor an "info" color exists in the 14-token v2 table (`docs/design-tokens-v2.md` / Phase 1 table). Migrating orders to `StatusBadge` either loses status distinctions or forces enum+token expansion mid-cluster.
  3. Claimed consumers are mischaracterized: M6 is a **stat card using the wrong token** (`ux-flow-audit.md:193`: fix = "Dùng `AppColors.warning`", code at `manager_dashboard_widgets.dart:33` `color: AppColors.success`) — a one-line token swap, not a badge-component adoption. Profile/Notifications "badge" sites (`profile_screen.dart:83`, `notifications_screen.dart:86`) are icon-tint containers with no label — they don't fit a `StatusBadge(label, status)` API at all.
- **Failure scenario:** A day of Phase 2 spent building+migrating a new widget across ~7 screens whose badges already look correct, while introducing status-color regressions on Orders/OrderDetail (confirmed/shipping collapse to "info" with no token behind it) — on the recently live-verified manager order flow Phase 5's own risk section says not to touch carelessly.
- **Evidence:** file:line cites above; audit source `plans/260710-1158-ui-ux-overhaul-audit-pipeline/reports/phase-04-screen-gap-audit-by-role.md:80` (origin of the "13" number).
- **Suggested fix:** Cut `StatusBadge` from required scope. Keep the two real fixes: M6 one-liner (`success`→`warning` at `manager_dashboard_widgets.dart:33`) and the size-selector tonal fix (Finding 1). If any solid-fill+white badge actually survives a per-site grep, fix it in its cluster phase using the existing `managerOrderStatusColor`/`_statusColor` local pattern — the codebase already converged on it without a shared widget.

## Finding 3: "Hardcode count drops to 0" is unachievable — the token vocabulary has no target for 145+ of the 208 hits, and 12 of them live in files no phase owns

- **Severity:** High
- **Location:** Phase 1 "New: Hardcode Guard" + step 4; Phase 5 success criterion "hardcode count (baseline ~78) drops to 0"; Phase 7 success criterion "guard passes repo-wide with zero violations"
- **Flaw:** Running the plan's own script at pinned SHA yields 208 hits (plan says 195). Breakdown: `Colors.white` ×100, `Colors.black` ×31 (nearly all shadow `withValues(alpha:)`), `Colors.transparent` ×13, `Colors.grey` ×28, assorted ×36. The frozen v2 table (`app_colors.dart`, 14 constants) has **no onPrimary/white-on-fill token, no transparent, no shadow token, no info/blue**. Worse: 12 of the hits sit inside 4 of the "8 fully token-driven shared widgets" (`app_bottom_nav.dart:29,40,41,47`, `app_card.dart:38,43`, `app_button.dart:34,95`, `manager_bottom_nav.dart:22,33,34,40`) — Phase 1 is theme-files-only, Phase 2 explicitly says "no other shared widget touched," Phases 3-7 sweep screens per cluster. Nobody owns these 12 lines, yet Phase 7's closeout requires the guard at zero across `screens` + `widgets`.
- **Failure scenario:** Implementer hits `icon: Icon(Icons.add, color: Colors.white)` in cluster 3 with no defined replacement. Either invents tokens ad hoc per cluster (5 phases of inconsistent vocabulary — the exact disease the guard exists to cure), semantically misuses `AppColors.surface` as text-on-primary, or the zero-violation criteria get quietly waived at Phase 7 — making the whole guard apparatus ceremony.
- **Evidence:** grep counts above; `FE/lib/config/theme/app_colors.dart:6-20` (14 constants, none of the needed neutrals); Phase 2 non-functional requirement ("no other shared widget touched"); Phase 1 requirement ("no screen-level code changes").
- **Suggested fix:** In Phase 1, add exactly the 2-3 missing neutral tokens up front (`onPrimary`, `shadow`; whitelist `Colors.transparent` in the guard — it is not a color decision) and assign the 12 shared-widget lines to Phase 1's scope (they're widget-catalog files, which Phase 1's own requirement already names). Then "zero" becomes achievable and meaningful.

## Finding 4: The guard script — the acceptance instrument for 5 phases — has 6 verified false negatives, including the exact line Phase 2 exists to fix

- **Severity:** High
- **Location:** Phase 1, section "New: Hardcode Guard" (script body); consumed by success criteria in Phases 3, 4, 5, 6, 7
- **Flaw:** `grep -E 'Colors\.[A-Za-z]+|0xFF...'` matches the `Colors.` substring inside `AppColors.`, so the script bolts on `| grep -v 'AppColors'` — which drops entire **lines**, including lines containing both a token and a genuine hardcode. Verified false negatives at pinned SHA: `chat_screen.dart:228`, `admin_users_screen.dart:138`, `manager_product_list_screen.dart:457`, `product_detail_screen.dart:538` (the solid-fill size-chip text from Finding 1), `product_list_screen.dart:216`, `size_selector.dart:47`. The ternary `condition ? Colors.white : AppColors.x` idiom is exactly how selected-state hardcodes are written in this codebase, so the blind spot is systematic, not incidental.
- **Failure scenario:** Phase 5/7 success criteria read "0 per the hardcode-guard script" — script prints 0 while selected-state hardcodes remain shipped. The tool built to prevent pencil-whipping becomes the pencil-whipping mechanism.
- **Evidence:** script at phase-01 lines 60-70; the 6 file:line false negatives above (reproduced by running the script's exact pipeline).
- **Suggested fix:** Match per-occurrence with a boundary, not per-line exclusion: `grep -rnE '(^|[^A-Za-z])Colors\.[A-Za-z]+|0xFF[0-9A-Fa-f]{6}'` and drop the `-v` entirely (with the `Colors.transparent` whitelist from Finding 3). One-line change; do it in the plan text now, not during execution.

## Finding 5: Plan-level AC demands a 30-screen WCAG-tool pass; phases only budget ~7 — contradiction that ends as checkbox theater

- **Severity:** Medium
- **Location:** plan.md, "Acceptance Criteria" line "Real WCAG-tool contrast re-check done per screen"; vs Phase 3 step 3, Phase 4 steps 3-4, Phase 5 step 8, Phase 6 step 2, Phase 7 step 1
- **Flaw:** The phase files (correctly) scope real-tool contrast re-checks to the ~7 flagged findings (ProductDetail ×2, Profile, Chat, ManagerVoucher FAB, AdminDashboard, Login). The plan-level AC says "per screen" — 30 manual tool passes no phase budgets. `docs/design-tokens-v2.md:31` already pre-computes the pairings (white-on-v2-primary 6.70:1 etc.), so a blanket per-screen sweep re-derives known numbers.
- **Failure scenario:** At closeout either the AC is checked off without doing it (the plan trains the team to pencil-whip its own acceptance criteria), or a student burns a day tool-checking 23 screens with zero flagged findings — pure gold plating a week from a demo.
- **Evidence:** plan.md:71 vs phase files cited above; docs/design-tokens-v2.md:31 precomputed table.
- **Suggested fix:** Reword the AC to match the phases: "every *flagged* contrast finding re-verified with a real WCAG tool; new color pairings introduced during migration checked against the precomputed table in design-tokens-v2."

## Finding 6: Phase 0 contains a self-contradicting dead step and duplicates cluster-phase pre-conditions

- **Severity:** Medium
- **Location:** Phase 0, Implementation Steps 4 vs 6; vs Phase 3 "Pre-condition" and Phase 5 "Pre-condition"
- **Flaw:** Step 4 rules "this phase only diagnoses, cluster phases fix." Step 6 then conditions delta-recapture on the bugs being "trivial and get a same-day fix" — a precondition step 4 makes unsatisfiable (no fix happens in Phase 0 by its own rule). Meanwhile Phase 3's pre-condition re-does the Checkout/PaymentQr recapture decision and Phase 5's pre-condition re-does ManagerCreateProduct's — so step 6 is both dead logic and duplicated effort. Also: HEAD equals the pinned SHA today, so the phase's headline diff is a known no-op, yet the phase is budgeted at half a day with its own file, requirements, and risk section.
- **Failure scenario:** Half a day of ceremony for a 5-minute `git diff` plus a recapture step that can never fire; or worse, an implementer reads step 6 as license to fix the bugs in Phase 0 after all, contradicting the plan's own bug-fix placement (Phases 3/5).
- **Evidence:** phase-00 steps 4 and 6; phase-03 "Pre-condition" section; phase-05 "Pre-condition" section; `git rev-parse HEAD` == `6e77ccf...` at review time.
- **Suggested fix:** Delete step 6. Fold Phase 0 into Phase 1 as a 30-minute preamble (diff check + 2×1-hour bug root-cause reads). Cluster pre-conditions already own recapture.

## Finding 7: Optional refactors are "flagged as skippable" but invited inside the step lists — guaranteed scope leak

- **Severity:** Medium
- **Location:** Phase 5, step 2 ("If time allows, this is also the natural point to extract the shared `ProductFormBody`"); Phase 6, step 4 ("Consider whether to extract this into a shared widget... cheap if done here")
- **Flaw:** Phase 5's own Risk Assessment says "resist fully refactoring into `ProductFormBody`" — then step 2, the instruction an implementer actually executes, re-invites it. The M34 target is a ~1935-line pair (`manager_create_product_screen.dart` 928 + `manager_product_detail_screen.dart` 1007) — "extract if time allows" on that surface is a multi-day refactor wearing an "optional" sticker, inside the cluster the plan itself flags as touching the most recently live-verified flow. Same pattern in Phase 6 with the AdminShell NavigationBar extraction, in a P2 phase closest to the deadline.
- **Failure scenario:** Day 6 of 8.5, a teammate starts the ProductFormBody extraction "since we're in the file," blows the manager-cluster budget, and the demo lands with customer screens reskinned but the manager CRUD flow half-refactored and unverified.
- **Evidence:** phase-05 step 2 vs phase-05 Risk Assessment bullet 2; phase-06 step 4; `wc -l` on the two manager product files (928/1007).
- **Suggested fix:** Remove both invitations from the step lists. Keep them only as one-line "follow-up plan candidates" in the closeout note. In a deadline course project, "optional" work listed as a numbered step is not optional — it's scope.

## Finding 8: Frozen audit counts used as completion checklists are already wrong at the pinned SHA

- **Severity:** Medium
- **Location:** Phase 3 step 2 ("cite exact line numbers from phase-01 counts as your checklist"), Phase 5 step 7, Phase 2 success criterion ("`product_card.dart`'s 3 radii")
- **Flaw:** With zero repo drift, the plan's numbers still don't match code: guard-regex total 208 vs plan's "195 baseline"; `manager_product_list_screen.dart` 29 hits vs "28"; ProductDetail 8 vs "7"; `product_card.dart` has **4** raw radius literals (`:38,:62,:87,:122`) vs the plan's "3" — Phase 2's success criteria are internally contradictory ("3 radii reference named constants" AND "zero raw `BorderRadius.circular(literal)`"; satisfying the first leaves :122 violating the second). M34's "~965/1033 lines" is actually 928/1007. Individually trivial; as a method — "use the frozen count as your done-signal" — it systematically undercounts.
- **Failure scenario:** Implementer fixes 7 hardcodes on ProductDetail, checklist says done, 8th survives; the backstop is the guard script, whose false-negative list (Finding 4) includes ProductDetail:538. Both nets have matching holes.
- **Evidence:** grep counts at pinned SHA vs phase-01/02/03/05 text; `grep -n "BorderRadius.circular" FE/lib/widgets/product_card.dart` → 38, 62, 87, 122.
- **Suggested fix:** Strike "as your checklist" language. The checklist is `grep` output at execution time; the audit counts are context only. Fix Phase 2's radii criterion to "zero raw radius literals" alone.

## Finding 9: Strict sequential dependency chain across file-disjoint clusters serializes a 5-person team for 8.5 days

- **Severity:** Medium
- **Location:** plan.md "Dependency Chain" (Phase 3 → 4 → 5 → 6 → 7 as hard `dependencies:` in each phase frontmatter); Phase 6 + Phase 7 existing as separate full-ceremony phases
- **Flaw:** The user-locked decision is cluster **order** (demo-visibility-first delivery priority) — not that admin work may not begin until every manager screen is signed off. Clusters 3-7 touch disjoint file sets (`screens/{home,cart,checkout,...}` vs `screens/manager/` vs `screens/admin/` vs `screens/auth/`); after Phase 2 there is no shared-file conflict. Yet phase frontmatter encodes hard chaining, summing to 8.5 sequential days for a group-of-5 course project. Separately, Phase 6 (4 screens, ~22 hardcode lines) and Phase 7 (2 screens, ~25 lines) each carry a full phase file, regression checklist, and risk section — two ceremonies for what is jointly under a day and a half of token sweeps.
- **Failure scenario:** Four teammates idle (or freelancing unreviewed changes into the same repo — the exact drift Phase 0 fears) while one person walks the chain; the demo date arrives mid-Phase-5 with admin/auth untouched — which the visibility ordering was supposed to make survivable, but 8.5 serialized days makes likely rather than tail-risk.
- **Evidence:** phase frontmatter `dependencies: [2],[3],[4],[5],[6]`; effort tags summing 8.5 days; disjoint paths per cluster tables; manager cluster verified at zero shared-widget imports (`grep -rn "import.*widgets/" FE/lib/screens/manager` → empty) so it can't even conflict with Phase 3-4 work through shared widgets.
- **Suggested fix:** Keep the delivery/merge **priority** order exactly as locked. Relax phases 4-7's `dependencies:` to `[2]` (all need tokens + shared components only), and merge Phases 6+7 into one closing phase with a combined checklist. Same order, same safety, ~half the ceremony, parallelizable across the group.

---

## Verification Results

**Claims sampled: 27. Verified: 18. Failed: 7. Partially verified/drifted: 2.**

Verified (evidence in findings above unless noted):
1. Theme file line counts 21/17/150/113 — exact match (`wc -l FE/lib/config/theme/*.dart`).
2. `AppColors.` consumers: 56 files; `AppSpacing.`: 36; `AppTypography.`: 44 (all `FE/lib`, grep -rl).
3. `ProductCard` consumers: `home_screen.dart:112,172`, `favorites_screen.dart:70`, `product_list_screen.dart:289` — matches Phase 3 cluster coverage.
4. `section_header.dart` uses `Theme.of(context)`/`ColorScheme` pattern — confirmed (whole file).
5. `app_theme.dart` uses explicit `ColorScheme.light(` (line 13), not `fromSeed` — Phase 1's hedge is safe.
6. Manager 9/9 screens zero shared-widget imports — confirmed (grep empty).
7. Manager hardcode baseline "~78" — exactly 78 via the plan's own script regex.
8. Per-file hardcode counts: ManagerProductDetail 20 ✓, ManagerCreateProduct 18 ✓, Login 18 ✓, DeliveryMap 14 ✓, AdminDashboard 12 ✓, Splash 7 ✓, Home 8 ✓, EditProfile 4 ✓ (spot-checked set).
9. `admin_users_screen.dart` 671 LOC ✓.
10. Anchors: `profile_screen.dart:128` delivery-map link ✓; `manager_shell.dart:55` `_ManagerProfileScreen` ✓; `admin_shell.dart:83` `_AdminProfileScreen` ✓; FAB block `manager_product_list_screen.dart:195-213` (plan cites 196-207) ✓.
11. M19: fixed on list screen (`manager_product_list_screen.dart:47` AppBar `surface`) ✓; still `AppColors.primary` on detail `:305` and create `:242` ✓ — Phase 5 steps 3-4 accurate.
12. No `.github/workflows/` — Phase 1's "CI wiring optional" hedge is accurate; `FE/scripts/` exists (2 scripts), so script placement convention claim holds.
13. `FE/test/`: 13 test files, **zero** golden tests, zero tests pinning `AppColors`/`Color(`/fonts — no golden-regeneration gap exists; plan's silence on goldens is correct, not an omission.
14. Native surfaces: Android `launch_background.xml` is plain white (no v1 pink leaks to demo audience); `styles.xml` uses system colors. Web `manifest.json` has Flutter-default `#0175C2` but web is not a deliverable surface for this Android course project — acceptable out-of-scope.
15. `google_fonts: ^6.2.1` in `FE/pubspec.yaml` — single-package font swap claim ✓.
16. 30-screen partition: 8+7+9+4+2 = 30 ✓.
17. M2/M6/M12/M21/M28/M34/C30/G16 all exist in `docs/ux-flow-audit.md` with cited semantics ✓ (M2 hardcode is at `manager_shell.dart:79`, class at :55 — plan cite acceptable).
18. Status-badge tonal rule exists in `docs/design-tokens-v2.md:31` as quoted ✓.

Failed:
1. **`size_selector.dart` drives ProductDetail/CartItemEdit** — FALSE, zero importers; duplicated inline / ChoiceChip (Finding 1).
2. **"8 of the 10 shared widgets fully token-driven"** — FALSE; 4 of the 8 contain 12 hardcode lines (Finding 3).
3. **`StatusBadge` "closes ~13 findings"** — flagship consumer sites already tonal; enum can't express the status domain; M6 mischaracterized (Finding 2).
4. **product_card "3 raw radii"** — 4 exist (`:122` missed) (Finding 8).
5. **"195 hardcode-hit lines" baseline** — plan's own script yields 208 at the pinned SHA (Finding 8).
6. **Guard script correctness** — 6 false negatives from `grep -v 'AppColors'` line-level exclusion (Finding 4).
7. **"Hardcode count drops to 0" achievability** — no token targets for white/transparent/shadow/blue; 12 hits unowned by any phase (Finding 3).

Partially verified / drifted:
1. M34 "~965/1033 lines" → files are 928/1007 today (claim directionally right, numbers stale).
2. ManagerProductList 28 → 29; ProductDetail 7 → 8 (off-by-one class, at zero repo drift).

## Unresolved Questions

1. Which regex did the audit's "195" use? If different from the guard script's, the plan carries two incompatible definitions of "hardcode" and every baseline/zero criterion is ambiguous.
2. Is `Colors.transparent` (13 uses) considered a violation by the design system, or whitelisted? The plan never says; Phase 7's "zero violations" is undefined until it does.
3. Does the team intend solo or parallel execution of clusters 3-7? Finding 9's severity rises to High if the demo date is inside the 8.5-day window.
