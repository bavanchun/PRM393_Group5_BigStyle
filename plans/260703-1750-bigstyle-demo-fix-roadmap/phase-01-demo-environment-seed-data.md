---
phase: 1
title: "Demo Environment & Seed Data"
status: pending
priority: P1
dependencies: []
effort: "M"
---

# Phase 1: Demo Environment & Seed Data

## Overview

Build a clean, realistic testbed for the demo: a **dedicated manager account** (separate email), seeded **customer accounts + orders across statuses**, and cleanup of test junk. This foundation is required to validate Phase 4 (manager) properly and kills the "Doanh thu 0đ / Khách hàng 0" artifacts at their source (single flip-role account). Fixes audit X8; supports M6b/M7b diagnosis; addresses open question #5.

**Why first:** Phase 4 cannot verify M7b (orders tab) or M6b (revenue) without real seeded orders and a real manager account. Confirmed-order + delivered-order rows are the inputs those fixes are validated against.

## Requirements

- Functional: one `profiles` row with `role='manager'` reachable by a real OTP-capable email; ≥2 customer profiles; a spread of orders (`pending`, `confirmed`, `delivered` dated today) so dashboard revenue/pending/customer counts are non-zero and demonstrable.
- Non-functional: no destructive deletion of real data without confirmation; seed SQL idempotent where feasible; keep secrets out of committed SQL.

## Architecture

Role is resolved from `profiles.role` at splash/login (`auth_service.dart:16-17` → `user_model.dart:12,46-48`; splash `splash_screen.dart:30-33`, login `login_screen.dart:54-57`). `role='manager'` → `/manager`. Signup auto-creates a `profiles` row via DB trigger (`FE/schema.sql:30`, default `role='customer'`). So the manager account = normal signup, then promote via SQL `update`.

Current gap: `FE/seed_data.sql` (417 lines) seeds categories/products/variants but **zero accounts** (its "2 test profiles" comment is stale — no `insert into public.profiles`). Orders reference IDs that may not exist for a fresh account.

## Related Code Files

- Reference (read): `FE/schema.sql` (profiles table + trigger + `is_manager()` L41-53), `FE/seed_data.sql` (existing seeds), `FE/lib/services/auth_service.dart:16-17`, `FE/lib/models/user_model.dart:12,46-48`.
- Create: `FE/seed_demo_accounts_and_orders.sql` — new idempotent seed script (accounts promotion note + customer/order rows). Kebab/snake per SQL convention.
- Modify: none in app code for this phase.

## Implementation Steps

1. **Dedicated manager account (USER ACTION — email OTP required):**
   - User signs up in-app (or via Supabase Auth) with a real manager email (e.g. `manager+bigstyle@<user-domain>`), completes OTP.
   - Promote: `update public.profiles set role='manager' where id = (select id from auth.users where email = '<manager-email>');`
   - Verify: relaunch → lands on `/manager`.
2. **Seed customer accounts:** either 2 real signups (OTP) OR document that dashboard "customers" counts `role='customer'` profiles (`manager_dashboard_stats.dart:46`) so ≥2 customer rows make the count realistic.
3. **Seed orders across statuses (SQL):** insert orders for a seeded customer with `status` in {`pending`, `confirmed`, `delivered`} and `created_at = now()` for at least one `delivered` + one `confirmed` today. Include matching `order_items` + a `payments` row so manager order detail renders. Use real product/variant IDs from `seed_data.sql`.
   - NOTE: today-revenue currently only counts `delivered` (see Phase 4 / M6b). Seed **both** a `delivered`-today (proves revenue after M6b fix and even before) and a `confirmed`-today (proves the M6b fix specifically).
4. **Clean test junk (X8):** identify + remove/soft-hide leftover test orders (`bae4dca4` pending 380k, `4d9a08a3`, `edbc36eb`), test prices (10k), so demo data looks intentional. Confirm each row with the user before deleting (do not delete data you did not create).
5. Write all DDL/DML into `FE/seed_demo_accounts_and_orders.sql` with comments; user runs it via Supabase → SQL Editor (anon key cannot run DDL — same constraint as the prior wishlist migration).

## Success Criteria

- [ ] Dedicated manager email logs in and lands on `/manager`.
- [ ] Manager dashboard "Khách hàng" ≥ 2 (not 0).
- [ ] ≥1 `confirmed`-today and ≥1 `delivered`-today order exist for a seeded customer, each with `order_items` + `payments`.
- [ ] Test-junk orders/prices removed or clearly not in the demo path.
- [ ] `FE/seed_demo_accounts_and_orders.sql` committed (no secrets).

## Risk Assessment

- **User-action dependency:** account creation needs email OTP the agent cannot perform; SQL DDL/DML needs the user's Supabase console. This phase is partly manual — plan for a handoff, not full automation.
- **RLS:** seeded inserts must satisfy RLS or run as service role in SQL Editor (bypasses RLS) — prefer SQL Editor. Verify `is_manager()`/owner policies (X1) don't block the demo customer from seeing their own seeded orders.
- **Data safety:** deleting "test" orders risks removing something real — confirm each deletion with the user.
