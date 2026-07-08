-- ============================================================
-- Migration: Thêm INSERT policy cho payments table
-- ============================================================

drop policy if exists "Users insert own payments" on public.payments;

create policy "Users insert own payments"
  on public.payments for insert
  with check (auth.uid() = user_id);
