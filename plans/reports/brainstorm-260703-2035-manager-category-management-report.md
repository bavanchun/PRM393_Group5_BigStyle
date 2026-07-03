---
title: "Manager Category Management — Brainstorm Report"
date: 2026-07-03
branch: dev
status: design-approved
modes: []
supersedes_stub: "manager dashboard 'Danh mục' coming-soon action"
---

# Manager Category Management — Design

## Problem
Manager dashboard quick action **"Danh mục"** is a stub (`onComingSoon` →
"Tính năng đang phát triển"). Categories are seed-only in DB; manager cannot
create/rename/hide them. Demo-visible dead button + genuine missing CRUD.

## Scope (approved)
Full, thorough version:
- **List** all categories (active + inactive) with product count.
- **Create**: name (required) → auto slug; optional image; sort_order; is_active.
- **Edit**: name, image, sort_order, toggle is_active.
- **Delete**: **soft-delete** (set `is_active=false`) — avoids FK breakage.

Out of scope: reordering by drag is optional polish; customer-home filtering of
inactive categories is a follow-up (see Risks).

## Locked decisions (user)
- Delete strategy: **soft-delete** via `is_active`.
- Fields: **full** — name + slug(auto) + image_url + sort_order + is_active.
- State: **dedicated `ManagerCategoryBloc`** (matches app's bloc-heavy convention).

## Codebase facts (scouted)
- RLS ready: policy `"Managers can manage categories" (ALL, is_manager())` —
  manager CRUD allowed, **no DB/migration change needed**.
- `categories` cols: `id, name(NN), slug(NN), image_url?, sort_order(def 0),
  is_active(def true), created_at`.
- **`categories.slug` is NOT NULL** — same trap just fixed for products. Must
  auto-generate slug (reuse the diacritic-stripping helper).
- FK `products.category_id → categories.id` → hard-delete of a used category
  fails; soft-delete sidesteps it.
- `CategoryModel` currently lacks `slug/isActive/sortOrder` → must extend.
- `getCategories()` does `select('*')` with no `is_active` filter.

## Architecture (mirror existing manager patterns)
- **Wire** dashboard "Danh mục" action → `ManagerCategoryListScreen` (replace
  `onComingSoon`). Pattern: `manager_orders_screen` (list) + bottom sheet like
  `order_status_update_sheet` for create/edit.
- **New files**
  - `screens/manager/categories/manager_category_list_screen.dart`
  - `screens/manager/categories/manager_category_edit_sheet.dart`
  - `services/category_service.dart` (getAll / create / update / softDelete)
  - `blocs/manager_category/` (bloc + event + state)
  - `utils/slug.dart` (shared `generateSlug`) — extract from `product_service`.
- **Modify**
  - `models/category_model.dart` — add `slug`, `isActive`, `sortOrder` (+ toMap/fromMap).
  - `services/product_service.dart` — use shared `generateSlug` (DRY) instead of
    the private copy added in fix 6ba7029.
  - `screens/manager/manager_dashboard_widgets.dart` / `manager_dashboard.dart` —
    "Danh mục" action navigates instead of coming-soon.
  - Bloc provider wiring (wherever `ManagerBloc` is provided).

## Risks
- **slug NN + unique**: generate `slugify(name)-<short-suffix>`; reuse helper.
- **Image upload bucket**: product images upload to a `products` storage bucket
  via `uploadProductImage`. Categories need a bucket + RLS, OR reuse products
  bucket, OR allow image via URL/skip. **Open item — resolve in plan.**
- **Inactive categories still visible on customer home**: `getCategories()` has
  no `is_active` filter. Either add `.eq('is_active', true)` for customer reads
  (and an unfiltered variant for manager), or accept for demo. **Decide in plan.**
- Product-count per category not a DB column — compute via count query or join.

## Acceptance criteria
- Manager opens "Danh mục" → sees category list (no coming-soon).
- Create category with name → row appears, slug auto-set, no 23502 error.
- Edit renames / toggles active; list reflects it.
- Soft-delete hides category from active list without FK error.
- `flutter analyze` clean.

## Open questions
1. Category image: upload (needs bucket) vs URL input vs omit for now?
2. Filter inactive categories out of customer-facing `getCategories()` this
   round, or defer?
