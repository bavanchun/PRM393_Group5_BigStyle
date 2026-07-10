---
phase: 5
title: "On-Camera Polish"
status: completed
priority: P2
dependencies: []
effort: "M"
---

# Phase 5: On-Camera Polish

## Overview

Fix the things that work but look unfinished on screen: wrong app branding, UUID order codes, dead buttons in the demo path, divergent shipping, and the chat mock tells. Covers M17, M19, M18, X2, X3/C21, C40, C41, C42, and the demo-path dead buttons in X7. Mostly independent; run after the blockers.

## Requirements

- Functional: manager product screen shows "BigStyle" branding + a surface (white) AppBar; every order code shown as human `orderNumber`; a single realistic flat shipping fee; chat labeled honestly with no fake presence dot / no mock image button; no visibly dead buttons on the recorded path.
- Non-functional: reuse existing `AppColors` tokens; no new hardcoded colors.

## Architecture & Findings (verified file:line)

- **M17/M19 (`manager/products/manager_product_list_screen.dart:45-77`):** AppBar `backgroundColor: AppColors.primary` (pink — unique vs `surface` elsewhere) + title `'CurveFit Admin'` (wrong app name).
- **M18 (`…manager_product_list_screen.dart:48-51,457-492`):** dead hamburger `onPressed: () {}`; fake pagination chevrons `onPressed: () {}` + static "Hiển thị N trên N".
- **X2 — UUID instead of orderNumber (6 sites):** `checkout_screen.dart:81`, `orders_screen.dart:78`, `order_detail_screen.dart:61`, `manager_order_detail_screen.dart:101`, `manager_order_card.dart:52`; `payment_qr_screen.dart:81` already prefers `orderNumber`. `order_model.dart:89` has `String? orderNumber` (DB `order_number`). NOTE: COD success path sets only `orderId`, never `orderNumber` (`checkout_bloc.dart` / `checkout_screen.dart:81`) — fixing display there needs `orderNumber` to be populated in that path too.
- **X3/C21 — shipping (`checkout_screen.dart:31` flat `1000`; `delivery_map_screen.dart:269-274` distance tiers; `checkout_bloc.dart:152-183` dead distance logic):** three sources, only flat used. **Decision: flat realistic value; delete the 2 unused.**
- **C40/C41/C42 (`chat_screen.dart:121-135,126-132,434,511`):** title "BigStyle Bot / Trợ lý thời trang AI" (keep, clarify); hardcoded green `AppColors.success` online dot (remove/justify); image button → snackbar "sẽ sớm được cập nhật" (hide or wire).
- **X7 demo-path dead buttons:** `profile_screen.dart:112-116` "Sản phẩm yêu thích" no `onTap` (wire → `/favorites`); `product_detail_screen.dart:139` Share `onPressed: () {}` (hide or wire share_plus); `edit_profile_screen.dart:70-84` decorative camera badge (hide or wire picker).

## Related Code Files

- Modify: `FE/lib/screens/manager/products/manager_product_list_screen.dart:45-77` — AppBar → `AppColors.surface`, title → "BigStyle" / "Quản trị BigStyle"; hide dead hamburger + fake pagination (M17/M18/M19).
- Modify: X2 sites — replace `order.id.substring(0,8)` with `order.orderNumber ?? order.id.substring(0,8).toUpperCase()`: `checkout_screen.dart:81`, `orders_screen.dart:78`, `order_detail_screen.dart:61`, `manager_order_detail_screen.dart:101`, `manager_order_card.dart:52`. Ensure COD path populates `orderNumber`.
- Modify: `FE/lib/screens/checkout/checkout_screen.dart:31` — flat fee → realistic value (user's number, placeholder `30000`). Delete unused: `checkout_bloc.dart:152-183` distance logic + `delivery_map_screen.dart:269-281` fee getters (or repoint delivery map to the same constant).
- Modify: `FE/lib/screens/chat/chat_screen.dart:126-132,434/511` — remove/justify online dot; hide image button or wire `image_picker`; keep AI label clear.
- Modify: `FE/lib/screens/profile/profile_screen.dart:112-116` — `onTap → pushNamed('/favorites')`; `FE/lib/screens/product_detail/product_detail_screen.dart:139` — hide Share or wire; `FE/lib/screens/profile/edit_profile_screen.dart:70-84` — hide camera badge or wire.

## Implementation Steps

1. **Branding (M17/M19/M18):** manager product AppBar → surface + "BigStyle"; remove dead hamburger + fake pagination footer.
2. **orderNumber (X2):** central pattern `order.orderNumber ?? order.id.substring(0,8).toUpperCase()` at all 5 sites; make COD success set `orderNumber` so `checkout_screen.dart:81` shows it.
3. **Shipping (X3):** set flat fee to the user's realistic number; delete/neutralize the 2 unused shipping code paths so only one source remains.
4. **Chat (C40/C41/C42):** clarify AI label, remove the fake online dot, hide the mock image button (or wire a real picker).
5. **Demo-path dead buttons (X7):** wire "Sản phẩm yêu thích" → `/favorites`; hide the Share button and the decorative camera badge unless wired.
6. `flutter analyze` clean.

## Success Criteria

- [x] Manager product screen: white AppBar, "BigStyle" branding, no dead hamburger/pagination (M17/M18/M19). — manager_product_list_screen.dart:47 AppColors.surface, :53 "Quản trị BigStyle", no hamburger leading, footer :558 static count only.
- [x] All order codes display `orderNumber` (e.g. `CF-20260703-…`), not raw UUID; COD success dialog too (X2). — orderNumber ?? fallback at checkout_screen.dart:356, orders_screen.dart:99, order_detail_screen.dart:103, manager_order_detail_screen.dart:116, manager_order_card.dart:50, payment_qr_screen.dart:90.
- [x] One shipping fee, realistic value, no divergent unused code (X3/C21). — single source `AppConfig.flatShippingFee=30000` (app_config.dart); checkout_screen.dart:49 and delivery_map_screen.dart shippingFee getter both reference it; tiered getter removed.
- [x] Chat: honest label, no fake green dot, no mock image snackbar (C40/C41/C42). — chat_screen.dart:121-124 "BigStyle Bot / Trợ lý thời trang AI"; no AppColors.success online dot; no image button / "sẽ sớm" snackbar found.
- [x] No dead buttons on the recorded demo path; "Sản phẩm yêu thích" opens favorites (X7). — favorites wired (profile_screen.dart:116) + camera badge wired (edit_profile_screen.dart:118 _pickAvatar); product_detail_screen.dart:163 Share button now wired via share_plus `SharePlus.instance.share(...)`.
- [x] `flutter analyze` clean. — "No issues found!" (ran 2026-07-10).

## Risk Assessment

- **orderNumber population:** display fix alone is insufficient if the COD path never sets `orderNumber` — confirm the bloc/DB returns it; else the `??` fallback still shows UUID. Low risk (DB auto-generates `order_number`), but verify.
- **Deleting shipping code:** ensure nothing else imports the deleted distance-fee getters (delivery_map may display them) — repoint rather than break the map screen.
- **Scope creep:** X7 has ≥10 dead buttons total; only fix the ones on the recorded path. Hiding is acceptable and faster than wiring for the demo.
