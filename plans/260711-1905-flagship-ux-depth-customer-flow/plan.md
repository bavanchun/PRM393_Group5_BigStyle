---
title: "BigStyle Flagship UX-Depth — Customer Shopping Flow"
description: "Flagship interaction/motion/state upgrade for the customer shopping flow (home→list→detail→cart→checkout→orders) on top of the frozen Warm Terracotta v2 reskin. Hybrid approach: thin shared motion/haptics/feedback foundation + 5 choreographed signature moments (S1 personalized home, S2 Hero list→detail, S3 add-to-cart confirmation, S4 real search, S5 checkout success). Flutter/BLoC, built-in animation APIs, no Lottie."
status: pending
priority: P1
branch: "dev"
tags: [ui-ux, motion, interaction, flutter, customer-flow, flagship]
blockedBy: []
blocks: []
created: "2026-07-11T12:16:02.733Z"
createdBy: "ck:plan"
source: skill
---

# BigStyle Flagship UX-Depth — Customer Shopping Flow

## Overview

Upgrade the **interaction/UX layer** of the customer shopping flow to a flagship, delightful feel — *on top of* the already-shipped visual reskin (Warm Terracotta v2, frozen). The visual layer is done (customer flow raw-color debt is near-zero — 2 allowlisted `Colors.transparent` remain, red-team M3); this plan targets the layer the reskin did not touch: **motion, haptics, tap feedback, state parity, and signature moments**.

**Source brainstorm:** [`plans/reports/brainstorm-260711-1905-flagship-ux-depth-customer-flow-report.md`](../reports/brainstorm-260711-1905-flagship-ux-depth-customer-flow-report.md)
**Design tokens (frozen):** [`docs/design-tokens-v2.md`](../../docs/design-tokens-v2.md) — the v2 motion spec (easeOutCubic 250–300ms) is defined there but **never implemented in code**; Phase 1 finally codifies it.

**Approach (locked):** C — Hybrid. Layer 1 = thin shared foundation applied across all 6 screens (DRY). Layer 2 = 5 signature moments biased onto the demo path.

**Locked constraints:**
- Customer flow ONLY (home, product_list, product_detail, cart, checkout, orders). Manager/admin/guest out of scope.
- Visual reskin v2 frozen — do NOT reopen brand/tokens; add no NEW raw-color hardcodes (customer-flow baseline: 2 allowlisted `Colors.transparent`, red-team M3).
- Selective flow changes allowed only where UX needs it: S4 adds a `/search` route; navigation architecture otherwise unchanged.
- Flutter/BLoC; **built-in animation APIs only** (Hero, AnimatedX, TweenAnimationBuilder, HapticFeedback, Overlay, CustomPainter). **No `flutter_animate`, no Lottie** (validated 2026-07-11). `google_fonts` kept.
- Course-demo deadline → phase order is demo-visibility-first, so partial completion still upgrades what graders see.

**Accepted defaults + validated decisions:**
1. S4 recent-searches = in-memory v1 (defer `shared_preferences`).
2. Offline state = deferred this round (not a signature; low demo value).
3. Motion = built-in only; no `flutter_animate` dependency (validated).
4. S2 Hero = enabled from product_list **and** home, with context-unique tags passed via route arg (validated — avoids dup-tag crash).
5. S3 fly-to-cart target on product_detail = a new cart icon in the detail app bar (validated). **[SUPERSEDED by red-team 2026-07-12: detail has no app bar; S3 downgraded to badge-pop + haptic — see Red Team Review.]**
6. S4 = reuse existing `ProductService.getProducts(searchQuery:)` server `ilike` (verified present at `product_service.dart:16,38`); no new service method.

## Phases

