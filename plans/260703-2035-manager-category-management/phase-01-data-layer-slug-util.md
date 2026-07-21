---
phase: 1
title: Data Layer & Slug Util
status: completed
effort: ''
---

# Phase 1: Data Layer & Slug Util

## Overview
Extend `CategoryModel`, extract a shared slug generator, and add
`CategoryService` with manager CRUD (soft-delete). Foundation for the bloc.

## Requirements
- Functional: create/read(all for manager)/update/soft-delete categories; every
  create sets a valid unique `slug`; customer-facing category read returns only
  `is_active=true`.
- Non-functional: reuse existing Supabase client + upload pattern; DRY slug
  helper shared with product create; no DB migration.

## Architecture
- `categories` cols: `id, name(NN), slug(NN,unique), image_url?, sort_order(0),
  is_active(true), created_at`. RLS `Managers can manage categories (ALL,
  is_manager())` already allows writes.
- Soft-delete = `update({is_active:false})`, never `DELETE` (FK
  `products.category_id → categories.id`).
- Slug: `slugify(name)-<base36 time suffix>`; reuse the helper currently private
  in `product_service.dart` (commit 6ba7029) by moving it to `utils/slug.dart`.

## Related Code Files
- Create: `FE/lib/utils/slug.dart` — top-level `String generateSlug(String name)`
  (moved verbatim from product_service, made public).
- Create: `FE/lib/services/category_service.dart` — `CategoryService` with:
  - `getCategoriesForManager()` → all rows, ordered `sort_order, name`.
  - `createCategory(CategoryModel)` → insert, set `slug` via `generateSlug(name)`,
    drop empty `id`/`created_at`/`product_count`.
  - `updateCategory(CategoryModel)` → update by id (keep existing slug; do not
    overwrite unless name changed — regenerate only if changed).
  - `softDeleteCategory(String id)` → `update({is_active:false})`.
- Modify: `FE/lib/models/category_model.dart` — add fields `slug`, `isActive`
  (default true), `sortOrder` (default 0); update `toMap`/`fromMap`/`props`.
  Keep `productCount` (read-only, from count query; not written on insert).
- Modify: `FE/lib/services/product_service.dart` — delete the private
  `_generateSlug`, import and call `generateSlug` from `utils/slug.dart`
  (behavior unchanged).
- Modify: `FE/lib/services/product_service.dart` `getCategories()` — add
  `.eq('is_active', true)` so customer/home reads exclude hidden categories.
  (Manager list uses the new `CategoryService.getCategoriesForManager`.)

## Implementation Steps
1. Add `utils/slug.dart` with public `generateSlug`; move logic out of
   product_service; update product_service import + call site; run analyze.
2. Extend `CategoryModel` with `slug`/`isActive`/`sortOrder` (+ map/props).
3. Write `CategoryService` (getForManager/create/update/softDelete) with slug
   set on create and on rename.
4. Add `is_active=true` filter to `product_service.getCategories()`.
5. `flutter analyze` clean.

## Success Criteria
- [x] `generateSlug` shared; product create still compiles + behaves the same.
- [x] `CategoryModel` round-trips slug/isActive/sortOrder via to/fromMap.
- [x] `CategoryService` create sets a non-null unique slug; softDelete flips
      is_active; no hard delete anywhere.
- [x] `getCategories()` (customer) filters `is_active=true`.

## Risk Assessment
- Moving slug helper could break product create → covered by Phase 4 regression
  step (create a product after refactor).
- Rename-regenerates-slug could collide → suffix keeps it unique; acceptable.
