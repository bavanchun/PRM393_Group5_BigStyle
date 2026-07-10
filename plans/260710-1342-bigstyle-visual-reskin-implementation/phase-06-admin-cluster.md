---
phase: 6
title: "Admin Cluster"
status: pending
effort: "M-L (1 day, 4 screens)"
priority: P2
dependencies: [5]
---

# Phase 6: Admin Cluster

## Overview

Smallest role cluster (4 screens), but 4/4 at zero shared-widget use (Phase 1) — same bespoke-migration profile as manager, just less surface area. 2 screens tagged L (AdminDashboard, AdminUsers).

## Screens (effort tags from Phase 4 cluster table)

| Screen | File | Effort | Findings source |
|---|---|---|---|
| AdminDashboard | `FE/lib/screens/admin/admin_dashboard_screen.dart` | **L** — AppBar text-contrast flagged, re-verify with real tool | `phase-04-gap-findings-admin.md` |
| AdminUsers | `FE/lib/screens/admin/admin_users_screen.dart` | **L** | same |
| AdminProfile (inline) | `FE/lib/screens/admin/admin_shell.dart:83` (`_AdminProfileScreen`) | M | same |
| AdminCategories | `FE/lib/screens/admin/admin_categories_screen.dart` | M | same |

## Implementation Steps

1. Per screen: hardcode → token sweep using Phase 1's per-file counts (AdminDashboard 12 lines, AdminUsers 5, AdminCategories 5) as checklist.
2. AdminDashboard: re-check the AppBar text-contrast finding with a real WCAG tool before accepting — per the plan-level risk note, audit-cited numbers for this exact class of finding (text on the new primary) were shown unreliable in Phase 4's spot-check, and the precomputed table in `docs/design-tokens-v2.md` shows white-on-v2-primary clears AA comfortably (6.70:1) — this finding may be a false positive; verify before spending fix effort.
3. AdminUsers: same hardcode sweep; this screen has the most LOC in the admin cluster (671) — budget accordingly even though hardcode-line count is moderate (5).
4. AdminShell's `NavigationBar` (bottom nav, not one of the shared widgets — it's inline in `admin_shell.dart`, unlike manager which uses the shared `manager_bottom_nav.dart`): update its `indicatorColor`/`selectedIcon` color refs to v2 tokens — color refs ONLY. Extracting it into a shared widget is a follow-up outside this plan, not an in-phase option. <!-- Updated: Red Team Session 1 - optional refactor removed from step list so it can't leak into scope -->
5. `flutter analyze` per screen; `flutter test` at cluster end.

## Regression Checklist

- [ ] AdminDashboard: stats rendering (revenue/users/products/orders — per `admin-smoke-baseline.md`'s live-verified values) unchanged.
- [ ] AdminUsers: user list/role display unchanged.
- [ ] AdminCategories: category CRUD unchanged.
- [ ] AdminProfile: edit-profile link, logout unchanged.
- [ ] Bottom `NavigationBar` tab switching unchanged (this is a shell-infra element, not a screen — do not restructure its tab order, only its color scheme, per this plan's out-of-scope constraint).

## Success Criteria

- [ ] All 4 screens migrated.
- [ ] AdminDashboard's contrast finding resolved (fixed or confirmed-false-positive-and-closed with the real-tool measurement documented).
- [ ] Hardcode-guard passes for this cluster's files; `flutter analyze` + `flutter test` clean.

## Risk Assessment

- **Admin has no dedicated dart-define test button** (per the source audit pipeline) — manual QA of this cluster requires either reusing the manager dart-define slot pointed at an admin QA account (documented technique, see `plans/260710-0001-bigstyle-role-ops-hardening/reports/admin-smoke-baseline.md`) or real OTP login; budget for this when scheduling QA passes.
