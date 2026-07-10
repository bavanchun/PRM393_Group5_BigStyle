---
phase: 4
title: "Screen Gap Audit"
date: 2026-07-10
sha: 6e77ccfcc7572621729fd67efca277ef4d65dab4
rubric: rubric-v1
---

# Phase 4: Screen Gap Audit — Consolidated

Grades 26/30 Phase 2 screenshots against `docs/design-tokens-v2.md` (`rubric-v1`). Per-screen finding detail lives in the per-role checkpoint files (written incrementally, one per Gemini batch, per the phase's mid-phase-checkpoint requirement): `phase-04-gap-findings-guest.md`, `-customer.md`, `-manager.md`, `-admin.md`. This file consolidates: summary matrix, target component inventory, old-audit disposition, effort/cluster assignment, and a vision-model reliability note.

## Vision-Model Reliability Note (spot-check result — read before trusting any cited ratio)

Per the phase's hallucination-risk mitigation, contrast-ratio numbers cited by Gemini were spot-checked against the actual WCAG relative-luminance formula. **Result: the qualitative color/typography/shape/status-badge findings are reliable (visually verifiable, low hallucination risk), but specific contrast ratio NUMBERS are not** — four different findings cited four different ratios (4.23:1, 3.1:1, 2.89:1, 3.9:1) for what is structurally the same white-text-on-primary pairing. Computed authoritative value: **white-on-v1-primary (`#C4517A`) = 4.37:1; white-on-v2-primary (`#9A3F35`) = 6.70:1**. This directly **contradicts** several checkpoint findings claiming the v2 primary "still fails AA" for white button/AppBar text (AdminDashboard, ProductDetail) — those specific claims are wrong; the v2 swap alone clears AA comfortably for that pairing (matches Phase 3's own precomputed table). **Action: treat every cited numeric ratio in the per-role checkpoint files as an unverified estimate — the underlying "check this pairing" flag is valid, the number is not.** Re-measure with a real contrast tool during reskin implementation, don't code against the cited numbers.

## Summary Matrix

| Role | Screens captured | Findings (real) | token-swap-only | Not captured |
|---|---|---|---|---|
| Guest | 1/2 | 6 (Login) | 0 | 1 (Splash — architectural, session-cache routing) |
| Customer | 13/15 | ~72 across 12 screens | 1 (Favorites) | 2 (Checkout, PaymentQr — blocked by a possible cart-CTA bug, see below) |
| Manager | 8/9 | ~48 across 8 screens | 0 | 1 (ManagerCreateProduct — blocked by a possible FAB tap-target bug) |
| Admin | 4/4 | ~24 across 4 screens | 0 | 0 |
| **Total** | **26/30** | **~150 findings, 25 real / 1 token-swap-only** | | **4** |

Finding-type breakdown (approximate, from the 4 checkpoint files): color ~48, typography ~44, shape ~30, status-badge ~13, contrast ~24 (numbers unreliable, see note above), touch-target ~11, text-clip ~3, thumb-zone ~1.

## Findings on the 4 Not-Captured Screens (code-read fallback, per phase risk assessment)

- **Splash** (`splash/splash_screen.dart`, T2, 7 hardcode lines, 0 shared widgets, guest): inferred token-swap-only from Phase 1 code metrics — same profile as Login's non-structural findings, unverified visually.
- **Checkout** (`checkout/checkout_screen.dart`, T2, 1 hardcode line, 2 shared widgets, customer): low hardcode count and 2 shared-widget uses (`app_button`, `app_text_field`) suggest this is closer to token-swap-only than most customer screens — but genuinely unverified; capture blocked by the cart-CTA finding below, not a redaction issue.
- **PaymentQr** (`checkout/payment_qr_screen.dart`, T1, 0 hardcode lines, 2 shared widgets, customer): T1 tier + 2 shared widgets — likely token-swap-only, unverified.
- **ManagerCreateProduct** (`manager/products/manager_create_product_screen.dart`, T3, 18 hardcode lines, 0 shared widgets, manager): highest-debt manager screen per Phase 1; near-certain to need the same full color/typography/shape sweep as `ManagerProductDetail` (928 vs 1007 LOC, same form family, `ux-flow-audit.md` M34 already flags ~90% code duplication between them) — treat its findings as inherited from ManagerProductDetail's checkpoint entry until a real capture happens.

**Root-cause note (not fixed, audit-only):** both blockers (cart CTA, manager FAB) are tap-target/z-order bugs surfaced during Phase 2 capture, reproduced 3-4× each. Recommend a quick code-level check (not a full fix) before or during reskin implementation — if they're accidental widget-overlap bugs (e.g. an `InkWell` region shadowed by a sibling), the fix is trivial and unblocks the missing 3 screens for a delta-recapture.

