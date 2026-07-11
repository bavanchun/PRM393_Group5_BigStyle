---
phase: 6
title: "Security hygiene DB"
status: pending
effort: ""
---

# Phase 6: Security hygiene DB

> ⚠️ **RED-TEAM OVERRIDE (RT-10).** DROP `handle_new_user` (and any pure `AFTER`-trigger function) from the REVOKE list — triggers fire as owner regardless of API grant, so revoking is a no-op at best and **breaks signup** if someone alters definer to "make it bite". Keep REVOKE only for functions genuinely callable with meaningful args. Storage: specify the EXACT replacement policy — keep public object GET (`for select using (bucket_id='products')`), remove only any listing grant — and verify with an **anonymous URL fetch** (the path the app actually uses), not just an authenticated branch query, or you 403 every catalog/review image. (RT-15) This phase is DB-only → verify via `get_advisors security` diff + smoke, not a Dart "failing test first". (RT-9) Source = `FE/supabase/migrations/`, not `FE/schema.sql`.

## Overview
Group C-sec: clear Supabase security advisor warnings — mutable search_path (notify_order_update, update_sold_count), public-bucket listing, leaked-password protection. (REVOKE scope corrected per RT-10.)

## Requirements
- Pin `search_path` on `notify_order_update` and `update_sold_count` (the two flagged; PR #23 already fixed the others).
- `REVOKE EXECUTE` from `anon`/`authenticated` on trigger-only functions exposed as REST RPC (bump_support_conversation, notify_order_update, update_product_rating, prevent_profile_role_self_escalation, handle_new_user, update_sold_count) — they should run only as triggers, not be callable.
- Tighten broad SELECT on public buckets `products` and `reviews` (object listing not needed for URL access).
- Enable Auth leaked-password protection (HaveIBeenPwned).

## Architecture
DB migration on a Supabase branch: `ALTER FUNCTION … SET search_path = public` for the 2 funcs; `REVOKE EXECUTE ON FUNCTION … FROM anon, authenticated` for the trigger-only set (keep them owned/executable for the trigger context). Storage: replace the broad "Public can view" SELECT policy with object-read that doesn't allow listing (or restrict `list` while keeping public object GET). Auth: enable leaked-password protection via project auth config (dashboard/API) — not SQL; document as a config step.

## Related Code Files
- Modify (DB branch migration): function search_path + REVOKEs + storage policy. Source: `FE/schema.sql` / migrations under `FE/`.
- Config (not code): Supabase Auth setting (leaked-password protection).
- Verify: re-run `get_advisors security` → addressed warns gone; confirm app still works (triggers still fire; product/review images still load).

## Implementation Steps
1. On branch: `ALTER FUNCTION public.notify_order_update() SET search_path = public;` and same for `update_sold_count()`.
2. `REVOKE EXECUTE … FROM anon, authenticated` on the 6 trigger-only functions; verify triggers still fire (they run as definer/owner, unaffected).
3. Replace broad bucket SELECT policies for `products`/`reviews` with non-listing object read; test image URLs still resolve.
4. Enable leaked-password protection in Auth config.
5. Re-run `get_advisors security`; test app (order status change still notifies; product/review images render).
6. `merge_branch`.

## Success Criteria
- [ ] `get_advisors security`: search_path (×2), trigger-func executable, public-bucket-listing warns cleared; leaked-password warn gone.
- [ ] Triggers still fire (order notification, sold count, rating); images still load; no regression in web smoke.

## Risk Assessment
- REVOKE could break a flow if any of these funcs is actually called as RPC by the app — verify via grep of services for `.rpc('bump_support_conversation'…)` etc. (they're triggers, but confirm). Storage policy change could break image loading if mis-scoped — test URLs on branch. All reversible; branch-test first.
