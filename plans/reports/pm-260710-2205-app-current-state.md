# PM Report — BigStyle app current state

**Date:** 2026-07-10 22:05 | **Branch:** `dev` (== `main` @ `a3a256c`) | **Author:** project-management

## TL;DR
Code-side largely complete and green. `dev`/`main` synced, latest reskin + post-audit UI/UX fixes merged (PR #15). Remaining gaps are **runtime/DB-verification** items needing a device + Supabase session — not code changes.

## Build health (ground truth)
| Signal | Value |
|--------|-------|
| `flutter analyze` | **0 issues** |
| `flutter test` | **66 cases / 19 files — green** |
| hardcode-color guard | **0 (PASS)** |
| Git | `dev` == `main` @ `a3a256c`, all pushed |

## App surface
- **47 screens, 16 blocs, 13 services, 14 models.**
- Feature areas: admin, auth, cart, chat, checkout, delivery(map), favorites, home, manager, notifications, orders, product detail/list, profile, splash.
- Roles: customer / manager / admin (no delivery role; delivery = map view only).
- Design: Warm Terracotta v2 tokens, hardcode guard enforced at 0.

## Plan portfolio (14 plans)
| Status | Count | Notes |
|--------|-------|-------|
| completed | 12 | bugfixes, audits, category mgmt, feature-gap, stability, role-ops, QA-fix, UI/UX audit, reskin, branch cleanup |
| done | 1 | post-audit UI/UX fix batches (this session) |
| partial | 1 | demo-fix-roadmap — see open items |

> Note: many "completed" plans show unticked checkboxes — those are acceptance/requirement lists never back-ticked, not real gaps. `status` frontmatter + git are the reliable signal.

## Latest delivered (this session → merged to main)
- **Currency:** shared `formatVnd()`; all VND prices render `10.000đ` (17 sites + 4 local formatters unified).
- **FABs:** unique `heroTag` ×6 — admin-login Hero-collision crash fixed.
- **Manager stat cards:** design-token alignment (bold textPrimary, warning/info accents).
- **OTP UX:** paste (noisy-clipboard aware), backspace-to-prev, re-submit after edit, verify-in-flight gating + spinner, focus-after-error.
- **Auth:** per-email resend cooldown (leak-safe), proper `validateEmail`, verify targets emailed address, rate-limit message.
- Reviewed by code-reviewer: no critical/high/medium findings.

## Open items (genuinely remaining)
1. **Runtime/DB verification (demo-fix-roadmap, partial)** — all code-unverifiable, need live emulator + Supabase:
   - Manager OTP login lands on `/manager` (runbook not yet performed).
   - Manager dashboard "Khách hàng" ≥ 2; ≥1 confirmed-today + ≥1 delivered-today order with items+payments (seed/DB state).
   - Test-junk orders/prices removed from demo path.
2. **Runtime smoke pending** — stability-hardening phases 4/5/6 marked "runtime pending" / "blocked by no device/session"; post-audit plan's emulator spot-checks (visual separators, live Hero log, on-device OTP paste/backspace, countdown 1×) not run in this environment.
3. **Known limitations carried (documented, out of scope):** `AuthBloc` default concurrent transformer (bloc-level overlapping send/verify still possible); OTP cooldown is client-courtesy only (server rate limits are the guard); `shouldCreateUser` default (OTP send auto-creates accounts).

## Plan hygiene
- **RESOLVED 2026-07-10:** demo-fix-roadmap rollup reconciled — X7 Share verified wired (`product_detail_screen.dart:165`), Phase 5 → ✅ Completed (X3 shipping also unified). Plan stays `partial` **only** on Phase 1 DB/runtime seed (needs live emulator + Supabase), which is correct, not stale.
- 3 untracked docs in working tree (audit/report + red-team journal) — not committed; decide keep vs commit.

## Recommended next steps
1. **One emulator+Supabase pass** to clear the entire runtime/DB verification backlog (items 1–2) — the single biggest remaining lever; no code work.
2. Tick X7 done + reconcile demo-fix-roadmap → likely `completed`.
3. Optional hardening (separate plan): `droppable()` transformer on `AuthBloc` to close the app-wide send/verify race.

## Unresolved questions
- Which Supabase env does the demo build target (hosted 60s OTP window vs local-dev 1s/2-per-hour) — affects whether the rate-limit snackbar is reachable in testing.
- Keep or commit the 3 untracked audit/report docs?
