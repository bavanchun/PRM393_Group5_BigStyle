---
phase: 2
title: "Shared Component Layer"
status: pending
effort: "M (1 day)"
priority: P1
dependencies: [1]
---

# Phase 2: Shared Component Layer

<!-- Updated: Red Team Session 1 - phase substantially retargeted: size_selector.dart is an ORPHAN (zero importers); StatusBadge contract redefined around OrderStatus + StatusColors ThemeExtension -->

## Overview

Fix the widget-layer findings Phase 4's code pass surfaced — with two red-team corrections to that audit: (a) `size_selector.dart` is **dead code with zero importers**; the real tonal violation lives in ProductDetail's inline copy (fixed in Phase 3, where the screen code lives) and in `chipTheme` (fixed in Phase 1, where the theme code lives); (b) the claimed `StatusBadge` consumers are **already tonal** via near-identical `_getStatusColor` maps duplicated across ~4 files — the component's real value is DRY consolidation of those maps, not tonal conversion.

## Requirements

- Functional: `size_selector.dart` deleted (orphan — grep-verify zero importers immediately before deleting; `flutter analyze` must stay clean after).
- Functional: `product_card.dart` fully tokenized — **4** raw radii (not 3 as the audit said) AND its 5 direct `GoogleFonts.dmSans` calls (which bypass `AppTypography` and would otherwise ship the most demo-visible widget in the old font).
- Functional: new `StatusBadge` widget exists — **OrderStatus-aware**, tonal, driven by the `StatusColors` `ThemeExtension` Phase 1 added (bare `Theme.of(context)` is insufficient: M3 `ColorScheme` has no success/warning slots).
- Non-functional: no other shared widget touched (the other 8 got their alias cleanup in Phase 1 and are now token-only).

## Related Files

