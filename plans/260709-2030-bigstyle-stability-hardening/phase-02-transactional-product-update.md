---
phase: 2
title: "Transactional Product Update"
status: done_pending_db_apply
priority: P1
effort: "1d"
dependencies: [1]
---

# Phase 2: Transactional Product Update

## Overview

Replace unsafe product update behavior with an atomic database write path so a
variant insert failure cannot leave a product with deleted variants.

## Requirements

- Functional: Product row and full variant replacement commit or fail together.
- Functional: Preserve `category_id`, images, price/sale fields, `color_hex`,
  stock and fit ranges.
- Functional: Existing `ManagerProductBloc` callers should keep working.
- Non-functional: Migration follows Supabase SQL style already in
  `FE/supabase/migrations/`.
- Non-functional: No service-role key in Flutter.

## Architecture

Preferred design:

```text
ManagerProductBloc._onUpdateProduct
  -> ProductService.updateProduct(product)
  -> Supabase RPC public.update_product_with_variants(product jsonb, variants jsonb)
  -> PL/pgSQL transaction boundary
  -> returns updated product via existing getProductById(product.id)
```

PL/pgSQL functions run in one transaction for the function call. If delete or
insert fails, PostgreSQL rolls back the function effects.

## File Inventory

| File | Action | Size/Risk | Test impact |
|------|--------|-----------|-------------|
| `FE/supabase/migrations/{timestamp}_update_product_with_variants.sql` | Create | DB integrity critical | Manual Supabase migration verify |
| `FE/lib/services/product_service.dart` | Modify | Shared service | Unit test with fake client difficult; cover via integration/manual |
| `FE/lib/blocs/manager_product/manager_product_bloc.dart` | Likely read only | Existing caller | Ensure state messages unchanged |
| `FE/lib/models/product_model.dart` | Read only | Serialization contract | Verify `toMap()` fields match RPC |
| `FE/lib/models/variant_model.dart` | Read only | Serialization contract | Verify `toMap()` fields match RPC |

## Interface Checklist

- [ ] `ProductService.updateProduct(ProductModel product)` remains public API.
- [ ] RPC accepts product fields and variants in a shape directly derived from
      `ProductModel.toMap()` and `VariantModel.toMap()`.
- [ ] RPC checks caller is manager/store owner using existing RLS-safe logic or
      current auth uid.
- [ ] RPC deletes/reinserts variants inside one function.
- [ ] RPC returns enough data or service reloads via `getProductById`.

## Dependency Map

```text
Phase 1 color preservation -> variant payload includes correct color_hex
Phase 2 RPC -> Phase 5 tests/smoke validate data integrity
Phase 6 modularization -> can rely on stable update contract
```

## Implementation Steps

1. Draft migration under `FE/supabase/migrations/` with existing
   timestamp-plus-domain-slug style, e.g.
   `20260709_update_product_with_variants.sql`.
2. RPC contract:
   - `p_product_id uuid`
   - `p_product jsonb`
   - `p_variants jsonb`
3. In RPC:
   - verify `auth.uid()` is not null.
   - verify product exists and caller can update it (manager/store ownership
     aligned with current policies).
   - update product scalar fields.
   - delete product variants for `p_product_id`.
   - insert each variant from `p_variants`.
   - return updated product id or row JSON.
4. Update `ProductService.updateProduct` to call RPC, then call
   `getProductById(product.id)`.
5. Remove direct update/delete/insert sequence from Flutter service.
6. Add error handling that surfaces original Supabase error enough for manager
   troubleshooting while keeping UI message friendly.
7. Run migration locally/Supabase as appropriate, then run `flutter analyze`.

## Test Scenario Matrix

| Scenario | Type | Expected |
|----------|------|----------|
| Valid product edit with variants | Manual integration | Product + variants updated |
| Variant insert fails due bad field | DB/manual | Product and old variants remain unchanged |
| Unauthorized customer calls RPC | DB/manual | RPC rejects |
| Manager edits category/images/price | Manual | All scalar fields persist |
| Manager edits variant stock/color | Manual | Variants persist with correct `color_hex` |

## Success Criteria

- [ ] No delete-then-insert variant replacement remains in Flutter client.
- [ ] Failed variant insert cannot leave product with zero/missing variants.
- [ ] Manager edit product still reloads list and shows success/error states.
- [ ] `flutter analyze` passes.

## Risk Assessment

- Risk: RPC bypasses RLS if `SECURITY DEFINER` is too broad. Mitigation: set
  `search_path = public`, check `auth.uid()`, check manager/store ownership
  explicitly.
- Risk: JSON payload mismatch. Mitigation: reuse current `toMap()` keys and
  verify against table column names.
- Risk: migration not applied in Supabase. Mitigation: Phase 5 smoke matrix
  includes migration verification.

## Security Considerations

Do not add service-role secrets to Flutter. RPC must enforce authorization
inside DB and avoid trusting client-supplied `store_id` for ownership.
