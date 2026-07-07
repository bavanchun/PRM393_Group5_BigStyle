---
phase: 1
title: Setup & Methodology
status: completed
priority: P1
dependencies: []
effort: 0.25d
---

# Phase 1: Setup & Methodology

## Overview

Dựng khung audit dùng chung: severity rubric, finding schema, ma trận screen×actor,
harness chụp emulator, và skeleton `docs/ux-flow-audit.md`. Không audit nội dung ở
phase này — chỉ chuẩn bị để phase 2–4 điền nhất quán.

## Requirements

- Functional: doc skeleton có sẵn section cho mỗi actor + mỗi screen; quy ước ảnh;
  bảng findings rỗng theo schema.
- Non-functional: quy ước 1 chỗ → 3 phase sau chỉ điền, không tự chế format.

## Architecture

- **Severity rubric** (khớp plan.md): P0 chặn nghiệp vụ/mất tiền/crash · P1 sai
  chức năng/silent failure · P2 UX kém · P3 cosmetic.
- **Finding schema** (khớp plan.md): `# | Screen | Type | Severity | Hiện trạng | Đề xuất | Evidence`.
- **Ảnh**: lưu **local, KHÔNG commit** (thư mục scratchpad hoặc `docs/audit-assets/`
  đã gitignore). Chỉ dùng để phân tích; doc KHÔNG nhúng ảnh — mô tả bằng chữ +
  evidence file:line. Screen không dựng được state → ghi "N/A — <lý do>".
- **Emulator harness**: dùng `adb` như session trước (device `emulator-5554`,
  screenshot 1080x2400). Ghi 1 đoạn "cách chụp" ngắn để phase sau lặp lại.

## Related Code Files

- Create: `docs/ux-flow-audit.md` (skeleton)
- Create: `docs/audit-assets/` (thư mục ảnh; .gitkeep nếu cần)
- Read-only tham chiếu: `FE/lib/config/theme/*` (để biết token chuẩn khi chấm consistency)
- KHÔNG sửa file code nào.

## Implementation Steps

1. Tạo `docs/ux-flow-audit.md` với cấu trúc:
   - `# BigStyle — UX & Flow Audit` + ngày + branch + "Scope: audit only".
   - `## Cách đọc` (severity rubric + giải thích Type).
   - `## Actor: Guest` / `## Actor: Customer` / `## Actor: Manager` — mỗi actor có
     placeholder cho từng screen (heading `### <screen>` + dòng "States:" + bảng
     findings rỗng).
   - `## Cross-cutting` (theme, routing, shared widgets, error/empty/loading).
   - `## Top Priorities` (bảng tổng xếp P0→P3, điền ở phase 5).
2. Chuẩn bị nơi để ảnh local (scratchpad hoặc `docs/audit-assets/` + thêm vào
   `.gitignore`) — ảnh không vào repo.
3. Verify emulator sẵn sàng: `adb devices` thấy `emulator-5554`; app cài bản debug
   hiện tại. Ghi lại lệnh chụp mẫu vào doc (mục "Cách chụp").
4. Dán severity rubric + schema (không để phase sau tự định nghĩa lại).

## Success Criteria

- [ ] `docs/ux-flow-audit.md` tồn tại, có đủ heading cho 3 actor + mọi screen
      trong bảng inventory (plan.md) + cross-cutting + Top Priorities.
- [ ] Nơi lưu ảnh local sẵn sàng + đã gitignore (ảnh không commit).
- [ ] `adb devices` xác nhận emulator; lệnh chụp mẫu ghi trong doc.
- [ ] Severity rubric + finding schema xuất hiện đúng 1 lần, dùng chung.

## Risk Assessment

- Emulator không chạy → visual audit blocked. Mitigation: phase 1 verify sớm;
  nếu không có emulator, xin user bật hoặc chuyển screen đó sang "code-only + N/A ảnh".
- docs.maxLoc 800: doc có thể dài. Mitigation: bảng súc tích, ảnh ra thư mục riêng
  (không nhúng base64), tách phụ lục nếu vượt.
