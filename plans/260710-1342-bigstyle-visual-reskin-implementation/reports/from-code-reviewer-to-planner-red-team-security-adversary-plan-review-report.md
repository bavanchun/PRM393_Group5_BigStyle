# Red-Team Plan Review — Security Adversary Perspective

**Plan:** `plans/260710-1342-bigstyle-visual-reskin-implementation/` (8 files)
**Reviewed at:** 2026-07-10, HEAD == pinned SHA `6e77ccf` (no drift; all checks run against the exact tree the plan describes)
**Reviewer stance:** hostile fact-check + attacker mindset scoped to what a visual reskin can break or leak.

---

## Finding 1: Phase 2 "fixes" an orphaned widget — the real tonal violations live elsewhere and the plan never reaches them

- **Severity:** Critical
- **Location:** Phase 2, sections "Requirements" and "Related Files"; Phase 3, "Regression Checklist" (ProductDetail line)
- **Flaw:** Phase 2 states `size_selector.dart:37-47` is the "Phase 4 code-confirmed root cause of ProductDetail/CartItemEdit tonal-violation findings." The shared `SizeSelector` widget has **zero consumers** — `grep -rn "SizeSelector" FE/lib` returns only its own definition. ProductDetail renders sizes via its own private inline copy `_buildSizeSelector` (duplicated solid-fill+white code), and CartItemEdit uses a Material `ChoiceChip` whose solid-fill selected state comes from `app_theme.dart`'s `chipTheme.selectedColor: AppColors.primary`. Reworking `size_selector.dart` changes nothing on either screen.
- **Failure scenario:** Phase 2 is executed exactly as written, its success criterion ("size_selector selected state is tonal") passes, phase is marked done. Phase 3's regression checklist then asserts "ProductDetail: size selector (now tonal per Phase 2)" — a change that never happened. Either the migrator rubber-stamps a nonexistent fix, or discovers the miss mid-cluster and improvises unplanned edits to `app_theme.dart`'s `chipTheme` — a theme-file change outside any phase's stated scope, after Phase 1's theme gate already closed. Compounding: ProductDetail's actual violating line is invisible to the Phase 3 hardcode checklist because the guard script excludes it (see Finding 2) — the plan has no remaining mechanism that ever touches it.
- **Evidence:**
  - `FE/lib/widgets/size_selector.dart:1-56` — widget defined; `grep -rn "SizeSelector\|size_selector" FE/lib` shows no import/usage anywhere.
  - `FE/lib/screens/product_detail/product_detail_screen.dart:504` (`_buildSizeSelector`), `:528` (`color: isSelected ? AppColors.primary : AppColors.background`), `:538` (`color: isSelected ? Colors.white : AppColors.textPrimary`) — the real render path, an inline duplicate.
  - `FE/lib/screens/cart/cart_item_edit_screen.dart:239` (`ChoiceChip`) + `FE/lib/config/theme/app_theme.dart:133-136` (`chipTheme: ChipThemeData(... selectedColor: AppColors.primary`) — CartItemEdit's tonal state is theme-driven, not size_selector-driven.
- **Suggested fix:** Rewrite Phase 2's scope: (a) fix ProductDetail's inline `_buildSizeSelector` (ideally replace it with the shared widget so the orphan gains a consumer, or delete the orphan); (b) add a `chipTheme` tonal decision to Phase 1's `app_theme.dart` rewrite (selectedColor → tonal tint per the design-tokens-v2 rule) since `ChoiceChip` consumers inherit it; (c) correct Phase 3's checklist premise.

---

## Finding 2: The hardcode-guard — the plan's only automated enforcement gate — has demonstrated false negatives and fails open

