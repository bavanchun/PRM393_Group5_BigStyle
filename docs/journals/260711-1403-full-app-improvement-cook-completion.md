# Journal — BigStyle full-app improvement cook completion

**Date:** 2026-07-11 14:03–16:20
**Plan:** `plans/260711-1403-bigstyle-full-app-improvement/`
**Branch flow:** per-phase `feat/*` → squash-merge to `dev` (PRs #24–#30)
**Status:** 6/6 active phases merged; phase 09 (native/emulator) non-blocking, pending

## What shipped

| Phase | PR | Summary |
|-------|----|---------|
| 01 Money-path | #24 | Voucher discount applies real server-validated value + atomic usage_limit row-lock; stock now locked→checked→decremented per item (sorted by variant_id for deadlock safety), oversell rejected; shipping_fee forced to server constant; negative/zero-quantity gap found in review, fixed with 4th migration same session. |
| 03 Order-status enum | #25 | Dart enum missing processing/refunded (DB has 7, Dart had 5 → silent fallback); aligned both; new statuses read-only; `fromMap` fallback now asserts loudly instead of swallowing unknowns. |
| 04 Dashboard customer count | #26 | Root cause: RLS gap (no manager SELECT policy on profiles), not the count query itself. Fixed via narrow `get_customer_count` SECURITY DEFINER RPC + internal `is_manager()` gate, preserving deliberate PII boundary. |
| 06 Security hygiene | #27 | Pinned search_path on 2 trigger functions; revoked EXECUTE on 6 trigger-only RPC surface; tightened 2 storage bucket policies. First REVOKE (FROM anon, authenticated) was a no-op — PUBLIC grant inherited by default — corrected to REVOKE FROM PUBLIC, verified via information_schema before/after. |
| 07 RLS perf hygiene | #28 | Added 7 indexes for unindexed foreign keys; wrapped 21 `auth.uid()` calls in RLS policies so Postgres caches once per query instead of per-row. Policy consolidation (120 warnings) deliberately cut — high cross-tenant PII leak risk for near-zero perf gain at ~7-order scale. |
| 08 Catalog pricing | #29 | All 15 products showed 10.000đ placeholder. `order_items` had 2 prices: 10000 (placeholder artifact, retired) and 350000 (one real transacted value, anchored across 5 categories). |

Verification: `flutter test` 109/109 green · `flutter analyze` 0 · hardcode-color guard 0.

## Friction & decisions

**Supabase branch strategy failed mid-Phase-01.** Plan mandated `create_branch → test → merge` per migration. Branching requires Pro plan — unavailable on this org. Discovered only when `create_branch` failed during Phase 01's first migration. Pivoted (after initially confusing the user about which cost was being asked) to direct prod apply + `BEGIN...ROLLBACK` verification before trusting — mirroring how every actual migration in this repo's history was already done, despite the plan's assumption. Updated plan & phase files to reflect actual practice.

**Code-review false positives (phases 03 & 07).** Two reviews came back blocking/low-score due to the reviewing subagent lacking Supabase MCP tool access, not real defects:
- **Phase 03:** Reviewer cited a stale, never-applied repo migration claiming 5-value enum, contradicted by live `enum_range(order_status)` query showing 7.
- **Phase 07:** Reviewer couldn't verify 12/21 rewritten RLS policies against live `pg_policies`; flagged 2 as name-mismatches despite both existing exactly as named when queried.

Both independently re-verified against live database before merging — a reminder that a subagent's tool-access gap can produce false negatives that look like real findings.

## What didn't ship (non-blocking)

**Phase 09 (native/emulator verification):** Reviews/wishlist/chat/support e2e rows, Google Maps/geolocator/image-picker/Google-signin/SePay flows. Blocked on `sudo modprobe kvm_amd` (user hasn't run it yet); explicitly non-blocking per red-team assessment.

**Follow-ups (not silently dropped):**
- Leaked-password protection: Auth-dashboard-only toggle, no SQL/MCP path available.
- `is_manager()` still not repatriated into repo migrations (pre-existing repo/prod drift).
- `20260708140000_update_order_status_enum.sql` has stale comment claiming 5-value enum; live DB has 7 — never actually applied (same repo/prod migration-history drift class as Phase 01's vouchers gap).

## Lessons

- Plan assumptions about tooling (Supabase branching) should be validated in kickoff, not discovered mid-Phase-01. The pivot was fast but burned credibility initially while the user's mental model updated.
- Two-pass review discipline (subagent + verification against live sources) proved essential when tool access is gapped. Blindly accepting or dismissing review scores would have either blocked valid PRs or shipped real defects.
- Live DB drift (missing/stale migrations, mismatched Dart enums) accumulates quietly. Phase 5 should start with an inventory audit, not assume migrations are synchronized.
- Policy consolidation red-team veto (high blast radius, low perf gain) was correct. 120 warnings flagged real structural debt but the risk/reward didn't justify the change at this scale — good example of "don't fix it just because an advisor complained."

## Next

Phase 09 awaits the user's KVM setup. Meanwhile: `plans/260711-1403-bigstyle-full-app-improvement/plan.md` and all phase files are synced to reflect completion; corrected the DB-branching-strategy note to match what actually happened.
