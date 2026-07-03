---
phase: 4
title: "Integration Verify"
status: pending
priority: P2
dependencies: [2, 3]
effort: "0.25d"
---

# Phase 4: Integration Verify

## Overview

Sau khi phase 2 ∥ 3 xong: hợp nhất điểm giao, verify end-to-end cả 2 flow trên emulator, chạy gate chất lượng.

## Requirements

- Functional: toàn bộ Acceptance Criteria của plan.md pass.
- Non-functional: `flutter analyze` sạch, không regression flow cũ (browse/cart/COD/orders/notification list).

## Related Code Files

- Modify (nếu cần): `lib/config/routes/app_router.dart` — xác nhận route '/payment-qr' (phase 2) tồn tại; nếu phase 3 cần route named cho manager detail thì thêm ở đây (điểm giao đã dồn về phase này).
- Không tạo file mới (trừ fix nhỏ phát sinh).

## Implementation Steps

1. Merge/rebase 2 nhánh công việc nếu chạy parallel bằng worktree; resolve app_router nếu đụng.
2. `flutter analyze` toàn repo.
3. E2E COD: đặt hàng → orders + payments(cod) + cart clear → manager thấy đơn.
4. E2E SePay: đặt → màn QR → curl webhook (đúng amount) → app chuyển màn ≤5s → confirmed/success → khách thấy notification.
5. E2E manager: confirmed→processing→shipping→delivered qua sheet + detail; mỗi bước khách nhận notification; huỷ 1 đơn pending bỏ dở → cart khách (nếu còn) không ảnh hưởng.
6. Edge: webhook thiếu tiền → order vẫn pending, payments ghi gateway_response, recovery = manager confirm tay qua sheet (thấy warning chưa thanh toán); webhook lặp → idempotent; race: manager cancel rồi webhook đến → order giữ cancelled, payments vẫn ghi.
7. Spawn `code-reviewer` subagent review diff toàn feature (acceptance criteria + regression + contracts).
8. Fix findings, commit cuối (`test/fix(payment,manager): integration verify`) — ≥1 commit.

## Success Criteria

- [ ] Toàn bộ Acceptance Criteria trong plan.md pass.
- [ ] `flutter analyze` 0 lỗi.
- [ ] code-reviewer không còn finding blocking.
- [ ] ≥1 commit.

## Risk Assessment

- Conflict app_router khi merge parallel: đã dồn quyền sửa route về phase này.
- Webhook test cần order thật trong DB → tạo đơn từ app trước rồi curl với content chứa order_number đó.
