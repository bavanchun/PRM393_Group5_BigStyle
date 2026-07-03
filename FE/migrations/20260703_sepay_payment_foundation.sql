-- SePay payment foundation
-- Applied to Supabase project bigstyle-prm393 (agbnpqgxsppdrpbqoipo) 2026-07-03.
-- Cho phép phương thức bank_transfer (SePay VietQR) + user tự tạo payment + realtime.

-- 1. Cho phép 'bank_transfer' trên orders.payment_method + payments.method
alter table public.orders drop constraint orders_payment_method_check;
alter table public.orders add constraint orders_payment_method_check
  check (payment_method in ('cod','vnpay','momo','bank_transfer'));

alter table public.payments drop constraint payments_method_check;
alter table public.payments add constraint payments_method_check
  check (method in ('cod','vnpay','momo','bank_transfer'));

-- 2. User tự tạo payment row cho đơn của mình (checkout)
create policy "Users can insert own payments" on public.payments
  for insert with check (auth.uid() = user_id);

-- 3. Chặn nhiều payments pending cho 1 order (checkout/createPayment retry)
create unique index payments_one_pending_per_order
  on public.payments(order_id) where status = 'pending';

-- 4. Bật Realtime cho payments (app subscribe trạng thái thanh toán)
alter publication supabase_realtime add table public.payments;
