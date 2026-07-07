# Manager Category Management — Implementation Journal

Date: 2026-07-03 · Branch: dev · Commit: c2111fe

## What
Replaced the manager dashboard "Danh mục" coming-soon stub with real category
CRUD: list (active+inactive, product count), create, edit, soft-delete.

## Key decisions
- **Soft-delete** (`is_active=false`), not hard-delete — `products.category_id`
  FK makes DELETE of a used category fail. Update-only path is FK-safe by
  construction.
- **Shared slug util** (`utils/slug.dart`): `categories.slug` is NOT NULL +
  unique, the same trap that broke product create (fixed 6ba7029). Extracted the
  generator out of product_service so both create paths share it (DRY).
- **Dedicated `ManagerCategoryBloc`** mirroring `ManagerProductBloc`; image
  upload reuses `ProductService.uploadProductImage` (no new storage bucket).
- Customer-facing `getCategories()` now filters `is_active=true`.

## Bugs caught in review (fixed before ship)
- **List collapsed to a false "error" widget** when the shared bloc emitted a
  non-list state (ImageUploaded / OperationSuccess) from the edit sheet. Fixed by
  caching the last loaded list in the list screen's State and only showing the
  error widget when there is no data yet.
- **Submit stayed tappable during image upload**, capturing a stale null image
  URL. Fixed by disabling submit while `_uploadingImage`.

## Verification
Emulator (manager role): list opens (no coming-soon); create → slug
`qa-danh-muc-test-5o3b`, no 23502; soft-delete → `is_active=false`, badge
"Đã ẩn", no FK error; customer active filter 5/6; product-create regression
passed (moved slug util intact). `updateCategory` rename-slug-regen verified by
review (shares create/soft-delete plumbing). Test data removed; roles restored.

## Known limitation
A product in a soft-deleted category is silently reassigned to the first active
category if a manager opens its editor and saves (because the product editor's
dropdown uses the now-filtered `getCategories()`). Low severity; deferred.
