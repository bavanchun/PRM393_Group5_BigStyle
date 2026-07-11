---
phase: 9
title: "Verification harness native and zero-row"
status: pending
effort: ""
---

# Phase 9: Verification harness native and zero-row

> ⚠️ **RED-TEAM OVERRIDE (RT-12).** This is verification (produces a report, not code) AND is hard-blocked on user-run `sudo modprobe kvm_amd`. It is kept in-plan per the "A→E together" choice but is **NON-BLOCKING**: the plan is considered complete at Phases 01+03+04+06+07+08. Run 09 as a separate KVM-gated track after those merge; it may spawn its own fix plans. Do not let it hold plan closure hostage.

## Overview
Group E: the parts the 2026-07-11 test pass could NOT cover — 5 zero-row features (reviews, wishlist, chat, support conversations/messages) never exercised e2e, and native flows (Google Maps, geolocator, image-picker, Google sign-in, SePay QR realtime) that Flutter web can't run. Verify on a real Android emulator.

## Requirements
- Functional: each of reviews / wishlist / chat / support has ≥1 real e2e row created through the UI; each native flow demonstrated working (or a defect logged).
- Non-functional: this is verification, not feature work — it produces a report, not code (unless a defect requires a fix, which spins its own phase/plan).

## Architecture
**HARD DEPENDENCY:** `/dev/kvm` is absent; the emulator needs `sudo modprobe kvm_amd` (interactive sudo — must be run by the user once; persist via `/etc/modules-load.d/kvm.conf`, add user to `kvm` group). Until then this phase is blocked. AVD `flutter_phone` exists. Build with the test dart-defines (BIGSTYLE_TEST_MANAGER/CUSTOMER_* already known: password `BigStyleTest2026!` on +manager/+customer2; +admin set too) so debug-login works; drive UI via `adb shell input` + `screencap`, verify DB rows via Supabase MCP.

## Related Code Files
- No code changes expected (verification). Test accounts: `hoangbavan4478+{customer2,manager,admin}@gmail.com` / `BigStyleTest2026!`.
- Output: a QA verification report in `plans/reports/`.

## Implementation Steps
1. **Prereq (user):** `sudo modprobe kvm_amd` → confirm `/dev/kvm` exists.
2. Boot `flutter_phone`; `flutter run` on it with the 4 `BIGSTYLE_TEST_*` dart-defines.
3. Customer role: create a **review** (needs a delivered order — seed one first), add/remove **wishlist** item, send an **AI chat** message, open **support chat** + send a message. Verify each writes a row via Supabase MCP (`reviews`, `wishlist_items`, `chat_messages`, `support_conversations`/`support_messages`).
4. Manager role: reply in **support inbox** (verify 2-way), verify realtime.
5. Native: **delivery map** (route/polyline/fee), **geolocator** (checkout "lấy vị trí"), **image-picker** (edit-profile avatar → avatars bucket), **Google sign-in**, **SePay QR** bank-transfer realtime payment watch.
6. Admin role: dashboard/users/categories (couldn't test on web — no admin debug button) via adb text login.
7. Log every result; file defects as new findings (own fix plan if needed).

## Success Criteria
- [ ] `/dev/kvm` present; emulator boots; app runs with debug-login.
- [ ] reviews/wishlist/chat/support each have ≥1 real row created via UI.
- [ ] All 5 native flows demonstrated (pass or defect logged).
- [ ] Admin role screens verified.
- [ ] Verification report written to `plans/reports/`.

## Risk Assessment
- Blocked on user-run sudo (KVM) — cannot proceed otherwise; keep Phases 1–8 independent. Software-mode emulator (no KVM) is too slow to be viable. Creating a delivered order for review-eligibility may need a seed step. Native flows depend on valid Google Maps / Google OAuth / SePay keys in env (Maps native key present; SePay set; verify Directions REST optional).
