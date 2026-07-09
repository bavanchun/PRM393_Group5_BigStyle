# Manager Product Form Modularization

Date: 2026-07-10
Branch: `dev`

## Summary

Extracted the shared manager product variant form table from the create and edit
screens without changing BLoC/service contracts.

## Code Changes

- `FE/lib/screens/manager/products/form/manager_product_variant_form_row.dart`
  - Owns variant row controllers.
  - Maps existing `VariantModel` rows into editable state.
  - Converts edited rows back to `VariantModel` while preserving existing
    per-variant `colorHex`.
- `FE/lib/screens/manager/products/widgets/manager_product_variants_table.dart`
  - Replaces duplicated create/edit variant table UI.
  - Keeps add/remove/size dropdown callbacks owned by parent screens.
- `FE/lib/screens/manager/products/widgets/manager_product_variant_table_cells.dart`
  - Extracts reusable table cells/dropdown so new widget files stay focused.
- `FE/lib/screens/manager/products/manager_create_product_screen.dart`
  - Uses the shared variant row model/table.
- `FE/lib/screens/manager/products/manager_product_detail_screen.dart`
  - Uses the shared variant row model/table and keeps existing variant
    `colorHex` during update.

## Size Change

| File | Before | After |
|---|---:|---:|
| `manager_create_product_screen.dart` | 1305 | 928 |
| `manager_product_detail_screen.dart` | 1400 | 1007 |
| `manager_product_variant_form_row.dart` | 0 | 109 |
| `manager_product_variants_table.dart` | 0 | 184 |
| `manager_product_variant_table_cells.dart` | 0 | 166 |

## Added Coverage

- `FE/test/manager_product_variant_form_row_test.dart`
  - Existing edit variant preserves `colorHex` instead of falling back to the
    selected swatch.
  - New row falls back to current swatch when no per-row hex exists.
- `FE/test/widgets/manager_product_variants_table_test.dart`
  - Table renders existing row values.
  - Delete and add callbacks are wired.
  - Size dropdown writes the selected size to the row controller.

## Verification

- `cd FE && flutter analyze`: PASS, no issues.
- `cd FE && flutter test`: PASS, 17 tests.

## Notes

The create/edit screens remain over 900 lines because image/category/general
form sections are still inline. This phase removed the highest-risk duplicated
variant table and established a tested extraction path for further form
sections.

## Unresolved Questions

None.
