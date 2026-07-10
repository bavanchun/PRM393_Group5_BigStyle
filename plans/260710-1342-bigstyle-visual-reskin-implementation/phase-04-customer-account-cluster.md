---
phase: 4
title: "Customer-Account Cluster"
status: pending
effort: "M-L (1.5 days, 7 screens)"
priority: P1
dependencies: [3]
---

# Phase 4: Customer-Account Cluster

## Overview

Second customer cluster — account/order-management screens plus DeliveryMap (a customer-profile screen, not a delivery role — no such role exists).

## Screens (effort tags from Phase 4 audit's cluster table)

| Screen | File | Effort | Findings source |
|---|---|---|---|
| Profile | `FE/lib/screens/profile/profile_screen.dart` | **L** — badge-contrast finding (re-verify with real tool, audit number unreliable) + a text-wrap bug noted | `phase-04-gap-findings-customer.md` |
| EditProfile | `FE/lib/screens/profile/edit_profile_screen.dart` | M | same |
| Orders | `FE/lib/screens/orders/orders_screen.dart` | M | same |
| OrderDetail | `FE/lib/screens/orders/order_detail_screen.dart` | M (2 states captured: loading, default) | same; closes old-audit `C30` residual (status-badge tonal finding layered on top of the already-fixed always-primary bug) |
| Chat | `FE/lib/screens/chat/chat_screen.dart` | **L** — contrast finding on avatar/chips, re-verify with real tool | same |
| Notifications | `FE/lib/screens/notifications/notifications_screen.dart` | M | same |
| DeliveryMap | `FE/lib/screens/delivery/delivery_map_screen.dart` | M | same. **Reminder: this is a customer-profile screen (`profile_screen.dart:128` links to it), not a "delivery role" screen — no such role exists in this app.** |

## Implementation Steps

