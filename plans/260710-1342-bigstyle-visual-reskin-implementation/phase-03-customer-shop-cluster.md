---
phase: 3
title: "Customer-Shop Cluster"
status: pending
effort: "L (1.5 days, 8 screens)"
priority: P1
dependencies: [2]
---

# Phase 3: Customer-Shop Cluster

## Overview

First customer-facing cluster — highest demo visibility. Migrates the shopping funnel: browse → product → cart → checkout.

## Screens (effort tags from Phase 4 cluster table)

| Screen | File | Effort | Findings source |
|---|---|---|---|
| Home | `FE/lib/screens/home/home_screen.dart` | M | `phase-04-gap-findings-customer.md` |
| ProductList | `FE/lib/screens/product_list/product_list_screen.dart` | M | same |
| ProductDetail | `FE/lib/screens/product_detail/product_detail_screen.dart` (+ `product_review_section.dart`, `review_editor_sheet.dart`, `size_guide_sheet.dart`) | **L** — 2 contrast findings survive the token swap, re-verify with real tool | same |
| Cart | `FE/lib/screens/cart/cart_screen.dart` | M | same; **also carries the Phase 0 checkout-CTA bug fix if root-cause was trivial** |
| CartItemEdit | `FE/lib/screens/cart/cart_item_edit_screen.dart` | M | same |
| Checkout | `FE/lib/screens/checkout/checkout_screen.dart` (+ 5 files in `checkout/widgets/`) | S (inferred, ungraded — see below) | Phase 1 code metrics only |
| PaymentQr | `FE/lib/screens/checkout/payment_qr_screen.dart` | S (inferred, ungraded) | Phase 1 code metrics only |
| Favorites | `FE/lib/screens/favorites/favorites_screen.dart` | **S — token-swap-only**, no structural findings | same |

## Pre-condition

Checkout and PaymentQr were **never visually captured** (blocked by the cart-CTA finding during the audit). Phase 0's human-tap check determines the path <!-- Updated: Red Team Session 1 - Phase 0 is diagnose-only; likeliest verdict is adb-capture artifact, not a bug -->: if the tap works by hand (capture-tool artifact — the likely case, since `cart_screen.dart:308-357` has no z-order structure that could swallow taps), Phase 0 already delta-captured these screens and this cluster proceeds normally. If Phase 0 diagnosed a real trivial bug, this phase fixes it (step 1). If it flagged non-trivial, migrate these 2 screens from code+Phase 1 metrics alone and flag them `unverified` in this phase's completion note — don't block the whole cluster on 2 screens.

## Implementation Steps

1. If Phase 0 diagnosed a real, trivial cart-CTA bug: fix it in a **separate commit** from any token work — never fused with the reskin diff. <!-- Updated: Red Team Session 1 - hard two-commit rule; the old "one commit, separable diffs" wording contradicted plan.md's own separate-changes rule and breaks revert isolation on the demo-critical checkout funnel -->
2. Per screen: replace `Colors.*`/hex hardcodes with `AppColors.*` tokens and swap any inline `TextStyle`s for `AppTypography.*`. **Checklist = live output of the Phase 1 guard script filtered to this cluster's files** — the audit's per-screen counts (ProductDetail 7, Home 8, ProductList 8) are context only; they undercount lines that mix a token with a hardcode (e.g. `product_list_screen.dart:216`, `product_detail_screen.dart:538`). <!-- Updated: Red Team Session 1 -->
3. **ProductDetail's inline size-selector block (`product_detail_screen.dart:504-550`)**: rework the selected state to tonal (light-tint background + primary text, replacing solid-fill+white at `:529`/`:538`) — this is the REAL code behind the audit's size-selector tonal finding; the standalone `size_selector.dart` widget was an orphan and Phase 2 deleted it. <!-- Updated: Red Team Session 1 -->
4. ProductDetail's 2 surviving contrast findings: re-check with a real WCAG tool (not the audit's Gemini-cited numbers, per the plan-level risk note) — likely candidates are price/badge text on the new terracotta primary; adjust the specific element's color pairing if it genuinely fails, don't blanket-darken.
5. Where a `StatusBadge` consumer was identified in Phase 2 but not yet migrated on these screens, do it now (Phase 2 built the component, cluster phases do the full-screen rollout).
6. `flutter analyze` after each screen; `flutter test` at cluster end.
7. Regression checklist (below) — manual pass, this is a VISUAL reskin, zero flow changes.

## Regression Checklist (flow/behavior must be identical pre/post)

- [ ] Home: search bar, category chips, product-card taps all navigate identically.
- [ ] ProductList: filter sheet (inline, not a separate screen) opens/closes/filters identically.
- [ ] ProductDetail: size selector (inline block, now tonal per step 3), add-to-cart, review section, size-guide sheet all function identically. <!-- Updated: Red Team Session 1 -->
- [ ] Cart: item selection, quantity edit, checkout navigation (bug-fixed or not) all function identically to pre-migration behavior minus the bug itself.
- [ ] CartItemEdit: save/cancel behavior unchanged.
- [ ] Checkout/PaymentQr: address/payment-method/voucher sections, QR display — unchanged (verify once reachable).
- [ ] Favorites: empty state + populated state (add a favorite in a demo account to verify populated state, since Phase 2 audit only captured empty).

