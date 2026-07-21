# Brainstorm Report — Remaining Issues, Flow Completeness, Next Updates

**Date:** 2026-07-10 22:35 | **Branch:** `dev` (== `main` @ `60560a5`) | **Mode:** markdown only (no --html/--wiki)
**Inputs:** `pm-260710-2205-app-current-state.md` + 3 parallel codebase/plan audits + direct schema verification.

## TL;DR
Code-side app is genuinely healthy: payment (SePay VietQR + Realtime) is real, chat has real Claude API path, routing clean, all CRUD flows complete. Remaining work splits into: **(1) small real code bugs** (6 items, mostly low/medium), **(2) flow gaps** (review ungated — confirmed exploitable at DB level; manager-chat absent; delivery map not order-linked), **(3) verification backlog** (emulator + DB seed — no code), **(4) new-update candidates**.

## 1. Real code defects still present (verified in current code)

| # | Sev | Issue | Location |
|---|-----|-------|----------|
| D1 | Med | Admin profile menu: "Hồ sơ", "Cài đặt", "Trợ giúp" have empty `onTap: () {}` — dead buttons | `FE/lib/screens/admin/admin_shell.dart:169,174,179` |
| D2 | Med | `_onMarkRead` swallows all errors (`catch (_) {}`) — mark-read silently fails | `FE/lib/blocs/notification/notification_bloc.dart:46` |
| D3 | Med | `_onLoadCategories` swallows errors — category filter silently empty on backend error | `FE/lib/blocs/product/product_bloc.dart:77` |
| D4 | Low | `MockLoginEvent` handler = dead code + latent auth-bypass surface (not dispatched anywhere) | `FE/lib/blocs/auth/auth_bloc.dart:120` |
| D5 | Low | Hardcoded `via.placeholder.com/150` fallback images (external dependency in product UI) | `manager_product_detail_screen.dart:219`, `manager_product_list_screen.dart:415` |
| D6 | Low | Manager product-list hardcodes "Quản trị BigStyle"/"Quản trị" badge regardless of role | `manager_product_list_screen.dart:49,67` |

Cosmetic (unscoped, from QA audit): admin-gradient vs manager-plain AppBar inconsistency (design decision needed); admin profile email wraps awkwardly.

## 2. Flow completeness (traced screens↔blocs↔services)

| Flow | Verdict |
|---|---|
| Customer browse→detail→cart→checkout→pay(QR/COD)→track | ✅ COMPLETE, robust (server-authoritative RPCs `create_order`, `validate_voucher`) |
| Auth (OTP, Google, role redirect, profile+avatar) | ✅ COMPLETE |
| Manager dashboard/product/category/voucher/order-status | ✅ COMPLETE (state machine enforced) |
| Admin (users+invite via Edge Fn, categories, platform stats) | ✅ COMPLETE |
| Notifications | ✅ FE complete (creation = BE triggers) |
| **Review after delivery** | ⚠️ **PARTIAL — real hole.** No purchase/delivered gate in FE (`review_service.dart`) **and confirmed none in DB**: `schema.sql:390` insert policy only `auth.uid() = user_id`. Any logged-in user can review any product. Also no "review" CTA from delivered order → flow disconnect. `isVerified` display-only. |
| **Order cancel** | ⚠️ UI narrower than backend: UI cancels only `pending`; `cancel_my_order` RPC allows `pending`+`confirmed` |
| **Manager↔customer chat** | ❌ ABSENT — chat = customer↔AI bot only, no manager inbox |
| **Delivery map** | ⚠️ Standalone store-locator demo (hardcoded shop coords), not linked to order shipping address |

## 3. Verification backlog (no code — needs emulator + Supabase session)
- Manager OTP login lands `/manager`; manager order status-mutation confirming pass (phase-04 evidence vs plan checkbox contradiction).
- Stability-hardening Phase 5/6 manual smoke (COD + pay-again, product-edit color persistence).
- Post-audit spot-checks: currency separators, Hero log, dashboard tokens, OTP paste/backspace, resend countdown 1×/s.
- DB seed: ≥2 customers, ≥1 confirmed-today + ≥1 delivered-today order with items+payments; remove test-junk orders (`bae4dca4`, `4d9a08a3`, `edbc36eb`, 10k prices — confirm each before delete).

## 4. Deliberately deferred (documented, don't re-litigate without new evidence)
`AuthBloc` concurrent transformer (droppable() = separate-plan candidate); OTP cooldown client-courtesy; `shouldCreateUser` auto-create; `createOrder` tx integrity (C46); create/edit product screen dup (M34); client role-guard (M38, RLS protects); error-vs-empty standardization (X5); notification navigation (C37–C39).

## 5. New-update candidates (evaluated)

| Idea | Value | Effort | Note |
|---|---|---|---|
| **A. Review gating + CTA from delivered order** | High (fixes real hole + closes loop) | S-M | RLS `exists(delivered order_item)` + FE gate + "Đánh giá" button on delivered order detail |
| **B. Cancel on `confirmed` in UI** | Med | XS | RPC already allows; one condition change + confirm dialog |
| **C. Link delivery map to order** (route shop→shipping address on shipping-status order) | Med-High demo-wow | M | Needs geocode of order address; map infra already exists |
| **D. Fix D1–D6 defect batch** | Med (polish) | S | Mostly small edits |
| **E. Manager↔customer human chat** | Low for course demo | L | New table + realtime + 2 UIs; AI bot already covers support story — YAGNI unless spec requires |
| **F. AuthBloc droppable() hardening** | Low-Med | XS-S | Known-limitation cleanup |
| **G. Refresh stale CODEBASE.md** | Low | XS | Says 14 screens/7 services vs actual 47/13 |

**Recommendation (brutal-honest):** skip E (over-engineering for a course demo). Highest ROI order: **A + B + D** (one fix-batch plan, all code-verifiable), then **runtime/DB verification pass** (§3, clears 14-plan portfolio), C optional if demo needs wow-factor.

## Unresolved questions
1. Supabase env for demo (hosted 60s OTP vs local-dev limits) — affects Phase-5 verification reachability.
2. AppBar gradient (admin) vs plain (manager): intentional design or unify?
3. Does course spec require human manager↔customer chat, or is AI bot sufficient?
