---
phase: 4
title: Verify
status: completed
effort: ''
---

# Phase 4: Verify

## Overview
Static + runtime verification on the emulator, including the slug-refactor
regression on product create.

## Requirements
- Functional: prove create/edit/soft-delete work end-to-end against the real
  Supabase project and that product create still works.
- Non-functional: `flutter analyze` clean; no FK errors; slugs valid + unique.

## Architecture
Runtime test on `emulator-5554` as manager. Temporarily flip
`hoangbavan4478@gmail.com` to `manager` via SQL to reach manager screens, then
revert to `customer` (same procedure used in prior demo testing). Verify DB rows
via Supabase MCP `execute_sql` on project `agbnpqgxsppdrpbqoipo`.

## Related Code Files
- None (verification only). Touches DB state (test category) — clean up after.

## Implementation Steps
1. `flutter analyze` on the whole `FE/lib` — clean.
2. Emulator: dashboard "Danh mục" → list renders (no coming-soon).
3. Create a test category → confirm row + non-null unique slug in DB
   (`select name, slug, is_active from categories where name like 'QA-%'`).
4. Edit its name/active → confirm update in DB.
5. Soft-delete a category that HAS products → confirm `is_active=false`, **no FK
   error**, and it drops from the active list / customer home.
6. Regression: create a product (any category) → still succeeds (shared slug
   util intact).
7. Cleanup: delete the QA test category row; revert the role flip to `customer`.

## Success Criteria
- [ ] `flutter analyze` clean.
- [ ] Create/edit/soft-delete verified in UI + DB.
- [ ] Soft-delete of an in-use category does not raise a FK violation.
- [ ] Product create regression passes.
- [ ] Test data removed; roles restored (customer/customer/manager).

## Risk Assessment
- Forgetting to revert the role flip → checklist step 7 is mandatory.
- Screenshot-driving text entry can misfire on keyboard scroll (seen in prior
  test) — enter one field, hide keyboard, then the next.