## Success Criteria

- [ ] All 8 screens migrated (or Checkout/PaymentQr explicitly flagged `unverified` with reason, not silently done).
- [ ] Hardcode-guard script (Phase 1) passes for this cluster's files.
- [ ] Regression checklist above signed off.
- [ ] `flutter analyze` + `flutter test` clean.

## Risk Assessment

- **Checkout/PaymentQr migrated blind and something breaks visually** → low risk (both low-debt, high-shared-widget-use per Phase 1), but explicitly re-verify once the cart-CTA bug unblocks live capture — don't let "inferred token-swap-only" quietly become "verified."

## Completion Note (2026-07-10)

**Status:** Done. Cart CTA confirmed a capture-tool artifact (user hand-tap on `emulator-5554`, see Phase 0) — no bug-fix step needed.

**Per-screen:**
- **Home:** 8 hits fixed (search-bar/hero-banner white→surface/onPrimary, shimmer greys→new `AppColors.skeletonBase/skeletonHighlight`).
- **ProductList:** 8 hits fixed (cart-badge/search-bar/selected-filter-chip text/shimmer — same skeleton tokens as Home, since this screen shares the identical `Shimmer.fromColors(Colors.grey[200]!, Colors.grey[100]!)` pattern verbatim).
- **ProductDetail (L):** 11 hits fixed across the screen + `size_guide_sheet.dart` (product name/price fonts moved off direct `GoogleFonts.playfairDisplay`/`dmSans` onto `AppTypography.displaySmall`/`price`/`caption` with `.copyWith()` for the sizes that don't have an exact preset; now-unused `google_fonts` import removed). Inline size-selector (`:504-550`) reworked tonal per the plan's explicit instruction: selected state is now `AppColors.primary.withValues(alpha:0.12)` bg + `AppColors.primary` text (was solid-fill + white). `product_review_section.dart` and `review_editor_sheet.dart` were already zero-hardcode (the latter's `ChoiceChip` picks up Phase 1's tonal chip fix automatically, no code change needed).
- **Cart:** 1 hit (bottom-bar shadow).
- **CartItemEdit:** 2 hits (white-swatch shadow, saving-spinner color). Its `ChoiceChip` size selector (the literal finding source for the plan's "CartItemEdit tonal-violation") needed **zero code change** — Phase 1's `chipTheme` rework already fixes it at the theme level, confirming that fix actually reaches its intended target.
- **Checkout:** 3 hits, all `Colors.green` (location-found success signal) → `AppColors.success`, with an explicit white content-text style added (see contrast note below) rather than relying on inherited SnackBar theme defaults.
- **PaymentQr:** zero hits — already fully token-driven. Migrated "blind" per the plan (no customer-role credentials this session to live-capture); flagged `unverified` visually, though the guard scan + `flutter analyze` prove the code itself has no hardcode debt.
- **Favorites:** zero hits, confirmed token-swap-only as the plan predicted.

**Contrast re-verification (both of ProductDetail's audit-cited findings are false positives):** the original audit claimed "(1) price + 'Hướng dẫn chọn size' link stay under AA even after v2 primary swap (3.9:1 vs 4.5:1 needed)" and "(2) white text on solid 'L' chip/'Mua ngay' button also under AA." I independently computed the WCAG relative-luminance contrast for `AppColors.primary` (`#9A3F35`) against white by hand: **6.70:1** — which exactly matches `docs/design-tokens-v2.md`'s own pre-verified "white-on-primary 6.70:1 (button text)" figure (identical color pair, contrast ratio is direction-symmetric). Also checked primary-as-text against the `background` cream tone (`#FBF6EF`): 6.23:1. Both comfortably clear the 4.5:1 AA threshold — the audit's 3.9:1 is stale/wrong, same failure class as the M2/M34/C30 findings Phase 0 already caught. No color-darkening fix applied (none needed); the size-selector tonal rework stands on its own design-consistency rationale, not a contrast one.

**New additive token:** `AppColors.skeletonBase`/`skeletonHighlight` (warm-toned counterparts to `Colors.grey[200]/[100]`) — the identical shimmer color-pair repeats verbatim in Home and ProductList, so this closes it once instead of twice, and gives the codebase one documented place recording "shimmer intentionally stays neutral, this isn't missed reskin debt."

**Guard:** 199 → 166 (−33; matches the edit count exactly: Home 8 + ProductList 8 + ProductDetail 11 + Cart 1 + CartItemEdit 2 + Checkout 3).

**Regression checklist:** NOT manually walked end-to-end in the emulator — no customer-role QA credentials available this session (same constraint noted in Phase 1; the cached emulator session is Admin, overwritten by my own Phase 1 smoke test). All changes this phase are either (a) mechanical `Colors.*`/`GoogleFonts.*` → token substitutions with the exact same values/behavior, or (b) the one tonal rework, which is a pure `BoxDecoration`/`TextStyle` color change with no touched `onTap`/state logic. `flutter analyze` + `flutter test` (43/43) both clean; no navigation, bloc-event, or conditional-logic lines were touched anywhere in this phase's diff.

**Verification:** `flutter analyze` clean; `flutter test` 43/43 pass; guard-scoped scan of this cluster's files returns zero non-allowlisted hits.
