# Brainstorm — Fix OTP + Google Sign-in + Config Reproducibility

- Date: 2026-07-03
- Branch: main
- Modes: brainstorm (no --html/--wiki)
- Scope: FE (Flutter + Supabase)

## Problem statement

Auth hỏng, đặc biệt "chỉ máy người làm feature mới chạy, máy khác pull code về không chạy":
- Sign-in OTP: email gửi link "Confirm your email address", click link không mở gì.
- Sign-in Google: không hoạt động.

## Root causes (verified by scout)

### OTP hỏng cho mọi máy (2 lỗi chồng nhau)
1. **Mismatch template vs UI**: email dùng template link (`{{ .ConfirmationURL }}`), nhưng UI `OtpInput` (login_screen.dart:283) chờ gõ **mã 6 số** → `verifyOtp(type: OtpType.email)` (auth_service.dart:38). Email không có mã.
2. **Deep-link chưa khai báo**: `sendOtp` set `emailRedirectTo: 'io.supabase.flutter://auth/callback'` (auth_service.dart:26) nhưng `AndroidManifest.xml` không có intent-filter cho scheme đó → click link = no-op.

### Google sign-in
3. **`.env` thiếu `GOOGLE_WEB_CLIENT_ID`** (có trong `.env.example`, thiếu trong file thật) → `AppConfig.googleWebClientId` rỗng → `serverClientId: ''` → fail.
4. **Google Cloud OAuth** cần Android client: package `com.bigstyle.bigstyle_app` + SHA-1 shared debug.keystore = `11:76:2E:AC:9E:64:06:6D:28:0E:C2:AF:B7:C9:25:44:65:C0:85:27`.

### Reproducibility (gốc rễ)
5. **`.env` bị gitignore** (.gitignore:47) → người pull không có config → app fail init (`No file for asset .env`).
6. **Path mismatch**: `pubspec.yaml` khai báo `- .env` (root) + `dotenv.load('.env')`, nhưng file thật ở `assets/.env`. `.env.example` hướng dẫn sai ("Copy to assets/.env").

Note: `SUPABASE_ANON_KEY` + `GOOGLE_WEB_CLIENT_ID` là key PUBLIC (nằm trong APK) — không phải secret. Bảo mật thật ở RLS + service_role + Google client secret (ở dashboard).

## Approaches evaluated

### OTP
- **A. Mã 6 số (CHOSEN)**: sửa email template Supabase dùng `{{ .Token }}`, khớp UI có sẵn, bỏ deep-link. KISS, chạy đều mọi máy.
- B. Magic-link: khai báo deep-link Android+iOS + xử lý callback. Nhiều việc, dễ vỡ, UI nhập mã thành thừa. Rejected.

### Config reproducibility
- X. Commit `.env` (anon key + web client id là public). 1 pull là chạy.
- **Y. Giữ `.env` bí mật + setup script (CHOSEN)**: `.env.example` đầy đủ + script copy + tài liệu.

### Google dashboard
- **User tự cấu hình (CHOSEN)**, cần checklist.

## Final solution

### Code (ít)
1. Chuẩn hoá env = `FE/.env` (khớp pubspec `- .env` + `dotenv.load('.env')`). Xoá `assets/.env`.
2. Hoàn thiện `.env.example`: sửa comment "Copy to .env"; đủ 5 key gồm `GOOGLE_WEB_CLIENT_ID`.
3. `scripts/setup.sh` + README: `cp .env.example .env` → nhắc điền value → `flutter pub get`.
4. (Optional) bỏ `emailRedirectTo` trong `auth_service.sendOtp` — thừa với flow mã số.

### Dashboard (user tự làm)
- **Supabase → Auth → Email Templates**: sửa "Confirm signup" + "Magic Link" chứa `{{ .Token }}`.
- **Google Cloud → Credentials**: Android OAuth client (package `com.bigstyle.bigstyle_app` + SHA-1 `11:76:2E:AC:9E:64:06:6D:28:0E:C2:AF:B7:C9:25:44:65:C0:85:27`); Web OAuth client → `GOOGLE_WEB_CLIENT_ID`.
- **Supabase → Auth → Providers → Google**: bật ON + Web Client ID + Secret.
- Thêm `GOOGLE_WEB_CLIENT_ID` vào `.env` mọi máy.

## Risks
- `verifyOtp` type: new user có thể cần `OtpType.signup` thay vì `OtpType.email` — verify khi implement.
- Shared debug.keystore SHA-1 phải khớp Google Cloud client, nếu trước đó đăng ký keystore cá nhân thì phải thêm SHA-1 shared.
- Nếu sau này build release → SHA-1 keystore release khác → phải đăng ký thêm.

## Success criteria
- Máy mới: clone → `scripts/setup.sh` → điền `.env` → `flutter run` → OTP (nhận mã số, gõ, vào được) + Google login đều chạy.
- Không còn phụ thuộc "máy người làm feature".

## Unresolved questions
- Đã bật Google provider ở Supabase chưa? OAuth client hiện đăng ký SHA-1 nào? (cần user kiểm tra dashboard)
- Có làm bản release (SHA-1 riêng) trong phạm vi môn học không?
