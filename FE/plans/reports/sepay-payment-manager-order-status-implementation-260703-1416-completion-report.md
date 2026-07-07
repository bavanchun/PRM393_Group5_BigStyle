# Completion Report — SePay Payment + Manager Order Status

- Date: 2026-07-03 · Branch: dev · Plan: `plans/260703-1416-sepay-payment-manager-order-status`
- Mode: `/ck:cook --parallel`. Phase 1 sequential (backend), Phase 2 ∥ Phase 3 (2 agent song song), Phase 4 verify.

## Delivered

| Commit | Nội dung |
|---|---|
| `8c040c1` | Backend: migration (bank_transfer constraints, payments insert RLS, unique pending index, realtime) + Edge Function `sepay-webhook` |
| `0769094` | Payment FE: checkout selector COD\|bank_transfer, PaymentService/Bloc, màn QR |
| `c731beb` | Manager FE: nextStatuses helper, update sheet, manager order detail screen |

Migration applied to Supabase `agbnpqgxsppdrpbqoipo`. Edge Function `sepay-webhook` deployed (verify_jwt=false, version 1, ACTIVE).

## Verification

- `flutter analyze`: 40 issues (tất cả pre-existing ở file không liên quan), **0 mới** ở file đụng tới.
- **DB-level webhook sim** (execute_sql, test data đã cleanup):
  - Full payment: order pending → confirmed, payment → success, **trigger tạo notification** "Cập nhật đơn hàng ..." ✓
  - Idempotency: chạy lại → notif vẫn 1 (conditional update hit 0 rows) ✓
  - Race (manager cancel rồi webhook đến): order giữ `cancelled` ✓
- **Webhook auth (HTTP curl)**: no-auth + wrong-key → 401 từ code (verify_jwt thật sự tắt) ✓
- **HTTP E2E success-path (LIVE, secret đã set)**: curl webhook Apikey đúng + content `"CT DEN:CF-20260703-HTTPX1..."` → normalize khớp order_number → order `confirmed`, payment `success`, `paid_at` set, `transaction_id`=referenceCode, gateway_response lưu full body, notification tạo bởi trigger; gửi lặp → idempotent (notif vẫn 1). Test data cleaned. ✓
- **RLS confirm** (DB thật): payments SELECT buyer ("Users see own payments") + manager ("Managers manage all payments" ALL) + INSERT (auth.uid()=user_id); orders insert không chặn bank_transfer. → buyer watch + manager panel hoạt động ✓
- **Code review**: cả 6 red-team fix verified đúng trong code, 0 BLOCKER.

## Red-team (12) + code-review — trạng thái

- 12 red-team findings: đã vá vào plan trước khi code, agent implement đủ; code-review xác nhận 6 fix trọng yếu landed đúng.
- MAJOR-verify (payments SELECT RLS): **đã thoả** — policies có sẵn trong schema (không phải thiếu).

## Known issues (MINOR, không fix — YAGNI cho scope đồ án)

1. Order creation không transactional (order + N order_items rời) — pattern pre-existing; fail giữa chừng để lại order mồ côi.
2. `awaitingPayment` giữ trong state → nếu sau này màn checkout dispatch `CheckoutCalculateShipping` (hiện KHÔNG) có thể re-nav; không reachable hiện tại.
3. Cart badge stale sau clear (CartBloc khác instance) — pre-existing cả COD.
4. `createPayment` comment nói "idempotent" — thực chất unique index chặn trùng bằng throw.
5. Migration không re-runnable (drop constraint không IF EXISTS) — one-shot, đã apply.

## Đã tự setup giúp user (qua Management API + SePay API)

- [x] Set secret `SEPAY_WEBHOOK_KEY` trong Supabase (Management API POST /secrets, HTTP 201).
- [x] `SEPAY_BANK=TPBank` / `SEPAY_ACC=03010216099` vào `FE/.env` (lấy từ SePay bankaccounts API).
- [x] HTTP E2E success-path verified live.

## Còn lại (chỉ user làm được)

- [ ] **Đăng ký webhook trong SePay dashboard** (Cấu hình → Webhooks): URL `https://agbnpqgxsppdrpbqoipo.supabase.co/functions/v1/sepay-webhook`, auth Apikey = `SEPAY_WEBHOOK_KEY`. (SePay userapi read-only, không tạo webhook qua API được.)
- [ ] Test trên emulator: COD regression, bank_transfer flow, cancel-from-QR giữ cart.
- [ ] 🔒 Xoá/tạo lại SePay API token + Supabase PAT đã dán trong chat (bảo mật).

## Unresolved Questions

- SePay test trên emulator: quét QR khó → dùng khối nhập tay hoặc test-webhook từ dashboard. Chưa chạy emulator E2E trong session này (cần user set secret trước).
