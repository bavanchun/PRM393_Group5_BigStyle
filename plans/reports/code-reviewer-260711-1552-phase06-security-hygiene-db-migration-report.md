---
title: Phase 06 security-hygiene DB migration review
scope: FE/supabase/migrations/20260711170000_security_hygiene_search_path_and_revokes.sql, FE/supabase/migrations/20260711170100_storage_public_bucket_no_listing.sql
score: 8/10
---

# Phase 06 security-hygiene DB migration review

## Scope
- Files: 2 new SQL migrations only. `git status` confirms no Dart files touched (only `FE/.claude/` untracked dir + the 2 migrations).
- Focus: DB-only security hygiene (search_path pinning, EXECUTE revokes, storage policy drop).
- Tool constraint: **no Supabase MCP tool was available to this subagent** (only Read/Bash/WebFetch/WebSearch/Write/Edit were granted). I could not independently run `get_advisors security` or query `pg_proc`/`information_schema.routine_privileges` against the live DB. All verification below is from static analysis of the migration SQL, `FE/schema.sql` baseline, and `FE/lib` client code — check (a) (advisor before/after) is **unverified by me**, not confirmed.

## Overall Assessment
The SQL is small, correct, and well-reasoned for the parts I could verify statically. Both files match their own inline comments and the parent's description. The trigger-only classification of all 6 revoked functions checks out against `FE/schema.sql` and the migration history, the storage-policy reasoning is corroborated by Supabase's own docs (two independent searches), and no client code depends on any of the revoked RPCs. One real gap: I cannot confirm the live-DB advisor diff or object-listing behavior post-deploy, since that requires DB access I don't have in this session.

## Critical Issues
None found.

## High Priority
None found in the SQL itself. Flagging one process gap:

- **Advisor before/after (check a) is unverified by this review.** I had no working Supabase MCP tool in this session (tried `mcp__09cbb4f9-d475-4427-8874-45c007f9954e__get_advisors` and `mcp__supabase__get_advisors`, both errored "No such tool available"). The parent's claim that all 8 targeted advisor warnings are gone and legitimate RPCs still show as callable is **not independently confirmed**. Recommend re-running `get_advisors security` from a session that actually has the Supabase MCP tool bound before treating this phase as closed.

## Medium Priority

1. **`restock_on_order_cancel` is a plan-vs-implementation scope addition, correctly justified but undocumented in the plan file itself.** `plans/260711-1403-bigstyle-full-app-improvement/phase-06-security-hygiene-db.md` (line 17) lists exactly 6 functions for the REVOKE list, including `handle_new_user` — which RT-10 (line 10 of the same file) then explicitly says to drop. The migration correctly drops `handle_new_user` per RT-10, but silently swaps in `restock_on_order_cancel` (from Phase 01's `20260711150200_create_order_money_path_hardening.sql`) to keep the list at 6 items. I verified `restock_on_order_cancel` is a genuine `AFTER UPDATE OF status ON orders` trigger with no other call path (grep of `FE/lib` and all migrations shows zero direct references outside the trigger definition and this revoke) — the addition is technically sound. But the phase-06 plan file itself was never updated to reflect this, so a future reader of the plan will see a stale function list that doesn't match the migration. This is a documentation-sync gap, not a code defect — worth a follow-up edit to the plan file (by whoever owns plan mutation, not this review).

2. **Phase 06's "Enable leaked-password protection" success criterion is not addressed by either migration**, and can't be — it's an Auth dashboard/API config setting, not SQL (correctly scoped that way in the plan's own Architecture section, line 22: "not SQL; document as a config step"). Neither migration file nor this session's summary mentions whether that config step was actually performed. If it wasn't, phase 06 is incomplete against its own success criteria even though the SQL is fine. Confirm out-of-band (Supabase dashboard → Auth → Policies) and record the outcome.

## Low Priority
None.

## Verification of Mandatory Checks

**(a) Re-run `get_advisors security` — NOT independently verified.** No Supabase MCP tool was bound in this subagent session. Flagging as an open item rather than accepting the parent's summary at face value.

**(b) Grep FE/lib for `.rpc()` calls to the 6 revoked functions or storage-policy-adjacent flows — PASSED.** Full list of `.rpc()` call sites in `FE/lib`:
- `voucher_service.dart:14` → `validate_voucher`
- `order_service.dart:49` → `get_customer_count`
- `order_service.dart:130` → `create_order`
- `order_service.dart:195` → `cancel_my_order`
- `product_service.dart:118` → `update_product_with_variants`
- `support_chat_service.dart:15` → `get_or_create_my_conversation`
- `support_chat_service.dart:53` → `mark_conversation_read`

None of these touch `bump_support_conversation`, `notify_order_update`, `update_product_rating`, `prevent_profile_role_self_escalation`, `update_sold_count`, or `restock_on_order_cancel`. Image access (`product_service.dart:168,181`) uses `storage/v1/object/{bucket}` and `storage/v1/object/public/{bucket}` URL construction directly, never `storage.objects` table SELECT or the `list()` API — confirms the storage-policy drop has no client-side dependency either.

**(c) Is dropping the storage SELECT policies safe given zero objects exist to test — REASONING CONFIRMED, independently corroborated.** Two Supabase-doc fetches confirm: (1) public buckets bypass `storage.objects` RLS entirely for GET/serve-by-URL — "anyone who possesses the asset URL can readily access the file" regardless of RLS policy state; (2) the `list()` API / table SELECT enumeration is a *distinct* operation that does still require an explicit SELECT policy on `storage.objects`, even for public buckets (Supabase's `storage.allow_only_operation()`/`allow_any_operation()` helpers exist specifically to let you split GET-by-URL from listing). So dropping the broad SELECT policy removes exactly the listing/enumeration surface while leaving object-URL GET (what `FE/lib` actually uses) unaffected. The zero-objects-in-bucket gap means this can't be *empirically* smoke-tested against real files, but the reasoning is correct per first-party documentation, not just the migration author's inference. Low residual risk: if objects are ever uploaded to these buckets, verify a fresh anonymous URL fetch once real data exists (the plan's own RT-15 override says exactly this: "verify with an anonymous URL fetch... not just an authenticated branch query").

