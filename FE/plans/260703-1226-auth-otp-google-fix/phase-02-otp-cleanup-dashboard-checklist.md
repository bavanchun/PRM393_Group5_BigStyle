---
phase: 2
title: OTP Cleanup + Dashboard Checklist
status: completed
effort: ''
---

# Phase 2: OTP Cleanup + Dashboard Checklist

## Overview

Dọn code OTP cho khớp flow mã 6 số (bỏ deep-link thừa) và cung cấp checklist cấu hình dashboard (Supabase + Google Cloud) để user tự làm. Đây là phần biến OTP + Google từ "chết" thành "chạy".

## Requirements
- Functional: sau khi user cấu hình dashboard theo checklist, OTP nhận mã 6 số + Google login chạy trên mọi máy dùng shared debug.keystore.
- Non-functional: code không còn tham chiếu deep-link không tồn tại.

## Architecture

Flow OTP mã số hoàn toàn server-side + gõ tay: `signInWithOtp(email)` → email chứa `{{ .Token }}` (6 số) → user gõ vào `OtpInput` → `verifyOtp(email, code, type)`. `emailRedirectTo` chỉ dùng cho magic-link → thừa, gỡ bỏ để tránh hiểu nhầm.

Google login (native `google_sign_in` + `serverClientId` + `signInWithIdToken`) không cần google-services.json, nhưng cần Android OAuth client trong Google Cloud đăng ký đúng package + SHA-1 của shared debug.keystore.

## Related Code Files
- Modify: `lib/services/auth_service.dart` — `sendOtp`: bỏ tham số `emailRedirectTo` (chỉ còn `signInWithOtp(email: email)`).
- Verify (không sửa): `verifyOtp` dùng `OtpType.email`; nếu user mới cần `OtpType.signup` thì xử lý fallback (xem risk).
- Create: `plans/260703-1226-auth-otp-google-fix/dashboard-setup-checklist.md` — tài liệu checklist user tự làm (không phải code).

## Implementation Steps
1. Sửa `auth_service.dart` `sendOtp`: gỡ dòng `emailRedirectTo: 'io.supabase.flutter://auth/callback'`, còn `await _client.auth.signInWithOtp(email: email);`.
2. Viết checklist dashboard (markdown) gồm:
   - **Supabase → Auth → Email Templates**: sửa "Confirm signup" + "Magic Link" chèn `{{ .Token }}` (mã 6 số).
   - **Google Cloud → Credentials**: Android OAuth client (package `com.bigstyle.bigstyle_app` + SHA-1 `11:76:2E:AC:9E:64:06:6D:28:0E:C2:AF:B7:C9:25:44:65:C0:85:27`); Web OAuth client → giá trị `GOOGLE_WEB_CLIENT_ID`.
   - **Supabase → Auth → Providers → Google**: bật ON + Web Client ID + Secret.
   - Nhắc thêm `GOOGLE_WEB_CLIENT_ID` vào `.env` mọi máy.
3. Test thủ công sau khi user cấu hình: gửi OTP → nhận mã số → gõ → login; bấm Google → login.

## Success Criteria
- [ ] `auth_service.sendOtp` không còn `emailRedirectTo`
- [ ] Checklist dashboard đầy đủ, cụ thể (có sẵn SHA-1 + package + tên template)
- [ ] (User verify) email OTP hiện mã 6 số, gõ vào login được
- [ ] (User verify) Google login chạy trên máy khác dùng shared keystore

## Risk Assessment
- **verifyOtp type cho user mới**: Supabase có thể phân biệt `OtpType.email` (đăng nhập) vs `OtpType.signup` (đăng ký mới). Nếu user mới verify fail → thêm nhánh thử `OtpType.signup`. Verify khi test thật, không over-engineer trước.
- **SHA-1 mismatch**: nếu Google Cloud client đang đăng ký SHA-1 keystore cá nhân của dev cũ → phải thêm SHA-1 shared. Bản release sau này có SHA-1 khác → đăng ký thêm.
- **Rate limit email**: Supabase free tier giới hạn email/giờ → test vừa phải.
