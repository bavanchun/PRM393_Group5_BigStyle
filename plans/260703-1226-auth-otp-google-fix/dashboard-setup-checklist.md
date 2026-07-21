# Dashboard Setup Checklist — OTP + Google Sign-in

Project Supabase: **bigstyle-prm393** (`https://agbnpqgxsppdrpbqoipo.supabase.co`, org bavanchun) — đã tạo + apply schema + seed (5 categories, 15 products, 87 variants).

Phần này **user tự làm** trên Supabase + Google Cloud + Resend (không phải code). Sau khi xong, OTP nhận mã 6 số + Google login chạy trên mọi máy dùng shared `debug.keystore`.

## 0. Resend SMTP (fix rate-limit + gửi email ổn định)

Supabase built-in email chỉ ~2-4 email/giờ → phải dùng Custom SMTP.

**Resend:**
1. (Nếu muốn gửi tới email bất kỳ) Resend → Domains → verify 1 domain của bạn. Không có domain → dùng sender `onboarding@resend.dev` nhưng Resend sandbox chỉ gửi tới email đã đăng ký tài khoản Resend.
2. API key đã có: `re_...` (dán ở bước dưới).

**Supabase → Authentication → Emails → SMTP Settings → Enable Custom SMTP:**
- Host: `smtp.resend.com`
- Port: `465` (SSL) hoặc `587` (TLS)
- Username: `resend`
- Password: `<RESEND_API_KEY>` (re_...)
- Sender email: email thuộc domain đã verify (hoặc `onboarding@resend.dev`)
- Sender name: `BigStyle`

**Supabase → Authentication → Rate Limits:** nâng "emails per hour" lên (vd 100).

## A. Supabase — OTP đổi từ link sang mã 6 số

Dashboard → **Authentication → Email Templates**:

1. Mở template **"Confirm signup"** (email user mới nhận hiện tại).
2. Thay nội dung link `{{ .ConfirmationURL }}` bằng dòng chứa mã token, ví dụ:
   ```
   Mã xác thực BigStyle của bạn: {{ .Token }}
   Mã có hiệu lực trong ít phút.
   ```
3. Làm tương tự cho template **"Magic Link"** (phòng trường hợp user đã tồn tại).
4. Save.

→ Email sẽ gửi **mã 6 số** khớp với ô `OtpInput` trong app.

## B. Google Cloud — OAuth clients

Console → **APIs & Services → Credentials**:

1. **Android OAuth client** (tạo mới nếu chưa có):
   - Application type: Android
   - Package name: `com.bigstyle.bigstyle_app`
   - SHA-1: `11:76:2E:AC:9E:64:06:6D:28:0E:C2:AF:B7:C9:25:44:65:C0:85:27`
     *(SHA-1 của shared `android/app/debug.keystore` — cả nhóm build chung keystore này nên chỉ cần đăng ký 1 lần.)*
2. **Web OAuth client** (dùng cho `serverClientId`):
   - Application type: Web
   - Copy **Client ID** → đây chính là `GOOGLE_WEB_CLIENT_ID` trong `.env`.
   - Copy **Client Secret** → dùng ở bước C.

> Lấy lại SHA-1 khi cần: `keytool -list -v -keystore android/app/debug.keystore -alias androiddebugkey -storepass android -keypass android`

## C. Supabase — bật Google provider

Dashboard → **Authentication → Providers → Google**:

1. Bật **ON**.
2. Dán **Web Client ID** (bước B.2) + **Client Secret**.
3. Save.

## D. `.env` mọi máy

- Đảm bảo `GOOGLE_WEB_CLIENT_ID=<web client id>` có trong `FE/.env`.
- `.env.example` đã có sẵn key này để tham chiếu.

## E. Verify (test thật)

<!-- unverified (2026-07-12): không có bằng chứng trực tiếp cho 3 mục dưới trong phiên này. Gián tiếp: 3 tác giả khác nhau (bavanchun/VChun, Lữ Anh Bảo Khang, Tri) đều có commit sau khi fix apply — ngụ ý máy khác đã setup + chạy được, nhưng không xác nhận cụ thể qua OTP/Google (có thể qua nhánh mock/password-auth thêm sau này). Không thuộc phạm vi Phase 1 của plans/260712-1644-bigstyle-product-completeness (phase đó test password-auth, không riêng OTP/Google). -->
- [ ] Gửi OTP → email hiện **mã 6 số** (không phải link) → gõ mã → login thành công.
- [ ] Bấm "Đăng nhập với Google" → chọn account → vào app.
- [ ] Máy khác (dùng shared keystore) pull code → `bash scripts/setup.sh` → điền `.env` → cả OTP + Google đều chạy.

## Ghi chú rủi ro

- **verifyOtp type**: nếu user MỚI verify mã báo lỗi, code hiện dùng `OtpType.email`. Có thể cần thử `OtpType.signup` cho lần đăng ký đầu — kiểm tra khi test, sửa `auth_service.verifyOtp` nếu cần.
- **SHA-1 mismatch**: nếu Google login vẫn fail sau khi cấu hình, kiểm tra lại SHA-1 đăng ký có khớp keystore đang build không (có thể trước đó đăng ký keystore cá nhân).
- **Bản release**: khi build release sẽ có keystore + SHA-1 khác → phải đăng ký thêm Android OAuth client cho SHA-1 release.