| Phase | Name | Status |
|-------|------|--------|
| 1 | [Foundation: Motion, Haptics & Feedback](./phase-01-foundation-motion-haptics-feedback.md) | Pending |
| 2 | [S1: Personalized Home + Staggered Entrance](./phase-02-s1-personalized-home-staggered-entrance.md) | Pending |
| 3 | [S2: Hero List-to-Detail](./phase-03-s2-hero-list-to-detail.md) | Pending |
| 4 | [S3: Add-to-Cart Confirmation (badge pop + haptic)](./phase-04-s3-fly-to-cart.md) | Pending |
| 5 | [S4: Real Product Search](./phase-05-s4-real-product-search.md) | Pending |
| 6 | [S5: Checkout Success + QA Regression Gate](./phase-06-s5-checkout-success-qa-gate.md) | Pending |

## Dependency Chain

```
Phase 1 (foundation) ──> Phases 2,3,4,5,6 all consume AppMotion/Haptics/PressableScale
Phase 4 (S3 downgraded to badge-pop + haptic) no longer shares heroTag plumbing with Phase 3
Phase 6 QA gate runs LAST (validates the whole flow) — depends on 1–5
```

Phases 2–5 are independent of each other once Phase 1 lands (could parallelize), but the QA gate (Phase 6) is a hard barrier after all of them. Recommended serial order = demo-visibility priority.

## Acceptance Criteria (whole plan)

- [ ] Every interactive element in the 6 screens has press feedback and uses `AppMotion` tokens — no literal `Duration(...)` **in animation code** (snackbar/`.timeout`/`Future.delayed` durations are exempt — red-team M5).
- [ ] product_detail shows a skeleton at parity with list (no blank spinner).
- [ ] Haptics fire on add-to-cart, size/color select, checkout confirm, item delete.
- [ ] All cart tap targets ≥ 44×44.
- [ ] Checkout has inline field validation (`autovalidateMode.onUserInteraction`).
- [ ] S1, S2, S3(reduced), S4, S5 all demoable on device.
- [ ] `flutter analyze` = 0 new issues; `flutter test` passes; customer-flow raw `Colors.*`/`0xFF` count stays at **baseline** — `Colors.transparent` allowlisted (2 known: `product_detail_screen.dart:625`, `size_guide_sheet.dart:15`); no *new* hardcodes (red-team M3).

## Related Plans (cross-links, non-blocking)

- `plans/260703-1750-bigstyle-demo-fix-roadmap` (partial) — its deferred cosmetic backlog was already absorbed by the completed reskin plan; no dependency here.
- `plans/260710-1342-bigstyle-visual-reskin-implementation` (completed) — this plan builds on its tokens/components; reuses its hardcode-guard grep gate in Phase 6.
- `plans/260710-2235-review-gate-map-chat-hardening` (in-progress) — different surface (map/chat/review), no file overlap.

## Validation Log

### Session 1 — 2026-07-11 (Full-tier verification + 4-question interview)

**Verification Results**
- Claims checked: ~15 across 6 phases · Tier: Full (5+ phases)
- Verified: all core file:line anchors (home greeting/search, `product_card` imageUrl, `app_bottom_nav` badge, checkout COD dialog, router, product_detail add-to-cart/size/color, `AuthState.user` nullable).
- Failed: 0. Refinement: S4 overstated effort — `ProductService.getProducts()` **already** has `searchQuery` + `ilike('name', …)` (`product_service.dart:16,38`); S4 reuses it (no new method). Effort L→M.
- Confirmed risk: home renders `ProductCard` in both featured (`home_screen.dart:112`) and new-arrivals (`:172`) → dup Hero tag is a real crash risk.

**Decisions confirmed (all Recommended)**
1. **S2 Hero tag** → product_list + home, tag = `product-${id}-${screen}-${section}-${index}`, passed to detail via route arg so both ends match. (→ phase-03)
2. **S3 fly-to-cart target** → add a cart icon to the product_detail app bar as the landing target (+ badge). (→ phase-04) **[SUPERSEDED by red-team 2026-07-12 — S3 downgraded, arc + phantom app-bar icon cut.]**
3. **S4 search** → reuse existing server `getProducts(searchQuery:)` `ilike`; small `SearchBloc` + debounce; no new service method. (→ phase-05)
4. **Motion dependency** → built-in only; drop `flutter_animate`. (→ phase-01, phase-02, phase-05)

