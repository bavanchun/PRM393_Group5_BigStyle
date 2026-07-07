# bigstyle_app

BigStyle - Thời trang bigsize tự tin, cao cấp. Flutter app + Supabase backend.

## Setup / Run

```bash
# 1. Cài đặt: tạo .env + fetch dependencies
bash scripts/setup.sh

# 2. Điền giá trị vào .env (Supabase keys, GOOGLE_WEB_CLIENT_ID, ...)
#    Xem .env.example để biết các key cần thiết.

# 3. Khởi động emulator/device rồi chạy
flutter run
```

- `.env` nằm ở gốc `FE/` (cạnh `pubspec.yaml`), được gitignore. Nguồn tham chiếu key: `.env.example`.
- Google Sign-In + OTP cần cấu hình dashboard (Supabase + Google Cloud) — xem checklist trong `plans/260703-1226-auth-otp-google-fix/`.

## Flutter resources

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Flutter documentation](https://docs.flutter.dev/)