## Old Audit Cross-Reference (from Phase 1, not re-derived)

| ID | Type | Screen | Disposition |
|---|---|---|---|
| C3 | ui | Home | already-fixed |
| C30 | consistency | OrderDetail | already-fixed (status badge always-primary bug) — **v2 tonal-badge finding on the same screen is a distinct, new requirement layered on top, not a regression of C30's fix** |
| C42 | consistency | Chat | already-fixed |
| M17 | consistency | ManagerProductList | already-fixed |
| M19 | consistency | ManagerProductList | already-fixed on list screen — **confirmed still open on ManagerProductDetail** (this phase's own finding, same AppBar-pink issue, different file) — dispositioned as still-open-outside-original-scope, folds into the v2 color sweep |
| G12 | consistency | Login | absorbed-by-v2-migration (color hardcodes → token table) |
| G16 | ui | Login (otp_input.dart) | still-open-outside-scope (focus/border state logic, not a token issue — needs a code fix, not a token swap) |
| C45 | consistency | DeliveryMap | absorbed-by-v2-migration (ship-fee display, unrelated to color tokens — still-open-outside-scope for the token migration, but unresolved as a data-consistency bug) |
| M2 | consistency | ManagerProfile | absorbed-by-v2-migration (`Colors.grey` → `textSecondary` token) |
| M6 | consistency | ManagerDashboard | absorbed-by-v2-migration **directly** — this phase's `status-badge` finding on ManagerDashboard/ManagerOrders IS M6's fix, delivered via the new tonal-StatusBadge component |
| M12 | ui | ManagerOrderDetail | still-open-outside-scope (date padding format bug, not a token issue) |
| M20 | consistency | ManagerProductList | absorbed-by-v2-migration (`.withOpacity` was already fixed repo-wide per Phase 1; remaining `Colors.green/grey/black/white` hardcodes → token table) |
| M21 | ui | ManagerProductList | still-open-outside-scope (broken external placeholder image URL, not a token issue) |
| M28 | ui | ManagerCreateProduct | still-open-outside-scope (broken external placeholder image URL, same class as M21) |
| M34 | consistency | ManagerCreateProduct + ManagerProductDetail | still-open-outside-scope (code-duplication refactor, not a token issue) — **but directly relevant to reskin sequencing**: fix both screens together, one pass, not twice |
| M37 | ui | ManagerProductDetail | still-open-outside-scope (fallback-image inconsistency, same family as M21/M28) |

**Disposition counts:** 5 already-fixed, 6 absorbed-by-v2-migration, 5 still-open-outside-scope (non-token code bugs: G16 focus state, C45 fee data, M12 date format, M21/M28/M37 broken image URLs, M34 duplication). None orphaned — all 16 dispositioned.

## Target Component Inventory (code pass, `FE/lib/widgets/*.dart`)

All 10 shared widgets already consume `AppColors.*`/`AppSpacing.*`/`AppTypography.*` semantic tokens (not raw hex) — confirmed by direct grep, not vision inference. This means **the v1→v2 swap for 8 of 10 widgets is a pure theme-file edit** (`FE/lib/config/theme/*.dart`), zero widget-code changes required.

| Widget | v2 action | Why |
|---|---|---|
| `app_bottom_nav.dart` | **Keep** — token-swap only | Fully `AppColors`/`AppTypography` driven |
| `app_button.dart` | **Keep** — token-swap only | Fully `AppColors`/`AppSpacing`/`AppTypography` driven |
| `app_card.dart` | **Keep** — token-swap only | Fully token driven |
| `app_error_state.dart` | **Keep** — token-swap only | Fully token driven |
| `app_text_field.dart` | **Keep** — token-swap only | Fully token driven |
| `expandable_text.dart` | **Keep** — token-swap only | Fully token driven |
| `manager_bottom_nav.dart` | **Keep** — token-swap only | Fully token driven |
| `section_header.dart` | **Keep** — zero changes needed | Uses `Theme.of(context)` (Material `ThemeData`/`ColorScheme`), not direct `AppColors` refs — the gold-standard pattern; picks up v2 automatically once `app_theme.dart` maps the new `ColorScheme`. **Recommend this pattern for all NEW shared components below**, not the direct-`AppColors`-reference pattern the other 9 use. |
| `size_selector.dart` | **Rework** | `size_selector.dart:37-47` hardcodes solid-fill-primary + white text for the selected state — this is the exact root cause behind the "selected chip solid-fill + white text, tonal violation" vision findings on ProductDetail and CartItemEdit. Code-confirmed, not just visual. Needs a genuine redesign (tonal selected-state), not a color-value swap. |
| `product_card.dart` | **Rework (minor)** | 3 raw hardcoded radii bypass the token system: `product_card.dart:38` (`BorderRadius.circular(16)`, should be `AppSpacing.cardRadius`), `:62` (`circular(4)`), `:87` (`circular(3)`) — these won't auto-update when `AppSpacing` values change in v2, silently drifting from the rest of the app. Low-effort fix (3 line edits), but must happen or the reskin ships an inconsistent product grid. |

**New shared components needed** (driven by Phase 1's bespoke-screen finding: manager 9/9 + admin 4/4 = 13/30 screens at zero shared-widget use):

1. **`StatusBadge` (tonal)** — highest leverage single component in this audit. Closes 13 of ~21 status-badge findings across manager (7 screens) + customer (6 screens: CartItemEdit, ProductList, EditProfile, Orders, OrderDetail, Profile, Notifications — 7 actually, cross-checked against checkpoint files) in one shared implementation. Directly implements `docs/design-tokens-v2.md`'s status-badge rule and resolves `ux-flow-audit.md` M6.
2. **Manager form section wrapper** — not a hard requirement of the token migration, but `ux-flow-audit.md` M34 (~90% code duplication between `ManagerCreateProduct` and `ManagerProductDetail`, ~965/1033 lines) means the reskin will otherwise duplicate every token change across two 900+-line files. Flagging for Phase 5 sequencing (fix once, not twice) rather than designing it here (out of this phase's scope).
3. No other missing shared components were identified as blocking — the bespoke-screen problem is overwhelmingly "screens don't USE the 10 existing widgets" (a migration/adoption problem), not "the widget catalog is missing categories." AppBar, chip, and tonal-badge coverage close the observed gaps.

## Effort Tags & Migration Clusters

Effort = Phase 1 tier (T1/T2/T3) crossed with this phase's finding density; L when a screen also carries a real contrast/touch-target/text-clip issue beyond the color/typography/shape sweep every screen needs.

| Cluster | Screens | Effort |
|---|---|---|
| **Auth/Guest** | Login (L — 6 findings incl. contrast), Splash (S — inferred token-swap-only) | Mixed |
| **Customer-shop** | Home (M), ProductList (M), ProductDetail (**L** — 2 contrast findings that survive the swap), Cart×2states (M), CartItemEdit (M), Checkout (S, inferred), PaymentQr (S, inferred), Favorites (**S — token-swap-only**) | Mixed, ProductDetail is the outlier |
| **Customer-account** | Profile (**L** — 2.76:1 badge fail + text-wrap bug), EditProfile (M), Orders (M), OrderDetail×2states (M), Chat (**L** — contrast on avatar/chips), Notifications (M), DeliveryMap (M) | Mostly M, 2×L |
| **Manager** | ManagerProductList (L), ManagerProductDetail (**L** — inherits ManagerCreateProduct too per M34), ManagerCreateProduct (L, inherited), ManagerDashboard (M), ManagerOrders (M), ManagerOrderDetail (M), ManagerProfile (M), ManagerCategoryList (M), ManagerVoucherList (**L** — FAB contrast issue persists post-swap per checkpoint, though ratio itself needs re-verification per reliability note above) | Skews L — matches Phase 1's tier prediction (manager dominates T3) |
| **Admin** | AdminDashboard (**L** — AppBar text-contrast flagged, needs re-verification), AdminUsers (L), AdminProfile (M), AdminCategories (M) | Skews L — matches Phase 1 (admin has 2×T3, 2×T2) |

This clustering can be handed directly to Phase 5 for reskin-plan phasing: auth/guest and customer-shop are natural early phases (customer-facing, high traffic); manager/admin are natural later phases (internal users, lower visual-polish urgency, but highest debt/leverage for the new StatusBadge component).

## Success Criteria

- [x] Every captured screen (26/30) has a gap entry; findings persisted per-batch in 4 append-only checkpoint files during the audit, not only in this final report.
- [x] No unredacted PII sent to Gemini — phase-02 log confirmed 0 `needs-redaction` frames; all 26 images sent as-is.
- [x] Every finding maps to a `rubric-v1` token/component (color/typography/shape/spacing/motion/status-badge) or a named universal heuristic (contrast/touch-target/thumb-zone/text-clip) — no free-floating notes.
- [x] Target component inventory written: 8/10 keep-as-is, 2/10 rework, 1 new shared component (`StatusBadge`) identified as highest-leverage.
- [x] Old-audit cross-reference complete: 16/16 dispositioned, 0 orphaned.
- [x] Effort tags + migration clusters assigned (table above) — directly consumable by Phase 5.
