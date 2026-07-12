---
phase: 5
title: "S4: Real Product Search"
status: completed
priority: P2
dependencies: [1]
effort: "M"
---

# Phase 5: S4 — Real Product Search

## Overview

Replace the fake home search bar (a `GestureDetector` that just navigates to `/products`, `home_screen.dart:260–283`) with a working search: a dedicated search screen with an autofocused input, live-filtered results, and lightweight recent/suggested terms. Largest effort of the plan (feature-ish) — cap scope tightly.

## Requirements

- Functional: typing a query returns matching products (name/tags); results animate in; empty-query shows recent + suggested; no-results shows a clear empty state; tapping a result opens product_detail.
- Non-functional: debounced queries; reuses existing `ProductService`/`ProductBloc`; nav architecture unchanged (adds one route).

## Architecture

- **Route:** add `case '/search'` in `config/routes/app_router.dart` (after `/products`, line ~37). Home search bar navigates here (still a tap target, but now leads to a real input) with autofocus.
<!-- Updated: Validation Session 1 — reuse existing server ilike; no new service method; no flutter_animate -->
- **Query path (VALIDATED):** verification found `ProductService.getProducts({searchQuery})` **already** exists and does Supabase `ilike('name', '%$searchQuery%')` (`product_service.dart:16,38`). **Reuse it directly** — no new service method. Wire it behind a small `SearchBloc` (or a `SearchProducts(query)` event) so states stay explicit.
- **Debounce:** 250–300ms debounce on input (`Timer`), so keystrokes don't spam queries. Show `AppSkeleton` list while querying.
- **Recent searches:** **in-memory v1** (a `List<String>` held in the search bloc/state or a simple in-screen list) — `shared_preferences` persistence explicitly deferred (accepted default).
- **Suggested:** static seed (e.g., top categories/tags) — no ML, no backend.
- **Results animation:** stagger-in via the Phase 1 built-in `StaggeredEntrance` primitive (no `flutter_animate`).

## Related Code Files

- Create: `FE/lib/screens/search/search_screen.dart`; optionally `FE/lib/blocs/search/` (or reuse `ProductBloc` with a query event)
- Modify:
  - `FE/lib/config/routes/app_router.dart` — `/search` route
  - `FE/lib/screens/home/home_screen.dart` — search bar → push `/search`
  - `FE/lib/services/product_service.dart` — **no change** (already has `getProducts(searchQuery:)` with `ilike`)

## Implementation Steps

1. Wire `SearchBloc` to the existing `getProducts(searchQuery:)` (no service change).
2. Build `search_screen.dart`: autofocus field, debounce, results list (reuse `ProductCard`), states (empty-query / loading / results / no-results).
3. Add recent (in-memory) + suggested (static) sections for empty query.
4. Add `/search` route; point the home search bar at it.
5. Wire result tap → product_detail (Hero from Phase 3 applies if the card carries a tag).
6. Test: typing, debounce, no-results, back-to-home, rapid typing.

## Success Criteria

- [x] Home search bar opens a real, autofocused search screen.
- [x] Queries return correct matches; debounced; skeleton while loading.
- [x] Empty-query shows recent (session) + suggested; no-results shows a clear empty state.
- [x] Result tap opens the correct product; `flutter analyze` clean.

## Risk Assessment

<!-- Red Team 2026-07-12 (H4): product_list ALREADY has a working search — TextField (product_list_screen.dart:155), SearchProducts event (:180), filteredProducts render (:251), no-results state (:375), over ProductBloc.SearchProducts (product_bloc.dart) + getProducts(searchQuery:) ilike (product_service.dart:18,37-38). USER DECISION: keep a dedicated /search surface anyway. -->
- **ACCEPTED RISK (red-team H4) — two search surfaces:** a dedicated `/search` screen duplicates the search UX product_list already ships. User chose to keep it for a distinct search entry from home. **Mitigation:** the new screen must reuse `getProducts(searchQuery:)` (and mirror `ProductBloc.SearchProducts` filter semantics) so behavior can't diverge from product_list; do NOT fork a second filtering algorithm. If time-boxed at the demo, the fallback is the ~5-line MVP (home search bar → product_list with autofocus of the existing `_searchFocusNode`, `product_list_screen.dart:26`).
- **Scope creep** (facets, history persistence, typo-tolerance) → HARD cap at v1: query + debounce + in-memory recent + static suggested. Anything more is a follow-up.
- **Supabase `ilike` performance / indexing** → seed dataset is tiny; if server path chosen, a simple `ilike` is fine; note index need only if catalog grows.
- **Deadline risk** (largest phase) → this is intentionally ordered 5th; if time-boxed, ship server/client filter + results and drop recent/suggested polish first.
