# BigStyle — System Architecture

> Cập nhật: 2026-07-13. Nguồn: đối chiếu trực tiếp `FE/lib/`, `FE/supabase/migrations/` tại thời điểm viết. Lưu ý: Phase 3 (badge realtime), 5 (refund flow), 6 (polish) đã code-complete-and-reviewed, device e2e pending Phase 1 của roadmap.
> Tổng quan nhanh: [CODEBASE.md](../CODEBASE.md) · README: [README.md](../README.md)

## 1. Tổng quan

Kiến trúc **client + BaaS**: app Flutter nói chuyện trực tiếp với Supabase, không có backend tự viết. Mọi ràng buộc nghiệp vụ quan trọng (tiền, quyền, tính toàn vẹn review/chat) được đẩy xuống Postgres (RLS, trigger, RPC `SECURITY DEFINER`) hoặc Edge Function — client không được tin tưởng.

```
┌─────────────────────────────┐
│      Flutter App (FE/)      │
│  Screens → BLoC → Services  │
└──────────────┬──────────────┘
               │ supabase_flutter (REST / Realtime / Auth / Storage)
┌──────────────▼──────────────────────────────────────────┐
│                    Supabase (hosted)                    │
│  Auth (OTP · password · Google)                         │
│  Postgres + RLS + triggers + RPCs                       │
│  Realtime (payments, support chat)                      │
│  Storage (products / avatars / reviews)                 │
│  Edge Functions: sepay-webhook · admin-invite-user      │
└──────────────▲──────────────────────────────────────────┘
               │ webhook (server→server, API key)
        ┌──────┴──────┐
        │    SePay    │  ← khách chuyển khoản VietQR
        └─────────────┘
```

Ngoài ra client gọi 2 API ngoài: **Google Directions** (vẽ lộ trình giao hàng) và **Anthropic Claude** (chat AI tư vấn, có mock fallback khi thiếu key).

## 2. Cấu trúc Flutter app (`FE/lib/`)

```
lib/
├── main.dart            # entry: load .env, init Supabase, MultiBlocProvider
├── config/
│   ├── app_config.dart          # đọc biến môi trường
│   ├── routes/app_router.dart   # onGenerateRoute — 21 route string-based
│   ├── supabase/supabase_config.dart
│   └── theme/                   # app_colors, app_typography, app_spacing, app_theme
├── blocs/               # 19 nhóm BLoC (Event → Bloc → State)
├── screens/             # 54 file màn hình, 16 nhóm theo feature
├── services/            # 14 service bọc Supabase client
├── models/              # 16 file: 12 model classes + enum/value objects
├── widgets/             # 14 widget tái sử dụng
└── utils/               # helpers (format tiền, validators, ...)
```

### BLoC (19)

`admin`, `auth`, `cart`, `chat` (AI), `checkout`, `manager`, `manager_category`, `manager_product`, `manager_voucher`, `notification`, `order`, `payment`, `product`, `product_detail`, `review`, `search`, `support_chat`, `support_inbox`, `wishlist`.

Quy ước: UI dispatch **Event** → Bloc gọi **Service** → emit **State** (equatable). Bloc không gọi Supabase trực tiếp; service không giữ state.

### Services (15)

| Service | Vai trò chính |
|---|---|
| `auth_service` | OTP, email+password sign-up/sign-in, password reset + update, profile, role lookup |
| `google_auth_service` | Google Sign-In (id token → Supabase) |
| `product_service` | catalog, filter/sort/search, chi tiết + variants |
| `category_service` | danh mục (customer + manager CRUD) |
| `cart_service` | giỏ hàng CRUD theo `cart`/`cart_items` |
| `order_service` | tạo đơn qua RPC `create_order`, list/detail, huỷ qua `cancel_my_order`, đổi trạng thái (manager) |
| `payment_service` | bản ghi `payments`, QR VietQR, **subscribe realtime** chờ webhook xác nhận |
| `voucher_service` | validate/redeem voucher qua RPC, CRUD (manager) |
| `wishlist_service` | yêu thích per-user |
| `review_service` | submit/upsert review (gate ở server), list theo sản phẩm |
| `notification_service` | list, unread count, mark read; subscribe realtime notify changes |
| `chat_service` | chat AI: gọi Claude API (hoặc mock), lưu `chat_messages` |
| `support_chat_service` | chat người-với-người: conversations/messages + realtime |
| `refund_request_service` | submit/view refund requests, manager decision qua `decide_refund_request` RPC |
| `admin_service` | thống kê hệ thống, mời manager qua Edge Function |

