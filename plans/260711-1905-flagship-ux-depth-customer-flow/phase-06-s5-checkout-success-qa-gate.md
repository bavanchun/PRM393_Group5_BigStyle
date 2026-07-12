---
phase: 6
title: "S5: Checkout Success + QA Gate"
status: completed
priority: P1
dependencies: [1, 2, 3, 4, 5]
effort: "M"
---

# Phase 6: S5 — Checkout Success Delight + QA Regression Gate

## Overview

Two jobs: (a) replace the flat COD success `AlertDialog` with an animated success moment, and (b) run the whole-flow QA/regression gate that validates every prior phase before this plan is considered done.

## Requirements

- Functional: successful order (COD path) shows an animated confirmation (drawn checkmark + scale + success haptic), then continues to `/order-detail` (unchanged destination); a per-screen interaction checklist passes; automated gates green.
- Non-functional: no regression to the order/money path (visual-only change to the success surface); no new raw-color debt.

## Architecture

### S5 — Success moment
<!-- Updated: Red Team 2026-07-12 — M2 real span 339–378 (not 369); M1 continue-route is /order-detail not /orders -->
- Replace the `AlertDialog` — its real span is **`checkout_screen.dart:339–378`** (the `showDialog(` at :339 closes at :378; lines 370–378 hold the pop + nav + braces; cutting at 369 orphans them) — with an animated success surface:
  - Animated checkmark: `CustomPainter` stroking a check path driven by an `AnimationController` (no Lottie), + container scale-in (`AppMotion.base`, `entrance`).
  - `Haptics.success()` on appear.
  - Preserve the existing CTA/destination **exactly**: `pushReplacementNamed('/order-detail', arguments: state.orderId)` (`checkout_screen.dart:369–372`) — the label is `'Xem đơn hàng'`. **Do NOT change it to `/orders`** (that would repoint the money-path outcome — red-team M1).
- **Do NOT touch** order-creation, cart-clear, or the SePay QR branch — only the COD-success *presentation*. Keep lines `:316–338` byte-identical (the COD/QR exclusive flags + cart-clear live there — red-team F5). The two outcomes stay mutually exclusive (`checkout_screen.dart:316,329`).

### QA regression gate (whole flow)
- **Automated:** `flutter analyze` (0 new issues) and `flutter test` (existing suite passes) — run from `FE/`.
- **Hardcode guard:** reuse the reskin plan's grep gate on customer-flow dirs (`home/ product_list/ product_detail/ cart/ checkout/ orders/ search/`) — assert **no NEW** raw `Colors.*`/`0xFF`, with `Colors.transparent` **allowlisted** (2 known-baseline: `product_detail_screen.dart:625`, `size_guide_sheet.dart:15` — red-team M3). Not a literal "0".
- **Motion-token guard (scoped — M5):** check that **animation** `Duration`s use `AppMotion`. Do NOT blanket-grep `Duration(` — it false-positives on legitimate non-animation uses: SnackBar `Duration(seconds:2)` (`product_detail_screen.dart:718`), `.timeout(Duration(...))` (`:764`, `checkout_screen.dart:249,294`), `Future.delayed` (`cart_item_edit_screen.dart:150`). Only the 2 real animation literals (`product_detail_screen.dart:308,514`) are in scope.
- **Per-screen interaction checklist** (manual, device/emulator): each screen has press feedback; loading = skeleton (not blank spinner); haptics on intentful actions; S1–S5 each demoed once end-to-end.

## Related Code Files

- Create: `FE/lib/widgets/animated_success_check.dart` (CustomPainter checkmark)
- Modify: `FE/lib/screens/checkout/checkout_screen.dart` (COD success dialog `339–378` only; preserve `/order-detail` nav + `:316–338`)
- Reference (no edit): reskin plan hardcode-guard script

## Implementation Steps

1. Build `animated_success_check.dart` (CustomPainter + controller).
2. Swap the COD success `AlertDialog` (`:339–378`) for the animated surface; wire haptic; preserve the `/order-detail` nav.
3. Run `flutter analyze` + `flutter test`; fix any new issues.
4. Run hardcode + motion-token grep guards; fix stragglers.
5. Walk the per-screen interaction checklist on device; log pass/fail.
6. Mark plan phases complete via `ck plan check`.

## Success Criteria

- [x] COD success shows the animated checkmark + scale + success haptic, then continues to **`/order-detail`** (unchanged destination).
- [x] Order/money path behavior unchanged (only the success visual changed); `:316–338` byte-identical; SePay branch untouched.
- [x] `flutter analyze` = 0 new issues; `flutter test` passes.
- [x] No NEW raw `Colors.*`/`0xFF` (Colors.transparent allowlisted); animation `Duration`s use `AppMotion` (non-animation Durations exempt).
- [x] Per-screen interaction checklist all-pass; S1–S5 demoed end-to-end.

## Risk Assessment

- **Regressing the money path** → strictly scope the edit to the COD-success presentation; do not alter order creation, cart clearing, or the QR branch. Re-test placing a real COD order end-to-end.
- **CustomPainter perf** → trivial single-path stroke; negligible.
- **Checklist skipped under deadline** → the automated gates (analyze/test/grep) are the non-negotiable minimum; the manual checklist is the quality bar for "flagship".