**(d) `restock_on_order_cancel` correctly added to revoke list — CONFIRMED, no objection.** Read `20260711150200_create_order_money_path_hardening.sql:171-192`: it's `SECURITY DEFINER`, `RETURNS TRIGGER`, attached via `AFTER UPDATE OF status ON public.orders`, and is not referenced anywhere else (no `.rpc()` call, no other trigger/function reference). It fits the exact pattern of the other 5 (trigger-only, mutates DB state, no meaningful args to call directly). Sound addition. Only issue is the plan-file staleness noted in Medium #1.

**(e) `handle_new_user` exclusion — CONFIRMED as reasoned correctly for the current function body.** `pg_get_functiondef`-equivalent read via migration source (`20260711013000_harden_secdef_search_path.sql:9-17` and the original `20260710235000_handle_new_user_full_name.sql:15-26`): the body is a single `INSERT INTO public.profiles (id, email, full_name) VALUES (...)` from the `NEW` row of an `auth.users` insert trigger — no grant-checked calls, no dynamic SQL, no invocation of other SECURITY DEFINER functions. RT-10's "no-op at best, risky if the body changes" framing holds for this specific body: revoking EXECUTE here would do nothing today (Postgres triggers execute as owner regardless of caller grants) and the stated future-risk (body later doing something grant-checked) is a real but currently-inapplicable concern. Correctly excluded.

**(f) Any other SECURITY DEFINER function missed from revoke scope — none found among trigger-only functions.** Enumerated every `security definer` occurrence across `FE/supabase/migrations/*.sql`. Full SECURITY DEFINER inventory and disposition:
- `create_order`, `cancel_my_order`, `update_product_with_variants`, `validate_voucher` (+ `repatriate_vouchers`), `get_customer_count`, `get_or_create_my_conversation`, `mark_conversation_read`, `is_staff` — all take meaningful args or are meant as direct "can I do X" / RPC entry points; correctly left callable (`is_staff` even has an explicit `grant execute ... to authenticated`).
- `is_admin`, `is_manager` — used inside RLS `USING` clauses across multiple policies (`add_admin_role.sql`, `add_brand_to_manager.sql`, `repatriate_vouchers...sql`); revoking EXECUTE from PUBLIC would break every RLS policy that calls them for anon/authenticated roles evaluating their own rows. Correctly excluded — this is the same class of "meant to be called directly" as the plan's stated reasoning.
- `handle_new_user` — see (e).
- `prevent_profile_role_self_escalation`, `bump_support_conversation`, `update_product_rating`, `notify_order_update`, `update_sold_count`, `restock_on_order_cancel` — all trigger-only, all now revoked. `notify_order_update` and `update_product_rating` are defined and attached to triggers in `FE/schema.sql` (lines 338/365 and 479/493/497 respectively), not in the `migrations/` history — I confirmed the trigger attachment exists there, consistent with the plan's own note that `schema.sql` is a baseline, not the active migration source of truth.

No other SECURITY DEFINER function found un-triaged.

## Edge Cases Found by Scout
- Scope drift on the REVOKE list vs. the phase-06 plan's literal 6-item list is real but justified (see Medium #1) — not a defect, but should be reconciled in the plan doc so future readers aren't misled.
- Leaked-password-protection success criterion has no artifact confirming it was done (see High Priority) — this is a phase-completeness gap, not a SQL correctness issue.
- No re-grant of EXECUTE to PUBLIC/anon/authenticated appears anywhere later in migration history for any of the 6 revoked functions (this migration is chronologically last of 22) — no risk of the revoke being silently undone by a later migration.
- Zero objects currently exist in `products`/`reviews` buckets, so the storage-policy change is unverified empirically against real files; documented as a known gap by the parent and independently reasoned as low-risk via first-party docs above.

## Positive Observations
`REVOKE ... FROM PUBLIC` (not just anon/authenticated) is the right fix for the stated problem — Postgres's implicit default grant to PUBLIC is inherited by every role regardless of a per-role revoke, and grep confirms no explicit `GRANT EXECUTE` statement exists anywhere for these 6 functions that would re-grant after the revoke.

## Recommended Actions
1. Re-run `get_advisors security` from a session with a working Supabase MCP binding to close out check (a) — do not treat this phase as fully verified until that's independently confirmed.
2. Confirm (out-of-band, Supabase dashboard) whether leaked-password protection was actually enabled; if not, that's an outstanding phase-06 item.
3. Update `plans/260711-1403-bigstyle-full-app-improvement/phase-06-security-hygiene-db.md`'s function list to reflect `restock_on_order_cancel` replacing `handle_new_user`, so the plan matches what actually shipped (lead/planner action, not this review's to edit).
4. When any product/review images are eventually uploaded to Supabase Storage (vs. today's external Unsplash URLs), do one real anonymous-URL fetch smoke test to close the empirical gap on the storage policy drop.

## Metrics
- Type Coverage: N/A (SQL-only change)
- Test Coverage: N/A (DB-only phase per RT-15, no Dart test angle)
- Linting Issues: 0

## Unresolved Questions
- Was `get_advisors security` actually re-run with a working tool binding, and does the before/after story hold? I could not confirm this myself in this session.
- Was Auth leaked-password protection enabled as part of this phase, or does it remain outstanding?
