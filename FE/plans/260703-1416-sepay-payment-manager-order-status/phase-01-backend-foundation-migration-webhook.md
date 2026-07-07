---
phase: 1
title: Backend Foundation (Migration + Webhook)
status: completed
priority: P1
dependencies: []
effort: 0.5d
---

# Phase 1: Backend Foundation (Migration + Webhook)

## Overview

Nền cho cả 2 mảng: migration DB (constraint `bank_transfer`, RLS insert payments, Realtime publication) + Edge Function `sepay-webhook` nhận webhook SePay. Mọi phase sau phụ thuộc phase này.

## Requirements

- Functional: insert `payment_method='bank_transfer'` hợp lệ; user tự insert được payments row của mình; webhook cập nhật payments+orders qua service_role; app subscribe được Realtime bảng payments.
- Non-functional: webhook trả lời <30s, idempotent (SePay retry), verify Apikey.

## Architecture

```
SePay → POST /functions/v1/sepay-webhook
  headers: Authorization: Apikey <SEPAY_WEBHOOK_KEY>
  body: {id, gateway, transactionDate, accountNumber, code, content, transferType, transferAmount, referenceCode, ...}
Function:
  1. transferType != 'in' → {"success":true} (bỏ qua tiền ra)
  2. verify Apikey header vs Deno.env SEPAY_WEBHOOK_KEY → sai: 401
  3. normalize(content) = uppercase + strip [^A-Z0-9]
  4. tìm order: select orders trong 7 ngày gần nhất (MỌI status — không lọc pending, nếu không nhánh idempotent/cancelled bên dưới không bao giờ chạy), so normalize(order_number) contains trong normalized content
  5. không match → log + {"success":true} (tránh SePay retry vô hạn)
  6. match — branch theo status TRONG handler, mọi update phải CONDITIONAL (atomic, chống race webhook vs manager-cancel vs double-delivery):
     - payments.status đã 'success' → idempotent, trả success luôn
     - amount so sánh numeric-safe: Number(transferAmount) < Number(orders.total) → chỉ ghi payments.gateway_response, KHÔNG confirm (thiếu tiền — recovery: manager confirm tay ở phase 3)
     - đủ tiền:
       `update payments set status='success', paid_at=now(), transaction_id=referenceCode, gateway_response=body where order_id=? and status='pending'` — check affected rows
       `update orders set status='confirmed' where id=? and status='pending'` — 0 rows (đơn đã cancelled/đổi) → KHÔNG lỗi, payments vẫn đã ghi để đối soát
     - KHÔNG dùng read-then-write cho status
  7. trả {"success":true}
```

Webhook dùng `SUPABASE_SERVICE_ROLE_KEY` (tự có trong Edge Function env) → bypass RLS.

## Related Code Files

- Create: `migrations/20260703_sepay_payment_foundation.sql` (lưu repo để teammate tái lập)
- Create: `supabase/functions/sepay-webhook/index.ts` (Deno, lưu repo + deploy qua MCP)
- Modify: `.env.example` — thêm `SEPAY_BANK=`, `SEPAY_ACC=` (FE build QR URL; KHÔNG đưa webhook key vào FE env)
- Modify: `FE/.env` local (user điền)

## Implementation Steps

1. Viết migration SQL:
   ```sql
   alter table public.orders drop constraint orders_payment_method_check;
   alter table public.orders add constraint orders_payment_method_check
     check (payment_method in ('cod','vnpay','momo','bank_transfer'));
   alter table public.payments drop constraint payments_method_check;
   alter table public.payments add constraint payments_method_check
     check (method in ('cod','vnpay','momo','bank_transfer'));
   -- user tạo payment row cho đơn của mình
   create policy "Users can insert own payments" on public.payments
     for insert with check (auth.uid() = user_id);
   -- chặn nhiều payments pending cho 1 order (checkout retry / createPayment retry)
   create unique index payments_one_pending_per_order
     on public.payments(order_id) where status = 'pending';
   -- realtime
   alter publication supabase_realtime add table public.payments;
   ```
   ⚠️ Xác nhận tên constraint thật bằng `execute_sql` (`select conname from pg_constraint where conrelid in ('public.orders'::regclass,'public.payments'::regclass)`) trước khi drop — schema.sql dùng inline check nên tên do PG sinh, kiểm CẢ HAI bảng.
   ⚠️ `alter publication ... add table` lỗi nếu bảng đã trong publication hoặc publication là FOR ALL TABLES → check trước bằng `select * from pg_publication_tables where pubname='supabase_realtime'`; đã có thì bỏ qua statement này.
2. Apply qua Supabase MCP `apply_migration` (project `agbnpqgxsppdrpbqoipo`); lưu file SQL vào `migrations/`.
3. Viết Edge Function `sepay-webhook/index.ts` theo Architecture trên; deploy qua MCP `deploy_edge_function` với `verify_jwt=false` (SePay không gửi JWT Supabase).
   ⚠️ VERIFY verify_jwt thực sự tắt: curl endpoint KHÔNG kèm header Supabase → phải nhận 401 từ CHÍNH code Apikey check (body của mình), không phải 401 JSON của gateway ("Missing authorization header"). Nếu MCP không hỗ trợ flag → fallback: dashboard toggle "Enforce JWT" hoặc `supabase functions deploy sepay-webhook --no-verify-jwt`.
4. Set secret `SEPAY_WEBHOOK_KEY` (sinh chuỗi random) — qua dashboard hoặc `supabase secrets set`; ghi vào checklist user.
5. Test bằng curl giả webhook payload: đúng key / sai key / content không match / đủ tiền / thiếu tiền / GỬI LẶP cùng payload (idempotent) / order đã cancelled (payments vẫn ghi, orders giữ cancelled) → verify từng case bằng `execute_sql`.
6. Cập nhật `.env.example`. Commit (`feat(payment): add sepay backend foundation`).

## User Setup Checklist (ngoài code)

- [ ] Tạo tài khoản sepay.vn, link tài khoản ngân hàng.
- [ ] SePay dashboard → Webhooks → thêm URL `https://agbnpqgxsppdrpbqoipo.supabase.co/functions/v1/sepay-webhook`, auth kiểu Apikey, key = `SEPAY_WEBHOOK_KEY` đã set.
- [ ] Điền `SEPAY_BANK` (tên bank theo qr.sepay.vn, vd `Vietcombank`), `SEPAY_ACC` (số TK) vào `FE/.env`.

## Success Criteria

- [ ] Insert `payment_method='bank_transfer'` không lỗi constraint.
- [ ] curl webhook đúng key + content chứa order_number → payments=success, orders=confirmed, notification row xuất hiện (trigger).
- [ ] curl sai key → 401; content không match → 200 success (không retry).
- [ ] Gửi lại cùng payload → không đổi gì (idempotent).
- [ ] ≥1 commit.

## Risk Assessment

- Tên constraint không đúng → migration fail: xác nhận trước bằng pg_constraint (step 1).
- Bank strip ký tự đặc biệt trong content → normalize 2 phía là bắt buộc; test với content có `CF-` bị strip thành `CF`.
- Edge Function verify_jwt mặc định true sẽ chặn SePay → phải deploy verify_jwt=false, tự verify Apikey trong code.
