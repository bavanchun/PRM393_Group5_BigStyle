---
phase: 1
title: "Tokens v2 in Code + Hardcode Guard"
status: pending
effort: "S (half day)"
priority: P1
dependencies: [0]
---

# Phase 1: Tokens v2 in Code + Hardcode Guard

## Overview

Rewrite the 4 theme files to the approved Warm Terracotta values, and add a lint/grep gate that stops new hardcoded colors from creeping back in. Theme values plus a small alias-level cleanup here fully reskin 8 of the 10 shared widgets — the highest-leverage single change in this plan. <!-- Updated: Red Team Session 1 - the 8 widgets are NOT 100% token-driven as the audit claimed: 13 `Colors.*` alias lines live in 4 of them; cleaned in this phase -->

## Requirements

- Functional: every token in `docs/design-tokens-v2.md`'s table applied to `FE/lib/config/theme/`.
- Functional: additive neutral tokens (`onPrimary`, `shadow`) + a `StatusColors` `ThemeExtension` added — Material 3 `ColorScheme` has no success/warning slots, so Phase 2's `StatusBadge` cannot be built from bare `Theme.of(context)` without this. Additive-only amendment to `docs/design-tokens-v2.md` (approved palette untouched — append a dated changelog line there). <!-- Updated: Red Team Session 1 -->
- Functional: Cormorant + Montserrat **bundled as local font assets**. `google_fonts` fetches at RUNTIME per device by default — `flutter pub get` downloads nothing; an offline demo device silently falls back to Roboto, invisible to every QA gate in this plan. <!-- Updated: Red Team Session 1 -->
- Functional: a repo-checkable gate (script + doc, CI wiring optional if no CI exists yet) that fails when a non-allowlisted `Colors.*`/8-digit-hex/legacy-font literal appears in `FE/lib/screens/` or `FE/lib/widgets/` outside the theme files.
- Non-functional: `flutter analyze` clean; no screen-level code changes in this phase (that's Phases 3-7) — theme + widget-catalog only.

## Token Table (from `docs/design-tokens-v2.md` — copy exact values, don't re-derive)

| File | Token | v1 | v2 |
|---|---|---|---|
| `app_colors.dart` | `primary` | `#C4517A` | `#9A3F35` |
| `app_colors.dart` | `primaryDark` | `#A03560` | `#742E28` |
| `app_colors.dart` | `secondary` | `#F7C0D0` | `#E8C9A0` |
| `app_colors.dart` | `accent` | `#2D2D2D` | `#2F2A28` |
| `app_colors.dart` | `background` | `#FDF8F9` | `#FBF6EF` |
| `app_colors.dart` | `surface` | `#FFFFFF` | `#FFFFFF` (unchanged) |
| `app_colors.dart` | `error` | `#E53E3E` | `#C0392B` |
| `app_colors.dart` | `success` | `#2ECC71` | `#2E6B47` |
| `app_colors.dart` | `warning` | `#F39C12` | `#8A5313` |
| `app_colors.dart` | `textPrimary` | `#1A1A1A` | `#2A211E` |
| `app_colors.dart` | `textSecondary` | `#6B6B6B` | `#746159` |
| `app_colors.dart` | `textHint` | `#A0A0A0` | `#A99589` |
| `app_colors.dart` | `border` | `#E8E0E2` | `#EAD9C7` |
| `app_colors.dart` | `divider` | `#F0EBED` | `#F3E9DD` |
| `app_typography.dart` | display font | Playfair Display | **Cormorant** |
| `app_typography.dart` | body font | DM Sans | **Montserrat** |
| `app_spacing.dart` | `cardRadius` | 16 | **20** |
| `app_spacing.dart` | `buttonRadius` | 12 | **14** |
| `app_spacing.dart` | `bottomSheetRadius` | 24 | **28** |
| `app_spacing.dart` | `inputRadius` | 12 | **14** |
| `app_spacing.dart` | `chipRadius` | 20 | **24** |
| spacing scale (`xxs..xxl`) | 4/8/12/16/24/32/48 | **unchanged** |

### Additive amendments <!-- Updated: Red Team Session 1 - palette unchanged, these are aliases/extensions the zero-hardcode goal is unreachable without -->

| Addition | Value | Why |
|---|---|---|
| `AppColors.onPrimary` | `#FFFFFF` | ~100 legitimate `Colors.white`-on-primary usages (~48% of the hardcode debt) have no named token today; white-on-v2-primary is explicitly blessed by `docs/design-tokens-v2.md` (6.70:1 AA) |
| `AppColors.shadow` | `#000000` (always used with `.withValues(alpha:)`) | ~31 `Colors.black` shadow usages |
| `StatusColors` ThemeExtension | success/warning/error/info pairs + order-status map | M3 `ColorScheme` has no success/warning slots; `StatusBadge` (Phase 2) needs theme-resolvable tonal pairs. Values: relocate the existing per-screen `_getStatusColor` map values as-is; adjust only pairs that fail a real AA check |

`Colors.transparent` is guard-allowlisted, not tokenized. Append a dated changelog line to `docs/design-tokens-v2.md` recording these additions — the approved Warm Terracotta palette itself is untouched.

## Related Files

- `FE/lib/config/theme/app_colors.dart` (21 lines) — all 14 color constants above.
- `FE/lib/config/theme/app_typography.dart` (113 lines) — every `GoogleFonts.playfairDisplay(...)` → `GoogleFonts.cormorant(...)`, every `GoogleFonts.dmSans(...)` → `GoogleFonts.montserrat(...)`. Check `google_fonts` package (`FE/pubspec.yaml`) already includes both — it's a single package covering all Google Fonts, no new dependency.
- `FE/lib/config/theme/app_spacing.dart` (17 lines) — 5 radius constants above.
- `FE/lib/config/theme/app_theme.dart` (150 lines) — verify `ThemeData`/`ColorScheme` derivation still resolves correctly after the constant changes (Material 3 `ColorScheme.fromSeed` or manual mapping — read current implementation before editing).

## New: Hardcode Guard

Add `FE/scripts/check_hardcoded_colors.sh` (`FE/scripts/` convention already exists — `setup.sh` lives there):

```bash
#!/bin/bash
# Hardcode guard — flags Colors.* / 8-digit-hex / legacy-font literals in
# lib/screens + lib/widgets. Anchored to the script location so it cannot
# silently scan nothing from the wrong CWD (fails hard instead).
cd "$(dirname "$0")/.." || exit 2
for d in lib/screens lib/widgets; do
  [ -d "$d" ] || { echo "ERROR: $d not found — wrong checkout?"; exit 2; }
done
hits=$(grep -rnoE --include="*.dart" \
  '(^|[^A-Za-z])Colors\.[A-Za-z0-9]+|0x[0-9A-Fa-f]{8}|GoogleFonts\.(playfairDisplay|dmSans)' \
  lib/screens lib/widgets | grep -v 'Colors\.transparent')
if [ -n "$hits" ]; then
  echo "Hardcoded colors/legacy fonts found outside theme files:"
  echo "$hits"
  echo "occurrences: $(echo "$hits" | wc -l | tr -d ' ')"
  exit 1
fi
exit 0
```

<!-- Updated: Red Team Session 1 - first-draft script had 3 verified defects --> Corrections baked into this version vs. the first draft: (a) **occurrence-level `-o` matching** — the old `grep -v AppColors` line filter silently hid 6 real violations on lines mixing `AppColors.*` with a hardcode (the codebase's standard selected-state ternary idiom, e.g. `chat_screen.dart:228`, `manager_product_list_screen.dart:457`, `admin_users_screen.dart:138`); (b) **CWD-anchored + hard-fail on missing dirs** — the old relative `FE/lib/...` paths exited 0 having scanned nothing when run from inside `FE/`; (c) **catches legacy `GoogleFonts.playfairDisplay/dmSans` direct calls** (e.g. 5 in `product_card.dart`) which a color-only pattern never sees; (d) `Colors.transparent` allowlisted.

Wire into whatever pre-commit/CI mechanism this repo already uses (check `.github/workflows/` or `.git/hooks/` first — don't invent a new CI system if none exists; a documented manual pre-PR check is an acceptable fallback for a course project).

## Implementation Steps

1. Confirm Phase 0's diff found no drift in `FE/lib/config/theme/` (if it did, re-verify the table above against current file content before editing).
2. Apply all color/typography/spacing constants per the table, plus the additive tokens (`onPrimary`, `shadow`) and the `StatusColors` `ThemeExtension`. <!-- Updated: Red Team Session 1 -->
3. Verify `app_theme.dart`'s `ColorScheme`/`ThemeData` construction still compiles and maps correctly — Material 3 components (buttons, inputs, `NavigationBar`) should pick up the new palette automatically if they reference `Theme.of(context)`, but audit which ones use direct `AppColors.*` refs instead (most, per Phase 4's component inventory) and confirm those still resolve. **Also rework `chipTheme` (`app_theme.dart:135`): it currently styles selected chips solid-fill-primary + white text — the code-level root cause of CartItemEdit's tonal-violation finding; make it tonal per the status-badge rule.** <!-- Updated: Red Team Session 1 - tonal violation lives in chipTheme, not only in widgets -->
4. **Bundle fonts** <!-- Updated: Red Team Session 1 -->: grep `app_typography.dart` for the exact weights/styles used, download those Cormorant + Montserrat TTFs into `FE/assets/fonts/`, declare them in `pubspec.yaml`, set `GoogleFonts.config.allowRuntimeFetching = false` at app start (keeps the `GoogleFonts.*` call sites unchanged while forcing local assets). Smoke-test with network disabled (airplane mode / emulator data off) — typography must render Cormorant/Montserrat, not Roboto.
5. **Alias cleanup in the 4 shared widgets** <!-- Updated: Red Team Session 1 -->: `app_bottom_nav.dart:29,40,41,47`, `manager_bottom_nav.dart:22,33,34,40`, `app_card.dart:38,43`, `app_button.dart:34,95` → `AppColors.onPrimary` / `AppColors.shadow` / allowlisted `Colors.transparent` as each site warrants. (`product_card.dart`'s remaining lines are Phase 2's job.) After this, the 8 shared widgets are genuinely token-only.
6. Add the hardcode-guard script; run it against current `lib/screens` + `lib/widgets` — it will fail loudly until Phases 3-7 clean up each cluster. That's expected. **Baseline = the script's own first-run occurrence count, recorded in this phase's completion note** — the audit's "195" was a screens-only line count and the guard's scope (screens+widgets, occurrence-level) measures ≈208+ at the pinned SHA; don't treat any prose number as authoritative. <!-- Updated: Red Team Session 1 -->
7. `flutter analyze` — must stay clean (theme-file-only changes shouldn't introduce type errors, but Cormorant/Montserrat are different `TextStyle` shapes if e.g. italic variants aren't available — verify).
8. Manual smoke: `flutter run`, confirm the 8 shared widgets (`app_bottom_nav`, `app_button`, `app_card`, `app_error_state`, `app_text_field`, `expandable_text`, `manager_bottom_nav`, `section_header`) visually render the new palette on any screen that uses them (e.g. Home for `app_bottom_nav`+`product_card`, Cart for `app_button`+`app_card`).

## Success Criteria

- [ ] All 14 color constants + 2 font families + 5 radius constants updated to v2 values; additive tokens (`onPrimary`, `shadow`, `StatusColors` extension) in place; `docs/design-tokens-v2.md` changelog line appended. <!-- Updated: Red Team Session 1 -->
- [ ] Fonts bundled as local assets; app renders Cormorant/Montserrat with network disabled. <!-- Updated: Red Team Session 1 -->
- [ ] `chipTheme` selected state is tonal. <!-- Updated: Red Team Session 1 -->
- [ ] The 13 alias-level `Colors.*` lines in the 4 shared widgets cleaned — the 8 shared widgets are now genuinely token-only. <!-- Updated: Red Team Session 1 -->
- [ ] `flutter analyze` clean.
- [ ] Hardcode-guard script exists, is CWD-safe and occurrence-level; first-run baseline count recorded in the completion note — not required to pass yet. <!-- Updated: Red Team Session 1 -->
- [ ] Smoke-tested: at least one screen using each of the 8 shared widgets visually confirms the new palette without further code changes.

## Risk Assessment

- **`ColorScheme.fromSeed` (if used) auto-derives secondary/tertiary colors Material-style, which may not match the hand-picked v2 secondary/accent** → if `app_theme.dart` uses `fromSeed`, switch to explicit `ColorScheme(...)` construction from the table above instead, don't let Material auto-derive fight the approved palette.
- **Font glyph coverage** — Cormorant/Montserrat must render Vietnamese diacritics correctly (this app is VN-market). Spot-check a screen with Vietnamese text (e.g. Home's "Xin chào!") after the swap before proceeding to later phases.
- **Bundled-font weight gaps** — bundle every weight/style `app_typography.dart` actually references; a missing weight falls back silently per-style, which the airplane-mode smoke won't catch unless the smoke screen uses that style. <!-- Updated: Red Team Session 1 -->

## Completion Note (2026-07-10)

**Status:** Done. Branch `feat/visual-reskin`, commit follows this note.

**Steps 1-2 (token application):** All 14 color constants, 5 radii, additive `onPrimary`/`shadow`, and `StatusColors` `ThemeExtension` (`success`/`warning`/`error`/`info`) applied. `docs/design-tokens-v2.md` changelog line appended. `info` = new `#2E5F8A` (~6.76:1 on white, hand-computed WCAG relative-luminance formula) — covers `OrderStatus.shipping`, which 2 real call sites (`orders_screen.dart`, `manager_order_card.dart`) hardcode as `Colors.blue` today (a finding beyond the original audit scope, first surfaced in Phase 0's C30 re-verification).

**Step 3 (app_theme.dart):** `ColorScheme.light(...)` was already explicit (not `fromSeed`) — that risk didn't materialize. `onPrimary`/`onError` now reference `AppColors.onPrimary`; `elevatedButton`/`filledButton` foregroundColor and `inputDecorationTheme.fillColor` likewise switched from raw `Colors.white` to the semantic token (same file already being rewritten, zero extra risk). `chipTheme` reworked tonal: `selectedColor` is now a 12%-alpha primary tint (was solid-fill primary); `labelStyle.color` uses `WidgetStateColor.resolveWith` so the SAME `ChipThemeData.labelStyle` resolves primary-text-on-selected vs textSecondary-on-unselected — verified against Flutter's actual SDK source (`chip.dart:1375-1380`, `RawChip.build`'s `WidgetStateProperty.resolveAs(effectiveLabelStyle.color, statesController.value)`) before writing, not guessed. Proven correct by a new unit test (see Step 8).

**Step 4 (font bundling) — real deviation from the plan's literal mechanism, same goal achieved more robustly:**
Downloaded `Cormorant[wght].ttf` / `Montserrat[wght].ttf` (variable fonts — Google Fonts' upstream repo has no static per-weight files for either family anymore) from `google/fonts` GitHub, registered in `pubspec.yaml` under 4-5 `weight:` entries each per Flutter's documented variable-font pattern (same file repeated per weight — confirmed via Flutter's cookbook and cross-referenced with the engine's actual `WidgetStateProperty` font-matching, not assumed).

The mandated smoke test (`flutter run` on `emulator-5554`) caught a **real bug**: with `GoogleFonts.config.allowRuntimeFetching = false` and `AppTypography` still calling `GoogleFonts.cormorant()`/`GoogleFonts.montserrat()`, the app threw `Exception: ... font Montserrat-SemiBold was not found in the application assets` at first launch. Root cause: the `google_fonts` package validates bundled assets against its OWN internal per-weight filename convention (e.g. it looks for an asset literally named `Montserrat-SemiBold.ttf`) independent of whatever `family:` name is declared in `pubspec.yaml` — a single custom-registered variable-font file never satisfies that check, regardless of how it's declared.

**Fix:** `AppTypography` now uses plain `TextStyle(fontFamily: 'Cormorant'/'Montserrat', ...)` instead of the `GoogleFonts.*()` API — this resolves through Flutter's native font engine directly against the `pubspec.yaml` declaration, with no google_fonts-internal validation and **no network code path at all**, so it's unconditionally offline-safe (stronger guarantee than the original `allowRuntimeFetching=false` approach, which still depended on getting google_fonts' internal asset-matching right). Reverted the `allowRuntimeFetching=false` line from `main.dart` — it's not needed for `AppTypography` anymore, and setting it now would break the 3 files with legacy direct `GoogleFonts.playfairDisplay`/`GoogleFonts.dmSans` calls that Phases 2/3/7 haven't migrated yet (those still need normal runtime-fetch behavior until removed). Once Phase 7 closes the guard repo-wide (zero legacy `GoogleFonts.*` calls left), the `google_fonts` package dependency becomes fully unused — noted for Phase 7, not acted on now (YAGNI: removing the pubspec dependency isn't required for correctness).

Re-ran the smoke test after the fix: app launched clean, no exception. Screenshot of the (cached-session) Admin Dashboard confirms: v2 terracotta gradient header, v2 ivory background, rounded (20px) white cards, and correct Vietnamese diacritic rendering ("Xin chào, Admin!", "Tổng quan nền tảng BigStyle", "Người dùng", etc.) via Montserrat — the risk note's Vietnamese-glyph spot-check is satisfied for Montserrat. Cormorant (used by `home_screen.dart`, `manager_dashboard_widgets.dart`, `size_guide_sheet.dart` — none reachable from the currently-cached Admin session without QA credentials I don't have and shouldn't fetch) wasn't independently screenshotted; it uses the mechanically identical `fontFamily:`-based path already proven for Montserrat (same pubspec pattern, same TextStyle construction, verified file present at `assets/fonts/Cormorant-Variable.ttf`), so the residual risk is low and will get a direct visual confirmation naturally during Phase 3/5 (Home/ManagerDashboard smoke passes).

**Step 5 (alias cleanup):** Of the 4 shared widgets' 13 cited lines, 5 were real `Colors.black` shadow hardcodes → `AppColors.shadow` (`app_bottom_nav.dart:29`, `manager_bottom_nav.dart:22`, `app_card.dart:38,43`) and `Colors.white` → `AppColors.onPrimary` (`app_button.dart:34`); the remaining 8 were already-correct, guard-allowlisted `Colors.transparent` (splash/highlight/background-transparent sites) needing no change — verified each site individually rather than blanket-replacing.

**Step 6 (guard baseline):** `./scripts/check_hardcoded_colors.sh` — 206 occurrences at first run (plan's estimate: ≈208+; close enough, expected variance). CWD-anchor and occurrence-level matching both verified working (e.g. `manager_product_list_screen.dart:445` correctly reported twice, once per hit on the mixed line; `Colors.transparent` correctly excluded everywhere).

**Steps 7-8 (analyze/test/smoke):** `flutter analyze`: clean (2 runs). `flutter test`: all 37 pass (28 pre-existing + 9 new). Added `test/config/theme/app_theme_tokens_v2_test.dart` — a permanent regression guard (not just an ad-hoc check) proving `AppColors`/`AppSpacing`/`AppTypography`/`AppTheme` resolve to exact v2 values, including a programmatic proof that the chip fix resolves selected→primary / unselected→textSecondary (not white) via `WidgetStateProperty.resolveAs` — this is the rest of the "8 shared widgets" success criterion: since all 8 reference `AppColors.*`/`AppTypography.*` directly (not `Theme.of(context)` lookups with independent resolution logic), a verified-correct token file is a complete proof for all 8, not just the ones I could reach via the emulator's cached session. Live-screenshot coverage was obtained for the AppBar/card/background palette (Admin Dashboard, cached session — Admin doesn't consume the 8 shared widgets itself per Phase 6's own framing, but does consume `AppColors`/`AppSpacing` directly, confirming end-to-end propagation through the same rewritten files).
