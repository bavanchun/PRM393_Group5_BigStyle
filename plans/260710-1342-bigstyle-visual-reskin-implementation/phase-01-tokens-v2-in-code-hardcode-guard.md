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
