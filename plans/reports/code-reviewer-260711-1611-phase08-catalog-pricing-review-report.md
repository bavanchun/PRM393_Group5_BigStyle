# Phase 08 Review: Catalog Pricing Data Fix

**File reviewed:** `FE/supabase/migrations/20260711190000_realistic_catalog_pricing.sql` (single file, 15 UPDATE statements, already applied to prod)

**Tooling note:** No `mcp__supabase__*` tool was bound in this session's toolset (only Read/Bash/WebFetch/WebSearch/Write/Edit/SendMessage available). All findings below are static analysis against the migration history plus the pre-supplied investigation results (DB query outputs, manual app verification) — I could not independently re-run SQL against the live DB to corroborate those figures.

## Score: 8/10

## HARD-GATE-NO-SIDE-EFFECTS: PASS
- `git status --porcelain` confirms exactly one tracked file changed (`FE/supabase/migrations/20260711190000_realistic_catalog_pricing.sql`); `.claude/` and `FE/.claude/` are untracked tooling dirs, not part of this change.
- Migration only touches `public.products.base_price` / `sale_price` via `WHERE id = <literal>`. Grepped `20260710233700_review_purchase_gate.sql`'s product UPDATEs (the only other migration that writes to `products`) — confirmed it only touches `avg_rating`/`review_count`/`updated_at`, no overlap.
- `order_items.unit_price` is captured only at order-creation time via `create_order`/checkout RPCs (`20260708120000_create_order_rpc.sql` and successors) and is never live-joined to `products`. No seed migration inserts `order_items` rows. Confirms the claim that existing orders' totals are unaffected — this is architecturally guaranteed, not just empirically spot-checked.

## Critical Issues
None.

## Warnings

**1. Plan document contains a stale, contradicted price-source figure (item d, expanded).**
`plans/260711-1403-bigstyle-full-app-improvement/phase-08-data-cleanup-pricing.md` line 10 states: *"Validation V3 — price source DECIDED: reuse prices captured in existing order_items (**11k/21k/40k/380k**) as the reference."* This directly conflicts with the task-supplied investigation (`select count(distinct base_price)... from order_items` → only 2 distinct values, 10000 and 350000) and with the migration's own comment block (lines 1-9), which cites only 10000/350000. Since `order_items` has zero seed-migration rows (all runtime-generated), migration history can't arbitrate which figure is correct, but the "11k/21k/40k/380k" note reads like an early unvalidated guess written before the actual investigation ran (it sits in the same line as the "DECIDED" annotation, suggesting it wasn't updated when the real number was found). **Recommend the plan file be corrected to reflect the actual investigated figure (10000/350000)** so future readers of phase-08 don't inherit a wrong assumption — flagging for the lead/planner to fix, not editing it myself per role boundaries.

**2. Product catalog rows (`a1000000-...` IDs) are architecturally out-of-band — same gap as previously logged for RLS policies.**
Grepped all of `FE/supabase/migrations/*.sql` for the 15 `a1000000-0000-0000-0000-000000000001`...`015` IDs touched by this migration: they appear **nowhere** except in the migration under review. The tracked seed migration (`20260704100000_seed_bigstyle_data.sql`) only seeds `p1000000-...`-prefixed product IDs (with real, non-10000 prices like 320000/280000 — itself informative, since it shows the "uniform 10000đ" bug was specific to whichever process created the `a1000000-...` rows, not a project-wide seeding pattern). This means I cannot independently verify from source history that: all 15 `a1000000-...` IDs actually exist in `products` (vs. a typo silently no-op'ing a `WHERE id = ...` UPDATE), that there isn't a 16th/17th product missed by this migration, or that these rows were genuinely uniform-10000 before this ran. This is a pre-existing project gap (see prior review of `20260711180100_rls_perf_wrap_auth_uid.sql`), not a new defect — but it does mean this migration's correctness rests partly on the DB-side manual verification already performed (13-value spot check `count(distinct base_price)=12, min=45000, max=350000`), which I have no way to re-confirm this session. Recommend running with live Supabase MCP/psql access on the next review pass over this repo when available.

## Suggestions

**3. `base_price`/`sale_price` UPDATE-by-PK statements are safely idempotent** — confirmed by inspection: all 15 statements are `SET col = <literal> WHERE id = <literal>` with no dependency on the row's pre-update state (no `WHERE base_price = 10000`, no arithmetic increments). Re-running produces an identical end state from any starting state. No objection here, just noting the idempotency claim in the task holds and needs no guard clause (`IF NOT EXISTS`, etc.) added.

**4. IDs, arithmetic, and downstream consumers all check out.**
- 15 statements, 15 distinct `id` values, no duplicates, no overlapping targets (verified via `sort | uniq -c`).
- All 7 rows with a non-null `sale_price` have `base_price > sale_price` (verified programmatically: 89000>69000, 120000>89000, 350000>300000 ×2, 260000>220000, 330000>280000). No inverted-discount bug.
- `FE/lib/models/product_model.dart` `discountPercent` getter (line 66-69) guards `originalPrice! <= price` before dividing, so even a hypothetical future bad row wouldn't divide-by-zero or show a negative/nonsensical badge — but this migration doesn't trigger that path anyway since the guard condition never fires against these values.
- Grepped `FE/lib` for any price-range assumption (`RangeSlider`, `priceMin`/`Max`, "starting from" aggregates): none exist. `formatVnd` (`FE/lib/utils/currency_format.dart:7`) is a generic `NumberFormat` grouping formatter with no hardcoded range — safe for the new spread (45000-350000).
- Category-to-price-band assignment is internally consistent by product name (Thắt Lưng/Túi Tote → accessories 45k-89k; Áo* → tops 120k-350k; Quần* → pants 160k-260k; Set* → sets 300k-350k; Đầm* → dresses 260k-350k) — could not cross-check against a `category_id` column value directly since categories aren't joined in this migration, but names and comments align.

**5. On item (d) — retiring 10000 vs. literal V3 reading:** Agree this is the more faithful interpretation, not a deviation requiring separate sign-off. V3's stated intent ("reuse the varied prices captured in existing order_items... as the reference," "not a curated or user-supplied list") is about grounding in real data, and 10000 is definitionally not real market data — it's the artifact of the bug being fixed. Using 350000 as the sole real anchor and deriving category bands below it is a reasonable, disclosed extrapolation given only one genuine data point existed. This should still be called out to the user as a judgment call (which the migration's own comment does, lines 1-9), which satisfies the "surface it" bar — I would not block on this.

## Metrics
- Files changed: 1 (migration only, confirmed via `git status`)
- UPDATE statements: 15 / 15 products covered, 0 duplicates
- Arithmetic violations (base ≤ sale): 0 / 7 sale-price rows
- Idempotency: confirmed (pure literal SET by PK)
- Downstream FE consumers checked: `product_model.dart`, `product_card.dart`, `product_detail_screen.dart`, `currency_format.dart` — no breakage risk found

## Unresolved Questions
1. Was the "11k/21k/40k/380k" figure in `phase-08-data-cleanup-pricing.md` line 10 ever real, or is it a stale draft note? Recommend the lead/planner correct that line to match the validated 10000/350000 figure so the plan's own record is accurate.
2. Could not verify against live DB this session (no Supabase MCP tool bound) that all 15 `a1000000-...` product IDs exist and were uniformly 10000 pre-migration, or that no product was missed — this rests on the manual verification already reported in the task context. Recommend a follow-up pass with DB access if that verification is ever in doubt.
