---
phase: 1
title: "Review Purchase-Gate & Delivered-Order Review CTA"
status: completed
priority: P1
dependencies: []
effort: "M"
---

# Phase 1: Review Purchase-Gate & Delivered-Order Review CTA

## Overview
Close the ungated-review hole end-to-end: only customers with a **delivered** order containing the product may write a review; wire the unused `reviews.order_item_id` + `is_verified` columns; add per-item "Đánh giá" CTA on delivered order detail.

## Requirements
- Functional: non-purchaser sees no active "Viết đánh giá" (caption "Mua và nhận hàng để đánh giá"); purchaser (delivered) can review from product page AND from delivered order detail; review saved with own `order_item_id`, `is_verified` computed server-side; RLS rejects direct inserts/updates from non-purchasers AND forged fields.
- Non-functional: existing suite stays green (baseline = `flutter test` count at execution time); no N+1 (single eligibility query per product page load).

## Architecture
**DB (authoritative gate)** — new migration `FE/supabase/migrations/<ts>_review_purchase_gate.sql` (include rollback SQL block in header comment restoring original policies); update `FE/schema.sql` baseline to match. Contents:
1. **INSERT policy** (replaces `"Users insert own reviews"`, `FE/schema.sql:390-392`): `auth.uid() = user_id` AND eligibility EXISTS binding the row's own item: `exists (select 1 from order_items oi join orders o on o.id = oi.order_id join product_variants pv on pv.id = oi.variant_id where oi.id = reviews.order_item_id and o.user_id = auth.uid() and o.status = 'delivered' and pv.product_id = reviews.product_id)`. `order_item_id` required (NOT NULL for new rows enforced by the policy — it can't pass with NULL). This also blocks pointing at another customer's order item.
2. **UPDATE policy** (decided now, not at implementation): same USING + **WITH CHECK** as insert.
3. **ONE combined trigger** (`BEFORE INSERT OR UPDATE`, single function — do NOT split into separate guard + setter triggers: both would fire in the same BEFORE UPDATE phase in alphabetical-name order, and a guard covering `is_verified` could reject the setter's own false→true transition, e.g. resubmit of a backfilled seed review): (a) on UPDATE, raise when `NEW.product_id/user_id/order_item_id IS DISTINCT FROM OLD.*` (immutable provenance); (b) always recompute `NEW.is_verified` server-side from the eligibility EXISTS — client-sent values are overwritten, so `is_verified` needs no immutability guard and owner PATCH spoofing is inert. Covers the upsert conflict/UPDATE path (badge stays correct on resubmit).
4. **Recreate `update_product_rating` as SECURITY DEFINER** (`set search_path = public`): current function (`FE/schema.sql:398-409`) is invoker-rights; products UPDATE is manager-only (`FE/schema.sql:128-130`) so customer review inserts silently fail to bump `avg_rating`/`review_count`. Fix in this migration.
5. **Legacy/seed reviews**: backfill valid `order_item_id` for seed reviews that have a matching delivered order, DELETE seed reviews that don't (do NOT weaken the policy to keep them editable).

**FE:**
- Eligibility: `ReviewService.getEligibleOrderItem(productId, userId)` → order_items joined orders (delivered, own) joined variants for product, **`.order(deterministic).limit(1)` — NOT `maybeSingle`** (repeat purchaser with ≥2 delivered orders of the same product returns multiple rows → maybeSingle throws 406). When the user already has a review, reuse its existing `order_item_id` (it's immutable per trigger) instead of re-resolving. (`ReviewService` already takes injected `SupabaseClient` — DI-testable.)
- `upsertReview` (`FE/lib/services/review_service.dart:32-46`) gains required `orderItemId`; stops writing nothing for `is_verified` (DB owns it). Upsert `onConflict: 'product_id,user_id'` kept — conflict path passes UPDATE policy because eligibility still holds for a real purchaser.
- Bloc: `ReviewLoad` loads eligibility (`canReview`/`eligibleOrderItemId` in state); `ReviewSubmit` carries `orderItemId`.
- UI product page: `product_review_section.dart:35-39` — active write button only when `canReview || myReview != null`; else caption.
- UI order detail: `order_detail_screen.dart:107-138` item rows — when `status == delivered`, trailing `TextButton('Đánh giá')` per item → `ReviewEditorSheet.show` with productId + userId + orderItemId. `OrderItem` model gains `id` (order query already selects `order_items(*)` per `order_service.dart:16`, so only `fromMap` needs the field — no select change).

## Related Code Files
- Create: `FE/supabase/migrations/<ts>_review_purchase_gate.sql`; `FE/test/blocs/review_bloc_test.dart` (**create** — no review tests exist today)
- Modify: `FE/schema.sql`, `FE/lib/services/review_service.dart`, `FE/lib/blocs/review/*`, `FE/lib/screens/product_detail/product_review_section.dart`, `product_detail_screen.dart`, `review_editor_sheet.dart` (orderItemId param), `FE/lib/models/order_model.dart` (OrderItem.id), `FE/lib/screens/orders/order_detail_screen.dart`
- Tests: new `review_bloc_test.dart` (FakeReviewService pattern per `manager_bloc_test.dart`); OrderItem id-parse test added following `FE/test/models/order_customer_name_mapping_test.dart` convention; widget test for gated button

## Implementation Steps (TDD)
1. **Tests first (create, not extend):** ReviewBloc — (a) no eligibility → `canReview=false`; (b) eligibility → `canReview=true`, submit passes `orderItemId`; (c) OrderItem.fromMap parses `id`. Widget test: write button hidden/disabled when `canReview=false && myReview==null`. Run → red.
2. Extend `OrderItem` with `id` (fromMap only).
3. `getEligibleOrderItem` + service param; bloc/state changes → green.
4. UI: product_review_section gating + order_detail per-item CTA.
5. Migration SQL (items 1–5 above, rollback block included) + schema.sql. `flutter analyze` + full `flutter test`.
6. Adversarial REST checks deferred to Phase 5 runbook (insert non-purchaser, PATCH is_verified, forged order_item_id — all must reject).

## Success Criteria
- [ ] New bloc/model/widget tests green; existing suite green; analyze 0.
- [ ] Non-purchaser: no active write button on product page.
- [ ] Delivered order detail per-item Đánh giá CTA; editor prefilled; resubmit updates AND badge stays verified (upsert UPDATE path covered by trigger).
- [ ] Migration applies cleanly with documented rollback; seed reviews backfilled/pruned; RLS + immutability guards verified in Phase 5.
- [ ] Product `avg_rating`/`review_count` update after customer review (SECURITY DEFINER rating trigger).

## Risk Assessment
- Upsert conflict path hits UPDATE policy — mitigated: UPDATE policy mirrors eligibility, and purchasers always satisfy it; legacy rows handled by backfill/prune (step 5), not policy weakening.
- `unique(product_id,user_id)` = 1 review per product regardless of repurchase — accepted, existing behavior.
- Rollback: migration header contains SQL restoring original `"Users insert own reviews"`/`"Users update own reviews"` policies and dropping new triggers.
