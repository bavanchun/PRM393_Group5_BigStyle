---
title: "BigStyle Product Completeness Roadmap"
description: "PA1 verify-first roadmap turning BigStyle into a complete product: close device-pass verify debt, fix repo docs, add realtime badge + password reset, FCM push, customer refund flow, Manager/Admin UX polish."
status: in-progress
priority: P1
branch: "dev"
tags: [roadmap, verification, docs, notifications, fcm, refund, ux]
blockedBy: []
blocks: [260710-2235-review-gate-map-chat-hardening, 260703-1750-bigstyle-demo-fix-roadmap]
created: "2026-07-12T09:55:02.539Z"
createdBy: "ck:plan"
source: skill
---

# BigStyle Product Completeness Roadmap

## Overview

Execute user-approved brainstorm roadmap (PA1 Verify-first) from
`plans/reports/brainstorm-260712-1644-bigstyle-product-completeness-roadmap-report.md`.
Goal: app trọn vẹn như sản phẩm thật. Order: chốt baseline verify → hồ sơ repo →
quick product wins → FCM (nặng nhất) → refund flow → polish Manager/Admin.

Stack: Flutter (BLoC) + Supabase. Quality gate mỗi phase: `flutter analyze` 0,
`flutter test` xanh (≥104), hardcode-color guard 0.

## Phases

| Phase | Name | Status |
|-------|------|--------|
| 1 | [Device Pass Verification](./phase-01-device-pass-verification.md) | Blocked (needs user: sudo/emulator/device) |
| 2 | [Repo Documentation](./phase-02-repo-documentation.md) | Done |
| 3 | [Realtime Badge And Password Reset](./phase-03-realtime-badge-and-password-reset.md) | Code complete, reviewed — device e2e + Supabase Auth redirect-URL registration pending (Phase 1) |
| 4 | [FCM Push Notifications](./phase-04-fcm-push-notifications.md) | Pending |
| 5 | [Customer Refund Request](./phase-05-customer-refund-request.md) | Code complete, reviewed — device e2e pending (Phase 1) |
| 6 | [Manager Admin UX Polish](./phase-06-manager-admin-ux-polish.md) | Done — manual device walkthrough (plan's own gate step 7) deferred to Phase 1 |

## Dependencies

- Phase 1 executes the pending device-pass checklist of
  `plans/260710-2235-review-gate-map-chat-hardening/phase-05-emulator-supabase-verification-pass.md`
  (32 unchecked items). Completing it flips that plan `completed` and closes
  `plans/260703-1750-bigstyle-demo-fix-roadmap` (`partial`). Both are listed in
  `blocks` above; their frontmatter references this plan in `blockedBy`.
- Phase order is sequential (each phase gates the next); Phase 2 is the only
  one safe to run out-of-order if Phase 1 blocks on user availability.
- Phase 4 requires Phase 3 done (B1 badge logic shared with push display path).

## Acceptance Criteria (plan-level)

- 32/32 device-pass items pass; 2 legacy plans flipped completed → 17/17 plans done.
- README renders on GitHub; fresh clone runs app following it.
- Badge updates realtime; password reset end-to-end; push arrives when app backgrounded.
- Customer can request refund; manager approves → order `refunded` + notifications both ways.
- No Manager/Admin screen missing empty/error/loading state.

## Backlog (rejected this round, do not implement)

Address book (multi-address), recently-viewed/recommendations, dark mode.

## Open Questions

None — both resolved in Validation Session 1 (see Validation Log).

## Validation Log

### Session 1 — 2026-07-12

### Verification Results
- Claims checked: 14
- Verified: 12 | Failed: 2 | Unverified: 0
- Tier: Full (6 phases)
- Failures:
  1. Phase 4-5 wrote `supabase/functions|migrations/` at repo root — actual: `FE/supabase/functions/`, `FE/supabase/migrations/` (naming `YYYYMMDDHHMMSS_slug.sql`). Fixed after user confirmation.
  2. Phase 3 cited `support_chat_service.dart` as realtime channel reference — actual `.channel().onPostgresChanges` pattern lives in `FE/lib/services/payment_service.dart:73`. Fixed after user confirmation.

### Decisions
1. **Path corrections**: apply both fixes above → phases 3-5 updated.
2. **Deep link scheme**: custom scheme `bigstyle://` — nhóm không có domain, app mobile chạy local. Applies to Phase 3 (reset password) + Phase 4 (push tap routing).
3. **Firebase account**: Gmail cá nhân hoangbavan4478@gmail.com tạo project, mời thành viên nhóm làm editor (Phase 4).
4. **Refund window**: 7 ngày sau delivered — enforce bằng RLS time check + ẩn nút UI ngoài window (Phase 5).
5. **Foreground push policy**: background-only confirmed — foreground dựa badge realtime Phase 3 (Phase 4, no change).
6. **Phase 1 defect policy**: record-only — không fix inline; mọi defect dồn batch fix riêng sau khi chạy hết 32 mục (Phase 1 updated).

### Whole-Plan Consistency Sweep
- Swept plan.md + 6 phase files after propagation: paths `FE/supabase/...` consistent across phases 4-5; realtime reference updated in phase 3; `bigstyle://` consistent phases 3-4; defect policy consistent phase 1; refund window added phase 5.
- Unresolved contradictions: 0.
