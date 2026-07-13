---
phase: 3
title: "Manager stat-card token alignment"
status: done
effort: "30m"
priority: P2
dependencies: []
---

# Phase 3: Manager stat-card token alignment

## Overview
Manager dashboard `_StatCard` renders values in serif Cormorant (`AppTypography.displaySmall`) tinted to each card's accent color, and labels in `AppTypography.caption` (`textHint` — the palette's lowest-contrast tone, meant for placeholders). Admin's identical stat-card pattern uses bold sans `textPrimary` values + `textSecondary` labels. Align Manager to Admin. Also closes old audit M6: the "Đơn chờ xác nhận" (pending) card is tinted `AppColors.success` (green) — semantically wrong and inconsistent with `StatusBadge`, which maps pending→warning (locked by `status_badge_test.dart`).

**Red-team addition:** 'Tổng sản phẩm' already uses `AppColors.warning` (`manager_dashboard_widgets.dart:39`), so pending→warning alone would produce two identical amber cards. Move 'Tổng sản phẩm' to the `StatusColors.info` tone (`#2E5F8A`, already in the theme extension) — result: 4 cards, 4 distinct accents, all from the token vocabulary (primary / warning / info / accent).

## Requirements
- Functional: value = bold sans `textPrimary`; label = `textSecondary`; pending card accent = `AppColors.warning`; 'Tổng sản phẩm' accent = `StatusColors.info` (resolved via `Theme.of(context).extension<StatusColors>()!` — `ManagerStatsGrid.build` has context). Icon keeps per-card accent tint (same as Admin).
- Non-functional: no layout change (keep fontSize 20 — cards are tighter than Admin's; w700 weight only).

## Related Code Files
- Modify: `FE/lib/screens/manager/manager_dashboard_widgets.dart`
  - `:33` pending card `color: AppColors.success` → `AppColors.warning`
  - `:39` 'Tổng sản phẩm' `color: AppColors.warning` → `statusColors.info` (resolve extension once in `build`)
  - `:88-91` label style `AppTypography.caption.copyWith(fontSize: 11)` → `AppTypography.labelSmall.copyWith(fontSize: 11)` (w500, `textSecondary`)
  - `:96-104` value style `AppTypography.displaySmall.copyWith(fontSize: 20, color: color)` → `AppTypography.headlineLarge.copyWith(fontSize: 20, fontWeight: FontWeight.w700)` (Montserrat via token, `textPrimary` — do NOT use a raw `fontFamily:` literal; stay inside `AppTypography`)
- Create: `FE/test/widgets/manager_stats_grid_test.dart`

## Implementation Steps
1. Apply the 4 edits (leave `ManagerQuickActions` untouched — its tinted-bg colored-label pattern matches Admin's action cards).
2. Widget test: pump `ManagerStatsGrid` with a fake `ManagerDashboardStats` inside `MaterialApp(theme: AppTheme.light)` (note: the getter is `AppTheme.light` — `app_theme.dart:10` — matching existing tests); assert value Text color == `AppColors.textPrimary`, pending card Icon color == `AppColors.warning`, product-count Icon color == `StatusColors.standard.info`.
3. `flutter analyze` + `flutter test`.
4. Emulator: manager dashboard — numbers bold/dark, labels legible, pending amber, product-count blue-info.
5. Commit.

## Success Criteria
- [x] No `displaySmall`/`caption` in `_StatCard`; no `success` accent on pending; no duplicate accents across the 4 cards <!-- code re-verified 2026-07-12: _StatCard uses headlineLarge w700; accents primary/warning/info/accent; remaining caption use is in _ActionCard, not _StatCard -->
- [x] New widget test green; analyze/tests green; 1 commit <!-- test/widgets/manager_stats_grid_test.dart; commit 55bc5ca -->

## Risk Assessment
Purely presentational. Value color no longer varies per card — that's the point (matches Admin); icons keep differentiation. Shares `manager_dashboard_widgets.dart` with phase 1 (different hunks); sequential execution only.
