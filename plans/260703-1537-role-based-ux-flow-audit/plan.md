---
title: Role-Based UX & Flow Audit (Guest / Customer / Manager)
description: >-
  Systematic per-actor audit of every screen — flow logic + UI/UX — using
  emulator (visual) + code review. Output = single consolidated
  docs/ux-flow-audit.md with prioritized findings + fix recommendations. Audit
  only; no code changes.
status: completed
priority: P2
branch: dev
tags:
  - audit
  - ux
  - flow
  - documentation
blockedBy: []
blocks: []
created: '2026-07-03T08:38:30.290Z'
createdBy: 'ck:plan'
source: skill
---

# Role-Based UX & Flow Audit (Guest / Customer / Manager)

## Overview

Rà soát toàn bộ tính năng theo TỪNG ACTOR — (1) logic của flow, (2) UI/UX từng
screen — rồi ghi lại thiếu sót + điểm không hợp lý để user tự cải thiện.

**Method (user-locked):** Visual + Code. Chạy emulator screenshot từng screen +
review widget/bloc tương ứng.
**Deliverable (user-locked):** MỘT tài liệu tổng `docs/ux-flow-audit.md` (docs/
đang trống → đây cũng là doc UX đầu tiên của project).
**Actors (user-locked):** Guest (splash/login/OTP) + Customer + Manager.

**Scope: AUDIT ONLY.** Không sửa code trong plan này. Mỗi finding kèm đề xuất
sửa + severity; việc fix để user quyết định sau (có thể spin `/ck:cook` riêng).

Đã có 2 scout report (nền cho plan này) — ~36 issue cụ thể đã lộ, mỗi actor
phase seed sẵn danh sách nghi vấn để audit XÁC NHẬN/mở rộng thay vì bắt đầu từ 0.

## Actors → Screens (inventory)

| Actor | Screens (route/tab) |
|-------|---------------------|
| **Guest** | splash `/`, login `/login`, otp_input (inline) |
| **Customer** | home (tab0), product_list (tab1), product_detail (+review section/editor, size guide), cart (tab2), checkout `/checkout`, payment_qr `/payment-qr`, orders `/orders`, order_detail `/order-detail`, favorites (tab3), profile (tab4), edit_profile `/edit-profile`, notifications `/notifications`, chat `/chat` (AI bot), delivery_map `/delivery-map` |
| **Manager** | manager_shell (dashboard/products/orders/profile tabs), manager_dashboard, manager_orders + card, manager_order_detail, order_status_update_sheet, product_list, create_product, product_detail |

Note đã xác nhận qua scout: **chat = AI bot** (không phải chat với manager);
**delivery-map = store-locator khách** (không phải shipper — enum chỉ
customer/manager), và hiện **unreachable dead code**.

## Finding Schema (dùng chung toàn doc)

Mỗi finding 1 dòng bảng:

| # | Screen | Type | Severity | Mô tả (hiện trạng) | Đề xuất sửa | Evidence (file:line) |

- **Type**: `flow` (logic/luồng) | `ui` (hiển thị) | `ux` (trải nghiệm) | `dead` (nút/màn chết) | `consistency` (lệch design-system)
- **Severity**: `P0` chặn nghiệp vụ / mất tiền / crash · `P1` sai chức năng, silent failure · `P2` UX kém, khó dùng · `P3` cosmetic/polish

## Phases

| Phase | Name | Status | Depends |
|-------|------|--------|---------|
| 1 | [Setup & Methodology](./phase-01-setup-methodology.md) | Pending | Completed |
| 2 | [Guest Flow Audit](./phase-02-guest-flow-audit.md) | Pending | Completed |
| 3 | [Customer Flow Audit](./phase-03-customer-flow-audit.md) | Pending | Completed |
| 4 | [Manager Flow Audit](./phase-04-manager-flow-audit.md) | Pending | Completed |
| 5 | [Cross-cutting & Synthesis](./phase-05-cross-cutting-synthesis.md) | Pending | Completed |

**Parallel:** Phase 2/3/4 độc lập (khác screen). Emulator chỉ 1 → phần *visual*
serialize theo 1 hàng đợi; phần *code review* chạy song song được. Phase 5 tổng
hợp sau cùng.

## Acceptance Criteria (toàn plan)

- [ ] `docs/ux-flow-audit.md` tồn tại: mỗi actor 1 section, mỗi screen liệt kê
      trạng thái (loading/empty/error/success) + bảng findings theo schema trên.
- [ ] Mỗi màn của mỗi actor được kiểm bằng emulator (visual) — screenshot lưu
      **local, KHÔNG commit** (gitignore); doc mô tả bằng chữ + evidence file:line,
      không nhúng ảnh. Màn không dựng được state → ghi rõ "N/A — lý do".
- [ ] Toàn bộ ~36 issue từ 2 scout report được xác nhận (giữ/loại) + bổ sung phát
      hiện mới; không bỏ sót screen nào trong bảng inventory.
- [ ] Section "Top Priorities" cuối doc xếp hạng P0→P3 để user biết sửa gì trước.
- [ ] KHÔNG có thay đổi code (chỉ doc + ảnh). Nếu phát hiện quick-win user muốn
      fix, tách plan/PR riêng.

## Dependencies

- Emulator Android (`emulator-5554` đã dùng ở session trước) + `adb` cho visual.
- Tài khoản: customer `hoangbavan4478@gmail.com` (đã có). Manager: **chưa có →
  sẽ promote 1 user thành `role=manager`** qua Supabase (`update users set role`)
  lúc chạy phase 4 (hỏi user email dùng làm manager). Lưu ý: nếu promote chính
  account customer thì mất đường test customer → nên dùng email/ account thứ 2, hoặc
  flip tạm rồi trả về.
- Screenshot: lưu local (ngoài repo / gitignore), KHÔNG commit — chỉ phục vụ phân
  tích; doc dùng chữ + evidence file:line.
- 2 scout report input: manager+cross-cutting, guest+customer (đã có, tóm tắt
  seed trong các phase file).