- `FE/lib/widgets/size_selector.dart` — **DELETE**. Zero imports anywhere in `FE/lib`; keeping it means token-fixing dead code and misleading future readers. The live selected-state code it duplicates is `product_detail_screen.dart:504-550` (Phase 3's job).
- `FE/lib/widgets/product_card.dart:38,62,87,122` — 4 raw `BorderRadius.circular(N)` literals; `:91,103,140,152,174` — 5 direct `GoogleFonts.dmSans(...)` calls → `AppTypography.*`.
- `FE/lib/widgets/section_header.dart` — reference pattern for theme-driven styling.
- `FE/lib/config/theme/app_theme.dart` — hosts the `StatusColors` `ThemeExtension` (added Phase 1) that `StatusBadge` resolves from.
- `docs/design-tokens-v2.md` — status-badge tonal-usage rule: "status badges/chips must use tonal style (light-tint background + the dark token as text color), never solid-fill + white text, for `success` and `warning`."

## New Component: `StatusBadge`

Create `FE/lib/widgets/status_badge.dart`:

```dart
// Tonal status badge — light-tint background + dark token text.
// Consolidates the near-identical _getStatusColor maps currently duplicated
// across orders_screen, order_detail_screen, manager_order_card and
// manager dashboard widgets (DRY), and enforces the tonal rule from
// docs/design-tokens-v2.md.
class StatusBadge extends StatelessWidget {
  final String label;
  final OrderStatus status; // the app's real 5-value status enum —
  // NOT a new 4-value success/warning/error/info enum, which cannot
  // express confirmed/shipping and would force lossy mapping at call sites.
  const StatusBadge({super.key, required this.label, required this.status});
  // Implementation: resolve status -> (background tint, text color) via the
  // StatusColors ThemeExtension (Phase 1). Color VALUES are relocated as-is
  // from the existing per-screen maps; adjust only pairs that fail a real
  // AA check. Chip-shaped, AppSpacing.chipRadius.
}
```

## Consumers to migrate (the duplicated `_getStatusColor` maps this consolidates)

Verified call sites (red-team grep, at pinned SHA): `orders_screen.dart:102-118,193-206`, `order_detail_screen.dart:83-97`, `manager_order_card.dart:17,101-107`. These are **already tonal** — the win is one shared map instead of four drifting copies, plus AA verification in one place. Note: `M6` (ManagerDashboard pending-order badge) is a **one-line token swap on a stat card** (`manager_dashboard_widgets.dart:33,180`), not a badge conversion — it moves to Phase 5's sweep, not this component's consumer list. Cross-check the remaining candidates against `phase-04-gap-findings-*.md` when this phase starts; migrate ≥1 real consumer here as smoke, leave full rollout to cluster phases.

## Implementation Steps

1. Grep-verify `size_selector.dart` still has zero importers, then delete it. `flutter analyze` must stay clean.
2. `product_card.dart`: replace the **4** literal radii (`:38,62,87,122`) with `AppSpacing` constants (verify which constant fits each site — the smaller radii (4, 3) may need 1-2 new named `AppSpacing` additions if nothing fits; additive is fine, a new raw literal is not), and replace the 5 `GoogleFonts.dmSans` calls with the matching `AppTypography.*` styles.
3. Build `StatusBadge` per the spec above, resolving colors from the `StatusColors` `ThemeExtension`.
4. Migrate ≥1 real consumer (e.g. `manager_order_card.dart`) to `StatusBadge` as a smoke test — full rollout of the remaining map sites happens in their cluster phases (Phases 4-5); don't scope-creep this phase into a full screen pass.
5. `flutter analyze` + `flutter test` (existing widget tests, if any, for `product_card` — check `FE/test/` first; red team found no golden tests exist, so no golden regeneration is needed).
6. Re-run the Phase 1 hardcode-guard script — `product_card.dart` and the deleted orphan should reduce the count; confirm no NEW occurrences appeared.

## Success Criteria

- [ ] `size_selector.dart` deleted; `flutter analyze` clean.
- [ ] `product_card.dart`: zero raw `BorderRadius.circular(literal)` (all 4 sites) and zero direct `GoogleFonts.*` calls (all 5 sites).
- [ ] `StatusBadge` built, `StatusColors`-driven, OrderStatus-aware, used by ≥1 real consumer as a smoke test.
- [ ] `flutter analyze` clean; existing widget tests still pass.

## Risk Assessment

- **The app's OrderStatus enum may have variants/labels this phase's spec doesn't anticipate** → read the actual enum + all 4 existing `_getStatusColor` maps FIRST; the maps are the contract, the spec above is the shape.
- **No existing radius constant fits `product_card.dart`'s smaller radii (4, 3)** → adding 1-2 new named constants to `app_spacing.dart` is acceptable (small, additive) — just don't invent a new *raw* hardcode to replace the old one.
- **Deleting `size_selector.dart` while a teammate's in-flight branch imports it** → grep at delete time (step 1) covers the current tree only; if a later merge reintroduces an import, `flutter analyze` on the reskin branch will catch the missing file immediately.

## Completion Note (2026-07-10)

**Status:** Done.

**`size_selector.dart`:** grep-reconfirmed zero importers (the only match was `product_detail_screen.dart`'s own private `_buildSizeSelector` method — same name, unrelated code, not an import) — deleted. `flutter analyze` stayed clean.

**`product_card.dart`:** the 4 raw radii (:38 cardRadius=20, :62/:87/:122 → new `AppSpacing.microRadius`=4, added since no existing constant fit) and 5 `GoogleFonts.dmSans` calls (→ `AppTypography.labelSmall`/`labelLarge`/`priceSmall`/`caption` bases with `.copyWith()` for the sizes that don't have an exact-match preset — only `priceSmall` matched exactly with zero overrides) are fixed. Also caught and fixed a 6th guard hit the plan's own itemization missed: `Colors.white` on the SALE badge text (line 67) → `AppColors.onPrimary` — found by re-running the guard scoped to this one file before editing, not by re-reading the plan's list uncritically.

**`StatusBadge`:** built exactly per Phase 0's re-verified contract (OrderStatus-aware switch: pending→warning, confirmed→`AppColors.primary` directly — not part of the `StatusColors` tuple since it's the brand color not a status semantic, shipping→new `info` tone, delivered→success, cancelled→error), resolving from `Theme.of(context).extension<StatusColors>()`. Migrated `manager_order_card.dart` as the real consumer (its inline `Container`+`Text` badge replaced with `StatusBadge(label: order.status.label, status: order.status)`; the now-unused local `statusColor` var removed). **Did not** delete or touch the top-level `managerOrderStatusColor()` function in the same file — it's still a live dependency of `order_status_update_sheet.dart` and `manager_order_detail_screen.dart` (both need a raw `Color`, not a full badge widget; their `StatusBadge`/consolidation rollout is Phase 4/5's job per the plan's own phasing, not this one's).

Added `test/widgets/status_badge_test.dart` (6 cases: all 5 status→tone mappings resolve correctly including the `shipping`→`info`-not-`Colors.blue` case, plus a tonal-not-solid-fill structural check) — new shared component with real branching logic that Phase 4/5 will wire into ~6 more screens, worth a permanent regression guard before that fan-out happens.

**Guard re-run:** 206 → 199 (−7: product_card.dart's 6 hits + size_selector.dart's 1; `manager_order_card.dart:24`'s `Colors.blue` inside `managerOrderStatusColor` is unchanged and still counted, correctly — that function wasn't touched). No new occurrences introduced.

**Verification:** `flutter analyze` clean (2 runs); `flutter test` 43/43 pass (37 prior + 6 new).
