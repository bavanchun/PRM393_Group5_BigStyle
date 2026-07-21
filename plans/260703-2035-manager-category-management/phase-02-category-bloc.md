---
phase: 2
title: Category Bloc
status: completed
effort: ''
---

# Phase 2: Category Bloc

## Overview
Add `ManagerCategoryBloc` mirroring `ManagerProductBloc`, and register it in the
app's `MultiBlocProvider`.

## Requirements
- Functional: events to load, create, update, soft-delete, and upload image;
  states for loading/loaded/error; after a successful mutation, reload the list.
- Non-functional: follow the exact structure/style of
  `blocs/manager_product/` (class-based states, not copyWith).

## Architecture
- Reuse the `ManagerProductBloc` shape: `Initial/Loading/Loaded(list)/Error(msg)`.
- On create/update/softDelete success → re-fetch via
  `CategoryService.getCategoriesForManager()` and emit `Loaded`.
- Image upload reuses `ProductService.uploadProductImage` (returns public URL);
  the bloc can depend on both services, or expose an upload event that calls it.

## Related Code Files
- Create: `FE/lib/blocs/manager_category/manager_category_bloc.dart`
- Create: `FE/lib/blocs/manager_category/manager_category_event.dart`
  - `LoadManagerCategoriesEvent`
  - `CreateManagerCategoryEvent(CategoryModel)`
  - `UpdateManagerCategoryEvent(CategoryModel)`
  - `SoftDeleteManagerCategoryEvent(String id)`
  - `UploadManagerCategoryImageEvent(...)` (reuse product upload)
- Create: `FE/lib/blocs/manager_category/manager_category_state.dart`
  - `ManagerCategoryInitial/Loading/Loaded(List<CategoryModel>)/Error(String)`
  - Optional `ManagerCategoryActionSuccess` for snackbar (mirror product bloc if
    it has one; otherwise reload + let UI listen).
- Modify: `FE/lib/main.dart` — add `BlocProvider(create: (_) =>
  ManagerCategoryBloc(CategoryService(), ProductService()))` to the existing
  `MultiBlocProvider` (match how `ManagerProductBloc` is registered).

## Implementation Steps
1. Copy `manager_product` bloc/event/state trio; rename to category; swap
   `ProductService.getProducts` → `CategoryService.getCategoriesForManager`, and
   create/update/delete → category equivalents (softDelete for delete).
2. Wire image upload event to `ProductService.uploadProductImage`.
3. Register the bloc in `main.dart` MultiBlocProvider next to ManagerProductBloc.
4. `flutter analyze` clean.

## Success Criteria
- [x] Bloc compiles; events map to `CategoryService` methods.
- [x] Success of a mutation triggers a list reload (`Loaded`).
- [x] Errors surface as `Error(message)`.
- [x] Bloc available via `context.read<ManagerCategoryBloc>()` app-wide.

## Risk Assessment
- Wrong provider placement → screen can't read bloc; verify against
  ManagerProductBloc registration in the same file.