- **Severity:** High
- **Location:** Phase 1, section "New: Hardcode Guard"; Phase 7, success criterion "Hardcode-guard passes repo-wide"
- **Flaw:** Two independent defects in the shipped script:
  1. **`grep -v 'AppColors'` drops entire lines.** Because `Colors\.[A-Za-z]+` also matches the substring inside `AppColors.primary`, the script filters out any line containing "AppColors" — including mixed lines with genuine raw `Colors.*`. Tested against the real tree: **6 live false negatives**, and they include the two tonal-violation lines this plan exists to fix.
  2. **Fail-open on wrong cwd.** The script uses repo-root-relative paths (`FE/lib/screens FE/lib/widgets`) but lives in `FE/scripts/`. Run from `FE/` (the natural cwd for every `flutter` command in this plan), grep errors to stderr, `$hits` is empty, script exits 0 — a clean pass having scanned nothing. Empirically confirmed.
- **Failure scenario:** Phase 7's closeout runs the guard from `FE/`, gets exit 0, and the plan is marked complete while (a) nothing was scanned, or (b) even when run correctly, `Colors.white`/`Colors.grey` remain shipped on Chat, AdminUsers, ManagerProductList, ProductList, ProductDetail, and size_selector. The "guard passes repo-wide" acceptance criterion is satisfiable while the thing it certifies is false — a fail-open verification gate.
- **Evidence (false negatives, plan's exact regex + filter):**
  - `FE/lib/screens/chat/chat_screen.dart:228` — `color: isBot ? AppColors.textPrimary : Colors.white`
  - `FE/lib/screens/admin/admin_users_screen.dart:138` — `isSelected ? Colors.white : AppColors.textSecondary`
  - `FE/lib/screens/manager/products/manager_product_list_screen.dart:457` — `isHidden ? Colors.grey : AppColors.primary`
  - `FE/lib/screens/product_list/product_list_screen.dart:216` — `isSelected ? AppColors.primary : Colors.transparent`
  - `FE/lib/screens/product_detail/product_detail_screen.dart:538` — the Finding-1 tonal line
  - `FE/lib/widgets/size_selector.dart:47` — the exact line Phase 2 cites as its target
  - Fail-open: `cd FE && <script body>` → "GUARD PASSES SILENTLY (exit 0)" (reproduced during review).
- **Suggested fix:** Match `(^|[^A-Za-z])Colors\.` (or `grep -P '\bColors\.'` — `AppColors` has no word boundary before `C`) instead of post-filtering with `-v AppColors`; anchor paths via `cd "$(dirname "$0")/.."`; `set -euo pipefail` plus an explicit existence check on the scan dirs so a missing dir is a hard failure, not a pass.

---

## Finding 3: Internal contradiction — Phase 7 requires a repo-wide guard pass over files that Phase 2 explicitly forbids touching and that no cluster phase owns

- **Severity:** High
- **Location:** Phase 2, "Requirements" ("no other shared widget touched"); Phase 7, success criterion "hardcode-guard passes repo-wide... all of FE/lib/screens + FE/lib/widgets"; Phase 5, screens table (missing companion files)
- **Flaw:** The guard (as written) flags 13 lines across the "other 8" shared widgets — `manager_bottom_nav` (4), `app_bottom_nav` (4), `app_card` (2), `app_button` (2), `product_card:67` — which Phase 2's non-functional requirement says must not be touched, and which Phase 1 declares "fully token-driven" and already-covered. Additionally, three manager product-form companion files exist under `FE/lib/screens/manager/` with real violations (`Colors.red`, `Colors.grey`, `Colors.black`) but appear in **no cluster phase's screen table** — Phase 5's per-file checklist enumerates only the 3 top-level product screens (28/20/18 lines).
- **Failure scenario:** Phases 1-6 complete per spec. Phase 7's final criterion runs the (corrected) guard and fails on 16 lines that no phase was authorized to fix. The implementer either violates Phase 2's no-touch constraint ad hoc at the last minute (untested widget edits after all cluster QA passed — shadow/splash `Colors.transparent`/`Colors.black` lines are behavioral, not just cosmetic), or weakens the guard with exclusions to force a green gate. Either path invalidates the plan's own acceptance story.
- **Evidence:**
  - `FE/lib/widgets/manager_bottom_nav.dart:22,33,34,40`; `FE/lib/widgets/app_bottom_nav.dart:29,40,41,47`; `FE/lib/widgets/app_card.dart:38,43`; `FE/lib/widgets/app_button.dart:34,95`; `FE/lib/widgets/product_card.dart:67` — all match the guard regex, none owned by any phase's fix scope.
  - Unowned screen-tree files with violations: `FE/lib/screens/manager/products/widgets/manager_product_variants_table.dart:171` (`Colors.red`), `FE/lib/screens/manager/products/widgets/manager_product_variant_table_cells.dart:95` (`Colors.grey`), `:149` (`Colors.black`). Also unlisted: `FE/lib/screens/manager/order_status_update_sheet.dart`, `FE/lib/screens/manager/products/form/manager_product_variant_form_row.dart` — the first is the exact surface of the "recently-verified, do-not-regress" order-status flow Phase 5's risk note protects.
  - Phase 5's own baseline arithmetic already includes these files: the verified 78-line manager total is a directory-wide count; the enumerated per-screen checklist sums to less.
- **Suggested fix:** Either (a) give the guard an explicit, documented allowlist for intentional non-token colors (`Colors.transparent`, shadow blacks) and add the companion files + widget cleanup to a named phase, or (b) scope Phase 7's criterion to "cluster-owned files at 0, allowlisted exceptions documented." Do not leave "repo-wide zero" colliding with "don't touch the other 8 widgets."

---

## Finding 4: Typography bypass blind spot — `product_card.dart` ships with the old font after every phase completes, and the guard cannot see it

- **Severity:** High
- **Location:** Phase 1, "Overview" ("theme-file-only edit already reskins 8 of the 10 shared widgets") + "New: Hardcode Guard" (regex covers colors only); Phase 2, "Requirements" (product_card scope = radii only)
- **Flaw:** `product_card.dart` calls `GoogleFonts.dmSans(...)` directly 5 times, bypassing `AppTypography` entirely. Phase 1 swaps fonts only inside `app_typography.dart`; Phase 2's product_card scope is exclusively "radii reference AppSpacing constants." No cluster phase owns shared widgets. The project's own frozen rubric (`docs/design-tokens-v2.md:64`) explicitly classifies "GoogleFonts.playfairDisplay/dmSans literal calls" as violations — yet the plan's enforcement script detects only `Colors.*`/`0xFF`, so this violation class is invisible to the gate. Bonus factual error: Phase 2 claims exactly 3 raw radii in product_card (`:38,62,87`); there is a 4th at `:122`.
- **Failure scenario:** Plan completes green. Every product card — the single most demo-visible component, rendered on Home, ProductList, and Favorites — displays DM Sans product names/prices while the rest of the app renders Montserrat. The mixed-typography result contradicts the plan's core deliverable, passes `flutter analyze`, `flutter test`, and the hardcode guard, and is only catchable by a human eyeballing font shapes. Same latent risk on `login_screen.dart` (3 direct calls) and `product_detail_screen.dart` (3 direct calls) if cluster implementers read "swap inline TextStyles" narrowly.
- **Evidence:**
  - `FE/lib/widgets/product_card.dart:91,103,140,152,174` — direct `GoogleFonts.dmSans(` calls; `:66-71,126-130` — inline `TextStyle(...)`; `:122` — 4th `BorderRadius.circular(3)` missing from Phase 2's enumeration.
  - `docs/design-tokens-v2.md:64` — rubric row: typography violation = "GoogleFonts.playfairDisplay/dmSans literal calls."
  - Direct-call census: `grep -rn "GoogleFonts\." FE/lib | grep -v app_typography` → product_card (5), login_screen (3), product_detail_screen (3).
- **Suggested fix:** Add product_card's font + inline-TextStyle migration to Phase 2's requirements; extend the guard regex with `GoogleFonts\.(playfairDisplay|dmSans)` (post-swap, any literal of the OLD families is per-se a violation and zero-false-positive); correct the radii enumeration to 4.

---

## Finding 5: The plan institutionalizes a shared live-admin password across its entire QA lifecycle with no rotation or disable step at closeout

- **Severity:** High
- **Location:** Phase 0, step 6 (delta-recapture); Phase 3, "Pre-condition"; Phase 5, "Pre-condition"; Phase 6, "Risk Assessment" (dart-define admin technique); Phase 7, "Whole-Plan Closeout" (omission)
- **Flaw:** The audit pipeline this plan builds on reset the 3 QA accounts' Supabase Auth passwords — **including the admin account** — to a single shared value via direct SQL against `auth.users.encrypted_password` on the live `bigstyle-prm393` project. The committed capture log documents the technique, the alias scheme (`+admin`, `+manager`, `+customer2`), and that admin is reachable via the manager dart-define slot. This reskin plan schedules repeated use of that credential path across ~7+ days (Phase 0 recapture, Phase 3/5 pre-condition captures, Phase 6's per-screen QA which explicitly cites the technique), and Phase 7's closeout checklist contains only diff/nav checks — **no step to rotate, expire, or disable the shared password when QA ends.**
- **Failure scenario:** The repo is public-facing coursework; git author email is in every commit, so the admin alias (`<author>+admin@gmail.com`) is derivable by anyone reading the repo, and the capture log tells them password-grant auth is enabled for it and shared across three roles. The plan's structure guarantees this credential stays valid for the full implementation window and — because no closeout step exists — indefinitely after. One leaked/shoulder-surfed/`.zsh_history`-scraped shared password = admin on the live Supabase project (user PII, order data, product catalog write access). Secondary vector: Phase 6 instructs pointing `BIGSTYLE_TEST_MANAGER_EMAIL/PASSWORD` at the admin account; a teammate persisting that into a committed `launch.json`/run-config would leak the credential outright (none committed today — verified — but the plan creates the recurring temptation and never warns against it).
- **Evidence:**
  - `plans/260710-1158-ui-ux-overhaul-audit-pipeline/reports/phase-02-visual-capture-log.md:13` — documents shared-password SQL reset, alias scheme, live project name, and admin-via-manager-slot technique (committed to the repo).
  - `FE/lib/screens/auth/login_screen.dart:21-31` — dart-define slots; `:373-378` — the only gate.
  - `FE/README.md:30-33` — documents the exact `--dart-define` invocation shape for teammates to copy.
  - `phase-06-admin-cluster.md`, Risk Assessment — plan text directing reuse of the technique; `phase-07-auth-guest-cluster.md`, "Whole-Plan Closeout" — 3 items, zero credential hygiene.
