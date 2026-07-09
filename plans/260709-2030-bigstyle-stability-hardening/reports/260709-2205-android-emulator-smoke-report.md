# Test Report — 2026-07-09 — Android Emulator Smoke

## Test Results Overview

- **Device**: `pixel8` AVD, `emulator-5554`, Android 15 API 35.
- **App**: debug build installed via `flutter run -d emulator-5554`.
- **Automated tests**: 3 passed, 0 failed.
- **Runtime smoke**: partial pass; authenticated customer/manager flows blocked.

## Commands

```text
flutter emulators --launch pixel8
emulator -avd pixel8 -no-snapshot-load
flutter analyze
flutter test
flutter run -d emulator-5554
```

## Build Status

- **Analyze**: PASS, no issues.
- **Unit/widget tests**: PASS, 3 tests.
- **Android assemble/install**: PASS, `app-debug.apk` installed.
- **Supabase init**: PASS, log shows Supabase init completed.

## UI Test Results

| Scenario | Status | Evidence |
|----------|--------|----------|
| Cold launch with no session | PASS | App reaches login, no splash hang. |
| Login screen renders | PASS | `android-smoke-screens/01-launch.png` |
| Empty email validation | PASS | UIA sees `Vui lòng nhập email`; screenshot `05-empty-email-validation-bounds.png` |
| Invalid email validation | PASS | UIA sees `Email không hợp lệ`; screenshot `06-invalid-email-validation.png` |
| Google login button | PARTIAL | Opens Google account picker. Did not select account to avoid using personal session without approval. |
| Manager OTP login | BLOCKED | Demo manager account known, but OTP email not found in Gmail; button automation did not produce OTP state/email during this run. |
| Customer/manager app flows | BLOCKED | Need authenticated session or OTP. |
| Reopen app after back/home | PASS | Returns to login after splash; screenshot `15-reopen-app-after-splash.png` |

## Observed Logs

- No fatal Android crash found in final log sample.
- Initial launch had skipped frames; emulator used software GL due low host memory.
- Android log shows `FlutterImageDecoderImplDefault` decode error for an image. Likely from trying to load the Google SVG icon through `Image.network`; UI falls back, but log noise remains.
- Emulator network probes to Google failed earlier during run, so external auth/network behavior may be unreliable on this AVD.

## Account Context Found

From public repo runbook:

- Manager demo: `hoangbavan4478+manager@gmail.com`
- Customer demo: `hoangbavan4478@gmail.com`
- Customer2 demo: `hoangbavan4478+customer2@gmail.com`

No Supabase MCP/direct query tool available in this session. Supabase CLI also not installed in PATH.

## Critical Issues

1. Authenticated smoke not completed.
   Impact: cannot verify cart/checkout/orders/manager order/product flows on emulator yet.

2. OTP send could not be confirmed.
   Impact: manager login remains blocked. Gmail search found no recent OTP from Supabase/BigStyle.

## Recommendations

1. Provide OTP from Gmail or approve using the emulator Google account, then rerun authenticated smoke.
2. Add a debug-only, clearly labeled mock login entrypoint or test-only route if the team wants repeatable emulator QA without OTP.
3. Replace remote SVG Google icon with an asset or SVG-capable widget to avoid decoder error logs.
4. Install/configure Supabase CLI or MCP so account/profile checks and migration apply can be verified directly.

## Unresolved Questions

- Should I use the Google account already present on the emulator to continue customer smoke?
- Can you provide the manager OTP when it arrives, or should we add a temporary debug-only manager login path?
