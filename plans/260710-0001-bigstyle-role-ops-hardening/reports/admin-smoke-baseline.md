# Admin Smoke Baseline

Date: 2026-07-10
Branch: `dev`
Base commit: `2e7c572`
Supabase project: `bigstyle-prm393`
Device: Android emulator `emulator-5554` / `pixel8`

## Summary

Admin smoke passed on a real remote Supabase admin account after normalizing the
manually created Auth record.

Durable QA admin:

- Email: dedicated `+admin` QA alias under the project owner mailbox.
- Profile role: `admin`
- Profile name: `Admin BigStyle QA`

No password is stored in this report.

## Regression Gate

- `cd FE && flutter analyze`: PASS, no issues.
- `cd FE && flutter test`: PASS, 3 tests.

Runtime warning:

- `flutter run` reports 42 packages with newer versions incompatible with
  current dependency constraints.
- Emulator logs include expected debug/runtime warnings such as skipped frames
  and Android back dispatcher manifest warning.

## Supabase Admin Account Fix

Initial state had no admin profile. A durable QA admin was created, but first
password login failed.

Verified root cause through Supabase Auth logs and normalized the QA admin Auth
metadata to match records created by Supabase Auth. The fix was applied only to
the QA admin account. Password login was then verified by REST grant and by the
Flutter app.

## Admin App Smoke

Login path:

- Cleared app data with `adb shell pm clear com.bigstyle.bigstyle_app`.
- Ran Flutter debug app with `BIGSTYLE_TEST_MANAGER_EMAIL` pointing to the admin
  QA account.
- Used visible debug button `Manager test`; despite label, it logs in whatever
  account is passed by dart-define.
- Result: routed to `/admin` and rendered `Admin Panel`.

Dashboard tab:

- PASS.
- Visible content: `Admin Panel`, `Xin chào, Admin!`, `Tổng quan nền tảng
  BigStyle`.
- Remote stats rendered: revenue `912.000đ`, users `4`, products `15`, orders
  `7`, categories `5`, customers `1`, managers `2`.

Users tab:

- PASS.
- Visible content: `Quản lý người dùng`, role filters `Tất cả`, `Khách hàng`,
  `Quản lý`, `Admin`, and action `Thêm người dùng`.
- Remote users rendered:
  - `Admin BigStyle QA` / dedicated `+admin` alias / `Admin`
  - `Trần Thị Demo` / dedicated `+customer2` alias / `KH`
  - `Quản lý BigStyle` / dedicated `+manager` alias / `QL`
  - project owner mailbox / `QL`
- Search smoke: entered `customer2`; list narrowed to the customer QA account.
- Combined search/filter smoke: with search `customer2`, tapped `Admin`; empty
  state `Không tìm thấy người dùng` rendered.
- Role filter smoke: cleared search while `Admin` filter was selected; list
  narrowed to `Admin BigStyle QA`.

Categories tab:

- PASS.
- Visible content: `Quản lý danh mục`, `Thêm danh mục`.
- Remote categories rendered: `Đầm`, `Áo`, `Quần`, `Set đồ`, `Phụ kiện`.

Profile tab:

- PASS.
- Visible content: `Admin BigStyle QA`,
  dedicated `+admin` alias, `Chỉnh sửa hồ sơ`, `Hồ sơ`, `Cài đặt`, `Trợ giúp`,
  `Đăng xuất`.

## Invite Baseline

Invite mutation was skipped to avoid sending a real email during baseline smoke.

Code-level baseline is confirmed at `FE/lib/services/admin_service.dart`:

- `AdminService.addUser()` calls `_client.auth.admin.inviteUserByEmail(...)`
  from the Flutter client.
- This is not production-safe because admin/service-role behavior must not live
  in the mobile app.
- Phase 2 should move invite behavior to a Supabase Edge Function that validates
  caller role server-side before using service-role privileges.

## Result

Phase 1 success criteria are met. The admin runtime works with a real remote
admin account; the current invite path remains the expected Phase 2 blocker.

## Unresolved Questions

None.
