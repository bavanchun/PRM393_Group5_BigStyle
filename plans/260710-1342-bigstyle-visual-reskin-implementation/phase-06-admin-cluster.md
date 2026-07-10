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

## Completion Note (2026-07-10)

**Status:** Done.

**AdminDashboard's AppBar-gradient contrast finding — confirmed false positive**, consistent with the plan's own prediction: "Admin Panel" title/icons are white-on-primary-gradient, the same verified-safe 6.70:1 pairing established independently in Phases 3/4/5. No fix needed.

**Stat-card categorical colors:** 3 of the dashboard's 6 stat cards (Users/Customers/Managers) already referenced proper semantic tokens (`primary`/`success`/`warning`) and weren't guard hits. The other 3 (Products/Orders/Categories) used raw `Colors.blue`/`orange`/`purple` purely as visual differentiators for a 6-metric grid, not semantic status colors — remapped to `StatusColors.info`, `AppColors.primaryDark`, and `AppColors.accent` respectively (all already-existing, already-distinct tokens) rather than inventing new arbitrary hues not blessed by the design session. Preserves the original "6 visually distinct stat cards" property using only tokens already in the frozen palette + its Phase 1/5 additive extensions.

**AdminShell's `NavigationBar`:** `indicatorColor`/`selectedIcon` already referenced `AppColors.primary` correctly — the plan's "update color refs to v2 tokens" instruction was already satisfied via token propagation, confirmed rather than assumed. No code change needed there; only the shell's shadow and its inline `_AdminProfileScreen` header (same light-on-dark-gradient pattern as `manager_shell.dart`'s equivalent, fixed identically) needed touching.

**Per-screen hits fixed:** AdminDashboard 12, AdminUsers 6, AdminCategories 5, AdminShell 6 = 29 total, matching the guard delta exactly.

**Guard:** 59 → 30 (−29). Remaining 30 hits are now entirely in `auth/login_screen.dart` + `auth/otp_input.dart` — Phase 7's full scope, zero stragglers elsewhere. This is the last cluster before whole-plan closeout.

**Verification:** `flutter analyze` clean; `flutter test` 43/43 pass. Regression checklist not manually walked end-to-end (no admin-role QA credentials this session — same constraint as Phases 3-5, and per this phase's own risk note, admin has no dedicated dart-define test button making this harder than other roles regardless); all changes are color/token substitutions, no navigation, bloc-event, or CRUD-logic lines touched in any of the 4 files.
