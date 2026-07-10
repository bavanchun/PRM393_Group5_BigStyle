# Red-Team Plan Review — Failure Mode Analyst

**Plan:** `plans/260710-1342-bigstyle-visual-reskin-implementation/`
**Reviewer role:** hostile failure-mode analysis + flow tracing, codebase-evidence-backed
**HEAD at review:** `6e77ccf` (== plan's pinned SHA, no drift)
**Respected user-locked decisions:** visual-only scope, frozen Warm Terracotta palette, demo-first cluster order, 3 roles + guest. No finding below proposes reversing them.

---

## Finding 1: Hardcode-guard script produces false PASSES two independent ways — the plan's primary quality gate is unsound

- **Severity:** Critical
- **Location:** Phase 1, section "New: Hardcode Guard" (and every downstream phase's "hardcode-guard passes" success criterion)
- **Flaw:** The script as specified in phase-01 has two silent false-pass modes:
  1. `grep -v 'AppColors'` drops any line containing BOTH a hardcode and an `AppColors` ref. The regex `Colors\.[A-Za-z]+` also matches the substring inside `AppColors.primary`, so the `-v` filter is structurally required — and structurally wrong. Six real hardcodes are invisible to the guard **right now**:
     - `FE/lib/widgets/size_selector.dart:47` — `isSelected ? Colors.white : AppColors.textPrimary`
     - `FE/lib/screens/chat/chat_screen.dart:228` — `isBot ? AppColors.textPrimary : Colors.white`
     - `FE/lib/screens/admin/admin_users_screen.dart:138` — `isSelected ? Colors.white : AppColors.textSecondary`
     - `FE/lib/screens/manager/products/manager_product_list_screen.dart:457` — `isHidden ? Colors.grey : AppColors.primary`
     - `FE/lib/screens/product_detail/product_detail_screen.dart:538` — `isSelected ? Colors.white : AppColors.textPrimary`
     - `FE/lib/screens/product_list/product_list_screen.dart:216` — `isSelected ? AppColors.primary : Colors.transparent`
  2. The script lives at `FE/scripts/check_hardcoded_colors.sh` but greps relative paths `FE/lib/screens FE/lib/widgets`. Run from `FE/` (the natural CWD for a Flutter repo — where `flutter analyze`/`flutter test` are run), grep scans nonexistent dirs, `$hits` is empty, and the script **exits 0: false PASS**. A guard whose failure mode is silent success is worse than no guard — Phase 7's closeout "guard passes repo-wide" could be a green light on a broken scan.
  Also: regex misses lowercase `0xff` literals and `Color.fromARGB/fromRGBO` forms (none present today, but nothing stops a teammate adding one mid-plan), and the script has no per-cluster path-scoping (see Finding 3).
- **Failure scenario:** Phase 7 closeout runs the guard from `FE/`, gets exit 0, marks the plan complete. `Colors.grey` at `manager_product_list_screen.dart:457` and 5 other mixed-line hardcodes ship in the "fully migrated" reskin — the exact class of defect the whole plan exists to eliminate, certified clean by its own gate.
- **Evidence:** script text at phase-01 lines 60-70; live grep reproduction: guard logic run against HEAD returns 208 lines, and the mixed-line filter demonstrably hides the 6 lines above.
- **Suggested fix:** anchor the script with `cd "$(dirname "$0")/.."` + fail hard if scan dirs missing (`[ -d lib/screens ] || exit 2`); replace the `grep -v` approach with a negative-lookaround-capable tool (`grep -P '(?<!App)Colors\.'`) or per-match extraction; add `0x[fF]{2}` and `Color\.from` to the pattern; add an optional path argument for per-cluster runs.

## Finding 2: No branch or rollback strategy — Phase 1's global flip creates a week-long two-palette app on shared `dev`

- **Severity:** Critical
- **Location:** plan.md frontmatter (`branch: "dev"`) + plan.md "Risk Assessment" (no rollback section anywhere in the plan; zero occurrences of "rollback"/"revert" across all 8 files)
- **Flaw:** Total declared effort is 8.5 days (0.5+0.5+1+1.5+1.5+2+1+0.5 per phase frontmatter), committed directly to `dev` on a team repo with no freeze. Phase 1 flips `AppColors.*` constants globally on day ~1, which instantly reskins every `AppColors`-referencing element terracotta — while all ~200 hardcoded v1 values stay pink until their cluster phase. Worst case is Login, migrated **last** (Phase 7, day ~8): it hardcodes the v1 pink hexes directly — `Color(0xFFC4517A)`/`Color(0xFFA03560)` gradient at `FE/lib/screens/auth/login_screen.dart:249`, pink-tinted background gradient at `:54`, plus `:143,:231,:255`. DeliveryMap similarly hardcodes `0xFFC4517A` at `FE/lib/screens/delivery/delivery_map_screen.dart:80,96,206` until Phase 4. The plan's documentation-management rules require rollback notes per phase; none exist.
- **Failure scenario:** Day 3 of migration, a teammate needs to demo (or a lecturer asks for an ad-hoc walkthrough). Fresh install / logged-out state shows a Login screen with terracotta themed inputs inside a pink hero gradient — visibly broken branding, worse than the untouched v1. There is no documented way to get back to a coherent state: reverting Phase 1's theme commit on `dev` also reverts whatever cluster commits landed on top, and nothing records which commits belong to this plan.
- **Evidence:** plan.md:6 (`branch: "dev"`); effort frontmatter across phase-00..07; `login_screen.dart:54,143,231,249,255`; `delivery_map_screen.dart:80,96,206`; grep for "rollback|revert" across the plan dir returns nothing.
- **Suggested fix:** run the whole plan on a `reskin/warm-terracotta` feature branch merged to `dev` once Phases 1-3 (theme + shared + customer-shop) are done as a minimum coherent unit; add a per-phase rollback note (at minimum: "revert = `git revert <phase commit range>`, safe because theme files/screens are not touched by other plans"); tag the pre-Phase-1 commit so a clean demo checkout is one command.

## Finding 3: Phase 7's "guard passes repo-wide, zero violations" is unsatisfiable — 13 widget hardcode lines are owned by no phase, and there is no whitelist policy

- **Severity:** High
- **Location:** Phase 7, "Success Criteria" bullet 3; Phase 1 "Overview"/step 4; Phase 2 "Requirements" ("no other shared widget touched")
- **Flaw:** The guard scans `FE/lib/widgets`, which currently contains 13 flagged lines in exactly the 8 widgets the plan declares "fully token-driven" and forbids touching: `app_button.dart:34,95` (`Colors.white`, `Colors.transparent`), `app_card.dart:38,43` (`Colors.black` shadows), `app_bottom_nav.dart:29,40,41,47`, `manager_bottom_nav.dart:22,33,34,40`, `product_card.dart:67`. Phase 1 edits theme files only; Phase 2 explicitly touches only `size_selector`/`product_card` radii/`StatusBadge`; Phases 3-7 are screens-only. So the final criterion "zero violations across all of FE/lib/screens + FE/lib/widgets" cannot be met by executing the plan as written. Relatedly, the plan's stated baseline ("195 hardcode-hit lines") doesn't match the script's own scan scope: the script yields **208** at HEAD (195 screens + 13 widgets) — the audit counted screens, the guard scans screens+widgets, and nobody reconciled them. Worse, many of these 13 (and dozens of screen-level `Colors.white`-on-gradient lines, e.g. `manager_shell.dart:81-141`, `admin_shell.dart:109-150`) are *legitimate*: white text on a primary gradient, transparent splash, black shadow. There is no `onPrimary`-style token in `AppColors` and no whitelist mechanism in the script, so "make the guard pass" pressures an implementer toward wrong fixes (e.g. `Colors.white` → `AppColors.textPrimary` on a terracotta gradient = contrast regression on the exact screens the plan promises not to break).
- **Failure scenario:** Phase 7 closeout: guard reports 13+ violations in files the plan forbids touching. Implementer either (a) quietly edits the 8 "don't touch" widgets out-of-band — scope drift with no findings basis, or (b) weakens the script ad hoc to pass — gate integrity gone, or (c) marks the criterion done anyway — the plan's completion claim is false.
- **Evidence:** widget grep at HEAD (13 lines listed above); Phase 2 requirement text "no other shared widget touched"; Phase 1 requirement "no screen-level code changes in this phase"; baseline mismatch 195 (phase-01 step 4) vs 208 (script logic run at HEAD).
- **Suggested fix:** define an explicit allowlist in the script (`Colors.transparent`, `Colors.black.withValues` shadows, `Colors.white` where an adjacent comment marks on-primary usage — or better, add `AppColors.onPrimary`/`shadow` tokens as a permitted additive change like Phase 2 already permits for radii); reconcile the baseline number to the script's actual scope; assign the widget-file cleanup to a named phase.

## Finding 4: Phase 0's bug-triage happy path rests on mechanically impossible hypotheses — both "likely trivial" root causes contradict Flutter's hit-testing, and the recapture step contradicts the phase's own diagnose-only rule

- **Severity:** High
- **Location:** Phase 0, steps 2-6 + "Risk Assessment"; Phase 3 "Pre-condition"; Phase 5 "Pre-condition"
- **Flaw:** Flow-traced both bugs:
  - **Manager FAB:** the FAB is a standard `Scaffold.floatingActionButton` (`manager_product_list_screen.dart:195-214`). Scaffold hit-tests the FAB **above** the body — a list item "beneath" it cannot swallow its taps, ever. Phase 0 step 3's hypothesis ("list's bottom padding doesn't reserve space, FAB tap area overlaps the last card's InkWell") describes a visibility problem, not a tap-swallowing mechanism; it is not a possible root cause.
  - **Cart CTA:** the button is a plain `AppButton` inside a bottom `Container→SafeArea→Column` (`cart_screen.dart:308-357`), `onPressed → Navigator.pushNamed('/checkout')` at `:348-353`. No `Stack`, no competing `GestureDetector` — Phase 0 step 2's first hypothesis ("Stack/GestureDetector z-order") has no code path. The reported symptom ("resets the cart selection to unchecked and stays on Cart", reproduced at multiple coordinates per `phase-02-visual-capture-log.md:74`) with selection held in a local `Set<String> _selectedIds` (`cart_screen.dart:24`) rebuilt under `BlocBuilder<CartBloc>` (`:31`) points at either a CartBloc re-emission clearing effective selection, or — given the *same* symptom shape as the FAB bug (automated taps landing on the widget behind the intended target, 4/4 and 3/3 reproducible) — a capture-tooling coordinate-offset artifact, which is Phase 0 step 5's own "non-trivial → separate plan" branch.
  Both plan-preferred hypotheses being impossible means the "trivial, same-day fix, delta-recapture 4 screens" happy path (step 6) is the unlikely branch, yet Phases 3 and 5 preconditions are written assuming it ("confirm Phase 0 **resolved** the cart-CTA bug", "if Phase 0 **fixed** the FAB issue") — while Phase 0 step 4 explicitly states "this phase only diagnoses, cluster phases fix." Step 6's recapture requires a fix that no phase performs before Phase 3. Internal contradiction: Phase 0 cannot simultaneously be diagnose-only and deliver same-day fixes + recaptures.
- **Failure scenario:** Half-day Phase 0 burns its 1-hour-per-bug budget chasing z-order/padding ghosts, lands in the "needs deeper investigation" branch, and Checkout, PaymentQr, and ManagerCreateProduct — including the demo-critical **payment step of the purchase funnel** — are all migrated blind with no visual verification, exactly the screens the audit never saw. Meanwhile Phase 3's precondition ("confirm Phase 0 resolved the bug") is unmeetable as written, stalling the first demo-visible cluster on a wording bug.
- **Evidence:** `manager_product_list_screen.dart:195-214`; `cart_screen.dart:24,31,346-353`; `phase-02-visual-capture-log.md:74-75` (both bugs reproduce at multiple coordinates, FAB bug persists "even after scrolling so the FAB had clear space below the last card" — ruling out overlap entirely); phase-00 step 4 vs step 6 vs phase-03/05 precondition wording.
- **Suggested fix:** reword Phase 0 step 2/3 hypotheses to lead with the two mechanically possible causes (BLoC re-emission for cart; input-injection coordinate offset for both); make the on-device manual tap check (30 seconds with a finger, not adb) a Phase 0 step — if a human tap works, both "bugs" are capture artifacts and the recapture path reopens cheaply; fix Phase 3/5 precondition wording to reference Phase 0's *diagnosis*, not a resolution Phase 0 is forbidden to produce.

## Finding 5: Cart bug fix bundled into the token-migration commit violates the plan's own separation rule and breaks revert isolation

- **Severity:** High
- **Location:** Phase 3, step 1 ("one PR/commit, clearly separable diffs... in the description even if same commit") vs plan.md "Out of Scope" bullet 2 ("keep the token diff and the bug fix as separate, clearly-labeled changes")
- **Flaw:** plan.md demands separate, clearly-labeled *changes* for bug fixes riding along with token work; Phase 3 step 1 downgrades that to "same commit, separable in the description." If the cart root cause is the BLoC/selection-state race (the plan's own stronger hypothesis, and the one consistent with the code — see Finding 4), the fix lands in state-management code (`_selectedIds` handling in `cart_screen.dart` or `cart_bloc.dart`), i.e. behavioral code on the single most demo-critical flow (checkout), fused into a visual commit.
- **Failure scenario:** Post-migration, Cart renders wrong (a token mistake) — team reverts the Cart commit for a clean demo and silently un-fixes the checkout-CTA bug (or vice versa: the state fix regresses selection behavior and reverting it takes the reskin with it). During an 8-day migration on a shared branch, revert-by-commit is the only fast rollback tool available, and this step removes it for the highest-value screen.
- **Evidence:** phase-03 step 1 text; plan.md Out of Scope bullet 2; `cart_screen.dart:24,31,346-353` (fix surface is state logic, not styling).
- **Suggested fix:** two commits, hard rule: `fix(cart): ...` first (verifiable independently against pre-reskin UI), then `refactor(cart): token migration`. Same PR is fine; same commit is not.

## Finding 6: StatusBadge spec is unimplementable as written — the theme exposes no tonal/success/warning slots, and `BadgeStatus.info` has no token anywhere

- **Severity:** High
- **Location:** Phase 2, sections "New Component: StatusBadge" and "Requirements"
- **Flaw:** Phase 2 mandates `Theme.of(context)`-driven resolution "per the section_header.dart pattern (not direct AppColors refs)" and says to "use ColorScheme surface-tint conventions (Material 3)... check what app_theme.dart exposes post-Phase-1 for tonal surfaces." Traced: `app_theme.dart:13-22` builds `ColorScheme.light(primary, secondary, surface, error, onPrimary, onSecondary, onSurface, onError)` — **no** container/tonal slots are set (Flutter defaults them: `primaryContainer→primary`, etc., i.e. full-strength colors, the opposite of tonal), and Material 3's `ColorScheme` has **no success/warning slots at all**. Phase 1 adds no `ThemeExtension` (it is constant-value swaps only, per its own requirements). So a `Theme.of(context)`-only `StatusBadge` cannot resolve `success`/`warning` — the two statuses the frozen tonal rule (design-tokens-v2.md:31) exists for. And the sketched enum includes `info` (`phase-02` code block line 36), but neither `app_colors.dart` (14 constants, no info) nor the frozen v2 table (design-tokens-v2.md:14-29) defines an `info` color — `BadgeStatus.info` maps to nothing.
- **Failure scenario:** Implementer follows the letter of the spec, reaches for `colorScheme.secondaryContainer`-style slots, gets full-strength `secondary` (`#E8C9A0`) as a "tint" and undefined colors for success/warning/info; either falls back to direct `AppColors` refs (violating the phase's explicit requirement, flagged in review) or invents ad-hoc colors (violating the frozen palette). Since ~13 findings and the M6/C30 closures all hang off this component, the defect propagates into Phases 3-6.
- **Evidence:** `app_theme.dart:13-22`; `app_colors.dart:6-20` (no info token); `docs/design-tokens-v2.md:14-31`; phase-02 enum sketch including `info`; `section_header.dart:20-27` (the cited pattern only ever needed `colorScheme.primary`, so it proves nothing about success/warning resolvability).
- **Suggested fix:** Phase 1 should add a small `ThemeExtension` (e.g. `StatusColors {success, warning, error, info}` with tonal-container pairs) wired into `AppTheme.light` — additive, palette-frozen values; drop `info` from the enum or define its token explicitly (plausibly `accent` or `textSecondary` family) before Phase 2 starts; specify the tint recipe concretely (e.g. `token.withValues(alpha: .12)` bg + full token text) instead of pointing at tonal theme surfaces that don't exist.

## Finding 7: Font swap mitigation is factually wrong — google_fonts runtime-fetches, nothing is bundled, and the failure is silent at demo time

- **Severity:** High
- **Location:** plan.md "Risk Assessment" bullet 3 ("one-time asset cache... no mitigation needed beyond normal `flutter pub get` / asset warm-up"); Phase 1 step 5 / Related Files bullet 2
- **Flaw:** `google_fonts: ^6.2.1` (`FE/pubspec.yaml:17`) fetches font files **at runtime over HTTP, per device, on first render** and caches locally. `flutter pub get` downloads no fonts — the plan's stated mitigation does not exist. The repo bundles no font assets: pubspec's assets section contains only `.env` (`FE/pubspec.yaml:41-42`); repo-wide search finds no ttf/otf outside build artifacts. Playfair/DM Sans are warm in every existing dev device's cache from months of use; Cormorant/Montserrat are cold everywhere the day Phase 1 lands. On fetch failure, google_fonts falls back to the default platform font **silently** — no error, no crash, just Roboto.
- **Failure scenario:** Demo day: campus wifi blocked/flaky, or a graderʼs fresh emulator with no network. App boots fine, colors are terracotta, and the entire "boutique" typography identity — half the approved v2 direction — renders as Roboto with nobody noticing until the presentation. Also mid-plan: Phase 1's smoke test on the implementer's networked machine passes, so the risk is never observed before it matters.
- **Evidence:** `FE/pubspec.yaml:17,38-42`; no `GoogleFonts.config.allowRuntimeFetching=false` anywhere in `FE/lib`; no bundled fonts (find across `FE/` excluding `build/`).
- **Suggested fix:** bundle Cormorant + Montserrat TTFs under `FE/assets/fonts/` + pubspec `fonts:` section, and set `GoogleFonts.config.allowRuntimeFetching = false` in `main.dart` (google_fonts then resolves from bundled assets); make this a Phase 1 step with an airplane-mode smoke check in the Phase 1 success criteria.

## Finding 8: Stale code citations baked into phase steps — M2 targets code that no longer exists, product_card has 4 raw radii not 3

- **Severity:** Medium
- **Location:** Phase 5, step 6 + Success Criteria bullet 2; Phase 2, "Related Files" bullet 2 + Success Criteria bullet 2
- **Flaw:** Two plan-cited code facts fail verification at the pinned SHA (this is not drift — HEAD equals the audited SHA):
  1. Phase 5 step 6: "ManagerProfile (inline class): `Colors.grey` → `AppColors.textSecondary` (closes `M2`)." There is **no `Colors.grey` in `manager_shell.dart`** — the profile header was rebuilt as white-on-gradient (`Colors.white.withValues(...)` at `:81,:113,:124,:129`) sometime after the old audit (which cited `manager_shell.dart:79`, per `docs/ux-flow-audit.md:189`). Step 6 is a no-op, the "M2 closed" success criterion is unverifiable as written, and applying the prescribed `textSecondary` substitution to what's actually there (white text on a primary gradient) would be a contrast regression. Also: Phase 5's success criteria list "`M20` closed" but no implementation step mentions M20 (steps cover M2/M6/M19/M34) — it is only implicitly covered by the step-7 sweep, unmapped.
  2. Phase 2 cites "`product_card.dart:38,62,87` — 3 raw `BorderRadius.circular(N)` literals." There are **four**: `:38(16), :62(4), :87(3), :122(3)`. The success criterion says "zero raw literals," which contradicts the cited inventory of 3; an implementer checklisting off the cited lines misses `:122`.
- **Failure scenario:** Phase 5 executor burns time hunting a `Colors.grey` that isn't there, then either marks M2 "closed" without any change (false completion record) or "fixes" the white-on-gradient text to `textSecondary` (visible regression on the manager profile header). Phase 2 executor fixes 3 of 4 radii, the guard doesn't check radii at all, and `product_card.dart:122` ships unmigrated in the plan's flagship shared widget.
- **Evidence:** grep of `manager_shell.dart` (zero `grey` hits; white-on-gradient at `:81-141`); `docs/ux-flow-audit.md:189` (M2's original citation); `product_card.dart:38,62,87,122`; phase-05 success criteria listing M20 with no implementing step.
- **Suggested fix:** re-verify each old-audit bug ID cited as "closes X" against HEAD before its phase starts (add to Phase 0, which already exists for exactly this class of staleness); correct the product_card citation to 4 sites; map M20 to step 7 explicitly or drop it from the criteria.

## Finding 9: The motion spec in the frozen token doc is silently dropped — no phase implements or defers it

- **Severity:** Medium
- **Location:** plan.md "Overview" + "Acceptance Criteria" vs `docs/design-tokens-v2.md` "Motion" section; all cluster phases' implementation steps
- **Flaw:** The plan claims to implement `docs/design-tokens-v2.md`, whose spec includes a Motion section (easeOutCubic entrances, 250-300ms; design-tokens-v2.md:53-55) and whose `rubric-v1` defines a `motion` finding type (`:67`) that Phase 4's gap audit graded against. Yet Phase 1's token table has no motion entries, no motion constant is added to any theme file, and Phases 3-7's per-screen steps cover only colors, TextStyles, and radii (e.g. phase-03 step 2). Any `motion`-type findings in the `phase-04-gap-findings-*.md` checkpoint files have no phase step that closes them — violating plan.md's own acceptance criterion "migrated (or explicitly deferred with reason, not silently dropped)."
- **Failure scenario:** Phase 7 closeout marks all 30 screens migrated; a cross-check of gap findings against the rubric shows open `motion` findings on multiple screens with no deferral note. Either the completion claim is false, or someone retro-fits deferral notes at closeout — the plan's audit trail (its main structural virtue) breaks at the finish line.
- **Evidence:** `docs/design-tokens-v2.md:53-55,67`; phase-01 token table (no motion rows); grep for "motion|duration|curve|ease" across phase-01..07 files returns nothing actionable.
- **Suggested fix:** one explicit sentence in plan.md: "Motion spec is deferred out of this plan's scope; `motion`-type gap findings are recorded as deferred, not closed" — or add motion constants (`AppMotion.entrance = 280ms/easeOutCubic`) to Phase 1 and one line-item per cluster. Either is fine; silence is not.

## Finding 10: Mid-implementation drift handling is a conditional sentence, not a mechanism — on a live team branch over 8.5 days

- **Severity:** Medium
- **Location:** plan.md "Risk Assessment" bullet 1 ("re-run it if implementation spans multiple days"); Phase 7 "Whole-Plan Closeout"
- **Flaw:** Declared effort across phases totals 8.5 days, so "if implementation spans multiple days" is a certainty phrased as a conditional — and no phase step operationalizes the re-run. Between Phase 0 (day 0) and Phase 7's closeout diff (day ~8), teammates can freely push to `dev`: reintroducing hardcodes into clusters already marked "guard passes" (per-cluster criteria are never re-checked), restyling a screen whose Phase 4 findings then describe code that no longer exists, or adding a new screen that the 30-screen inventory never covers. Phase 7's closeout diff will *show* such files, but by then clusters 3-6 are signed off and the discovery cost is maximal. The per-cluster phases contain no "re-diff files in this cluster against last-known state before starting" step.
- **Failure scenario:** Day 4: a teammate hotfixes ProductDetail (Phase 3, already "done") adding `Colors.red` for an urgent badge. Nothing re-runs the guard until Phase 7. Day 8: closeout fails on a cluster completed five days earlier; the fix now requires re-opening a signed-off phase and re-running its manual regression checklist — the most expensive possible time to find it.
- **Evidence:** effort frontmatter totals; phase-03..06 steps (no re-diff step, guard run only at cluster end for that cluster's own work); plan.md risk wording.
- **Suggested fix:** make it mechanical: each cluster phase's step 0 = `git diff <last cluster's end SHA>..HEAD -- FE/lib` scoped to this cluster's files **and** all previously-completed clusters' files, guard re-run included; record the end-of-phase SHA in each phase's completion note so the next phase has a concrete anchor.

---

## Verification Results

**Claims sampled:** 21 behavioral/factual claims traced across phases. **Verified: 14. Verified-with-caveat: 1. Failed: 6.**

| # | Claim (phase) | Result |
|---|---|---|
| 1 | `app_theme.dart` may use `ColorScheme.fromSeed` (P1 hedge/risk) | VERIFIED-resolved — uses explicit `ColorScheme.light(...)`, `app_theme.dart:13-22`; the fromSeed risk item is moot, but note no container/tonal slots defined (see Finding 6) |
| 2 | Theme-file-only edit reskins the 8 shared widgets (P1) | VERIFIED-WITH-CAVEAT — all 8 style via `AppColors.*`/`AppTypography.*`/theme, so constant swaps do reskin them; but 13 palette-neutral `Colors.*` lines remain (`app_button.dart:34,95`; `app_card.dart:38,43`; `app_bottom_nav.dart:29,40,41,47`; `manager_bottom_nav.dart:22,33,34,40`; `product_card.dart:67`) which the guard flags (Finding 3) |
| 3 | `section_header.dart` uses `Theme.of(context)` pattern (P2) | VERIFIED — `section_header.dart:20,25-27` |
| 4 | `size_selector.dart:37-47` solid-fill+white selected state (P2) | VERIFIED — `:38` (`isSelected ? AppColors.primary`), `:47` (`Colors.white`) |
| 5 | `product_card.dart` has 3 raw radii at `:38,62,87` (P2) | **FAILED** — 4 raw radii: `:38,:62,:87,:122` |
| 6 | Cart CTA likely Stack/GestureDetector z-order issue (P0) | **FAILED** — no Stack/GestureDetector in the CTA path; plain `AppButton→Navigator.pushNamed` in bottom Container, `cart_screen.dart:308-357`; selection is local `Set` state `:24` under `BlocBuilder` `:31` |
| 7 | Manager FAB tap swallowed by list item beneath; likely bottom-padding fix (P0/P5) | **FAILED** — FAB is `Scaffold.floatingActionButton` (`manager_product_list_screen.dart:195-214`), hit-tested above body by framework; "item beneath swallows tap" has no mechanism; capture log's "clear space below last card" note (`phase-02-visual-capture-log.md:75`) already ruled out overlap |
| 8 | `manager_shell.dart:55` = `_ManagerProfileScreen` (P5) | VERIFIED |
| 9 | `Colors.grey` in ManagerProfile, closes M2 (P5 step 6) | **FAILED** — zero `Colors.grey` in `manager_shell.dart` at HEAD; header is white-on-gradient (`:81-141`); M2's cited line (ux-flow-audit.md:189 → `:79`) is stale |
| 10 | `admin_shell.dart:83` = `_AdminProfileScreen` (P6) | VERIFIED |
| 11 | Admin bottom nav is inline `NavigationBar`, manager uses shared widget (P6 step 4) | VERIFIED — `admin_shell.dart:47` vs `manager_shell.dart:39` (`ManagerBottomNav`) |
| 12 | `profile_screen.dart:128` links to DeliveryMap (P4) | VERIFIED — `Navigator.pushNamed(context, '/delivery-map')` at `:128` |
| 13 | google_fonts already a dependency; "flutter pub get / asset warm-up" suffices for the font swap (plan.md risk) | Dependency VERIFIED (`pubspec.yaml:17`); mitigation **FAILED** — runtime fetch per device, no bundled fonts (assets = `.env` only, `pubspec.yaml:41-42`), `pub get` downloads nothing (Finding 7) |
| 14 | `flutter test` gates non-vacuous (all phases) | VERIFIED — 13 test files in `FE/test/` (blocs/models/services/widgets); none pin colors/fonts, so Phase 1 won't break them, but they also verify zero visual behavior — the manual regression checklists are the only real visual net |
| 15 | Login debug buttons `kDebugMode`-gated (P7 step 2) | VERIFIED — `login_screen.dart:374,380` |
| 16 | Guard baseline "195 hardcode-hit lines" (P1 step 4) | **FAILED** — script's own scan scope yields 208 at HEAD (195 screens + 13 widgets) |
| 17 | v1 token values in the phase-01 table match current code | VERIFIED — `app_colors.dart:6-20` and `app_spacing.dart:12-16` match the v1 column exactly; file line counts (21/113/17/150) match plan citations exactly |
| 18 | Checkout has 5 widget files; PaymentQr/DeliveryMap/Splash paths (P3/P4/P7) | VERIFIED — all paths exist as cited |
| 19 | White-on-v2-primary 6.70:1 precomputed (P6 step 2) | VERIFIED — `docs/design-tokens-v2.md:16` |
| 20 | Guard script "fails when a new hardcode appears" (P1) | **FAILED** — 6 current hardcodes invisible to it (mixed `AppColors`+`Colors.*` lines); CWD-dependent false pass (Finding 1) |
| 21 | M19 fixed on list screen only, still open on detail/create (P5 steps 3-4) | VERIFIED — `ux-flow-audit.md:224` (P1 ✅, `manager_product_list_screen.dart:46`), `phase-02-visual-capture-log.md:76` confirms detail/create still pink |

**Feeder artifacts:** all 8 cited report files exist in `plans/260710-1158-ui-ux-overhaul-audit-pipeline/reports/`; `docs/design-tokens-v2.md` frozen table matches phase-01's copy exactly.

## Unresolved Questions

1. Do the `phase-04-gap-findings-*.md` checkpoint files contain `motion`-type findings? (Finding 9's severity rises to High if yes — I verified the rubric defines the type, not the per-screen finding counts.)
2. Was the manager-profile header redesign (that removed M2's `Colors.grey`) part of a known plan (`stability-hardening`?), i.e. are other old-audit line citations in `docs/ux-flow-audit.md` equally stale? Phase 0 should sample-check every "closes {ID}" citation, not just the 2 tap-target bugs.
3. Is there any CI at all (`.github/workflows/` not inspected for wiring)? If none, the guard is manual-only, which doubles the weight of Finding 1's false-pass modes.
