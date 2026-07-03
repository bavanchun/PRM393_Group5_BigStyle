---
phase: 2
title: "Guest Flow Audit"
status: pending
priority: P1
dependencies: [1]
effort: "0.25d"
---

# Phase 2: Guest Flow Audit

## Overview

Audit luồng chưa đăng nhập: splash → login → OTP → Google. Xác nhận/mở rộng các
nghi vấn scout, chụp emulator từng bước, điền section `## Actor: Guest`.

## Requirements

- Functional: mỗi screen ghi rõ states (loading/empty/error/success) + bảng findings.
- Non-functional: đi đúng luồng thật (nhập email → OTP → vào app); note các nhánh
  lỗi (email rỗng, OTP sai, session hang).

## Screens & Flow

`splash /` → (có session) `/manager|/home` · (không) `/login` → nhập email →
`SendOTPEvent` → OTP inline → `VerifyOTPEvent` → landing theo role. Google song song.
Mock quick-login (`!kReleaseMode`).

## Seed findings (từ scout — cần XÁC NHẬN + severity hoá)

- `splash`: chỉ có spinner, **không có error/timeout state**; `Future.delayed(1500ms)`
  re-arm mỗi lần state đổi → có thể queue nhiều navigation; `AuthError`/`AuthLoading`
  **kẹt splash vĩnh viễn**. (flow, nghi P1)
- `login`: mock quick-login tạo `mock-*` user → browse được nhưng bị chặn ở
  add-to-cart/checkout/review → dead-end `/login` sau khi mất công. (ux/flow)
- `login`: "Đăng ký" chỉ resend OTP, không đăng ký thật; email rỗng thì im lặng.
- `login`: validate email chỉ `contains('@')`; Google icon load SVG từ CDN remote.
- `otp_input`: **không backspace về ô trước**; không paste; sửa ô giữa sau khi đầy
  không re-submit; ternary padding chết (`index<6?4:0` luôn true).

## Implementation Steps

1. Chạy app trên emulator từ cold start → chụp splash. Kiểm: session cũ có auto-vào
   không; thử để trống/mạng chậm xem có kẹt spinner (xác nhận nghi vấn hang).
2. Màn login: chụp default, sau khi nhập email, sau khi OTP hiện. Thử email sai
   format, email rỗng bấm "Đăng ký", OTP sai → ghi có feedback không.
3. OTP: gõ 6 số auto-submit; thử xoá 1 ô (backspace) xem focus có lùi; thử paste.
4. Google login + mock quick-login (customer & manager) → chụp; xác nhận mock-guard
   chặn ở đâu (thử add-to-cart bằng mock customer).
5. Điền `## Actor: Guest` trong `docs/ux-flow-audit.md`: mỗi screen States + bảng
   findings (giữ/loại seed + phát hiện mới). Ảnh giữ local (không commit); doc mô tả
   bằng chữ + evidence file:line.

## Success Criteria

- [ ] 3 screen guest (splash/login/otp) đủ States + bảng findings.
- [ ] Mỗi seed finding được đánh giá giữ/loại + gắn severity + evidence file:line.
- [ ] Mỗi screen kiểm visual bằng emulator (ảnh local, không commit) hoặc "N/A — lý do".
- [ ] Kết luận rõ: mock-login có nên giữ cho demo không (đường browse vs chặn mua).

## Risk Assessment

- Không dựng được state lỗi (splash hang) trên emulator → mô tả bằng code-review +
  đánh dấu "không repro visual". Không bịa ảnh.
- OTP thật cần email nhận mã → dùng account thật của user; nếu rate-limit, note lại.
