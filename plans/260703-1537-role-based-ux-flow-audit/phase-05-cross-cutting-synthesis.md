---
phase: 5
title: "Cross-cutting & Synthesis"
status: pending
priority: P1
dependencies: [2, 3, 4]
effort: "0.25d"
---

# Phase 5: Cross-cutting & Synthesis

## Overview

Audit các vấn đề xuyên suốt (không thuộc riêng screen nào) + tổng hợp toàn bộ
findings 3 actor thành bảng "Top Priorities" xếp P0→P3 để user biết sửa gì trước.
Chốt `docs/ux-flow-audit.md`.

## Requirements

- Functional: điền `## Cross-cutting` + `## Top Priorities`; dedupe finding trùng
  giữa các actor (vd routing, shipping, chat/AI, delivery-map).
- Non-functional: doc ≤ ~800 dòng (docs.maxLoc); nếu vượt → tách phụ lục.

## Cross-cutting dimensions (seed từ scout)

1. **Design-system drift**: nhóm product manager screens hardcode Colors.*/TextStyle,
   `.withOpacity` deprecated (phần còn lại dùng `.withValues`); AppBar hồng vs trắng;
   status `Colors.blue` hardcode ở order card; branding "CurveFit Admin" ≠ "BigStyle".
2. **Shared widgets reinvented**: `AppButton`/`AppTextField`/`AppCard` tồn tại nhưng
   product screens tự chế button/field/card; `AppTextField` gần như không dùng.
3. **Routing**: switch phẳng, **không role guard**; route arg untyped (`/order-detail`
   nhận String, dễ throw); mix named-route vs MaterialPageRoute trực tiếp.
4. **State dispatch trong build()**: order_detail, notifications (customer) → re-fire.
5. **Error/empty/loading**: order-domain nhất quán tốt; product-domain thiếu error
   state; nhiều silent failure (payment fetch, status update, edit profile).
6. **Bloc scope**: ManagerBloc/ManagerProductBloc global — sống cả session customer.
7. **Navigation stack**: bottom nav tab 1–4 dùng `pushNamed` → back stack phình,
   highlight tab desync.
8. **Feature naming**: "Hỗ trợ & Chat" thực ra AI bot; delivery-map là store-locator
   unreachable.

## Implementation Steps

1. Điền `## Cross-cutting` trong doc theo 8 nhóm trên (mỗi nhóm: hiện trạng + đề xuất
   + severity + evidence). Screen-specific đã ở section actor → ở đây chỉ pattern chung.
2. Gom tất cả findings (guest+customer+manager+cross) → **dedupe** (vd routing xuất
   hiện ở customer & manager → 1 dòng cross-cutting). 
3. Xây `## Top Priorities`: bảng xếp P0→P3, cột `# | Severity | Actor/Scope | Vấn đề
   | Đề xuất | Effort ước lượng (S/M/L)`. Đề xuất "quick wins" (P1 dễ sửa) lên đầu.
4. Rà doc: mọi screen inventory có mặt; số finding khớp; ảnh liên kết đúng.
5. Kiểm độ dài doc; nếu > ~800 dòng, tách bảng chi tiết per-actor sang phụ lục
   `docs/ux-flow-audit-appendix-<actor>.md`, giữ doc chính là tổng quan + Top Priorities.
6. (Tuỳ chọn) Viết report ngắn `plans/reports/` tóm tắt số finding theo severity.

## Success Criteria

- [ ] `## Cross-cutting` đủ 8 nhóm; không lặp lại chi tiết đã ở section actor.
- [ ] `## Top Priorities` xếp P0→P3, có effort ước lượng, quick-wins nổi bật.
- [ ] Không finding trùng giữa các section (đã dedupe).
- [ ] Doc chốt, trong ngưỡng maxLoc (hoặc đã tách phụ lục).
- [ ] Toàn plan: 0 thay đổi code; chỉ docs + ảnh.

## Risk Assessment

- Trùng lặp finding giữa actor → phải dedupe cẩn thận, giữ evidence đầy đủ nhất.
- Xếp severity mang tính phán đoán → bám rubric P0–P3; khi lưỡng lự ghi lý do 1 dòng.
- User có thể muốn fix ngay 1 số P0/P1 → kết doc bằng gợi ý tách `/ck:cook` riêng,
  không tự sửa trong plan này.
