---
phase: 1
title: "Variant Color Edit Fix"
status: completed
priority: P1
effort: "3h"
dependencies: []
---

# Phase 1: Variant Color Edit Fix

## Overview

Fix manager product edit so saving an existing product preserves real variant
`color_hex` instead of overwriting every variant with `#914B34`.

This phase is intentionally narrow. Do not refactor the whole product form yet.

## Requirements

- Functional: Editing a product must preserve each variant's current
  `colorHex` unless the user deliberately changes color.
- Functional: New variant rows in edit screen must get a deterministic color hex
  from selected swatch or a safe default.
- Non-functional: `flutter analyze` remains clean.
- Non-functional: No database schema change in this phase.

## Architecture

Current path:

```text
ManagerProductDetailScreen._updateProduct
  -> builds VariantModel list
  -> UpdateManagerProductEvent
  -> ManagerProductBloc._onUpdateProduct
  -> ProductService.updateProduct
```

Change only the variant construction in the edit screen. Preserve the
`VariantModel.colorHex` value from `widget.product.variants` for existing rows.
If UI supports a selected swatch, store selected hex in state and use it for new
rows.

## File Inventory

| File | Action | Size/Risk | Test impact |
|------|--------|-----------|-------------|
| `FE/lib/screens/manager/products/manager_product_detail_screen.dart` | Modify | 1372 lines, high risk due size | Add widget/unit-level coverage in Phase 5 |
| `FE/lib/models/variant_model.dart` | Read only | Small, stable | Verify `colorHex` maps `color_hex` |
| `FE/lib/screens/manager/products/manager_create_product_screen.dart` | Read only | 1305 lines | Mirror swatch logic only if needed |

## Interface Checklist

- [x] `VariantModel.colorHex` remains required.
- [x] `VariantModel.toMap()` still emits `color_hex`.
- [x] `ManagerProductDetailScreen._updateProduct()` no longer hardcodes
      `'#914B34'` for existing variants.
- [x] New edit-screen rows have predictable `colorHex`.
- [x] No caller signature changes.

## Dependency Map

```text
Phase 1 output -> Phase 2 RPC/update contract must preserve color_hex
Phase 5 tests -> lock this behavior
Phase 6 modularization -> can extract color controls after behavior locked
```

## Implementation Steps

1. In `ManagerProductDetailScreen.initState`, keep enough variant identity to map
   each form row back to its original `VariantModel`.
2. In `_updateProduct`, when building each `VariantModel`:
   - if row has an existing id, find original variant by id and reuse
     `original.colorHex` unless the row explicitly changed swatch.
   - if row is new, use edit-screen selected swatch hex or a documented default.
3. Initialize edit-screen swatch from first existing variant with non-empty
   `colorHex` if product has variants.
4. Keep `color` text field independent from `colorHex`, matching current product
   create behavior.
5. Run `flutter analyze`.

## Test Scenario Matrix

| Scenario | Type | Expected |
|----------|------|----------|
| Existing variant `colorHex=#2A6767`, manager edits stock only | Unit/widget later | Saved variant keeps `#2A6767` |
| Product has multiple variant colors | Manual/code review | No row silently resets to `#914B34` |
| New row added in edit screen | Manual | Row gets selected swatch hex |
| Product has no variant color | Manual | Save still succeeds with safe default |

## Success Criteria

- [x] No `colorHex: '#914B34'` hardcode remains in edit save path.
- [x] Existing variants preserve their stored `color_hex` after edit.
- [x] Create product behavior is unchanged.
- [x] `flutter analyze` passes.

## Risk Assessment

- Risk: trying to repair all color UX expands scope. Mitigation: only preserve
  data now; richer color editor waits for modularization.
- Risk: row identity lost when deleting/reordering variants. Mitigation: keep
  original variant id in `_variantsList` and resolve by id, not index.

## Security Considerations

No new auth path. Existing manager RLS remains the authorization boundary.
