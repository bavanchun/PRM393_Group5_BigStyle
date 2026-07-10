---
phase: 2
title: "Visual Capture 3 Roles + Guest"
status: completed
effort: "M-L (1-2 days, user-assisted; 3 role sessions + guest)"
priority: P1
dependencies: [1]
---

# Phase 2: Visual Capture 3 Roles + Guest

## Overview

Capture fresh screenshots of every screen from the Phase 1 inventory, per role (customer, manager, admin) plus guest, on the Android emulator. These images are the raw material Phase 4 grades with vision analysis. Fresh capture is mandatory — `docs/audit-assets/` images from 2026-07-03 predate several fix plans and no longer match the code.

**Session model (corrected by red team):** the app holds ONE session, routed by role at splash (`splash_screen.dart:58-62`); there is no in-app role flip. Switching role = sign-out + sign-in. Structure this phase as **3 sequential per-role capture sessions + guest last**, each with an explicit login checkpoint.

## Requirements

- Functional: ≥1 screenshot per inventoried screen per owning role; key alternate states (loading/empty/error/filled) where reachable without code changes.
- Non-functional: consistent device frame — **one AVD for the entire set** (same resolution/density/font scale), portrait; every capture command uses `adb -s <serial>` explicitly; images stay local/gitignored; **PII policy from plan.md applies to every frame and to the capture log**.

## Entry Gates (verified in Phase 1 — do not start capture without them)

- Emulator running (`emulator-5554`-class AVD, Android 15 as in prior audit); serial recorded.
- **Manager + admin logins proven working on the capture AVD** (Phase 1 exit criterion — NOT assumed from demo-fix roadmap, whose Phase 1 is still in-progress with "manager OTP login not done"; seed SQL cannot create auth users: `FE/seed_demo_accounts_and_orders.sql:6-9`).
- Capture build = **debug build with test-login dart-defines**: `--dart-define TEST_MANAGER_EMAIL/TEST_MANAGER_PASSWORD/TEST_CUSTOMER_EMAIL/TEST_CUSTOMER_PASSWORD` enable one-tap password sign-in (`login_screen.dart:21-31,374-427` → `auth_service.dart:61`), making customer↔manager switches OTP-free. **Admin has no test button** — admin session is OTP-bound: schedule admin as a single uninterrupted session and budget its OTP send.
- **OTP budget:** Supabase email OTP is rate-limited. Plan sends: 1 admin login + 1 guest OTP-screen capture (+ reserve). Do not burn sends on avoidable re-logins.
<!-- Updated: Validation Session 1 - demo customer is THE capture account for customer role -->
- **Customer capture account = seeded demo customer** (validated decision): all customer-role screens shot from the demo account with fake "Khách Demo" data — the real customer session is NOT used for capture. Point `TEST_CUSTOMER_EMAIL/PASSWORD` dart-defines at the demo account. `needs-redaction` tagging remains only as an exception safety net if real data appears in any frame.

## Implementation Steps

0. **Pin the tree:** record `git rev-parse HEAD` + date in the capture log. <!-- Updated: Validation Session 1 - no freeze possible on team repo --> No dev freeze (team repo, validated): before starting Phase 4 and again before Phase 5, diff current `dev` against the pinned SHA and re-shoot only screens whose files changed (delta-recapture rule) — this is the sole staleness defense.
1. Derive capture checklist from `reports/phase-01-ui-inventory-debt-map.md` (screen × role × states). Delivery-map is captured inside the **customer** session (it is a customer-profile screen, `profile_screen.dart:128`).
2. Naming + storage: `docs/audit-assets/overhaul/{role}/{NN}-{screen}-{state}.png`. Re-verify `docs/audit-assets/` is gitignored (`.gitignore:6`). Never `git add -f`.
3. Capture sessions in order: **customer → manager → admin → guest last**. Per session: login checkpoint (dart-define button; admin via OTP) → navigate → settle → `adb -s <serial> exec-out screencap -p > {path}`. Batch with a small shell script if repetitive.
4. Guest (splash/login/OTP screens) is the FINAL action: only after 100% of authenticated captures are ticked, sign out (or `adb shell pm clear` — equivalent to logout, acceptable only at this point). No second AVD (violates same-frame requirement).
5. Tick each checklist row; note screens that were unreachable and why. **Capture log refers to accounts by role alias only** (`customer-A`, `manager`, `admin`) — no emails, no OTP codes.
6. Write capture log: `reports/phase-02-visual-capture-log.md` (pinned SHA, AVD serial/config, checklist with coverage %, unreachable list, `needs-redaction` list).

## Success Criteria

- [x] 87% (26/30) of Phase 1 screens captured; the other 4 explicitly logged unreachable-with-reason (Splash: instant-route when session cached; Checkout/PaymentQr: flaky cart-CTA tap target; ManagerCreateProduct: FAB swallowed by underlying list item).
- [x] Customer, manager, admin, and guest all covered; guest (Login) captured last; **0 OTP sends** consumed (better than planned — debug password login used for all 3 authenticated roles, see capture log's Method Deviation section).
- [x] Single AVD (`emulator-5554`, 1080x2400@420dpi), consistent config across the whole set; every command used `adb -s`.
- [x] Capture log written with pinned `git rev-parse HEAD` (`6e77ccf`); assets under `docs/audit-assets/overhaul/`, not committed; log contains no emails/PII.
- [x] Every PII-bearing frame is from the demo/QA account by design; 0 `needs-redaction` cases.

See [phase-02 capture log](./reports/phase-02-visual-capture-log.md) for full data and findings surfaced during capture.

## Risk Assessment

- **OTP rate-limit / inbox unavailability (biggest, fires per role switch without dart-defines)** → debug build with test logins removes customer/manager OTP dependency; admin scheduled as one uninterrupted session; guest last.
- **Mid-pipeline dev drift** (no freeze available) → pinned SHA + mandatory delta-recapture check before Phase 4 and Phase 5 (step 0).
- **Manager/admin data emptiness** → apply seed SQL first (user runs prerequisite steps in `FE/seed_demo_accounts_and_orders.sql`); empty states are themselves capture targets, not failures.
- **Emulator unavailable** → phase blocks; do NOT substitute stale 03/07 images for grading.
