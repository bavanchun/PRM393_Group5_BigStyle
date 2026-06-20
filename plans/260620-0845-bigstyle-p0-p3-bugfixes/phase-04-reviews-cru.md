---
phase: 4
title: "Reviews CRU"
status: pending
priority: P3
effort: "2.5h"
dependencies: [1]
---

# Phase 4: Reviews CRU

## Overview
Replace hardcoded mock reviews on the product detail screen with real Supabase reviews: Create, Read, Update (no Delete — there is no DELETE RLS policy; default scope is CRU). Inserting/updating a review auto-recalculates `products.avg_rating` via existing DB triggers.

## Requirements
- Functional: product detail lists real reviews; a logged-in user can submit/edit their own review (rating + comment + optional size_feedback); avg rating updates.
- Non-functional: `flutter analyze` clean; no schema change for CRU.

## Key Insights (verified, file:line)
- **No ReviewService exists**; reviews are mock: `product_detail_bloc.dart:27, 51-75` (`_mockReviews()`), UI shape `ProductReview` in `product_detail_state.dart:4-19` (`name, rating, date, comment, avatarUrl`) — does **not** match DB columns.
- `reviews` table (`schema.sql:345-357`): `id, product_id, user_id, order_item_id?, rating(1-5 NOT NULL), comment?, images[], size_feedback in('smaller','true_to_size','larger'), is_verified, created_at`, `unique(product_id, user_id)`.
- RLS (`schema.sql:359-370`): SELECT anyone; INSERT/UPDATE own (`auth.uid()=user_id`); **no DELETE policy** → delete blocked.
- Triggers (`schema.sql:373-391`) auto-update `avg_rating`/`review_count` on insert/update — client must NOT recompute.
- Insert minimum: `product_id, user_id, rating`. `unique(product_id,user_id)` → use upsert for "edit own review".

## Architecture
- **ReviewModel** (`lib/models/review_model.dart`): map real columns; join `profiles(full_name, avatar_url)` for display name/avatar.
- **ReviewService** (`lib/services/review_service.dart`): `getReviews(productId)` (select + join profiles, order by created_at desc); `upsertReview(...)` (insert-or-update on `(product_id,user_id)`); read current user's review for prefill.
- **ReviewBloc** (`lib/blocs/review/`): events `ReviewLoad(productId)`, `ReviewSubmit(...)`; state list + myReview + isLoading + error. Follow `lib/blocs/order/` pattern; register in `main.dart`.
- **Product detail**: remove `_mockReviews()`; render real reviews; add a "Viết đánh giá" sheet (rating stars + comment + size feedback) gated by Phase 1's auth guard; refresh product avg after submit.

## Related Code Files
- Create: `lib/models/review_model.dart`, `lib/services/review_service.dart`, `lib/blocs/review/{review_bloc,review_event,review_state}.dart`
- Modify: `lib/blocs/product_detail/product_detail_bloc.dart` (drop `_mockReviews`), `product_detail_state.dart` (replace `ProductReview` shape or reuse ReviewModel)
- Modify: `lib/screens/product_detail/product_detail_screen.dart` (real list + write sheet)
- Modify: `lib/main.dart` (provide ReviewBloc)

## Implementation Steps
1. Use `/mobile-development` skill.
2. Create ReviewModel matching DB columns (+ joined profile name/avatar).
3. Create ReviewService: `getReviews`, `upsertReview`, `getMyReview`.
4. Create ReviewBloc trio; register in `main.dart`.
5. Replace mock reviews in product detail with `BlocBuilder<ReviewBloc>`; show empty-state when none.
6. Add write sheet (rating required 1-5, comment optional, size_feedback optional); on submit → upsert → reload reviews + product.
7. Apply auth guard (reuse Phase 1) so only logged-in users can write.
8. `cd FE && flutter analyze` clean. Smoke: submit a review → row appears → `products.avg_rating` changes (verify REST).
9. Commit + PR via `/vchun-git prc`.

## Success Criteria
- [ ] Product detail shows real reviews (mock removed)
- [ ] Logged-in user can create and edit own review (upsert respects `unique(product_id,user_id)`)
- [ ] `avg_rating`/`review_count` update via DB trigger (client does not recompute)
- [ ] Non-logged-in user is guarded from writing
- [ ] `flutter analyze` clean
- [ ] ≥1 commit + PR via `/vchun-git prc`

## Risk Assessment
- **Delete not supported** by RLS — scope is CRU. If user wants Delete, add a DELETE policy migration (`using auth.uid()=user_id`) in SQL Editor; out of default scope, flag in PR.
- **Double-recompute**: do NOT update avg_rating from client — triggers own it.
- **Unique conflict** on second review → must upsert, not insert.

## Security Considerations
- INSERT/UPDATE bound to `auth.uid()=user_id` by RLS; client cannot forge another user's review.
