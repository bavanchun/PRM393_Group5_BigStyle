---
title: Manager Category Management
description: >-
  Replace the manager dashboard 'Danh mục' coming-soon stub with real category
  CRUD (list, create, edit, soft-delete) for BigStyle. Flutter (BLoC) +
  Supabase.
status: completed
priority: P2
branch: dev
tags:
  - manager
  - category
  - crud
  - flutter
  - supabase
blockedBy: []
blocks: []
created: '2026-07-03T13:45:27.191Z'
createdBy: 'ck:plan'
source: skill
---

# Manager Category Management

## Overview

Manager dashboard quick action **"Danh mục"** is a stub (`onComingSoon`).
Give managers real category management: list (active+inactive, with product
count), create (name → auto slug + image + sort_order), edit, and **soft-delete**
(`is_active=false`, avoids FK breakage). RLS already permits it
(`is_manager()`), so **no DB migration**. Design source:
`plans/reports/brainstorm-260703-2035-manager-category-management-report.md`.

**Stack:** Flutter + BLoC + Supabase. Mirrors the existing `ManagerProductBloc`
(Load/Create/Update/Delete/UploadImage) and product create screen patterns.

## Locked decisions (from brainstorm)
- **Delete = soft-delete** via `is_active` toggle.
- **Fields = full**: name + slug(auto) + image_url + sort_order + is_active.
- **State = dedicated `ManagerCategoryBloc`** (mirror `ManagerProductBloc`).
- **Image upload = reuse** `product_service.uploadProductImage` (products bucket);
  no new storage bucket.

## Phases

| Phase | Name | Status |
|-------|------|--------|
| 1 | [Data Layer & Slug Util](./phase-01-data-layer-slug-util.md) | Completed |
| 2 | [Category Bloc](./phase-02-category-bloc.md) | Completed |
| 3 | [UI & Dashboard Wiring](./phase-03-ui-dashboard-wiring.md) | Completed |
| 4 | [Verify](./phase-04-verify.md) | Completed |

**Runtime-verified on emulator (manager role):** list opens (no coming-soon),
create → slug `qa-danh-muc-test-5o3b` + no 23502, soft-delete → `is_active=false`
+ badge "Đã ẩn" + no FK error, customer active-filter = 5/6, product-create
regression passed (moved slug util intact). `updateCategory` (rename slug-regen)
verified by code review; shares the create/soft-delete plumbing. Test data
removed; roles restored (customer/customer/manager).

## Dependency Chain

```
Phase 1 (model + service + slug util) ──> Phase 2 (bloc needs service)
Phase 2 (bloc) ──> Phase 3 (UI needs bloc + provider)
Phase 3 (UI) ──> Phase 4 (runtime verify)
```

Sequential; each phase depends on the prior. Phase 1 also refactors the slug
helper out of `product_service.dart` (added in commit 6ba7029) into a shared
util — product create must keep working after the move.

## Acceptance Criteria (whole plan)

- [x] Manager taps "Danh mục" on dashboard → category list (no coming-soon).
- [x] Create category (name + optional image/sort) → row appears, slug auto-set,
      no 23502 slug error.
- [ ] Edit category (name/image/sort/active) persists and reflects in list. <!-- updateCategory verified by code review only per docs/journals/260703-manager-category-management.md; save-path not device-verified; deferred to device pass (plans/260712-1644 Phase 1) -->
- [x] Soft-delete hides a category with products **without** FK error.
- [x] Product create still works (shared slug util refactor intact).
- [x] Customer home shows only active categories.
- [x] `flutter analyze` clean. <!-- re-verified 2026-07-12: No issues found -->

## Out of Scope
- Drag-to-reorder UI (sort_order editable via number field only).
- Category detail analytics.
- Hard-delete path (soft-delete only this round).

## Open Questions
None — image mechanism (reuse products bucket) and inactive-filter (add
`is_active` filter for customer reads) resolved during planning.
