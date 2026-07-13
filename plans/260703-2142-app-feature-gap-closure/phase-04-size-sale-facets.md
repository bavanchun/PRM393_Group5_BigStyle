---
phase: 4
title: Size & Sale Facets
status: completed
priority: P2
dependencies: []
---

# Phase 4: Size & Sale Facets

## Overview
Turn the fake "Size XL/2XL/3XL" and "Sale" chips into real facets. Size filters
by actual variant sizes; Sale filters to products that have a `sale_price`.
Currently Size chips do a literal name search and Sale just sorts by price.

## Requirements
- Functional: "Size XL" shows only products with an XL variant; "Sale" shows only
  on-sale products; chips remain mutually consistent with category + search.
- Non-functional: filtering stays client-side (products already fully loaded);
  add facet fields to state cleanly (constructor + copyWith + props + getter).

## Architecture
`ProductModel` already exposes `List<String> get sizes` (distinct variant sizes,
canonical order) and `bool get hasDiscount` (`originalPrice != null` ⇔ sale_price
set). The product list filters live entirely in `ProductState.filteredProducts`.
Add `selectedSize` and `saleOnly` to the state, two new events, two bloc
handlers, and rewire the two chip branches. Note chip labels say `Size XL` but
`sizes` holds `XL` — strip the `'Size '` prefix when mapping.

## Related Code Files
- Modify: `FE/lib/blocs/product/product_event.dart`
  - Add `class FilterBySize extends ProductEvent { final String? size; ... }` and
    `class ToggleSaleOnly extends ProductEvent { final bool saleOnly; ... }`.
- Modify: `FE/lib/blocs/product/product_bloc.dart`
  - Register handlers that `emit(state.copyWith(selectedSize:...))` /
    `copyWith(saleOnly:...)`.
- Modify: `FE/lib/blocs/product/product_state.dart`
  - Add fields `final String? selectedSize;` and `final bool saleOnly;` (default
    false) to constructor, `copyWith` (with explicit clear for size, e.g.
    `clearSize`), and `props`.
  - In `filteredProducts` getter (lines ~28-57): after category/search,
    `if (selectedSize != null) result = result.where((p) => p.sizes.contains(selectedSize)).toList();`
    and `if (saleOnly) result = result.where((p) => p.hasDiscount).toList();`.
- Modify: `FE/lib/screens/product_list/product_list_screen.dart`
  - `_onFilterSelected` (lines ~377-404): Size branch → `FilterBySize(label.replaceFirst('Size ',''))`;
    Sale branch → `ToggleSaleOnly(true)`. Non-size/sale chips must reset these
    facets (dispatch `FilterBySize(null)` + `ToggleSaleOnly(false)`) so switching
    chips doesn't leave a stale facet applied.

## Implementation Steps
1. Add the two events.
2. Add state fields + copyWith (with a `clearSize` bool for nulling) + props +
   getter filters.
3. Add bloc handlers.
4. Rewire chip mapping; ensure selecting a category/"Tất cả"/"Mới về" clears the
   size + sale facets to keep single-select chip semantics honest.
5. Sanity-check: `_selectedFilter` single-select still visually reflects the
   active chip.

## Success Criteria
- [x] "Size 2XL" lists only products having a 2XL variant. <!-- evidence: FE/lib/blocs/product/product_state.dart filteredProducts — result.where((p) => p.sizes.contains(selectedSize)) -->
- [x] "Sale" lists only products with `sale_price` set (use `hasDiscount`). <!-- evidence: FE/lib/blocs/product/product_state.dart filteredProducts — if (saleOnly) result.where((p) => p.hasDiscount) -->
- [x] Switching from "Sale" to "Áo" clears the sale facet (no stale filter). <!-- evidence: FE/lib/screens/product_list/product_list_screen.dart _onFilterSelected — every category branch also dispatches FilterBySize(null) + ToggleSaleOnly(false) -->
- [x] `flutter analyze` clean. <!-- evidence: docs/journals/260703-app-feature-gap-closure-batch1.md "Verification" section -->

## Risk Assessment
- Stale facet when switching chips (single-select UI, multi-field state).
  Mitigation: explicitly reset size+sale on every non-size/non-sale chip.
- `copyWith` nulling: Equatable copyWith can't null a field via `?? this.x`.
  Mitigation: add a `clearSize` flag param (existing pattern used elsewhere, e.g.
  `clearSelectedProduct`).
