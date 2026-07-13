# 260710-2300 — Remaining-issues brainstorm → review-gate/map/chat hardening plan

**Session:** 2026-07-10 22:15–23:00 | **Branch:** `dev` @ `60560a5` | **No code changes — planning only.**

## What happened
1. **Brainstorm** (3 parallel audits: plan backlog, code defects, flow completeness) → `plans/reports/brainstorm-260710-2227-remaining-issues-flows-and-next-updates-report.md`.
2. Key discoveries:
   - **Review gate hole confirmed end-to-end**: `schema.sql:390` RLS insert policy only checks `auth.uid() = user_id` — any logged-in user reviews any product. `reviews.order_item_id` + `is_verified` columns exist but app never writes them.
   - Payment/chat/routing healthy (SePay real, Claude API real, 19 routes clean). 6 small defects (D1–D6: admin dead menu, 2 swallowed catches, MockLoginEvent dead code, placeholder URLs, hardcoded badge).
   - `OrderModel` already stores lat/lng → order-linked map needs no geocoding.
   - Manager↔customer chat absent (AI bot only).
3. User picked ALL 4 workstreams (incl. chat despite effort warning) → **plan `260710-2235-review-gate-map-chat-hardening`** (`--tdd --deep`, 5 phases; blocks demo-fix-roadmap closure via Phase 5).

## Red-team gate (3 hostile reviewers, 24 raw → 13 accepted, 0 rejected)
Highest-impact catches that changed the design:
- **Chat would be DOA**: planned RLS (select/insert only) blocks both the `last_message_at` trigger and the `getOrCreateConversation` upsert-UPDATE path → redesigned to SECURITY DEFINER trigger + `get_or_create_my_conversation` RPC, zero UPDATE grants, `mark_conversation_read` RPC.
- **`is_verified` spoofable**: BEFORE-INSERT-only trigger misses upsert UPDATE path; owner could PATCH the flag → BEFORE INSERT OR UPDATE + immutability guard.
- **`cancel_my_order` exists in NO repo SQL** — live-DB drift; Phase 2 step 0 now repatriates it before widening the UI gate.
- **`update_product_rating` is invoker-rights** → customer reviews silently never bump `avg_rating` (pre-existing latent bug, folded into Phase 1 migration).
- App-scoped thread bloc race (manager switching conversations) → screen-scoped bloc + switch test.

## Validation decisions (user)
Seed reviews: backfill-or-delete (strict gate). Manager chat entry: **bottom-nav tab + badge** (overrode dashboard-card rec; nav de-const scoped). Phase 5 env: hosted Supabase. Implementation: single feature branch from `dev`.

## Lessons
- Red-team on RLS-heavy plans pays for itself: the original chat RLS design (mine) had a happy-path-fatal flaw all 3 reviewers caught independently.
- Live-DB drift is real here (`cancel_my_order`, prior `fix_rls_profiles_recursion.sql`): Phase 5 now starts with `supabase migration list` drift inventory.
- `CODEBASE.md` badly stale (says 14 screens; actual 47) — ✅ refreshed in Phase 2 (2026-07-12 Repo Documentation: rewrote CODEBASE.md with accurate screen/service/state count + new `docs/system-architecture.md` for system design).

## Next
Cook `plans/260710-2235-review-gate-map-chat-hardening/plan.md` on `feat/review-gate-map-chat` (user deferred — review first). 5 Claude Tasks hydrated with dependency chain (2←1; 5←1-4).