### Screens (16 nhóm / 57 file)

- **Customer:** `splash`, `auth` (login/OTP/password/**reset-password**), `home`, `search`, `product_list`, `product_detail` (6 file: carousel, variants, reviews…), `favorites`, `cart` (2), `checkout` (7 file: form, summary, payment QR, success…), `orders` (2, + refund request sheet), `delivery` (map route), `notifications`, `profile` (2), `chat` (AI + support chat entry).
- **Manager (19 file):** `manager_shell` + dashboard, `products/` (CRUD + variant form), `categories/`, `vouchers/`, orders (list/card/detail/status-sheet/**refund-decision-sheet**), `support/` (inbox + phòng chat).
- **Admin (4 file):** `admin_shell`, dashboard, categories, users (invite manager).

### Routes (từ `app_router.dart`)

`/` (splash), `/login`, `/home`, `/products`, `/product-detail`, `/search`, `/favorites`, `/cart`, `/cart-item-edit`, `/checkout`, `/payment-qr`, `/orders`, `/order-detail`, `/delivery-map`, `/notifications`, `/profile`, `/edit-profile`, `/chat`, `/support-chat`, `/manager`, `/admin`.

Điều hướng theo role sau đăng nhập: `customer → /home`, `manager → /manager`, `admin → /admin` (đọc `profiles.role`).

## 3. Backend Supabase

Nguồn schema chuẩn: `FE/supabase/migrations/` (27+ migration, đặt tên `YYYYMMDDHHMMSS_slug.sql`); `FE/schema.sql` là snapshot để đọc nhanh nhưng **đã cũ hơn 2 bảng** (`vouchers`, `wishlist_items` — cả hai chỉ có trong migrations, không có trong snapshot). Lưu ý drift đã biết: `FE/migrations/` (thư mục cũ, không canonical) còn `20260620_wishlist_items.sql` và file nền tảng SePay — bảng thật đã tồn tại trên project hosted.

### Bảng (nhóm theo domain)

| Nhóm | Bảng | RLS chính |
|---|---|---|
| Identity | `profiles` (role: customer/manager/admin, số đo jsonb) | tự xem/sửa; staff xem all; **cấm tự nâng role** (trigger) |
| Catalog | `categories`, `products`, `product_variants`, `vouchers` | đọc công khai (active); manager quản lý |
| Shopping | `cart`, `cart_items`, `wishlist_items` | chỉ chủ sở hữu |
| Orders | `orders`, `order_items`, `payments`, `refund_requests` | khách thấy đơn mình; staff thấy tất cả; khách tạo refund trên đơn delivered ≤7 ngày, manager decide |
| Social | `reviews` | đọc công khai; ghi qua review gate (mục 4) |
| Comms | `notifications`, `chat_messages` (AI), `support_conversations`, `support_messages` | per-user; support: khách thấy hội thoại của mình, staff thấy inbox |

### Hàm / trigger / RPC đáng chú ý

- `handle_new_user()` — tạo profile khi signup (kèm `full_name` từ metadata).
- `is_manager()` / `is_staff()` — helper cho policy.
- `create_order(...)` — RPC tạo đơn **tính tiền server-side**: đơn giá lấy từ `products` (`coalesce(sale_price, base_price)`) qua variant hiện tại, khoá row `FOR UPDATE` (không tin giá client gửi), voucher validate server-side, tổng = subtotal + phí ship − giảm giá; từ chối quantity ≤ 0, kiểm tra và trừ tồn kho; ghi `orders` + `order_items` + `payments` nguyên tử. Phí ship là tham số từ client (mức phí không phải dữ liệu nhạy cảm).
- `cancel_my_order(uuid)` — khách huỷ đơn khi status ∈ {pending, confirmed}.
- `validate_voucher` + redemption tracking — chống dùng voucher quá lượt.
- `notify_order_update()` — bắn notification khi đổi trạng thái đơn.
- Review gate: `enforce_review_gate()` + `update_product_rating()` (mục 4).
- Support chat: `get_or_create_my_conversation()`, `force_support_message_defaults()`, `bump_support_conversation()`, `mark_conversation_read()`.
- Refund request flow: `decide_refund_request(request_id, decision, note)` — manager RPC nguyên tử: cập nhật request + flip order → `refunded` trên approve (tái sử dụng `on_order_status_change` trigger notify khách) hoặc insert notification reject để khách biết; `orders_set_delivered_at_fn()` + `notify_refund_request_created()` trigger (7-day window RLS-enforced).
- `manager_customer_count` — RPC đếm khách cho dashboard (không lộ bảng profiles).
- Hardening: mọi hàm `SECURITY DEFINER` đã pin `search_path` (migration `harden_secdef_search_path`, `security_hygiene_search_path_and_revokes`); index phục vụ RLS (`rls_perf_fk_indexes`, `rls_perf_wrap_auth_uid`).

### Edge Functions (`FE/supabase/functions/`)

- **`sepay-webhook`** — nhận webhook SePay (xác thực API key), khớp nội dung chuyển khoản → cập nhật `payments.status = paid` + xác nhận đơn. Client không bao giờ tự đánh dấu đã thanh toán.
- **`admin-invite-user`** — admin mời tài khoản manager (service role phía server, client chỉ gọi qua function).

### Storage & Realtime

- Buckets: `products` (public, đã chặn listing), `avatars`, `reviews`.
- Realtime publication: `payments` (chờ xác nhận chuyển khoản — xem `payment_service.dart`), `support_messages`/`support_conversations` (chat 2 chiều + unread badge).

## 4. Các luồng chính

### Auth & phân quyền
1. Đăng nhập: Email OTP · email+password · Google (id token). Signup tạo `profiles` qua trigger.
2. App đọc `profiles.role` → điều hướng `/home`, `/manager` hoặc `/admin`.
3. Client không thể tự đổi role (trigger chặn self-escalation); thao tác đặc quyền (mời manager) đi qua Edge Function.

### Checkout & tiền (money path)
1. Giỏ hàng → `CheckoutBloc` gửi địa chỉ (kèm lat/lng nếu có) + voucher.
2. **`create_order` RPC** tính tiền ở server (đơn giá từ `products` qua variant hiện tại, voucher đã validate, tổng cộng server tự cộng; phí ship là tham số), từ chối quantity ≤ 0 và thiếu tồn kho, trừ kho → trả về đơn + bản ghi `payments`.
3. **COD:** đơn ở `pending`, manager xác nhận dần theo pipeline.
4. **Bank transfer:** màn `payment-qr` sinh QR VietQR (`SEPAY_BANK`/`SEPAY_ACC` + mã đơn) → khách chuyển khoản → SePay gọi `sepay-webhook` → update `payments` → app đang subscribe realtime tự chuyển màn thành công. Có "pay again" cho đơn chưa thanh toán.
5. Trạng thái đơn: `pending → confirmed → shipping → delivered` (+ `cancelled`); mỗi lần đổi bắn notification cho khách.

### Notification badge realtime (lượng thông báo chưa đọc)
- `NotificationService.subscribeToChanges(userId)` mở Supabase realtime channel trên `notifications` filtered `user_id=eq.{id}`.
- Mỗi insert/update trên `notifications` → `NotificationBloc` nhận sự kiện `NotificationRealtimeReceived` → fetch danh sách lại → recalc unread count → home screen bell-icon `Badge` rebuild từ state. Không cần refresh = trải nghiệm live.
- Unsubscribe on sign-out qua `NotificationBloc.unsubscribe()` (app-scoped bloc, call explicit từ `main.dart` auth listener, không rely trên close()).

### Mật khẩu reset (qua email + deep link)
- Khách click "Quên mật khẩu" trên login → `AuthService.sendPasswordReset(email)` → Supabase gửi email + custom link `bigstyle://reset-password?token=...`.
- Khách tap link trên device → app route handler (Android intent-filter) intercept → navigate `/reset-password`.
- App nhận `AuthChangeEvent.passwordRecovery` từ `onAuthStateChange` → route guard chuyển thẳng sang reset screen nếu cần.
- Khách nhập mật khẩu mới → gọi `AuthService.updatePassword(password)` → `auth.updateUser()` từ Supabase.
- Đặt mật khẩu thành công → điều hướng thẳng theo role (`/home`/`/manager`/`/admin`, giống hệt logic routing của login) — session recovery đã là session thật, không cần đăng nhập lại. Huỷ/back giữa chừng (`PopScope` chặn back mặc định) → sign out về `/login`, tránh để lại recovery session dở dang bị coi là đăng nhập hợp lệ ở lần mở app sau.
- Lưu ý: Supabase Auth dashboard cần register redirect URL `bigstyle://reset-password` trong settings (tay, không tự động — không có MCP tool quản Auth redirect-URL allowlist).

### Yêu cầu hoàn tiền (khách → manager)
- Khách xem đơn delivered → nút "Yêu cầu hoàn tiền" (ẩn nếu đã request hay ngoài cửa sổ 7 ngày) → sheet nhập lý do → gọi `RefundRequestService.submit()` → insert row `refund_requests`.
- Server RLS chặn: order phải delivered + `delivered_at >= now() - 7 days` (enforce cả DB + FE ẩn nút).
- Manager dashboard → "Yêu cầu hoàn tiền" badge → xem pending list → tap order → decision sheet (Phê duyệt / Từ chối + note tùy chọn).
- Phê duyệt → `decide_refund_request(request_id, 'approved', ...)` RPC: cập nhật request → flip order → `refunded` (trigger `on_order_status_change` notify khách tự động).
- Từ chối → RPC insert notification reject cho khách luôn (không đổi order status).
- Manager-scoped: `is_manager()` RLS, **không `is_staff()`** (admin excluded).

### Review gate (đánh giá có kiểm chứng)
- Chỉ khách có `order_item` thuộc đơn **delivered** của chính mình mới insert được review (RLS + `enforce_review_gate`).
- `is_verified` do server quyết định (client gửi gì cũng bị ghi đè); `order_item_id`/`product_id` bất biến sau khi tạo ("review provenance is immutable").
- `update_product_rating()` (SECURITY DEFINER) cập nhật `avg_rating`/`review_count` trên `products`.

### Chat hỗ trợ realtime (người ↔ người)
- Khách bấm chat → `get_or_create_my_conversation()` (mỗi khách 1 hội thoại).
- Gửi tin → trigger bump `last_message_at`, preview, unread counter cho phía kia; realtime đẩy tin cho cả 2 đầu; `mark_conversation_read()` xoá badge.
- RLS: khách chỉ thấy/ghi hội thoại của mình; manager/admin thấy inbox toàn bộ. Timestamp do server ép (`force_support_message_defaults`).

### Chat AI
- `chat_service` gọi Claude API (`CLAUDE_API_KEY`), thiếu key → mock trả lời để demo offline; lịch sử lưu `chat_messages` (cột `role`).

### Bản đồ giao hàng
- `delivery-map`: route shop → toạ độ trong `shipping_address` của đơn qua Google Directions; native Maps SDK key riêng trong `android/local.properties`.

## 5. Theme & design system

- Token trong `config/theme/`: primary `#9A3F35` (warm terracotta), nền `#FBF6EF`; Cormorant (heading) + Montserrat (body); radius: card 20 / button 14 / sheet 28.
- Chi tiết token v2: [design-tokens-v2.md](design-tokens-v2.md). Guard CI-style: `FE/scripts/check_hardcoded_colors.sh` chặn hardcode màu ngoài theme.

## 6. Testing & chất lượng

- `FE/test/`: 36 file / 140 test — blocs, services (contract với PostgREST builder), models, screens, widgets, utils (126 baseline + 14 new từ Phase 3/5 refund + realtime + password reset).
- Gate mỗi thay đổi: `flutter analyze` = 0, `flutter test` xanh, color guard = 0.
- Test service dùng fake Supabase query builder (không gọi mạng); xem `FE/test/services/`.

## 7. Bảo mật — tóm tắt posture

- Chỉ `SUPABASE_ANON_KEY` nằm trong app; mọi đặc quyền qua RLS/RPC/Edge Function.
- RLS bật trên toàn bộ bảng nghiệp vụ; staff check qua `is_staff()`/`is_manager()`.
- Tiền và trạng thái thanh toán chỉ đổi từ server (RPC + webhook), không từ client.
- `SECURITY DEFINER` đều pin `search_path`; bucket public đã chặn list; secrets chỉ trong `.env`/`local.properties` (gitignored).
- Còn lại (posture project, đã ghi nhận, ngoài scope): leaked-password protection off, một số hàm SECURITY DEFINER anon-executable theo thiết kế.
