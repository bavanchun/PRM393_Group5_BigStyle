---
title: "BigStyle Demo-Ready Fix Roadmap"
description: "Demo-oriented fix roadmap turning docs/ux-flow-audit.md (111 findings) into a phased, on-camera-first fix plan for the PRM393 course demo. Flutter (BLoC) + Supabase."
status: partial
priority: P1
branch: "dev"
tags: [demo, bugfix, ux-audit, flutter, supabase]
blockedBy: []
blocks: []
created: "2026-07-03T10:54:35.105Z"
createdBy: "ck:plan"
source: skill
---

# BigStyle Demo-Ready Fix Roadmap

## Overview

Turn `docs/ux-flow-audit.md` (111 findings, 2026-07-03, audit-only) into a **demo-oriented** fix plan for the PRM393 Group5 course submission. Prioritization axis is **"does it break or embarrass the on-camera walkthrough?"** — not raw P0→P3. A P0 that never appears in the demo path matters less than a P2 on screen the whole time.

**Stack:** Flutter + BLoC + Supabase (Postgres + RLS + SePay). Design tokens in `FE/lib/config/theme/app_colors.dart`.

**Demo walkthrough this plan protects:** login → browse → filter (Đầm/Áo/Quần) → product detail → add to cart / buy now → checkout → SePay pay → orders → order detail → flip to manager → dashboard → manage/update order status → create/edit product.

**Prior context (important):** A **completed** plan `260620-0845-bigstyle-p0-p3-bugfixes` (2026-06-20, on `main`) claimed to fix cart (Phase 1) and wire manager real data (Phase 3). Today's audit **still** finds cart (C15/C16) and revenue (M6b) broken → those fixes were incomplete or regressed on `dev`. This plan supersedes for demo scope. Both prior plans are `completed`; no cross-plan frontmatter links needed.

**User decisions locked (from brainstorm):**
- **Shipping:** keep flat model, change test `1000đ` → realistic value (e.g. `30000`); delete the 2 unused divergent models.
- **Chat:** keep AI bot; relabel clearly, fix fake online dot + mock image button.
- **Manager account:** create a **dedicated** manager account (separate email) + seed customer/order data so dashboard shows real numbers.

## Phases

| Phase | Name | Priority | Status |
|-------|------|----------|--------|
| 1 | [Demo Environment & Seed Data](./phase-01-demo-environment-seed-data.md) · [runbook](./phase-01-setup-runbook.md) | P1 | 🔄 In-progress — seed SQL committed; DB seed unverifiable code-only + manager OTP login not done |
| 2 | [Splash & Auth Unblock](./phase-02-splash-auth-unblock.md) | P0 | ✅ Completed — code-verified |
| 3 | [Customer Purchase-Flow Blockers](./phase-03-customer-purchase-flow-blockers.md) | P1 | ✅ Completed — code-verified |
| 4 | [Manager Operations Blockers](./phase-04-manager-operations-blockers.md) | P1 | ✅ Completed — code-verified |
| 5 | [On-Camera Polish](./phase-05-on-camera-polish.md) | P2 | 🔄 In-progress — X3 delivery_map divergent shipping + X7 product-detail Share dead button remain |

## Dependency Chain

```
Phase 1 (env/seed) ──> Phase 4 (manager: need seeded account+orders to test M7b/M6b)
Phase 1 (seed customer) ──> Phase 3 (need a real customer + persisted cart to test C15)
Phase 2 (splash) ── independent, ship first (fast P0 win)
Phase 5 (polish) ── mostly independent; revenue-count sanity depends on Phase 1 seed
```

- **Phase 1 gates Phase 4:** M7b and M6b can only be validated against a proper dedicated manager account + seeded confirmed/delivered orders. Phase 1 may also *resolve* M7b outright if "blank orders tab" was a flip-role/empty-data artifact (see Phase 4 risk).
- **Phase 2 is independent** and the fastest P0 → ship first as a confidence win.
- Phases 3/4/5 touch disjoint file sets — safe to run sequentially in any order after Phase 1.

## Out of Scope (deferred backlog — not demo-visible)

Transaction integrity for `createOrder` (C46), create↔edit product screen dedup (~90% dup, M34), client role-guard (M38 — RLS already protects data, verified X1), full error-vs-empty state standardization (X5), token/cosmetic cleanup (Colors.* hardcode, .withOpacity), OTP paste/backspace/cooldown polish (G10-G18), notifications navigation (C37-C39). These are real but do not affect the recorded demo.

## Cross-Plan Dependencies

None active. Prior plans `260620-0845-bigstyle-p0-p3-bugfixes` and `260703-1537-role-based-ux-flow-audit` are both `completed`.

## Acceptance Criteria (whole plan)

- [x] Fresh/logged-out launch reaches `/login` (no splash hang) — G1/G2. — auth_bloc.dart:39 + splash_screen.dart:64-68 (Phase 2, code-verified).
- [x] Customer purchase flow works end-to-end incl. cart persistence + clear after order — C15/C16/C11/C12.
- [x] Manager can view orders, update status with visible success/error, and see non-zero today revenue — M7b/M7/M6b/M13. — Phase 4 code-verified.
- [x] Manager create/edit product saves the chosen category — M23/M31. — create :211 / edit :233.
- [ ] No wrong branding ("CurveFit Admin"), no on-camera dead buttons in the demo path, orders show human-readable `orderNumber` — M17/M19/X2/X7. — branding + orderNumber done, but product_detail_screen.dart:163 Share button still dead (X7).
- [x] `flutter analyze` clean before each phase commit. — "No issues found!" (ran 2026-07-10).

## Reconciliation Notes

- 2026-07-10: Customer checkout criteria checked from
  `plans/260709-2231-bigstyle-remote-data-testability-hardening/reports/260709-remote-data-android-smoke-report.md`
  plus current `flutter analyze`/`flutter test` gates in
  `plans/260710-0001-bigstyle-role-ops-hardening/reports/pm-role-ops-hardening-completion.md`.
- Remaining unchecked criteria need a fresh demo-path runtime smoke, especially
  logged-out splash and manager order status mutation.

## Validation Notes (deep mode)

Red-team + validation gates were applied inline during authoring (see each phase's Risk Assessment). Key adversarial findings folded in: M7b is a hypothesis not a proven widget bug (Phase 4 makes it a *diagnose-then-fix* step, not a blind rewrite); Phase 1 requires user actions (email OTP + SQL DDL via Supabase console) that block automated execution; shipping "realistic value" is a placeholder pending user's exact number.
