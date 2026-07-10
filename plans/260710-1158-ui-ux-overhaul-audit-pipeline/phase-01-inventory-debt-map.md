---
phase: 1
title: "Inventory & Debt Map"
status: completed
effort: "S-M (0.5-1 day incl. entry-gate checks)"
priority: P1
dependencies: []
---

# Phase 1: Inventory & Debt Map

## Overview

Produce the authoritative, factual map of the UI surface — every screen per role, shared-widget usage, per-file design-debt — plus verify the pipeline's entry gates (accounts, Gemini key). This inventory is the checklist Phases 2–4 iterate over; nothing downstream may reference a screen not listed here.

**Definition of "screen" (red-team correction — file counts are NOT screen counts):** a screen is (a) a top-level route destination in `app_router.dart`, (b) a shell tab (manager/admin shells host their tabs internally), or (c) a private inline screen class (e.g. `_AdminProfileScreen` in `admin_shell.dart:83`). Widgets/sheets/cards inside screen dirs (e.g. `manager_order_card.dart`, `order_status_update_sheet.dart`) are components, not screens. Expected magnitude ≈ 35 screens, not 47 (dart-file count) or 44+ (plan draft).

## Requirements

- Functional: enumerate all screens per the definition above, grouped by role — customer, manager, admin, guest (splash/login/OTP). Delivery-map is a **customer** screen (`profile_screen.dart:128`); there is no delivery role (`user_model.dart:4`).
- Non-functional: audit-only, no code changes; report ≤ ~200 lines, table-driven.

## Related Code Files (read-only)

- `FE/lib/screens/**/*.dart` — primary source: full dir walk (47 files), classify screen vs component
- `FE/lib/screens/manager/manager_shell.dart`, `FE/lib/screens/admin/admin_shell.dart` — mandatory reads: shell tabs + inline screens invisible to route table
- `FE/lib/config/routes/app_router.dart` — provides the route column only (19 static routes; shells hide the rest); also grep `MaterialPageRoute` for direct-push screens
- `FE/lib/widgets/*.dart` — 10 shared widgets
- `FE/lib/config/theme/*.dart` — tokens v1 baseline
- `docs/ux-flow-audit.md` — pull the 10 `consistency` + 6 `ui` finding IDs per screen

## Implementation Steps

1. **Screens-dir walk first** (router provides route column where one exists): classify every dart file under `lib/screens/` as screen / component / shell; extract shell tabs and inline screen classes; grep `MaterialPageRoute` + `pushNamed` for entry points. Output: screen list with role, file, route/entry, definition-category (a/b/c).
2. Per screen file, measure: LOC, hardcode hits (`grep -c 'Colors\.\|0xFF'` excluding `AppColors`), `.withOpacity` (deprecated) hits, inline `TextStyle`/`GoogleFonts` usage, shared-widget imports.
3. Build shared-widget usage matrix: which of the 10 widgets each screen uses; flag screens using none (fully bespoke UI = highest migration cost).
4. Cross-reference `docs/ux-flow-audit.md`: attach the 10 `consistency` + 6 `ui` finding IDs to their screens, noting which are already marked fixed (✅).
5. Rank screens into migration-cost tiers (heatmap: debt hits × LOC × bespoke-ness).
6. **Entry-gate checks for Phase 2/4** (user-assisted where needed):
   <!-- Updated: Validation Session 1 - demo-customer capture account + user provisions Gemini key -->
   - **Demo customer login works** — validated decision: the seeded demo customer (fake "Khách Demo" data) is the capture account for ALL customer-role screens; verify seed applied + login on the capture AVD.
   - Manager login works on the capture AVD (demo-fix roadmap Phase 1 left "manager OTP login not done" — resolve it now: sign up manager email in-app, run promote SQL per `FE/seed_demo_accounts_and_orders.sql:6-18`).
   - Admin credentials identified and login proven (role-ops plan created an admin account — confirm it still works; note admin has no dart-define test button).
   - `GEMINI_API_KEY`: provided by user and validity-verified 2026-07-10 (models-list 200); stored in local `~/.zshenv`. Remaining check: one real `ck:ai-multimodal` analyze call (model `gemini-2.5-flash`) succeeds before closing this phase.
7. Write report: `reports/phase-01-ui-inventory-debt-map.md` (tables: screens-by-role, debt heatmap, widget matrix, entry-gate results).

## Success Criteria

- [x] Authoritative screen count produced per the screen definition (route destinations + shell tabs + inline classes), per role — not a file count. (30 screens: 2 guest, 15 customer, 9 manager, 4 admin)
- [x] Per-file debt table complete; recount of hardcode hits is authoritative (195 lines vs ~208 draft baseline — small downward drift from recent cleanup commits).
- [x] Every screen tagged with a migration-cost tier (T1 cheap → T3 expensive).
- [x] Entry gates green: manager + admin logins proven; Gemini key preflight done.
- [x] Report written to `reports/phase-01-ui-inventory-debt-map.md` (no PII, accounts by role alias).

See [phase-01 report](./reports/phase-01-ui-inventory-debt-map.md) for full data.

## Risk Assessment

- **Ambiguous screen-vs-component classifications** → decide by "does it own a full Scaffold/route or shell tab slot"; list borderline cases explicitly rather than silently dropping.
- **Dead screens discovered** (files never routed) → list them; propose exclusion from capture in Phase 2 rather than silently skipping.
- **Entry gates fail (no manager login, no Gemini key)** → phase output still valid; Phase 2 blocks until user resolves — surface immediately, don't defer discovery to capture day.
