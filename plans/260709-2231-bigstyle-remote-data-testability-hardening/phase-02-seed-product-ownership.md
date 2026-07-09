---
phase: 2
title: "Seed Product Ownership"
status: pending
priority: P1
effort: "1h"
dependencies: [1]
---

# Phase 2: Seed Product Ownership

## Overview

Assign current seed products to the intended manager account so manager product
list/edit uses the existing `store_id = auth.uid()` RLS model.

Locked owner: `hoangbavan4478+manager@gmail.com`.

## Requirements

- Functional: manager product tab shows 15 seed products.
- Functional: manager can open an existing product edit screen.
- Non-functional: mutation must be reversible and scoped.
- Security: do not relax RLS just to make seed data visible.

## Architecture

Existing product ownership model:

```text
profiles.id (manager)
  <- products.store_id
  <- product_variants via products.store_id policy
```

Do not change policies unless ownership assignment fails. The correct fix is
seed data alignment, not broad manager access to all products.

## Related Code Files

| File | Action | Notes |
|------|--------|-------|
| `FE/supabase/migrations/20260703143620_add_brand_to_manager.sql` | Read | Defines `store_id` and manager policies |
| `FE/supabase/migrations/20260704100000_seed_bigstyle_data.sql` | Read/update optional | Contains reminder to set manager UUID |
| `FE/lib/services/product_service.dart` | Read | Manager listing filters by `storeId` |

## File Inventory

| Path | Action | Test impact |
|------|--------|-------------|
| Remote `public.products` rows | Update data | Manager product tab changes from 0 to 15 |
| Optional new data migration | Create if making seed repair reproducible | Future DB reset remains correct |

## Dependency Map

- Depends on Phase 1 for final RPC/RLS state.
- Blocks manager product edit smoke in Phase 5.

## Implementation Steps

1. Resolve the locked owner UUID:
   ```sql
   select id
   from public.profiles
   where email = 'hoangbavan4478+manager@gmail.com'
     and role = 'manager';
   ```
   If the row is missing, create/fix that long-term manager account first
   instead of assigning products to the main personal account.
2. Pre-count:
   ```sql
   select store_id, count(*) from public.products group by store_id;
   ```
3. Update only orphaned seed products:
   ```sql
   update public.products
   set store_id = '<manager_plus_uuid>', updated_at = now()
   where store_id is null;
   ```
4. Post-count:
   ```sql
   select count(*) from public.products
   where store_id = '<manager_plus_uuid>';
   ```
5. Relaunch Android app as chosen manager.
6. Verify manager product tab shows 15 products.
7. Open one product detail/edit screen. Do not save yet unless Phase 1 verified.

## Test Scenario Matrix

| Scenario | Expected |
|----------|----------|
| Product tab before ownership repair | `Tổng: 0` |
| Product tab after ownership repair | `Tổng: 15` and visible cards |
| Other role/customer product manager tab | No access to manager shell |
| Manager product edit open | Existing variants/colors visible |

## Success Criteria

- [ ] `hoangbavan4478+manager@gmail.com` manager profile exists.
- [ ] Pre/post SQL counts recorded in implementation report.
- [ ] 15 active seed products have `store_id` equal to the `+manager` UUID.
- [ ] Manager product tab no longer empty.
- [ ] No RLS policy widened.

## Risk Assessment

- Risk: `+manager` account has no login/session yet. Mitigation: create/verify
  long-term login path for this account before final smoke.
- Risk: bulk update changes future marketplace assumptions. Mitigation: only
  update `store_id is null` seed rows and document rollback SQL.
