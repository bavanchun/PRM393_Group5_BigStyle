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
- Native Google Maps (màn Store/Delivery) dùng key riêng, KHÁC với `GOOGLE_MAPS_API_KEY` trong `.env` (key đó chỉ dùng cho Directions REST và bị bundle vào APK). Tạo key thứ 2 trên Google Cloud, giới hạn theo package name + SHA-1 (debug/release), bật Maps SDK for Android, rồi đặt vào `android/local.properties` (gitignore) dưới dạng `GOOGLE_MAPS_API_KEY=<sdk-key>`. Không có key thì build vẫn chạy, map chỉ trống.

## QA debug login

The login screen can show real Supabase test-account buttons in debug builds
only. Pass credentials at runtime with `--dart-define`; do not store passwords
in source, `.env`, or docs.

```bash
flutter run \
  --dart-define=BIGSTYLE_TEST_MANAGER_EMAIL=<manager-email> \
  --dart-define=BIGSTYLE_TEST_MANAGER_PASSWORD=<manager-password> \
  --dart-define=BIGSTYLE_TEST_CUSTOMER_EMAIL=<customer-email> \
  --dart-define=BIGSTYLE_TEST_CUSTOMER_PASSWORD=<customer-password>
```

- The buttons stay hidden in release builds.
- In debug builds, each button stays hidden unless both email and password for
  that role are provided.
- This path signs in through Supabase password auth; OTP and Google Sign-In
  remain the normal user-facing auth paths.

## Flutter resources

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Flutter documentation](https://docs.flutter.dev/)
