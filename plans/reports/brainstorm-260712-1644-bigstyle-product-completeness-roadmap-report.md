# Brainstorm Report — BigStyle Product-Completeness Roadmap

- Date: 2026-07-12 16:44 | Branch: `dev` | Mode: markdown only (no --html/--wiki)
- Goal (user-confirmed): app trọn vẹn như sản phẩm thật, không áp deadline, scope A+B+C+D.

## Problem Statement

App đã qua 17 plan (15 completed), 104 test xanh, security hardening nhiều đợt. Còn thiếu để thành "sản phẩm thật": (1) device-pass verify chưa chạy, (2) vài feature chuẩn sản phẩm (push, reset password, realtime badge, refund từ customer), (3) Manager/Admin UX chưa được polish như customer flow, (4) README hỏng + docs kiến trúc phân tán.

## Current State (scouted 2026-07-12)

| Area | State |
|------|-------|
| Customer flow | Đầy đủ: auth (OTP/Google/password), catalog/search/facets, cart→checkout (COD + SePay + voucher), order timeline+cancel, review purchase-gated, wishlist, AI chat + human support (realtime), delivery map. Flagship UX-depth merged (PR #33). |
| Manager | Products/categories/vouchers/orders/support — real Supabase, đã hardening. |
| Admin | **Real, không phải stub** (~2.1k LOC): dashboard stats, user role mgmt qua edge function, categories. Route theo role từ splash/login. |
| Notifications | In-app, DB-backed, **fetch-only** (không realtime), **không FCM** (pubspec không firebase). |
| Reset password | Chưa có — login gợi ý dùng OTP làm lối thoát. |
| Refund | Manager set `refunded` được; customer không có luồng yêu cầu. |
| Dark mode / address book / recently-viewed | Không có. |
| Verify debt | Phase 5 device pass 32 mục (plan `260710-2235-review-gate-map-chat-hardening`), blocker: `sudo modprobe kvm_amd`. |
| Repo docs | README 1 dòng hỏng encoding; `CODEBASE.md` 261 dòng tốt; `docs/` chỉ có audit + design-tokens; `FE/plans/` còn 2 plan legacy sai chỗ. |

## Evaluated Approaches

| PA | Thứ tự | Pros | Cons | Verdict |
|----|--------|------|------|---------|
| **PA1 Verify-first** | A→D→B1+B2→B3→B4→C | Baseline chốt trước khi xây; việc rẻ-giá-trị-cao trước; FCM nặng đứng sau khi badge realtime gánh phần lớn giá trị | Feature mới đến muộn | **CHỌN** (user-confirmed) |
| PA2 Feature-first | B→A→D→C | Feature wow sớm | Verify dồn cục, surface chưa kiểm chứng phình to | Rejected |
| PA3 Docs-first | D→A→B→C | Hồ sơ repo gấp | Không có deadline nên không cần | Rejected |

## Final Roadmap (PA1)

### Wave 1 — A: Device pass Phase 5 (verify, no new code)
32 mục: seed/cleanup data (cần user confirm xoá từng row), review-gate probes (REST non-purchaser, forged order_item_id, is_verified spoof, avg_rating trigger), map route/recenter, human chat realtime + RLS leak probes, auth password flows, smoke full purchase COD + bank. Blocker: emulator cần `sudo modprobe kvm_amd`. Done → flip plan `review-gate-map-chat-hardening` completed + đóng `demo-fix-roadmap` (partial).

### Wave 2 — D: Repo hồ sơ
- Viết lại `README.md` (UTF-8): mô tả app, screenshots, kiến trúc tóm tắt (link CODEBASE.md), setup + env, hướng dẫn chạy, phân công nhóm.
- Tạo `docs/system-architecture.md` tổng hợp (FE structure, Supabase schema/RLS, luồng chính).
- Di dời/archive 2 plan legacy `FE/plans/` về `plans/`.
- Sync-back checkbox ~6 plan completed cũ (thẩm mỹ).

### Wave 3 — B1+B2: Quick product wins
- **B1 Realtime notif badge**: Supabase realtime subscription bảng `notifications` (tái dùng pattern chat), badge update live.
- **B2 Reset password**: `resetPasswordForEmail` + deep link về app + màn đặt lại mật khẩu.

### Wave 4 — B3: FCM push notifications (nặng nhất)
Firebase project + `firebase_messaging`, DB trigger → edge function → FCM (order status, chat message), background handling + deep link vào order/chat. Prereq: B1 xong (tránh trùng lấn logic badge), Wave 1 xanh.

### Wave 5 — B4: Customer refund request
Nối dài luồng refund: customer gửi yêu cầu (lý do) trên đơn delivered → manager duyệt → status `refunded` (đã có). Cần thêm bảng/cột yêu cầu + notification 2 chiều.

### Wave 6 — C: Polish Manager/Admin UX
Audit-driven batch (không polish cảm tính): empty/error/loading states, offline snackbar, consistency với `design-tokens-v2.md`, motion parity với customer flow ở mức hợp lý.

## Risks

- FCM trên emulator cần Google Play image; test push thật nên có device thật.
- Deep link (B2, B3) cần config AndroidManifest + Supabase redirect URL — dễ sai môi trường.
- Wave 1 cần user có mặt (confirm xoá data, sudo).
- B4 đụng money-path (refund) → cần test kỹ, không đụng atomic stock logic đã hardening.

## Success Metrics

- Wave 1: 32/32 mục pass, 2 plan flip completed → 17/17 plan done.
- Wave 2: README render đúng trên GitHub, người mới clone chạy được app theo hướng dẫn.
- Wave 3-4: notification badge nhảy realtime; push đến khi app background; reset password end-to-end.
- Wave 5: customer tạo được refund request, manager duyệt, status sync.
- Wave 6: 0 màn Manager/Admin thiếu empty/error state.
- Mỗi wave: `flutter analyze` 0, `flutter test` xanh (≥104), hardcode-color guard 0.

## Backlog (considered, giữ lại — không lên kế hoạch đợt này)

- Sổ địa chỉ giao hàng (multi-address)
- Recently-viewed / gợi ý sản phẩm
- Dark mode

## Next Steps

1. Lên plan chi tiết qua `/ck:plan` (mỗi wave = 1 phase; hoặc tách Wave 1 chạy ngay vì không cần code).
2. Wave 1 cần session có user: emulator + sudo + confirm data.

## Unresolved Questions

1. Firebase project cho FCM: dùng account Google nào của nhóm? (cần trước Wave 4)
2. Deep link scheme mong muốn (`bigstyle://` hay App Links https)? (cần trước Wave 3-B2)
