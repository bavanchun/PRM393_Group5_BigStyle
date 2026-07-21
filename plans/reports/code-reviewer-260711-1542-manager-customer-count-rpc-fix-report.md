# Code Review: Manager Dashboard Customer Count Fix (F5)

## Scope
- Files: `FE/lib/models/manager_dashboard_stats.dart`, `FE/lib/services/order_service.dart`, `FE/test/models/revenue_recognition_test.dart`, `FE/supabase/migrations/20260711160000_manager_customer_count_rpc.sql` (new)
- LOC: 12 changed (Dart) + 25 (SQL migration)
- Focus: full diff, RLS/security boundary verification, runtime type trace
- Verification commands run: `flutter analyze` (0 issues), `flutter test` (109/109 pass), full migration history grep, `postgrest` package source trace for RPC scalar decoding

## Score: 9/10

## Overall Assessment
Correct, minimal, well-scoped fix. The root cause (RLS gap, not query logic) is accurately diagnosed and cross-corroborated by an *independent* prior migration (`20260709203942_order_shipping_address_customer_name.sql`) that documents the same "manager SELECT on profiles was deliberately dropped" fact — this isn't just the new diff's own comment asserting it. The RPC-only approach is the right call over adding a new "Managers can view all profiles" policy, and is consistent with how the rest of the codebase already treats the manager/customer-PII boundary (see (g) below). No side effects outside the stated scope.

## Mandated Checks

**(a) Acceptance criterion achieved, durably?** Yes. `get_customer_count()` returns `count(*) where role='customer'` — a real aggregate query, not hardcoded to the current 1-customer dataset. Gated by `is_manager()` with a hard `else 0` fallback for non-managers. Verified live per the task's own testing notes (manager JWT → 1, customer JWT → 0) and confirmed structurally correct by reading the SQL.

