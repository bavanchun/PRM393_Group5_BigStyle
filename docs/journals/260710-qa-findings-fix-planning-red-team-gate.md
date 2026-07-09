# QA Findings Fix — Planning & Red-Team Gate Reshape

**Date**: 2026-07-10 · 03:00–05:00 UTC  
**Branch**: dev  
**Plan**: `plans/260710-0305-qa-findings-fix/`

---

## What Happened

Started with 5 QA findings (high: blank Google map + no Android API key; medium: manager order shows generic customer name, stale dashboard; low: Favorites misplaces tab highlight, orders.updated_at not maintained). Ran brainstorm → user approved all fixes + Favorites becomes Profile subpage without bottom nav. Created 3-phase plan (`--tdd` for phase 1).

Then red-team review (3 hostile reviewers) performed adversarial code audit against live schema. Reshaped plan significantly: 21 raw findings → 12 accepted; plan now materially different.

## The Brutal Truth

The original phase-1 root-cause diagnosis was **wrong**. We confidently identified that getOrderById should JOIN on customer:profiles, but manager detail screen reads from ManagerBloc.state.orders, and the manager SELECT on profiles was deliberately dropped in migration 20260703150000 for RLS reasons. Naive join policy risks PII leakage + infinite recursion. Tests would pass green but the bug stays unfixed.

**The red-team gate caught this before implementation.** If we'd shipped phase 1, we'd have wasted the cycle and learned it at device test. Lesson: repo migrations are not the schema source of truth for bugs involving remote drift or policy edges.

## Technical Findings (Accepted by Red-Team)

**Phase 1 (Customer Name):**
- Denormalize customer name into `orders.shipping_address.name` instead of joining profiles.
- New RPC: `create_order` injection point + backfill migration.
- Zero new profile:* privileges (not column-scoped RLS, which is impossible).

**Phase 1 (orders.updated_at):**
- Column unverified on remote (schema drift: `cancel_my_order` RPC untracked in migrations).
- Trigger migration now self-sufficient: `add column if not exists` + uniquely named function `orders_set_updated_at_fn` with pinned `search_path` (avoid collisions on remote).

**Maps Keys:**
- `.env` bundled into APK as Flutter asset (cannot stay secret).
- Strategy: SDK key in `local.properties` via manifest placeholder (platform-side, not shipped code); Directions key API-restricted + quota-capped, accepted client-visible (Edge Function proxy deferred — YAGNI).

**ManagerBloc Race:**
- Dual request-id (load + update share `_ordersRequestId`); stuck-spinner trap on concurrent refresh failure; false "update failed" on retry.
- Spec now precise: split try/catch, interleaving bloc test, no shared ID crossing load/update boundaries.

**Test Harness:**
- FakeOrderService needs dummy SupabaseClient constructor signature match.
- Favorites widget test needs fake blocs + pushed route for `canPop` to work (was: popped immediately, test passed silently).

## Decisions & Deferred

**Accepted immediately:**
- Remove dead `customer:profiles` embed from `getAllOrders`.
- Quota-capped Directions key (client-visible, risk accepted).
- Fix `profiles.role` self-writability immediately if phase-1 diagnostic finds it (conditional, not pre-emptive).

**Deferred:**
- Edge Function proxy for Maps (YAGNI; revisit if quota exceeded).
- Implementation start (user to provision Google Cloud keys first).

## What We Tried

- **First root-cause path:** JOIN customer:profiles in `getOrderById` RPC.
  - **Why it failed:** Manager reads from bloc state (orders cache), not fresh query. RLS policy risk. Plan would ship green tests, bug persists.

- **Denormalization validation:** Red-team verified injection point at `create_order` (already SECURITY DEFINER) + backfill scope + no new policy holes.
  - **Why it worked:** Shipping_address is client-controlled, customer name is read-only after insert, zero new select exposure.

## Root Cause Analysis

Three interconnected issues hid the right fix:

1. **Code path mismatch:** Didn't trace far enough from "customer name missing" → "what code path reads this?" → manager detail's bloc state cache. Assumed live query, wrote a live-query fix.
2. **Schema drift as normal state:** Remote `orders.updated_at` was never backfilled on this project (cancel_my_order existed in production before the code was tracked in migrations). We assumed "if it's in code, it's in the schema." It wasn't.
3. **Maps secret leak model:** First instinct was to hide API key (impossible given APK bundling). Took red-team to reframe: two keys, one per-side, quota as policy.

## Lessons Learned

- **For remote-schema bugs, repo migrations ≠ source of truth.** Always `SELECT column_name FROM information_schema.columns WHERE table_name = 'orders'` first (or trust the red-team to do it).
- **Code-path tracing before RPC design.** The question "who calls this code?" must come before "what data structure fixes it?"
- **Denormalization is not evil if the source is immutable.** Shipping address name is set once at order creation (customer can't change it). Safe to denormalize.
- **Red-team gates work.** Adversarial review caught a plan that would ship quiet failure (green tests + live bug).

## Next Steps

1. **User:** Provision Google Cloud project, extract SDK key (local.properties) + Directions API key (capped quota, client-safe).
2. **Implementation:** Run phase 1 (--tdd) on `plans/260710-0305-qa-findings-fix/phase-01-*` when keys available + user approves.
3. **Validation log:** Add phase-01 diagnostic step (check `profiles.role` self-writability via RLS query) before phase-02.

---

**Status**: DONE  
**Summary**: Planned all-5-findings fix in 3 phases; red-team review caught original phase-1 root-cause was wrong (naive join vs. denormalize), reshaped plan to avoid shipping green tests with live bug. User deferred implementation pending Google Cloud key provisioning.