**Whole-Plan Consistency Sweep:** propagated to phases 01/02/03/04/05; no residual `flutter_animate` "optional" mentions; S4 wording aligned to reuse-existing; no contradictions remaining. Recommendation: **proceed to implementation**.

## Red Team Review

### Session — 2026-07-12 (4 hostile reviewers: failure-mode, assumption-destroyer, scope-critic, security/money-path)

**Findings:** 15 (all Accepted) · **Severity:** 4 Critical, 4 High, 7 Medium. Money/order/cart-clear path verified structurally safe (server-authoritative RPC, exclusive COD/QR flags) — the only money-path exposure was the plan's *own* wrong route/span for the S5 edit (M1/M2), now fixed.

| # | Finding | Sev | Disposition | Applied |
|---|---------|-----|-------------|---------|
| C1 | S2 Hero no-ops: detail loads async (spinner during transition) → tagged image absent; home passes only id | Critical | Accept | phase-03 |
| C2 | S2 Hero tag self-contradiction (naive `product-${id}` in steps) + missing `favorites_screen.dart:70` call site | Critical | Accept | phase-03 |
| C3 | S3 fly/haptic fire before async add guards + result | Critical | Accept (via S3 downgrade) | phase-04 |
| C4 | S1 greeting inverted null-safety → guest NPE + analyze fail | Critical | Accept | phase-02 |
| H1 | S3 target "detail app bar" does not exist (full-bleed carousel + floating avatars + draggable sheet) | High | Accept (via S3 downgrade) | phase-04 |
| H2 | GlobalKey on per-screen Stateless `AppBottomNav` collides across transitions; badge 0→1 no stable target; shared w/ profile | High | Accept | phase-04 |
| H3 | DraggableSheet z-orders above carousel → Hero lands clipped | High | Accept | phase-03 |
| H4 | S4 reinvents existing working product_list search | High | **User override — keep S4** (accepted risk: 2 search surfaces) | phase-05 note |
| M1 | S5 route is `/order-detail` (arg orderId), not `/orders` | Medium | Accept | phase-06 |
| M2 | S5 AlertDialog span is 339–378, not 339–369 | Medium | Accept | phase-06 |
| M3 | "0 raw-color debt" false — `Colors.transparent` × 2; gate needs allowlist | Medium | Accept | plan.md, phase-06 |
| M4 | Phase 1 validation anchor wrong — `Form(key:)` at :429-430 | Medium | Accept | phase-01 |
| M5 | `Duration(` grep gate false-positives (snackbar/timeout/Future.delayed) | Medium | Accept | plan.md, phase-06 |
| M6 | AppSkeleton over-abstraction — 2 divergent call sites | Medium | Accept (simplify) | phase-01 |
| M7 | S1 stagger at mount vs staged async data → shimmer animates, content pops | Medium | Accept | phase-02 |

**User decisions on scope-reversing findings:**
- **S3 (C3/H1/H2)** → downgraded: badge scale-pop + `Haptics.success` only, gated on real add-success; OverlayEntry arc + phantom detail cart icon **cut**.
- **S4 (H4)** → **kept as-is** (dedicated new screen + `SearchBloc`); reviewer's "reinvention / two search surfaces" logged as accepted risk.

**Verified NON-issues:** money path structurally safe (`checkout_bloc.dart:47,88-99,124-131`); `getProducts(searchQuery:)` `ilike` injection-safe (bound param, `product_service.dart:37-38`); detail carousel already `Image.network` matching card (no decoder-swap).

**Reports:** `reports/from-code-reviewer-to-planner-red-team-{security-adversary,assumption-destroyer,scope-complexity-critic,failure-mode-analyst}-plan-review-report.md`

### Whole-Plan Consistency Sweep (post-red-team)
Applied C1/C2/H3→phase-03, S3 downgrade→phase-04, C4/M7→phase-02, M1/M2/M3/M5→phase-06, M4/M6→phase-01, S4 risk-note→phase-05. Re-checked: no phase still references the cut OverlayEntry arc or the phantom detail app-bar as a live target; S5 route unified to `/order-detail`; Duration/color gates scoped. No unresolved contradictions.
