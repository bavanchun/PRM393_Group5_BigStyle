---
phase: 4
title: "Manager dashboard customer count"
status: pending
effort: ""
---

# Phase 4: Manager dashboard customer count

> ⚠️ **RED-TEAM OVERRIDE — DIAGNOSIS CORRECTED (RT-5).** The count logic is **already correct**: `manager_dashboard_stats.dart:35` counts `role=='customer'`. Do NOT "fix" `fromRows` — that's a phantom fix; the dashboard would still show 0 in prod. Real cause: the manager client receives **0 customer rows** from `profiles` — either RLS (`is_manager()` returns false for the logged-in manager → falls back to own-profile-only policy → sees just self), or the seeded customer's `role` isn't literally `'customer'`. Diagnose by running the count **under the manager's JWT** (not service-role): `select count(*) from profiles where role='customer'` via the manager session; check `is_manager()` result + the customer's exact role string. Fix the ACTUAL layer (RLS policy / `is_manager()` / seed role). Replace the mock-only test with one that exercises RLS.

## Overview
Fix F5 (MED): manager dashboard "Khách hàng" renders 0 though DB has ≥1 customer. Root cause is **data visibility (RLS), not the count query** — see override above.

## Requirements
- Functional: "Khách hàng" reflects the real customer count per the intended definition (all customer-role profiles, OR distinct customers who ordered — decide and document).
- Non-functional: query respects manager RLS (managers can view all profiles via `is_manager()`).

## Architecture
Locate the count in `OrderService.getDashboardStats()` (and/or `ManagerDashboardStats` model / `AdminService.getDashboardStats`). Verified live: `profiles where role='customer'` = 1, `distinct order user_id` = 2, dashboard shows 0 → the query likely filters wrong (e.g., counts a non-existent field, or role mismatch, or store-scoped join returning none). Fix to count `profiles.role = 'customer'` (or distinct order customers if that's the intended metric — confirm with the label's meaning).

## Related Code Files
- Modify: `FE/lib/services/order_service.dart` (`getDashboardStats`), possibly `FE/lib/models/manager_dashboard_stats.dart`.
- Verify: `FE/lib/blocs/manager/manager_bloc.dart`, manager dashboard screen stat card.
- Tests: add/extend a dashboard-stats test (mock service) asserting non-zero customer count for seeded data.

## Implementation Steps (TDD)
1. Failing test: given profiles with N customers, `getDashboardStats().totalCustomers == N` (mock Supabase response).
2. Inspect the actual query; fix the filter/count.
3. Verify live on branch/prod-read via `execute_sql` cross-check (already: 1 customer).
4. Confirm the dashboard card renders the corrected number (was 0 → ≥1) via web manager login.

## Success Criteria
- [ ] Dashboard "Khách hàng" shows the correct customer count (≥1 for current data).
- [ ] Test locks the count logic; suite green.

## Risk Assessment
- Low. Read-only stat fix. Main risk = choosing the wrong definition; resolve by matching the card's intent (all customers vs customers-who-ordered) — document the chosen definition.
