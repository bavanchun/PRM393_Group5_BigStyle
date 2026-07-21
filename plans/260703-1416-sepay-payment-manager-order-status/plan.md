---
title: SePay Payment + Manager Order Status
description: >-
  Tích hợp thanh toán chuyển khoản VietQR qua SePay webhook + cho manager đổi
  trạng thái đơn (kích hoạt notification trigger có sẵn)
status: pending
priority: P1
branch: dev
tags:
  - payment
  - sepay
  - manager
  - orders
blockedBy: []
blocks: []
created: '2026-07-03T07:21:03.611Z'
createdBy: 'ck:plan'
source: skill
---

# SePay Payment + Manager Order Status

## Overview

2 gap lớn nhất từ scout report: (1) app không có bước thanh toán — checkout tạo order thẳng; (2) manager không đổi được trạng thái đơn (`OrderService.updateOrderStatus` tồn tại nhưng 0 caller, trigger notification DB chưa bao giờ chạy).

Giải pháp đã chốt (brainstorm report: `plans/reports/brainstorm-260703-1416-sepay-payment-manager-order-status-report.md` — 9 quyết định user-locked):
- Checkout: chọn **COD | bank_transfer (SePay VietQR)**. Order tạo `pending` TRƯỚC màn QR; cart clear khi paid (SePay) / ngay (COD).
- Webhook SePay → Supabase Edge Function `sepay-webhook` → update `payments` + `orders.status=confirmed` → trigger DB tự bắn notification.
- Paid detection: **Realtime + polling fallback**.
- Manager: đổi status qua **bottom-sheet + màn manager-order-detail riêng**, guard luồng chuyển hợp lệ.

## Parallel Execution

- **Phase 1 (nền)**: chạy TRƯỚC, tuần tự.
- **Phase 2 ∥ Phase 3**: song song sau Phase 1 — không chung file ghi. Phase 3 sửa `order_status.dart` (thêm helper), Phase 2 chỉ đọc enum. Phase 2 sửa `order_model.dart`/`order_service.dart`; Phase 3 chỉ đọc 2 file này. Cả 2 thêm route vào `app_router.dart` → **điểm giao duy nhất**: mỗi phase thêm case riêng, merge dễ; nếu chạy 2 agent parallel, agent Phase 3 KHÔNG sửa app_router — để lại ghi chú, Phase 4 nối route.
- **Phase 4**: sau 2+3, verify end-to-end + nối route còn thiếu.

| Phase | Name | Status | Depends |
|-------|------|--------|---------|
| 1 | [Backend Foundation (Migration + Webhook)](./phase-01-backend-foundation-migration-webhook.md) | Pending | Completed |
| 2 | [Payment FE (Checkout + QR)](./phase-02-payment-fe-checkout-qr.md) | Pending | Completed |
| 3 | [Manager Order Status FE](./phase-03-manager-order-status-fe.md) | Pending | Completed |
| 4 | [Integration Verify](./phase-04-integration-verify.md) | Pending | 2, 3 |

## Acceptance Criteria (toàn plan)

<!-- Trạng thái thật (2026-07-12, đối chiếu plans/reports/sepay-payment-manager-order-status-implementation-260703-1416-completion-report.md):
     code + migration + edge function đã deploy; DB-level và HTTP curl E2E đã verify live (webhook success path, idempotency, RLS, wrong-key 401).
     Còn thiếu: (1) đăng ký webhook URL trong SePay dashboard — chỉ user làm được; (2) device/emulator pass cho COD+bank-transfer+manager-status —
     sẽ đóng qua plans/260712-1644-bigstyle-product-completeness Phase 1. Do đó status giữ `pending`, KHÔNG flip completed. -->

- [ ] COD flow cũ nguyên vẹn + lưu `payment_method=cod` + tạo `payments` row.
- [ ] SePay flow: order pending → màn QR (ảnh + khối nhập tay copy) → test-webhook → app tự chuyển màn thành công ≤5s → order=confirmed, payments=success → khách nhận notification.
- [ ] Bỏ ngang màn QR: cart nguyên, order pending tồn tại, manager huỷ được.
- [ ] Manager đổi status (sheet + detail screen), chỉ trạng thái kế hợp lệ, khách nhận notification qua trigger.
- [ ] `flutter analyze` sạch; mỗi phase ≥1 commit (yêu cầu user).

## Dependencies

- Supabase project `bigstyle-prm393` (`agbnpqgxsppdrpbqoipo`) — dùng Supabase MCP (`apply_migration`, `deploy_edge_function`, `execute_sql`).
- User setup ngoài code: tài khoản SePay + link bank + cấu hình webhook URL/Apikey (checklist trong phase 1).
- Quy ước commit: mỗi phase ≥1 commit, conventional format, không AI reference.
