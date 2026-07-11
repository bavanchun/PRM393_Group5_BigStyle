---
phase: 8
title: "Data cleanup pricing"
status: pending
effort: ""
---

# Phase 8: Data cleanup pricing

<!-- Updated: Validation V3 — price source DECIDED: reuse prices captured in existing order_items (11k/21k/40k/380k) as the reference; derive remaining products' prices from those bands. Not a curated or user-supplied list. DB source = FE/supabase/migrations/, not schema.sql (RT-9). -->

## Overview
Group D: catalog products all display a uniform 10.000đ (test-junk pricing), while real order totals vary (11k–380k). Set realistic prices for demo credibility — derived from existing `order_items` captured prices (V3).

## Requirements
- Functional: catalog products have realistic, varied `base_price`/`sale_price` (VND, no decimals).
- Non-functional: don't corrupt existing orders (order_items store captured unit_price at order time — unaffected by catalog price changes).

## Architecture
Data-only change on `products` (`base_price`, `sale_price`). Source of "realistic" prices — open question: (a) reuse the varied prices captured in existing order_items, or (b) a fresh curated list per category. Recommend a curated list keyed by product (dresses/tops/pants/sets/accessories price bands). Apply via a seed/update SQL script; can run on branch then merge, or directly (data-only, low risk, but keep on branch for consistency with the plan's DB-safety rule).

## Related Code Files
- Modify: a new `FE/seed_prices.sql` (or extend `FE/seed_data.sql`) with realistic prices; run via Supabase.
- Verify: web customer catalog shows varied prices; product detail price + discount % correct.
- Tests: none (data). Optional: assert `ProductModel.discountPercent` renders when sale_price < base_price.

## Implementation Steps
1. Decide price source (open question) — get a per-product price list.
2. Write idempotent `UPDATE products SET base_price=…, sale_price=… WHERE slug=…` script (or per-id).
3. Apply on branch → verify via customer web login that catalog shows varied prices + discount badges; confirm existing orders' totals unchanged.
4. Merge.

## Success Criteria
- [ ] Catalog shows realistic varied prices (no uniform 10.000đ); discount badges render where sale_price set.
- [ ] Existing orders' totals unchanged (order_items captured prices intact).

## Risk Assessment
- Low (data-only). Only risk = accidentally editing order_items or breaking discount logic; scope UPDATE to `products` only. Depends on open-question price-source decision.