**(b) Caller graph for `fromRows` / `getDashboardStats` — full regression check.**
Grepped all usages directly (did not trust the task's own list):
- `fromRows`: exactly 2 call sites — `order_service.dart:55` (production, updated) and `revenue_recognition_test.dart:68` (updated to `customerCount: 0`). No other call sites exist.
- `getDashboardStats`: `order_service.dart` (this one) vs. a *separate, unrelated* `admin_service.dart:19` method of the same name on a different class — not affected. Production callers: `manager_bloc.dart:24,125`, both consume the opaque `Future<ManagerDashboardStats>` return type, insulated from the `fromRows` signature change. Test double `manager_bloc_test.dart:55` implements its own `getDashboardStats()` stub, unaffected by the factory signature.
- Confirmed no other file imports `ManagerDashboardStats` and calls `fromRows` (`grep -rln ManagerDashboardStats FE/lib FE/test` → 7 files, all checked).
Full test suite (109/109) plus targeted `manager_bloc_test.dart` / `manager_stats_grid_test.dart` pass, confirming no downstream breakage.

**(c) Is the `is_manager()` gate meaningful / any bypass?**
- `is_manager()` (defined in base schema, `SECURITY DEFINER`, `stable`, `set search_path = public`) checks `profiles.role = 'manager' AND id = auth.uid()`. Runs under definer privileges specifically to avoid RLS recursion on `profiles` — legitimate, standard pattern, matches `is_admin()`'s identical shape.
- Self-escalation to `role='manager'` is independently blocked: `20260709204006_profiles_prevent_role_self_escalation.sql` adds a `BEFORE UPDATE` trigger that raises unless `is_admin()`, closing the obvious "update my own role to manager" bypass.
- The RPC leaks **only a scalar count**, never row-level data, and gates with `else 0` — repeated calls by a non-manager can at most confirm the answer is always `0`; there is no per-row information to extract via timing or repetition. Not a meaningful side channel.
- `search_path` is explicitly pinned (`set search_path = public`), consistent with the project's own hardening pass (`20260711013000_harden_secdef_search_path.sql`) — no search-path-hijack vector.
- No bypass found.

**(d) `Future.wait` mixed-type trace — compiles and behaves correctly at runtime?**
Traced this manually rather than trusting `flutter analyze`:
- `_client.rpc('get_customer_count')` returns `PostgrestFilterBuilder<dynamic>` (the `rpc<T>()` generic defaults to `dynamic` when uninstantiated) which `implements Future<dynamic>`.
- `Future.wait([...])` over a list mixing `Future<PostgrestList>` (from `.from().select()`) and `Future<dynamic>` infers `Future.wait<dynamic>`, returning `List<dynamic>` — exactly why the code casts each element explicitly (`as List`, `as num`).
- Confirmed via `postgrest-2.7.3` source (`postgrest_builder.dart:296-324`): when `R` is not `PostgrestList`/`PostgrestMap`, the JSON-decoded `body` passes through unmodified. A Postgres `integer` RPC return decodes via `jsonDecode` to a bare Dart `int`/`num`, not wrapped in a list or map — so `results[2]` really is a scalar at runtime, and `(results[2] as num).toInt()` is correct, not a lucky cast.
- `flutter analyze`: 0 issues (confirms static side). `flutter test`: 109/109 pass (confirms behavioral side, including the widget/bloc tests that exercise `getDashboardStats()` through mocked returns).
No issue found.

**(e) No breaking changes to public contracts?**
Confirmed: `ManagerDashboardStats`'s primary constructor (`ManagerDashboardStats({required this.todayRevenue, ...})`) is untouched — only the `fromRows` named-factory signature changed (dropped `profiles` list param, added `customerCount` int param). Verified single production call site (b above). This factory is an internal construction helper, not exposed outside `FE/lib`; no external consumers exist in this single-package Flutter app.

**(f) No new lint/type/build errors?**
Re-verified independently rather than trusting the tester agent's prior claim: `flutter analyze` → "No issues found!" `flutter test` (full suite) → "All tests passed!" (109/109). Matches the claimed numbers.

**(g) Simpler fix possible? Was the RLS-policy alternative correctly rejected? Any inconsistent PII exposure elsewhere?**
- A simpler fix (just adding back `"Managers can view all profiles"`) was considered and correctly rejected — that policy exists in the stale `FE/schema.sql` snapshot but was **explicitly dropped** in `20260703150000_add_admin_role.sql` and never recreated in any of the 21 applied migrations. Re-adding it would reverse a deliberate, previously-documented decision (also independently corroborated in `20260709203942`), which is exactly the kind of prior verified decision that should not be silently reversed by a "smaller diff" instinct.
- Checked for inconsistent PII exposure via other manager-accessible paths: `order_service.dart`'s embedded `orders` selects use `customer:profiles(...)` joins that always resolve to `null` for managers (no profiles SELECT grant) — customer name is sourced from denormalized `shipping_address.name`, not a `profiles` read. `product_service.dart`'s `store:profiles(brand_name)` join surfaces a manager's *own* profile (their own brand name, scoped via `store_id = auth.uid()`), not customer data — not a counterexample. `admin_service.dart`'s flat profile queries are gated by `is_admin()`, a distinct actor with an intentionally broader grant — not an inconsistency with the manager boundary.
- Conclusion: the RPC-only approach is the minimal correct fix; the precedent it preserves is real and still enforced; no inconsistent leak path exists elsewhere in the codebase.

## Critical Issues
None.

## High Priority
None.

## Medium Priority
None. (The migration's own inline comment claim "already applied to prod; verified live" could not be independently re-confirmed from this session — no `supabase`/`psql` CLI or Supabase MCP tool binding was available in this environment to query the live DB directly. This is a verification gap, not a defect: static evidence (migration history, RPC SQL, is_manager() definition, hardening consistency) is internally consistent and sufixiently strong, but if audit trail matters, capture the live verification output somewhere durable (PR description or migration comment) rather than only in the task description, since it can't be re-derived from the repo alone.)

## Low Priority
- `FE/.claude/` is an untracked stray directory in the working tree (unrelated to this diff). Not part of this changeset; flagging only so it isn't accidentally swept into a `git add -A` on this branch.

## Side Effects (HARD-GATE-NO-SIDE-EFFECTS)
None detected. Scope is contained to: one new SECURITY DEFINER RPC (additive, no destructive DDL), one factory signature change with a single production call site, one test update to match. No schema/data mutation beyond function creation, no changes to existing RLS policies, no changes to other services/blocs/widgets.

## Recommended Actions
1. None blocking. Safe to proceed/merge as-is.
2. Optional: record the live BEGIN/ROLLBACK verification (manager JWT → 1, customer JWT → 0) in the PR description for audit durability, since it isn't captured anywhere in the repo itself.

## Unresolved Questions
- Live DB state for the migration could not be independently re-verified in this session (no `psql`/`supabase` CLI or MCP tool binding available here) — relying on the task's stated live verification plus strong static/historical corroboration from the migration files themselves.
