---
phase: 3
title: Variant Color Persist
status: completed
priority: P3
dependencies: []
---

# Phase 3: Variant Color Persist

## Overview
Stop hardcoding `colorHex: '#914B34'` when a manager creates a product. The
chosen color swatch should drive the real `color_hex` saved to
`product_variants`, so product-detail color selectors show correct colors.

## Requirements
- Functional: manager picks a color swatch → new variants persist that swatch's
  hex → product detail renders the correct color dot.
- Non-functional: no change to per-row color *name* text inputs (keep current UX);
  only the hex is fixed.

## Architecture
`VariantModel.colorHex` and DB `product_variants.color_hex` already carry the
value end-to-end; the only defect is the create screen supplying a constant.
Add a `_selectedSwatchHex` in the create screen driven by the swatch tap, and use
it where variants are constructed. Product-global swatch (per locked decision).

## Related Code Files
- Modify: `FE/lib/screens/manager/products/manager_create_product_screen.dart`
  - State: add `String _selectedSwatchHex = '#914B34';` alongside existing
    `_selectedSwatchColor = 'Đất nung'` (line ~37).
  - Define a name→hex map for the 3 swatches: `Đất nung=#914B34`,
    `Xanh ngọc=#2A6767`, `Đen=#313030` (matches the `Color(...)` values at
    lines ~596-608).
  - `_buildColorSwatch(name, color)` onTap (lines ~1051-1084): also set
    `_selectedSwatchHex` from the map (or pass the hex in).
  - Variant construction in `_saveProduct()` (line ~208): replace the hardcoded
    `colorHex: '#914B34'` with `colorHex: _selectedSwatchHex`.
- No change: `models/variant_model.dart` (already carries color_hex correctly).

## Implementation Steps
1. Add `_selectedSwatchHex` state + the `{name: hex}` constant map.
2. Update `_buildColorSwatch` (or its callers) to set the hex on tap, keeping the
   existing selection highlight on `_selectedSwatchColor`.
3. Change line ~208 to `colorHex: _selectedSwatchHex`.
4. (Decision) Keep per-row `color` text as the variant color *name*; the swatch
   supplies only the hex. Document this so it's not mistaken for a bug later.

## Success Criteria
- [ ] Creating a product with "Xanh ngọc" selected persists `color_hex='#2A6767'`
      on its variants (verify in DB).
- [ ] Product detail color dot renders the chosen color, not always terra-cotta.
- [ ] `flutter analyze` clean.

## Risk Assessment
- Ambiguity: UI has both a global swatch and per-row color text. Mitigation:
  locked decision — swatch = hex (global), text = color name (per row). Edit-
  product screen keeps its own behavior; this phase touches the create screen
  only (edit screen's `via.placeholder` image + variant re-insert are separate
  known issues, out of scope).
