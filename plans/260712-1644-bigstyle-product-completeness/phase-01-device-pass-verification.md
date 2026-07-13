---
phase: 1
title: "Device Pass Verification"
status: pending
effort: "medium"
---

# Phase 1: Device Pass Verification

## Overview

Execute the 32 unchecked device-pass items from
`plans/260710-2235-review-gate-map-chat-hardening/phase-05-emulator-supabase-verification-pass.md`.
No new code — verify what's built works end-to-end on emulator + live Supabase.
Requires user present: sudo for KVM, confirm each test-junk row deletion.

## Requirements

- Functional: all 32 checklist items pass or get a documented defect.
- Non-functional: no destructive DB action without per-row user confirmation.

## Related Code Files

- Modify (checkboxes only): `plans/260710-2235-review-gate-map-chat-hardening/phase-05-emulator-supabase-verification-pass.md`
- Modify (frontmatter): `plans/260710-2235-review-gate-map-chat-hardening/plan.md`, `plans/260703-1750-bigstyle-demo-fix-roadmap/plan.md`
- No app source changes expected; defects found → separate fix items, not inline hacks.

## Implementation Steps

1. `sudo modprobe kvm_amd` (known blocker), launch Android emulator (Google Play image), `flutter run` from `FE/`.
2. Seed/cleanup pass (user confirms each deletion): ≥2 customer profiles, orders confirmed/delivered today, delete test-junk rows, seed shipping order with lat/lng.
3. Review-gate probes: REST insert/patch as non-purchaser, forged `order_item_id`, `is_verified` spoof, `avg_rating` trigger correctness.
4. Map: route shop→order coords, recenter without re-anchoring GPS.
5. Human chat: 2-way realtime, unread badge, RLS/realtime leak probes.
6. Auth: password sign-up/sign-in, duplicate-email, manager redirect.
7. Smoke: full purchase COD + bank transfer, manager product edit, currency separators, hero-tag log clean, dashboard stat cards.
8. Tick items in the source phase file as they pass; log any failure as defect note at file bottom. <!-- Updated: Validation Session 1 - record-only policy --> Defect policy (user-confirmed): record-only — KHÔNG fix inline trong Phase 1; mọi defect dồn thành batch fix riêng sau khi chạy hết 32 mục.
9. All pass → `cd plans/260710-2235-review-gate-map-chat-hardening && ck plan check 5`; flip that plan + demo-fix-roadmap frontmatter to `completed` (sync-back guard: sweep all their phase files first).

## Success Criteria

- [ ] 32/32 items ticked in source checklist (or defects filed)
- [ ] `260710-2235-review-gate-map-chat-hardening` status `completed`
- [ ] `260703-1750-bigstyle-demo-fix-roadmap` status `completed`
- [ ] `flutter analyze` 0, `flutter test` xanh (baseline unchanged)

## Risk Assessment

- Emulator/KVM unavailable → fallback real device via USB debugging.
- Probe reveals real defect → record-only (user-confirmed): file defect, continue checklist; batch fix after Phase 1 completes, before Phase 3 code work.

## Execution Log

### 2026-07-12 — attempt 1 (autonomous session): BLOCKED on user availability

- Preflight: `kvm` module loaded but `kvm_amd` NOT loaded → `/dev/kvm` missing; fix needs `sudo modprobe kvm_amd` (user password). AVD `flutter_phone` exists; adb/emulator/flutter toolchain OK.
- Beyond KVM, the checklist itself needs a human: per-row junk-delete confirmations, 2-session realtime chat, emulator mock-location driving, Supabase dashboard "Confirm email" toggle (dashboard access), visual UI checks.
- Source runbook's own 2026-07-11 log already classifies the 32 remaining items "Deferred — needs device/human (NOT automatable headless)". No re-attempt made headless.
- Per plan dependency note, Phase 2 (repo documentation) executed out-of-order instead; Phases 3–6 remain gated on this phase.
- Next session with user present: `sudo modprobe kvm_amd` → `emulator -avd flutter_phone` → `cd FE && flutter run` → walk section A–D of `plans/260710-2235-review-gate-map-chat-hardening/phase-05-emulator-supabase-verification-pass.md`.
