---
phase: 6
title: "UI Modularization"
status: partial
priority: P2
effort: "2d"
dependencies: [5]
---

# Phase 6: UI Modularization

## Overview

Reduce maintenance risk in oversized UI files after tests/smoke coverage exists.
Focus first on manager product create/edit duplication because those files are
the largest and touch the most fragile data behavior.

## Requirements

- Functional: No behavior change.
- Functional: Extract shared product form sections used by create/edit.
- Non-functional: Keep new files self-documenting and follow existing Dart
  `snake_case` file naming in this repo.
- Non-functional: Each extracted component has clear props and no hidden
  Supabase calls.
- Non-functional: `flutter analyze` and `flutter test` pass after each slice.

## Architecture

Target extraction:

```text
screens/manager/products/
  manager_create_product_screen.dart
  manager_product_detail_screen.dart
  product_form_sections/ or widgets/
    product_image_picker_section.dart
    product_color_swatch_section.dart
    product_general_info_section.dart
    product_variant_table_section.dart
```

Keep screen-level ownership of:
- BLoC listeners.
- navigation/discard dialogs.
- save/create/update command construction.

Move reusable presentation/control sections only.

## File Inventory

| File | Action | Size/Risk | Test impact |
|------|--------|-----------|-------------|
| `FE/lib/screens/manager/products/manager_create_product_screen.dart` | Modify | 1305 lines | Must stay behavior-equivalent |
| `FE/lib/screens/manager/products/manager_product_detail_screen.dart` | Modify | 1372 lines | Must preserve Phase 1 fix |
| `FE/lib/screens/manager/products/product-form-*.dart` or `widgets/*.dart` | Create | New shared widgets | Add smoke/widget coverage if feasible |
| `FE/test/...` | Extend | Existing from Phase 5 | Run after every extraction |
| `FE/lib/screens/product_detail/product_detail_screen.dart` | Optional later | 831 lines | Defer unless time remains |
| `FE/lib/screens/checkout/checkout_screen.dart` | Optional later | 690 lines | Defer unless time remains |

## Interface Checklist

- [ ] Extracted widgets are stateless where possible.
- [ ] Controllers remain owned/disposed by parent screen unless widget creates
      them explicitly.
- [ ] No product save logic moves into visual widgets.
- [ ] Existing image upload event path remains unchanged.
- [ ] Existing category dropdown data path remains unchanged.
- [ ] Phase 1 color preservation still covered after extraction.

## Dependency Map

```text
Phase 5 tests -> gate every extraction
Phase 1/2 product edit semantics -> must not regress
Optional later: product detail/checkout split after manager form success
```

## Implementation Steps

1. Measure duplication between create/edit product screens.
2. Extract the lowest-risk repeated pure UI first:
   - image list/picker display.
   - color swatch section.
3. Run analyzer/tests.
4. Extract general info/category/elasticity section.
5. Run analyzer/tests.
6. Extract variant table section only after controller ownership is clear.
7. Run analyzer/tests and manager product create/edit smoke.
8. Evaluate whether to continue to `product_detail_screen.dart` and
   `checkout_screen.dart`; if time/risk is poor, document as deferred backlog.

## Test Scenario Matrix

| Scenario | Type | Expected |
|----------|------|----------|
| Manager create product after extraction | Manual smoke | Product creates |
| Manager edit product color after extraction | Manual smoke/test | Color persists |
| Image add/remove/reorder | Manual smoke | Same behavior |
| Category dropdown create/edit | Manual smoke | Persists selected category |
| Discard dialog | Manual smoke | Still appears only when dirty |
| `flutter test` | Automated | Passes |

## Success Criteria

- [ ] Largest product form files shrink materially.
- [ ] Shared widgets/components have clear, bounded responsibilities.
- [ ] No behavior regression in manager create/edit product.
- [ ] `flutter analyze` and `flutter test` pass.
- [ ] Any remaining >200-line files are listed as intentional/deferred.

## Risk Assessment

- Risk: controller lifecycle bugs. Mitigation: parent owns controllers; widgets
  receive controllers and callbacks.
- Risk: huge diff hard to review. Mitigation: split extraction into small slices
  with analyzer/tests between them.
- Risk: over-abstracting one-off UI. Mitigation: only extract duplicated or
  clearly bounded sections.

## Security Considerations

No auth/data policy changes. Ensure extracted widgets do not create direct
Supabase clients.
