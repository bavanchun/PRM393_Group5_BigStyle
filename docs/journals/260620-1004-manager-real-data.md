---
date: 2026-06-20
session: phase-3-manager-real-data
---

# Journal: Phase 3 Manager Real Data

## Context

Manager dashboard statistics and order rows were hardcoded despite manager-capable RLS already existing in Supabase.

## What Happened

- Added normalized order/profile joins and minimal dashboard queries.
- Added ManagerBloc as the shared state source for dashboard and orders.
- Replaced mock statistics, orders, and the invalid `preparing` filter.
- Wired real order detail navigation and pull-to-refresh states.

## Decisions

- Count delivered orders created today as today's revenue because schema has no delivery timestamp.
- Keep Supabase RLS as the authorization boundary; no service-role credential enters Flutter.
- Ignore stale filter responses so rapid taps cannot overwrite the newest selection.

## Verification

- Live anon REST shapes returned HTTP 200 without exposing protected rows.
- Seven tests passed, including out-of-order filter completion.
- Android release APK built; analyzer has zero errors and warnings.

## Next

- User promotes a real manager profile and smoke-tests Phase 3.
- Await approval before Phase 4.

## Unresolved Questions

None.
