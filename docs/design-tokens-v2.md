# BigStyle Design Tokens v2 — "Warm Terracotta"

**Status:** FROZEN — approved by user 2026-07-10, direction B of 3 candidates (A Refined Rose, B Warm Terracotta, C Bold Editorial).
**Rubric version:** `rubric-v1` (2026-07-10) — Phase 4 (Screen Gap Audit) must cite this stamp in every grading batch.
**Source:** `plans/260710-1158-ui-ux-overhaul-audit-pipeline/phase-03-brand-direction-tokens-v2.md`
**Scope:** full token table for `FE/lib/config/theme/*.dart`; no Dart changes made by this doc (audit-only pipeline).

## Concept

Warm rust/terracotta + ivory identity — moves off the current pink-app genericism toward a boutique, VN-fashion-specific warmth (evokes lacquer/ao-dai tones) without going cold-minimalist. Rounder shapes and slower motion reinforce an unhurried, boutique feel vs. a transactional-app feel.

## Token Table (v1 → v2)

| Semantic token | v1 (current) | v2 (frozen) | WCAG note |
|---|---|---|---|
| `primary` | `#C4517A` | `#9A3F35` | white-on-primary 6.70:1 (button text) |
| `primaryDark` | `#A03560` | `#742E28` | — |
| `secondary` | `#F7C0D0` | `#E8C9A0` | decorative only, not used for text |
| `accent` | `#2D2D2D` | `#2F2A28` | — |
| `background` | `#FDF8F9` | `#FBF6EF` | textPrimary/bg 14.63:1 |
| `surface` | `#FFFFFF` | `#FFFFFF` | unchanged |
| `error` | `#E53E3E` | `#C0392B` | error/surface 5.44:1 (v1 was 4.13:1, non-AA as text) |
| `success` | `#2ECC71` | `#2E6B47` | success/surface 6.34:1 (v1 was 2.10:1, non-AA as text — **v1 bug, fixed in v2**) |
| `warning` | `#F39C12` | `#8A5313` | warning/surface 6.31:1 (v1 was 2.19:1, non-AA as text — **v1 bug, fixed in v2**) |
| `textPrimary` | `#1A1A1A` | `#2A211E` | on background 14.63:1, on surface 15.73:1 |
| `textSecondary` | `#6B6B6B` | `#746159` | on background 5.43:1 |
| `textHint` | `#A0A0A0` | `#A99589` | decorative/hint only, not body text |
| `border` | `#E8E0E2` | `#EAD9C7` | — |
| `divider` | `#F0EBED` | `#F3E9DD` | — |

**Status-color usage rule (new — closes a v1 gap):** `success`/`warning`/`error` are now text/icon-safe on white (all ≥4.5:1). For solid-fill badges (colored background + white text), only `error` passes white-on-fill at 4.5:1 (5.44:1); `success`/`warning` do NOT pass white-on-fill (3.42:1 / 3.29:1) at any reasonable saturation for this hue family. **Rule: status badges/chips must use tonal style (light-tint background + the dark token as text color), never solid-fill + white text, for `success` and `warning`.** This directly targets `ux-flow-audit.md` M6 (pending badge uses raw `success` fill).

## Typography

| Role | v1 | v2 |
|---|---|---|
| Display (headings) | Playfair Display | **Cormorant** (weights 400/500/600/700) |
| Body/UI | DM Sans | **Montserrat** (weights 300/400/500/600/700) |

Google Fonts confirmed available (`google_fonts` package, already a dependency — no new package). Mood: luxury/fashion/elegant/refined, matches "Luxury Serif" pairing convention. Keep the same type-role structure as v1 (`displayLarge/Medium/Small`, `headlineLarge/Medium/Small`, `bodyLarge/Medium/Small`, `labelLarge/Small`, `caption`, `button`, `price`, `priceSmall`) — only the font family + color values change, sizes/weights/line-heights carry over from `app_typography.dart` unless a screen-level finding says otherwise in Phase 4.

## Shape & Spacing

| Token | v1 | v2 | Delta |
|---|---|---|---|
| `cardRadius` | 16 | **20** | +4, rounder |
| `buttonRadius` | 12 | **14** | +2 |
| `bottomSheetRadius` | 24 | **28** | +4 |
| `inputRadius` | 12 | **14** | +2 |
| `chipRadius` | 20 | **24** | +4 |
| Spacing scale (`xxs..xxl`) | 4/8/12/16/24/32/48 | **unchanged** | rhythm carries over — no functional reason to change it independently of shape |

## Motion

Gentle `easeOutCubic` (or Flutter `Curves.easeOutCubic`) on entrances, **250–300ms** (vs. no explicit standard in v1) — deliberately slower than a typical "snappy" e-commerce app to reinforce the boutique pace. Implicit animations (`AnimatedContainer`, `AnimatedOpacity`) preferred over explicit `AnimationController` for consistency with current codebase patterns (no v1 screen uses explicit controllers per Phase 1 scan).

## Phase 4 Grading Rubric (`rubric-v1`)

Every Phase 4 finding must cite `rubric-v1` and one of these types:

| Finding type | Violation condition |
|---|---|
| `color` | Any `Colors.*`/`0xFF` hardcode not in this token table; any v1 hex value still present post-migration |
| `typography` | `TextStyle(...)` not using `AppTypography.*`; non-Cormorant/Montserrat font; GoogleFonts.playfairDisplay/dmSans literal calls |
| `shape` | Radius value not in {20,14,28,14,24}; inconsistent elevation/border width vs. component's peers |
| `spacing` | Padding/margin/gap not on the 4/8/12/16/24/32/48 scale |
| `motion` | Missing implicit animation on state change where v2 motion stance calls for one; duration outside 150–350ms |
| `status-badge` | `success`/`warning` used as solid-fill+white-text instead of tonal (see rule above) |

**Bounded re-grade rule:** if `rubric-v1` changes after Phase 4 starts (version bumps to `rubric-v2`), only findings of the *changed* type(s) are re-checked across already-graded screens — not a full re-grade. Record the rubric version on every finding so this is mechanically enforceable.

## Merge Note

Direction B was approved as-is (no merge requested) — the WCAG AA re-check-on-merge step (phase-03 step 6) does not apply; all pairs above were already verified pre-approval on the unmerged B palette.

## Changelog

- **2026-07-10 (Phase 1, visual reskin implementation):** additive-only amendment, approved palette values above untouched. Added `AppColors.onPrimary` (`#FFFFFF`) and `AppColors.shadow` (`#000000`) as named aliases for legitimate white-on-primary/shadow usages. Added a `StatusColors` `ThemeExtension` (`success`/`warning`/`error`/`info`) since Material 3's `ColorScheme` has no success/warning/info slots; `success`/`warning`/`error` reuse the values above, `info` is a new `#2E5F8A` (muted steel-blue, ~6.76:1 on white) covering the `OrderStatus.shipping` case that 2 screens previously hardcoded as `Colors.blue`.
