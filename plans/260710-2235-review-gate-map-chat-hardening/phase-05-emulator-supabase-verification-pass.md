---
phase: 5
title: "Emulator & Supabase Verification Pass"
status: pending
priority: P1
dependencies: [1, 2, 3, 4, 6]
effort: "M"
---

# Phase 5: Emulator & Supabase Verification Pass

## Overview
Single live runbook (Android emulator/device + Supabase session) clearing (a) runtime checks of Phases 1–4 and (b) the entire pre-existing verification backlog (demo-fix-roadmap Phase 1 seed, stability-hardening smoke, post-audit spot-checks). No code changes expected; file bugs back into this plan if found.

## Requirements / Pre-steps (in order)
1. **Target = current hosted Supabase project** (Validation decision 3) — confirm project ref before pushing; hosted OTP 60s window applies to rate-limit checks.
2. **Drift inventory (red-team):** `supabase migration list` / `supabase db diff` against the target to reconcile: loose non-canonical `FE/migrations/` files (`20260703_sepay_payment_foundation.sql` — contains publication add — and `20260620_wishlist_items.sql`), `cancel_my_order` (live-only until Phase 2 step 0 repatriates), `FE/fix_rls_profiles_recursion.sql` hotfix. Record what's already applied before pushing anything.
3. Apply pending migrations (Phase 1 review-gate incl. `update_product_rating` SECURITY DEFINER fix, Phase 2 cancel RPC backfill, Phase 4 support chat, **Phase 6 `handle_new_user` full_name**).
4. **Emulator mock location configured** (extended controls) — required for coord-bearing checkout and map checks; seeded shipping order must carry coords (see A4).

## Runbook checklist

### A. DB / seed (from demo-fix-roadmap Phase 1 — closes that plan)
- [ ] ≥2 `role='customer'` profiles exist (seed via `FE/seed_demo_accounts_and_orders.sql` if needed).
- [ ] ≥1 confirmed-today + ≥1 delivered-today order with matching `order_items` + `payments` row; manager dashboard "Khách hàng" ≥2, revenue reflects delivered.
- [ ] Remove test-junk: orders `bae4dca4`, `4d9a08a3`, `edbc36eb`, 10k test prices — **confirm each row with user before delete**.
- [ ] Seed ≥1 `shipping` order whose `shipping_address` jsonb includes `latitude`/`longitude` (red-team: current seed SQL has none — map CTA would be undemonstrable) + delivered order items for review-gate checks.

### B. New features (Phases 1–4) — functional + adversarial
Review gate:
- [ ] REST INSERT review as non-purchaser → RLS rejects; as delivered-purchaser with own `order_item_id` → OK, `is_verified=true`, badge renders.
- [ ] REST INSERT review with **another customer's / mismatched `order_item_id`** → rejected.
- [ ] REST PATCH own review: `order_item_id`/`product_id` change → rejected (immutable); `is_verified=true` sent by client → overwritten server-side (row unchanged unless genuinely eligible).
- [ ] Resubmit (upsert UPDATE path) keeps badge verified.
- [ ] Product `avg_rating`/`review_count` update after customer review (rating trigger now SECURITY DEFINER).
- [ ] Delivered order → per-item Đánh giá CTA → editor → review visible on product page.

Cancel + defects:
- [ ] Confirmed order cancellable in UI; shipping/delivered not; `cancel_my_order` present in repo migrations (Phase 2 step 0 done).

Map:
- [ ] Shipping order with coords → map route shop→destination; **destination marker matches the order's address text** (not device GPS/fallback — red-team: a wrong route still "renders"); recenter in delivery mode does not re-anchor to device GPS; store-locator entry unchanged.

Support chat:
- [ ] Customer sends → manager inbox updates live (2 sessions); reply flows back; returning customer reopens chat without error; `last_message_at`+preview+unread bump per message; badge clears via mark-read.
- [ ] REST: customer B cannot SELECT A's conversation/messages; cannot INSERT message with A's `conversation_id`; cannot UPDATE/PATCH any message content; customer SELECT on `support_conversations` returns own row only.
- [ ] Realtime leak probe: customer B subscribed while A chats → zero events for A's conversation.

Email-password auth (Phase 6):
- [ ] Đăng ký new account (name+email+password) → lands `/home`, profile row has full_name; record hosted "Confirm email" behavior observed.
- [ ] Đăng nhập email+password OK; wrong password → Vietnamese error; manager account password login → `/manager`.
- [ ] Duplicate-email signup (incl. OTP-created account) → "user exists" message; OTP + Google flows unaffected.

### C. Legacy backlog (stability-hardening + post-audit + role-ops)
- [ ] Manager OTP login lands `/manager` on relaunch.
- [ ] Manager order status mutation live (confirm→shipping): sheet closes, list+detail refresh (reconciles phase-04 evidence vs plan checkbox contradiction in stability-hardening).
- [ ] Full customer purchase smoke: COD + bank-transfer pay-again.
- [ ] Manager product edit: color persists after reopen; create/edit product smoke post-modularization.
- [ ] Currency separators visible: home, product detail, cart, checkout summary, voucher list.
- [ ] Admin login + manager Danh mục/Khuyến mãi push → no "multiple heroes" in `flutter run` log.
- [ ] Manager dashboard stat cards: bold/dark values, amber pending, blue-info product count.
- [ ] OTP: paste works, backspace-to-prev, in-flight disable + spinner; resend countdown ticks 1×/s; email change resets cooldown; `a@` rejected; no setState-after-dispose in log.

### D. Wrap-up
- [ ] Tick all criteria + backfill: demo-fix-roadmap → `completed`; note stability-hardening/post-audit runtime items verified (link this runbook).
- [ ] `ck plan check` phases; update `docs/` only if user-visible behavior changed beyond plan scope.
- [ ] Refresh stale `CODEBASE.md` counts (47 screens/16 blocs/13 services + new chat surfaces) — small, do here.

## Related Code Files
- No planned code changes. Possible hotfixes get their own commits referencing findings.
- Update: `plans/260703-1750-bigstyle-demo-fix-roadmap/plan.md` status, this plan's checklists, `CODEBASE.md`.

## Success Criteria
- [ ] All checklist items A–D ticked or converted to tracked findings.
- [ ] demo-fix-roadmap flipped `completed`.
- [ ] Zero unexplained errors in `flutter run` log during pass.

## Risk Assessment
- Hosted-vs-local Supabase OTP limits may make rate-limit snackbar unreachable — document observed env behavior instead of forcing.
- Junk-row deletion is destructive → per-row user confirmation mandatory.
- Manual SQL applied during live debugging can desync migration state — record every manual statement; publication adds already guarded in Phase 4 migration.
