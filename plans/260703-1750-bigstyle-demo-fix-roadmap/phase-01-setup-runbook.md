# Phase 1 — Demo Environment Setup Runbook

Status: **DONE via Supabase MCP** on 2026-07-03 (project `bigstyle-prm393`
/ `agbnpqgxsppdrpbqoipo`). Accounts + demo data seeded directly. `FE/seed_demo_accounts_and_orders.sql`
is kept as a reproducible reference for a fresh environment.

## What was done automatically

- **Dedicated manager account** created: `hoangbavan4478+manager@gmail.com`
  (`role=manager`, email identity, pre-confirmed). Gmail `+alias` → OTP lands in
  your normal `hoangbavan4478@gmail.com` inbox.
- **2nd customer** created: `hoangbavan4478+customer2@gmail.com` (so "Khách hàng"
  = 2) with 2 seeded orders (1 delivered/cod, 1 confirmed/bank_transfer), each
  with order_items + payment rows.
- Your original account `hoangbavan4478@gmail.com` (customer) + its 3 existing
  orders are untouched — they now serve as demo data.

## Resulting dashboard state (after the Phase 4 revenue fix)

| Metric | Value |
|--------|-------|
| Doanh thu hôm nay | 481.000đ (3 confirmed + 1 delivered; pending excluded) |
| Đơn chờ xác nhận | 1 (CF-20260703-534921, 380k, bank_transfer) |
| Tổng đơn | 5 |
| Khách hàng | 2 |

## The ONE step left for you

Log into the app once as the manager to verify the manager UI:

1. App → login → enter `hoangbavan4478+manager@gmail.com` → "Gửi mã OTP".
2. Open your Gmail (`hoangbavan4478@gmail.com`) — the OTP arrives there via the
   `+manager` alias. Enter it.
3. App should land on `/manager` with the dashboard numbers above.

Your customer-side demo still uses `hoangbavan4478@gmail.com` (no role flipping).

## Notes / gotchas

- Auth users were inserted directly (auth.users + auth.identities, pre-confirmed,
  passwordless/OTP). Login is OTP-only — no password needed.
- `payment_method='bank_transfer'` is valid (SePay migration).
- Revenue-counting statuses (Phase 4): confirmed, processing, shipping, delivered.
- Seeded shipping fee = 30.000đ (matches the Phase 5 flat fee).

## Unresolved

1. Manager OTP login not yet performed (needs your Gmail + a device) — the only
   remaining action to fully close Phase 1.
2. Emulator runtime verification of all phases still pending.
