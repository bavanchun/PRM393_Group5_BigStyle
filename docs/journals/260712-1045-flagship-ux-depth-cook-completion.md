# Flagship UX-Depth Customer Flow: Cook Complete (With Critical Regression Caught & Fixed)

**Date**: 2026-07-12 10:45
**Severity**: High (regression) → Resolved
**Component**: Customer shopping flow (home → product_list → product_detail → cart → checkout)
**Status**: Merged to dev (PR #33, commit 3d073b9)

## What Happened

Shipped all 6 phases of the flagship UX-depth customer flow plan (plans/260711-1905-flagship-ux-depth-customer-flow/plan.md) in a single feature branch + PR (8 commits total, squash-merged). The plan itself had passed /ck:plan validate + 4-reviewer red-team before implementation, so this session was pure execution via /ck:cook --auto.

The phases delivered: (1) motion tokens + haptics + PressableScale + product_detail skeleton + cart stepper 44px touch targets + checkout inline validation; (2) personalized home greeting + staggered section entrance (data-driven, not mount-driven); (3) Hero list-to-detail transitions with async load protection (imageUrl threaded through route args, placeholder Hero swapped to carousel under same tag); (4) add-to-cart confirmation with scale-pop animation + haptics on real Supabase completion; (5) dedicated /search screen + SearchBloc with 280ms Timer debounce (reusing server-side ilike, no new filter logic); (6) checkout success with custom-painted animated checkmark (ring + stroke draw-on).

Quality gates: flutter analyze 0 issues, flutter test 116/116 passing after each phase. End-to-end verified via Preview MCP: Hero transitions, live Supabase cart round-trip, real search, live COD order flow.

## The Brutal Truth

**A critical regression was introduced in Phase 4 and caught by code review before merge.** The add-to-cart success detector compared `cartBloc.state.items.length` before vs after dispatching the add, assuming that a successful add always grows the list. False assumption. Our cart_service.dart merges quantity into the existing row when the variant is already in the cart (unique constraint on cart_id+variant_id). Re-adding a variant you already have → items.length unchanged → 5-second timeout → false "Thêm vào giỏ hàng thất bại" (add failed) error displayed *even though the Supabase PATCH succeeded server-side*. Same regression broke "Mua ngay" (Buy Now). This is the most embarrassing and most valuable finding of the session: we shipped code that was internally inconsistent with the backend's actual behavior.

## Technical Details

The bug was in Phase 4's cart success-detector:
```
// WRONG (introduced by Phase 4)
int oldLength = cartBloc.state.items.length;
await cartBloc.add(AddToCartEvent(...));
// ... timeout logic ...
bool succeeded = cartBloc.state.items.length > oldLength;
```

When variant already in cart, the backend's PATCH just increments quantity; items.length is unchanged. The detector hung for 5 seconds, then showed false failure. Network logs confirmed the server accepted the write (200 PATCH response).

Fixed by tracking the specific variant's quantity before/after instead of list length:
```
int oldQty = cartBloc.state.getVariantQuantity(variantId);
await cartBloc.add(AddToCartEvent(...));
// ... timeout logic ...
bool succeeded = cartBloc.state.getVariantQuantity(variantId) > oldQty;
```

Manual end-to-end verification: deliberately added the same variant twice in the running app, confirmed network log showed PATCH (merge), confirmed cart showed quantity=2 with no false failure and no stall.

## What We Tried

Code-reviewer subagent pass (pre-merge) flagged this as Critical. Root cause diagnosis: conflating list growth with request success. Fix: switched to variant-level quantity tracking. Two additional findings also fixed: (1) /search was constructing fresh ProductService() instead of reusing via context.read<ProductService>() (DI inconsistency); (2) home loading skeleton was bare rounded-rectangle while product_list/search had full card shape — matched home's skeleton to the shared ProductGridSkeleton shape.

One accepted risk (not fixed): Hero transition's destination image gets covered by checkout sheet's rounded edge for ~300ms on landing. Proper fix requires custom flightShuttleBuilder (disproportionate risk). Documented explicitly in phase-03 Risk Assessment.

## Root Cause Analysis

The fundamental mistake: assuming a write operation's success can be inferred from structural changes to the client-side list when the backend can perform upserts/merges. Our backend design is correct (merge on conflict, don't duplicate). The Phase 4 code assumed a simpler backend (insert-only). This assumption was never explicitly stated or tested.

## Lessons Learned

- **Never infer backend write success from list structural changes when the backend can merge/upsert.** Track the specific entity's own state (quantity for cart items, row count for lists with unique constraints, timestamps for last-write idempotency).
- **Regression risk in success-detection logic is high because the code path is rarely exercised in normal flow** (success is fast, timeout is 5 seconds, and the bug only manifests on a specific input pattern — re-adding an existing variant).
- **Code review caught this before merge because we had actual end-to-end testing.** Without running the live app and deliberately testing the repeat-add case, this ships to users.

## Next Steps

- Phase 4 is now correct (variant-level quantity tracking). 
- Document this specific lesson ("upsert/merge operations don't guarantee list growth") in the project's code-standards.md or dev-notes under a section on "Common Assumptions That Break on Upsert Backends."
- For future cart/list operations with server merging: add explicit test coverage for the "add duplicate" case (e.g., Bloc test that adds the same variant twice and asserts quantity=2, not "add failed").

**Merged**: PR #33 squash-merged to dev, local dev synced to 3d073b9.