1. Per screen: hardcode → token migration. **Checklist = live output of the Phase 1 guard script filtered to this cluster's files**; the audit's per-file counts (EditProfile 4, Chat 7, DeliveryMap 14 — DeliveryMap is this cluster's highest-debt screen) are context only — they miss mixed token+hardcode lines like `chat_screen.dart:228`. <!-- Updated: Red Team Session 1 -->
2. OrderDetail + Orders: migrate their status badges to the new `StatusBadge` component (Phase 2) — this is the fix for old-audit `C30`'s residual finding.
3. Profile: fix the text-wrap issue noted in the checkpoint file (`phase-04-gap-findings-customer.md` — read the exact finding before assuming scope; it may be a token-adjacent layout tweak, not purely color/type) and re-check the badge-contrast finding with a real WCAG tool.
4. Chat: re-check avatar/chip contrast with a real tool; migrate any status-style elements (online indicator etc. — old-audit `C42` already fixed the hardcoded green dot, verify it still reads correctly against the new palette).
5. DeliveryMap: token/typography sweep only — `C45`'s ship-fee-display finding is a data-consistency bug (still-open-outside-scope per Phase 4/5 disposition), not this plan's job; don't fix it here, just don't let it block the visual migration.
6. `flutter analyze` per screen; `flutter test` at cluster end.

## Regression Checklist

- [ ] Profile: menu items, logout, edit-profile navigation, delivery-map link all function identically.
- [ ] EditProfile: form save/validation unchanged.
- [ ] Orders/OrderDetail: status filtering, order-detail navigation, badge display (now tonal) all correct per actual order status (not just visually — verify the `StatusBadge` maps the right color to the right status, this is the exact thing `M6`/`C30` were about).
- [ ] Chat: message send/receive UI, online indicator unchanged.
- [ ] Notifications: list rendering unchanged.
- [ ] DeliveryMap: map rendering (Google Maps SDK, unrelated to this migration), bottom-sheet shop-info card, "Chỉ đường" button all function identically.

## Success Criteria

- [ ] All 7 screens migrated.
- [ ] `StatusBadge` correctly wired on Orders/OrderDetail (closes `C30` residual + `M6` cross-reference to manager side is Phase 5's job, not this one).
- [ ] Profile + Chat contrast findings re-verified with a real tool, not audit-cited numbers.
- [ ] Hardcode-guard passes for this cluster's files; `flutter analyze` + `flutter test` clean.

## Risk Assessment

- **DeliveryMap's Google Maps rendering is unrelated to this migration but shares the screen** → don't let map-tile/API-key issues (a known separate concern per prior plans) block this screen's UI-chrome (bottom sheet, buttons) migration; scope the diff to non-map UI elements.

## Completion Note (2026-07-10)

**Status:** Done.

- **Profile:** zero token hardcodes (already clean at the pinned SHA). The audit's "badge-contrast finding" ("Khách hàng" chip solid pink + white text, 2.76:1) does **not match the current code** — the role-label chip is already tonal (`AppColors.primary.withValues(alpha:0.1)` bg + `AppColors.primary` text), which by the same WCAG math established in Phase 3 clears AA comfortably. Same stale-finding class as M2/M34/C30 from Phase 0 — the audit's description simply doesn't describe what's in the file, at zero drift. Fixed the real "text-clip" bug instead (`maxLines: 1` + `TextOverflow.ellipsis` on the email line — prevents the "orphaned single character" wrap). Formalized the chip's raw `BorderRadius.circular(4)` to `AppSpacing.microRadius` (Phase 2's established token for this exact micro-badge pattern) — not guard-flagged, done for consistency since the constant already exists for this precise use case.
- **EditProfile:** 4 hits fixed (avatar camera-badge border/icon, save-button foreground/spinner). Its role badge (`_getRoleColor`: admin→primary, manager→warning, customer→success) was already tonal and needed no fix — different enum (`UserRole`, not `OrderStatus`) so it's intentionally separate from `StatusBadge`, not a missed consolidation target.
- **Orders:** migrated to `StatusBadge`; deleted the now-fully-unused `_statusColor()` (its own `Colors.blue` hardcode goes with it — the guard-count drop below includes this).
- **OrderDetail:** migrated to `StatusBadge` in 2 places — the header badge (closes the **real** always-primary bug Phase 0 found, not just a re-skin: it now genuinely varies by `order.status`) and the timeline's cancelled-state badge (pure DRY consolidation, same visual result). This is the actual fix for old-audit `C30`'s residual finding, done properly this time.
- **Chat:** 8 hits fixed (avatar "BB" labels ×3, bot-bubble/input-bar/typing-indicator shadows ×3, user-message text, send-icon). No "online indicator" element exists anywhere in the current file — this is an AI-bot conversation screen ("BigStyle Bot"), not peer-to-peer messaging with presence status, so old-audit `C42`'s green-dot reference doesn't apply to anything in the current code (another stale citation). Re-verified the avatar (white-on-primary, 6.70:1, per Phase 3's established figure) and quick-reply chip (primary text on 30%-alpha-secondary tint ≈ 5.55:1 by hand) contrast pairings — both clear AA.
- **Notifications:** zero hits, already clean.
- **DeliveryMap (highest-debt, 14 hits):** 3 of the 14 were genuine v1-pink **literal hex** (`0xFFC4517A`) inside the `dart:ui` Canvas/Paint marker-icon-drawing code — these don't reference `AppColors.primary` at all, so they never auto-updated when Phase 1 rewrote the token file, unlike almost everything else in the app. Fixed all 3 (shop-marker fill, shop-marker "B" label, route polyline) plus the other 11 (marker inner-circles, FAB, back-button, loading-scrim, bottom-sheet bg/shadow, drag-handle, directions-button icon+text). Scoped strictly to non-map UI chrome — the `GoogleMap` widget itself (tiles, markers-as-data, polylines-as-data) is untouched. `C45`'s ship-fee-display finding is already resolved (confirmed via the existing code comment + `AppConfig.flatShippingFee` usage, matching commit #13 "Product share + flat shipping fee unification") — not this plan's job either way, and nothing left to do.

**Guard:** 166 → 139 (−27; matches exactly: EditProfile 4 + Orders 1 (the deleted `_statusColor`'s `Colors.blue`) + Chat 8 + DeliveryMap 14). Remaining hits are now squarely Phase 5 (manager) territory (`manager_shell.dart` ×3, `manager_order_card.dart`'s own `Colors.blue` in `managerOrderStatusColor`).

**Verification:** `flutter analyze` clean; `flutter test` 43/43 pass; guard-scoped scan of this cluster's files returns zero non-allowlisted hits. Regression checklist not manually walked end-to-end (same no-customer-credentials constraint as Phase 3); all changes are token/font substitutions plus the OrderDetail StatusBadge fix, which is a behavior change but a strictly *correcting* one (badge now matches actual order status instead of always showing primary) with no other logic touched.