- **Suggested fix:** Add a mandatory Phase 7 closeout item: rotate the QA accounts' passwords (or null the admin alias's password grant) after the final QA pass, and per-role distinct passwords if password QA continues. Add one line to each pre-condition using the technique: "dart-define values live only in shell invocation, never in committed run configs."

---

## Finding 6: Phase 7 declares the debug test-login surface "zero risk" while sweeping 18 hardcode lines through the same file, with no release-gate verification

- **Severity:** Medium
- **Location:** Phase 7, step 2 and "Regression Checklist"
- **Flaw:** The claim "these carry zero risk to the production visual surface" is true **today** because of one 6-line getter: `_hasDebugTestLogin` (`kDebugMode && creds-non-empty`) guarding the collection-if at the call site. Phase 7 step 1 rewrites 18 hardcode lines in this exact file and step 2 explicitly restyles `_buildDebugTestLoginButtons` — one of the hardcoded literals sits at `login_screen.dart:362` in the adjacent widget code. The regression checklist verifies only that the buttons "function identically (dev only)" — i.e., it tests debug-mode presence, never release-mode **absence**, and no criterion pins the gate itself.
- **Failure scenario:** During the sweep, the widget list around `login_screen.dart:116-119` is restructured (a plausible byproduct of retheming the column) and the `if (_hasDebugTestLogin)` collection-if is dropped or replaced with the per-button `isNotEmpty` checks that already exist inside `_buildDebugTestLoginButtons` (which do NOT check `kDebugMode`). Debug analysis stays clean, dev QA passes (buttons still show in debug), the checklist is satisfied. Any subsequent release/profile build launched with the README-documented dart-defines now ships one-tap manager/admin login in a distributable APK — precisely the class of silent gate erosion a visual-only sweep can cause.
- **Evidence:**
  - `FE/lib/screens/auth/login_screen.dart:373-378` — `_hasDebugTestLogin` getter (sole `kDebugMode` reference); `:116-119` — guarded call site; `:384-414` — per-button conditions check only credential non-emptiness, not `kDebugMode`; `:362` — `Color(0xFF2D2D2D)` literal in adjacent widget code targeted by the sweep.
  - `FE/README.md:30-33` — team-documented dart-define invocation.
