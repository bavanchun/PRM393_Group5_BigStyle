---
phase: 5
title: "Manager Product Form Modularization"
status: pending
priority: P2
effort: "1.25d"
dependencies: [4]
---

# Phase 5: Manager Product Form Modularization

## Overview

Split the 1300+ line manager create/edit product screens into focused widgets
and helpers without changing behavior. This is a protected refactor, not a new
feature phase.

## Requirements

- Functional: create/edit product flows behave the same before and after.
- Functional: preserve category selection, image list, variant color/stock/size,
  save/delete confirmations, and success/error handling.
- Non-functional: extracted files are focused and easier for future agents to edit.

## Architecture

Current issue:

- `manager_create_product_screen.dart`: 1305 lines.
- `manager_product_detail_screen.dart`: 1400 lines.

Target structure under `FE/lib/screens/manager/products/widgets/` and possibly
`FE/lib/screens/manager/products/form/`:

- image picker/list widget
- category dropdown widget
- pricing/stock inputs
- variant editor widget
- save/delete action bar
- shared form state mapper/helper

Keep BLoC boundaries unchanged: `ManagerProductBloc`, `ManagerCategoryBloc`,
and `ProductService` remain the data layer.

## File Inventory

| Path | Action | Test impact |
|---|---|---|
| `FE/lib/screens/manager/products/manager_create_product_screen.dart` | Modify | Reduce orchestration to screen-level state. |
| `FE/lib/screens/manager/products/manager_product_detail_screen.dart` | Modify | Reduce orchestration to screen-level state. |
| `FE/lib/screens/manager/products/widgets/*.dart` | Create | Widget tests for extracted parts. |
| `FE/lib/screens/manager/products/form/*.dart` | Create if useful | Pure mapping tests. |
| `FE/test/widgets/manager_product_form_*_test.dart` | Create | Regression tests for critical form controls. |

## Tests Before

- Add widget test for variant editor preserving color label and `colorHex`.
- Add mapper test for create/edit product payload if extraction creates pure helper.
- Add smoke widget test that required fields validation remains visible.

## Implementation Steps

1. Identify duplicated sections between create and edit screens.
2. Extract pure data mapping first:
   - controllers -> variants
   - image URLs -> product images
   - category id/name selection
3. Extract leaf widgets with no direct Supabase/BLoC calls.
4. Extract form sections one by one:
   - basic info
   - images
   - category/pricing
   - variants
   - action buttons
5. Keep parent screens responsible for navigation, BLoC listeners, and submit.
6. After each extraction, run tests.
7. Do not rename user-facing labels unless tests reveal overflow or stale branding.

## Test Scenario Matrix

| Scenario | Priority | Expected |
|---|---|---|
| Existing variant color loads | Critical | Text and hex preserved. |
| New variant color swatch | Critical | Selected hex maps to payload. |
| Missing category validation | High | Snackbar/error remains. |
| Image add/remove | High | Main image ordering preserved. |
| Save loading state | High | Duplicate submit prevented. |
| Delete confirm | Medium | Existing flow preserved. |

## Refactor

- Keep each new widget under ~200 lines where feasible.
- Prefer immutable input models and callbacks.
- Avoid nested cards and large decorative changes.

## Tests After

- Full unit/widget tests.
- Manual manager product edit smoke on emulator if admin/customer smoke server is available.

## Regression Gate

```bash
cd FE
flutter analyze
flutter test
```

## Success Criteria

- [ ] Create product screen reduced substantially and remains readable.
- [ ] Edit product screen reduced substantially and remains readable.
- [ ] Shared sections extracted without changing BLoC/service contracts.
- [ ] Variant color/category/image behavior covered by tests.
- [ ] Manager product smoke still passes.

## Risk Assessment

- Risk: extraction breaks controller disposal or state ownership. Mitigation:
  parent screen keeps controller lifecycle unless helper owns a clearly disposed
  object.
- Risk: behavior drift hidden by visual similarity. Mitigation: tests-before and
  emulator smoke after extraction.

## Security Considerations

- Image upload paths and manager-only permissions remain unchanged.
- Do not add client-side bypasses for store ownership.

## Dependency Map

Depends on Phase 4 tests. Phase 7 performs final smoke and plan sync.
