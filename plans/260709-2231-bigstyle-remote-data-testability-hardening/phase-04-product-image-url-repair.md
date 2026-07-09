---
phase: 4
title: "Product Image URL Repair"
status: completed
priority: P2
effort: "1h"
dependencies: [2]
---

# Phase 4: Product Image URL Repair

## Overview

Remove broken/flaky external image URLs from active seed products and replace
them with stable image sources suitable for Android demo and repeatable tests.

## Requirements

- Functional: active product cards/details render images without 404 logs.
- Functional: repaired URLs remain publicly readable by customer/manager UI.
- Non-functional: avoid committing binary assets unless needed.
- Security: do not expose service-role keys or private storage URLs.

## Architecture

Preferred image source:

```text
Supabase Storage public bucket `products`
  -> product.images text[]
  -> ProductCard/Image.network
```

Fallback: curated known-good HTTPS URLs checked via HEAD. Supabase Storage is
preferred because the app already has product upload flow and public bucket.

## Related Code Files

| File | Action | Notes |
|------|--------|-------|
| `FE/supabase/migrations/20260704100000_seed_bigstyle_data.sql` | Optional update | Future seed should not reintroduce broken URLs |
| `FE/lib/widgets/product_card.dart` | Read | Image error/fallback behavior |
| `FE/lib/screens/product_detail/product_detail_screen.dart` | Read | Detail image behavior |
| `FE/lib/services/product_service.dart` | Read | Storage public URL pattern |

## File Inventory

| Path | Action | Test impact |
|------|--------|-------------|
| Remote `public.products.images` | Update data | Removes runtime 404 |
| Remote `public.categories.image_url` | Audit optional | Category images may also use Unsplash |
| Optional script/report in plan folder | Create | Documents checked URLs |

## Dependency Map

- Depends on Phase 2 only for stable product ownership during manager smoke.
- Blocks final visual smoke in Phase 5.

## Implementation Steps

1. Export active product/category image URLs:
   ```sql
   select id, name, unnest(images) as image_url from public.products;
   select id, name, image_url from public.categories;
   ```
2. HEAD-check every URL outside the app. Record failures.
3. Decide replacement source:
   - Upload stable assets to Supabase Storage `products`, or
   - Use known-good public URLs only if storage upload is unnecessary.
4. Update only failed/flaky URLs first. If all Unsplash links are considered
   demo-risk, replace all seed product images.
5. Update local seed migration if the remote fix should survive DB reset.
6. Run Android product list/detail smoke and watch Flutter logs for
   `NetworkImageLoadException`.

## Test Scenario Matrix

| Scenario | Expected |
|----------|----------|
| Known broken image URL | HEAD fails or app logs 404 before fix |
| Product list after fix | No 404 for visible product cards |
| Product detail after fix | Main carousel image loads or fallback handles safely |
| Storage public URL | Opens without auth |

## Success Criteria

- [ ] URL audit report lists checked URLs and failures.
- [ ] No active seed product image URL returns 404.
- [ ] Android smoke log has no product `NetworkImageLoadException` 404.
- [ ] Local seed migration updated if remote data repair is intended permanent.

## Risk Assessment

- Risk: replacing all images takes time. Mitigation: first fix active broken
  URLs; bulk migrate to Storage only if demo reliability requires.
- Risk: Storage policy blocks public read. Mitigation: verify public URL in
  browser/HTTP before updating products.

## Completion Notes

- Audited 21 active product/category image URLs.
- Initial HEAD results found 2 HTTP 404 URLs:
  category `Đầm` and product `Thắt Lưng Vải Phối Màu`.
- Replaced those URLs with already checked 200 URLs.
- Second HEAD sweep returned HTTP 200 for every active seed image URL.
- No binary assets or storage secrets were committed.
