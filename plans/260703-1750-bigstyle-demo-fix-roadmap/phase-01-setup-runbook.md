# Phase 1 — Demo Environment Setup Runbook

Operational companion to `phase-01-demo-environment-seed-data.md`. Steps YOU run
(email OTP + Supabase SQL Editor can't be automated by the agent). SQL lives in
`FE/seed_demo_accounts_and_orders.sql`.

## 0. Create accounts in the app (OTP)

Sign up **3 emails** via the app login screen — each needs a real inbox for the
OTP code:

| Purpose | Example email | Notes |
|---------|---------------|-------|
| Manager | `manager+bigstyle@<you>` | promoted to manager in Step 1 |
| Customer 1 | `customer1+bigstyle@<you>` | gets seeded orders in Step 2 |
| Customer 2 | `customer2+bigstyle@<you>` | makes dashboard "Khách hàng" ≥ 2 |

Gmail trick: `youraddress+manager@gmail.com` all land in `youraddress@gmail.com`.

After signup each is `role='customer'` by default (DB trigger).

## 1. Promote the manager

In Supabase → SQL Editor, run **STEP 1** of the seed file with the manager email:

```sql
update public.profiles set role='manager'
where email = 'manager+bigstyle@<you>';
```

Relaunch the app logged in as that email → should land on `/manager`.

## 2. Seed demo orders

Edit `v_customer_email` in **STEP 2** of the seed file to Customer 1's email, run
it. Seeds 3 orders dated today:
- **confirmed** + bank_transfer (paid) — shows as revenue after the Phase 4 M6b fix
- **delivered** + cod (paid) — shows as revenue even before the fix
- **pending** + bank_transfer (unpaid) — for the "Thanh toán lại" demo + manager
  pending-order workflow

## 3. Verify

```sql
select email, role from public.profiles order by role;          -- 1 manager, 2 customers
select order_number, status, payment_method, total, created_at  -- 3 today orders
  from public.orders order by created_at desc limit 5;
```

On the manager dashboard you should see: Khách hàng ≥ 2, at least 1 pending order,
and (after Phase 4) non-zero "Doanh thu hôm nay".

## 4. (Optional) Clean test junk before a real demo

**STEP 3** of the seed file. Review the SELECT output first; delete only orders
you recognise as test data (by explicit UUID). Deleting an order cascades to its
items + payments.

## Notes / gotchas

- SQL Editor runs as service role → bypasses RLS, so seeded inserts aren't blocked
  by the owner/manager policies (X1).
- `payment_method='bank_transfer'` is valid (added by `20260703_sepay_payment_foundation.sql`);
  the base `schema.sql` is out of date on that constraint.
- Revenue-counting statuses agreed for Phase 4: **confirmed, processing, shipping,
  delivered** (accepted orders). Pending/cancelled/refunded excluded.
- Shipping fee seeded at `30000` to match the Phase 5 flat-fee value; change both
  together if you pick a different number.

## Unresolved

1. Confirm the 3 signup emails you'll use (so the SQL placeholders can be filled).
2. Which leftover test orders (if any) to purge in Step 4 — needs your eyes on the
   live data.
