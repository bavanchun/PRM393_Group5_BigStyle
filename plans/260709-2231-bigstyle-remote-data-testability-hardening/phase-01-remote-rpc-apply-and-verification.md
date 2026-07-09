---
phase: 1
title: "Remote RPC Apply And Verification"
status: completed
priority: P1
effort: "1.5h"
dependencies: []
---

# Phase 1: Remote RPC Apply And Verification

## Overview

Apply the already-created `update_product_with_variants` migration to remote
Supabase and verify the app contract before touching seed data.

## Requirements

- Functional: remote database exposes `public.update_product_with_variants`.
- Functional: manager-owned product update replaces variants atomically.
- Non-functional: do not change local app API/caller unless verification proves
  the migration contract is wrong.
- Security: keep `security definer set search_path = public`; verify function
  authorization checks `auth.uid()` and manager/admin role.

## Architecture

```text
Manager edit screen
  -> ManagerProductBloc
  -> ProductService.updateProduct()
  -> Supabase RPC public.update_product_with_variants
  -> update products + delete/insert product_variants in one transaction
```

## Related Code Files

| File | Action | Notes |
|------|--------|-------|
| `FE/supabase/migrations/20260709100000_update_product_with_variants_rpc.sql` | Apply remote | Existing migration SQL; do not rename unless using Supabase CLI migration create |
| `FE/lib/services/product_service.dart` | Read/verify only | App already calls RPC |
| `plans/260709-2030-bigstyle-stability-hardening/reports/implementation-verification.md` | Read | Prior local verification |

## File Inventory

| Path | Action | Test impact |
|------|--------|-------------|
| `FE/supabase/migrations/20260709100000_update_product_with_variants_rpc.sql` | Apply to remote | Enables manager product edit |
| `FE/lib/services/product_service.dart` | No change expected | Existing unit/analyze should still pass |

## Dependency Map

- Blocks Phase 2 and Phase 5.
- Depends on stability plan Phase 2 local migration output.

## Implementation Steps

1. Pre-check remote:
   ```sql
   select exists(
     select 1 from pg_proc p
     join pg_namespace n on n.oid = p.pronamespace
     where n.nspname = 'public'
       and p.proname = 'update_product_with_variants'
   );
   ```
2. Apply migration SQL to Supabase remote using the approved migration path.
3. Verify function signature and `search_path`:
   ```sql
   select p.proname, pg_get_function_arguments(p.oid), p.prosecdef
   from pg_proc p join pg_namespace n on n.oid = p.pronamespace
   where n.nspname = 'public' and p.proname = 'update_product_with_variants';
   ```
4. Run Supabase security advisor after DDL.
5. Run `flutter analyze` and `flutter test`.
6. Defer actual product edit smoke until Phase 2 gives manager ownership.

## Test Scenario Matrix

| Scenario | Expected |
|----------|----------|
| Function absent before apply | Pre-check shows false |
| Function present after apply | Post-check shows true |
| Unauthenticated RPC call | Raises `Not authenticated` |
| Non-manager RPC call | Raises `Not authorized` |
| Manager edits own product after Phase 2 | Product fields and variants update together |

## Success Criteria

- [ ] Remote `pg_proc` shows `update_product_with_variants`.
- [ ] Function has `SECURITY DEFINER` and fixed `search_path`.
- [ ] `flutter analyze` passes.
- [ ] `flutter test` passes.
- [ ] No duplicate/conflicting RPC migration is created.

## Risk Assessment

- Risk: applying DDL directly without migration tracking causes future drift.
  Mitigation: prefer Supabase migration/apply path and record exact SQL.
- Risk: public execute warning from SECURITY DEFINER. Mitigation: function body
  has auth/role checks; follow-up advisor findings can tighten grants if needed.

## Completion Notes

- Applied remote migration `update_product_with_variants_rpc` to
  `agbnpqgxsppdrpbqoipo`.
- Added and applied follow-up grant repair
  `restrict_update_product_with_variants_rpc_execute`.
- Verified remote function:
  `SECURITY DEFINER`, `search_path=public`, `anon_can_execute=false`,
  `authenticated_can_execute=true`.
- Verified manager-owned product update path with a rollback transaction:
  `public.update_product_with_variants(...)` returned product id
  `a1000000-0000-0000-0000-000000000002` and left no persisted mutation.