- **Suggested fix:** Add to Phase 7's success criteria: "diff shows `_hasDebugTestLogin` and its call-site guard unchanged" (cheap, greppable), or a one-time `flutter build apk --release` + assert-buttons-absent check.

---

## Finding 7: Phase 1's cited baseline (195) contradicts what the plan's own script measures at the pinned SHA (208)

- **Severity:** Medium
- **Location:** Phase 1, step 4 ("195 hardcode-hit lines per Phase 1 audit recount")
- **Flaw:** Running the phase's exact script logic at HEAD — which **is** the pinned audit SHA, so drift is excluded as an explanation — yields **208** lines, not 195. Every per-file count the plan cites elsewhere matches the script perfectly (ProductDetail 7, Home 8, ProductList 8, MPL 28, MPD 20, MCP 18, Login 18, Splash 7, EditProfile 4, Chat 7, DeliveryMap 14, AdminDashboard 12, AdminUsers 5, AdminCategories 5, manager cluster exactly 78), so the audit's 195 total was computed with a different aggregation than the tool this plan ships as its enforcement gate.
- **Failure scenario:** Phase 1 step 4 says to "document the current baseline count." The implementer records 208, sees it disagree with the phase file's 195, and — since Phase 0 will have just reported zero drift — has no sanctioned explanation. Best case: wasted re-audit time. Worst case: "the numbers are approximate anyway" becomes the norm, and downstream numeric criteria (Phase 5's "baseline ~78 drops to 0") lose their teeth because nobody trusts the arithmetic that defines done.
- **Evidence:** Plan's exact pipeline (`grep -rn --include="*.dart" -E 'Colors\.[A-Za-z]+|0xFF[0-9A-Fa-f]{6}' FE/lib/screens FE/lib/widgets | grep -v 'AppColors'`) → 208 at `6e77ccf`; phase-01 file line "195 hardcode-hit lines per Phase 1 audit recount"; per-file counts independently reproduced and matching.
- **Suggested fix:** Replace "195" with "the number the script itself prints on first run — record it as the baseline"; numeric criteria in later phases should reference the script's output, not prose constants.

