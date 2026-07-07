# Journal — Demo-Ready Fix Roadmap (2026-07-03)

Turned `docs/ux-flow-audit.md` (111 findings) into a demo-first fix roadmap
(`plans/260703-1750-bigstyle-demo-fix-roadmap/`) and implemented 4 of 5 phases
on `dev`. Prioritized by "breaks/embarrasses the on-camera walkthrough", not raw
P0→P3.

## Shipped (6 commits)
- **Phase 2 — Splash P0:** guest cold-start hung forever. Root cause = `AuthBloc`
  re-emitting `AuthInitial` (Equatable dedupe → no transition → splash listener
  never fired). Added `AuthUnauthenticated`, try/catch, `AuthLoading`-first (so
  retry re-transitions), navigate-once + `mounted` guards.
- **Phase 3 — Customer flow:** cart never loaded (`CartLoad` had zero dispatch
  sites) + never cleared in `CartBloc` after order; buy-now double-nav + silent
  wrong-colour variant fallback; category filter matched a lowercased label
  instead of the real category id; order detail loaded in `build()` + span
  forever on error; edit-profile claimed success unconditionally. Also cleared
  stale `selectedOrder` and gated re-pay so it doesn't wipe the current cart.
- **Phase 4 — Manager:** dashboard revenue counted `delivered`-only → always 0
  (now counts confirmed/processing/shipping/delivered); orders tab didn't reload
  on re-entry; status-update errors swallowed + request-id race; update sheet
  popped before the bloc resolved; category dropdown never persisted. Made the
  dropdown data-driven from real categories.
- **Phase 5 — Polish:** order codes show `orderNumber` not UUID (incl. COD
  dialog); single flat 30k shipping (deleted dead distance code); "CurveFit
  Admin" → "Quản trị BigStyle" + white app bar; removed chat fake online dot +
  mock image button, dead Share/camera/hamburger/pagination buttons; wired
  favorites entry.

## Handoff (Phase 1 — needs the user)
`FE/seed_demo_accounts_and_orders.sql` + `phase-01-setup-runbook.md`: create a
dedicated manager account (email OTP) + seed customers/orders via Supabase SQL
Editor. Manager-phase runtime validation depends on this.

## Notes / debt
- `manager_bloc` shares `_ordersRequestId` between load and update — latent
  stuck-spinner if orders polling is ever added (unreachable today).
- Two manager product screens were auto-reformatted to 80-col (behaviour-neutral,
  verified); diffs are large.
- Not runtime-tested on emulator yet — all changes are `flutter analyze`-clean
  and code-reviewed, but need a device pass.

## Unresolved
1. Runtime/emulator verification of all phases.
2. Phase 1 execution (user's OTP signups + SQL).
3. Confirm "today revenue = accepted statuses" reads right on the real dashboard.