---

## Verification Results

**Claims sampled: 29 · Verified: 25 · Failed: 3 · Partially verified: 1**

Verified (file:line):
1. `app_colors.dart` = 21 lines, 14 constants, all v1 hex values match plan table — `FE/lib/config/theme/app_colors.dart:6-20`
2. `app_spacing.dart` = 17 lines, radii 16/12/24/12/20, spacing scale 4-48 — `app_spacing.dart:4-16`
3. `app_typography.dart` = 113 lines; `app_theme.dart` = 150 lines — `wc -l` exact match
4. `app_theme.dart` uses explicit `ColorScheme.light(`, not `fromSeed` — `app_theme.dart:13` (plan's conditional risk note is correctly hedged)
5. `size_selector.dart:37-47` solid-fill+white selected state — `:37,:47` exact
6. `product_card.dart:38,62,87` radii literals 16/4/3 — exact (but see Failed #3)
7. `section_header.dart` uses `Theme.of(context)`, no `AppColors` — `:20,:26-27`
8. All 10 shared widgets exist; the "8 token-driven" names all present in `FE/lib/widgets/`
9. `manager_shell.dart:55` = `_ManagerProfileScreen` — exact
10. `admin_shell.dart:83` = `_AdminProfileScreen` — exact
11. `profile_screen.dart:128` = `/delivery-map` push — exact
12. `manager_product_list_screen.dart` FAB block at 195-212 (plan cites 196-207/195-230) — verified
13. All 14 sampled per-file hardcode counts match the script (7/8/8/28/20/18/18/7/4/7/14/12/5/5)
14. Manager cluster hardcode total = exactly 78 (plan: "~78")
15. `admin_users_screen.dart` = 671 LOC — exact
16. Admin shell inline `NavigationBar` + `indicatorColor` — `admin_shell.dart:47,52`; manager uses shared `ManagerBottomNav` — `manager_shell.dart:39`
17. `checkout/widgets/` = exactly 5 files
18. `docs/design-tokens-v2.md` v2 hex values, 6.70:1 white-on-primary, tonal-badge rule, Cormorant/Montserrat — `:16-38`
19. `google_fonts: ^6.2.1` — `FE/pubspec.yaml:17`
20. `.withOpacity` = 0 repo-wide — plan.md's "already done" claim correct
21. `kDebugMode` gating + dart-defines — `login_screen.dart:21-31,116-119,373-378`
22. `otp_input.dart` exists at `FE/lib/screens/auth/otp_input.dart`
23. All 4 `phase-04-gap-findings-*.md` + capture log + its "Findings Surfaced During Capture" section exist — capture-log `:72-75`
24. `docs/audit-assets/` gitignored — `.gitignore:5-6`
25. `admin-smoke-baseline.md` exists; contains no password ("No password is stored in this report", `:20`); M2/M6/M12/M19/M20/M21/M28/M34/C30/C42/C45/G16 all present in `docs/ux-flow-audit.md`; "Xin chào!" at `home_screen.dart:226`; splash session-routing at `splash_screen.dart:37-68`; `app_router.dart` at `FE/lib/config/routes/`

Failed:
1. **Phase 2 root-cause claim** — `SizeSelector` has zero consumers; ProductDetail uses inline duplicate (`product_detail_screen.dart:504-545`), CartItemEdit uses `ChoiceChip` + `chipTheme` (`cart_item_edit_screen.dart:239`, `app_theme.dart:135`). → Finding 1
2. **Phase 1 "195 hardcode-hit lines"** — plan's own script yields 208 at the pinned SHA. → Finding 7
3. **Phase 2 "3 raw radii" in product_card** — there are 4 (`product_card.dart:122`). → Finding 4

Partially verified:
1. **Phase 1 "8 of 10 shared widgets fully token-driven"** — token-driven for colors they *do* reference, but 4 of the 8 contain 12 raw `Colors.*` lines the guard flags, colliding with Phase 2's no-touch rule and Phase 7's repo-wide-pass criterion. → Finding 3

## Unresolved Questions

1. Are the widget-level `Colors.transparent` / shadow-black usages (Finding 3) *intended* to be guard-exempt? The design-tokens rubric doesn't say; the guard's allowlist policy needs an explicit decision.
2. Does the audit's "195" figure come from a screens-only count or a different filter? Worth one line in Phase 1 clarifying provenance so the 208 doesn't read as drift.
3. Is password-grant auth on the QA admin alias intended to persist beyond this plan (i.e., is it now the team's permanent QA mechanism)? The rotation recommendation in Finding 5 depends on that product decision.
