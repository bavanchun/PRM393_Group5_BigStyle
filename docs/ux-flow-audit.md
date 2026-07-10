# BigStyle — UX & Flow Audit

- **Ngày:** 2026-07-03 · **Branch:** dev · **Scope:** AUDIT ONLY (không sửa code).
- **Method:** Visual (emulator `emulator-5554`, Android 15) + Code review (widget/bloc/service/RLS).
- **Coverage:** Guest (code + splash visual), Customer (code + 17 screenshot flow, gồm test SePay thật), Manager (code + 8 screenshot, gồm flip role→manager rồi trả về customer).
- **Findings:** 111 (Guest 20 · Customer 51 · Manager 42 · Cross-cutting bổ sung). Ảnh lưu local `docs/audit-assets/` (gitignored, KHÔNG commit).

## Cách đọc
**Severity:** `P0` chặn nghiệp vụ/mất tiền/crash · `P1` sai chức năng, silent failure · `P2` UX kém · `P3` cosmetic.
**Type:** `flow` · `ui` · `ux` · `dead` (nút/màn chết) · `consistency` (lệch design-system).
**Marker:** ✅ = đã kiểm chứng trực tiếp trên emulator · 🖥 = code-review (chưa dựng được visual).
**Design tokens** (`FE/lib/config/theme/`): superseded 2026-07-10 by the Warm Terracotta v2 palette — see `docs/design-tokens-v2.md` for current values (primary `#9A3F35`, background `#FBF6EF`, radius card20/button14/input14/sheet28/chip24, etc.). The `#C4517A`-family values below are the v1 snapshot this audit was originally written against; findings citing specific v1 hex values below are historical, not current. Mọi `Colors.*` hardcode, `.withOpacity` deprecated, số lẻ = `consistency`.

---

## Actor: Guest

> Visual: chụp được **splash** (`m01`). login/otp cần trạng thái đăng-xuất (hiện đang có session customer thật; đăng xuất sẽ mất session, cần OTP để vào lại) → 🖥 code-review, chưa chụp. User có thể tự mở login để xem.

### splash (`/`)
States: chỉ **loading** (spinner). Thiếu error/timeout.

| # | Type | Sev | Hiện trạng | Đề xuất | Evidence |
|---|------|-----|-----------|---------|----------|
| G1 | flow | **P0** | Guest chưa login **treo splash vĩnh viễn**: `_onCheckSession` khi user==null lại emit `AuthInitial` — trùng props Equatable với state hiện tại → Bloc bỏ qua → `BlocListener` không chạy → không bao giờ điều hướng `/login`. | Dùng state riêng `AuthUnauthenticated`, hoặc điều hướng bằng `await` trong `initState`. | auth_bloc.dart:14,32; splash_screen.dart:24-37 |
| G2 | flow | **P0** | `_onCheckSession` không try/catch → `getCurrentUser()` lỗi (mất mạng/timeout) → không emit state → treo splash vô hạn, không retry. | Bọc try/catch → emit error + UI "Thử lại". | auth_bloc.dart:24-34 |
| G3 | flow | P1 | `Future.delayed(1500ms)` re-arm mỗi lần state đổi → queue nhiều `pushReplacementNamed`. | Điều hướng 1 lần (cờ `_navigated`/`listenWhen`). | splash_screen.dart:26-37 |
| G4 | flow | P1 | Callback delay dùng `context` sau 1500ms không kiểm `mounted` → có thể crash nếu dispose. | Thêm `if (!mounted) return;`. | splash_screen.dart:26-36 |
| G5 | ux | P2 | Không có UI lỗi/timeout, chỉ spinner trắng. | Thêm state error + retry. | splash_screen.dart:82-85 |

### login (`/login`)
States: loading/error(SnackBar)/success/otpSent. Thiếu validate cho "Đăng ký".

| # | Type | Sev | Hiện trạng | Đề xuất | Evidence |
|---|------|-----|-----------|---------|----------|
| G6 | dead | P1 | Logo Google load SVG qua `Image.network` → không decode SVG → **luôn** rơi vào errorBuilder (icon xám); gọi mạng thừa mỗi build. | Dùng asset SVG local (`flutter_svg`) hoặc PNG đóng gói. | login_screen.dart:336-342 |
| G7 | flow | P1 | Link "Đăng ký" chỉ resend OTP (không đăng ký thật) và **bỏ qua im lặng** khi email rỗng; không validate. | Đổi label đúng nghĩa; validate qua `_formKey`, báo lỗi khi rỗng. | login_screen.dart:450-482 |
| G8 | flow | P2 | Validate email chỉ `contains('@')` — chấp nhận `a@`, `@b`. Luồng "Đăng ký" không dùng validator. | Regex email chuẩn cho cả 2 luồng. | login_screen.dart:216-220,469 |
| G9 | flow | P2 | Mock quick-login tạo `mock-*` user **không có session Supabase** → duyệt được nhưng add-to-cart/checkout/review fail → dead-end `/login`. | Ghi rõ giới hạn mock; hoặc chặn action cần auth khi id `mock-`. | login_screen.dart:361-411; auth_bloc.dart:83-101 |
| G10 | ux | P2 | Không cooldown "Gửi mã OTP"/"Gửi lại" → spam → dính rate-limit Supabase mà không biết. | Cooldown 30–60s + đếm ngược. | login_screen.dart:224-246 |
| G11 | ux | P2 | `AuthError` lúc nhập OTP: ô OTP giữ số cũ, user tự xóa từng ô. | Reset ô OTP khi verify fail. | login_screen.dart:59-66,283-289 |
| G12 | consistency | P3 | Nhiều màu hardcode (`0xFFC4517A`,`0xFFF7C0D0`,`0xFFE8E0E2`,`0xFF2D2D2D`…) trùng token. | Thay bằng `AppColors.*`. | login_screen.dart:42,125,205,231,350,433,463 |

### otp_input (inline)
States: chỉ **input**. Không loading/error/clear khi verify.

| # | Type | Sev | Hiện trạng | Đề xuất | Evidence |
|---|------|-----|-----------|---------|----------|
| G13 | ux | P2 | Không backspace lùi ô (chỉ xử lý tiến). | Bắt Backspace → focus + xóa ô trước. | otp_input.dart:88-98 |
| G14 | ux | P2 | Không paste mã 6 số (mỗi ô maxLength 1). | Xử lý value dài >1 → tách điền + auto-submit. | otp_input.dart:42-47,88 |
| G15 | flow | P2 | Sửa ô giữa sau khi đủ 6 số không re-submit (chỉ index==5 gọi onCompleted). | Kiểm "đủ 6 ô" sau mỗi thay đổi. | otp_input.dart:93-97 |
| G16 | ui | P2 | Viền ô không đổi theo focus/nhập (không `setState` khi onChanged/focus). | Thêm listener focus + setState. | otp_input.dart:62-77,88-98 |
| G17 | dead | P3 | Ternary chết `index<6?4:0` (index 0..5 → luôn true). | Bỏ ternary, padding cố định. | otp_input.dart:38 |
| G18 | ux | P3 | Không phản hồi loading khi verify OTP. | Truyền cờ loading xuống ô. | otp_input.dart:42-100 |

**Kết luận Guest:** 2×P0 (splash hang) là rủi ro cao nhất — có thể chặn toàn bộ guest/first-launch. Quyết định giữ mock-login cho demo: nên giữ (đường browse UI) nhưng **đổi label** + chặn rõ action cần auth để không hiểu nhầm là flow thật (G9).

---

## Actor: Customer

> Visual đã đi trọn: home → product_list → product_detail (+size guide) → cart → checkout → **SePay QR → test thanh toán tiền giả → PASS** → orders → order_detail → profile → favorites → chat. Ảnh `c02`–`c17`.

**Xác nhận trực tiếp (✅):** search bar home = nút giả (mở product_list, không nhập được); size-guide sheet **làm rất tốt** (bảng M–5XL, highlight size có hàng); "Cửa hàng" mở **placeholder sheet** "Bản đồ sẽ hiển thị tại đây" (không phải map thật); chat = **BigStyle Bot AI** (chấm online xanh hardcode); mọi mã đơn hiển thị **UUID substring** thay orderNumber; ngày không pad 0 ("3/7/2026").

### home (tab0)
States: loading(shimmer)/loaded/empty-section. Không error.

| # | Type | Sev | Hiện trạng | Đề xuất | Evidence |
|---|------|-----|-----------|---------|----------|
| C1 | ux | P2 | Không error state; `ProductState.error` bị bỏ → lỗi tải hiện "Chưa có sản phẩm" (hiểu nhầm). | Thêm nhánh error + retry. | home_screen.dart:84-92,141-149 |
| C2 | ux | P2 ✅ | Chào "Xin chào!" tĩnh + avatar tĩnh, không dùng tên/avatar user dù có AuthBloc. | Đọc `AuthBloc.state.user` → tên + avatar. | home_screen.dart:206-220 |
| C3 | ui | P3 ✅ | Banner "Giảm đến 30% đơn đầu tiên" hardcode. | Lấy từ config hoặc gỡ %. | home_screen.dart:296-300 |
| C4 | ux | P3 ✅ | Search bar là nút giả (→ /products), không nhập được. | Điều hướng kèm focus ô tìm, hoặc search thật. | home_screen.dart:227-229 |
| C5 | ux | P3 | Chuông thông báo không badge số chưa đọc. | Badge từ `NotificationBloc.unreadCount`. | home_screen.dart:212-215 |

### product_list (tab1)
States: loading/loaded/empty. Có pull-to-refresh.

| # | Type | Sev | Hiện trạng | Đề xuất | Evidence |
|---|------|-----|-----------|---------|----------|
| C6 | flow | P1 | Chip lọc 'Đầm/Áo/Quần' gửi `FilterByCategory(label.lowercase)`; filter so `category.name=='đầm'`/id → tên viết hoa / id là UUID → **lọc ra rỗng**. | Map chip → categoryId thật, so bằng id. | product_list_screen.dart:357-362 |
| C7 | flow | P1 | `category.id` truyền từ home bị bỏ qua; list luôn mở **không lọc**. | Đọc arguments trong `didChangeDependencies` → set filter. | product_list_screen.dart:36-40 |
| C8 | flow | P2 | Chip 'Sale' chỉ `SortProducts('price-asc')`, không lọc sản phẩm sale. | Lọc `p.hasDiscount`. | product_list_screen.dart:369-370 |
| C9 | ux | P3 | Filter chips hardcode, tách rời category thật. | Sinh chip từ `state.categories`. | product_list_screen.dart:29-33 |

### product_detail (+review, editor, size_guide)
States: loading/error(retry)/loaded.

| # | Type | Sev | Hiện trạng | Đề xuất | Evidence |
|---|------|-----|-----------|---------|----------|
| C10 | dead | P2 ✅ | Nút Share `onPressed:(){}` chết (thấy nút, không hoạt động). | Nối share_plus hoặc ẩn. | product_detail_screen.dart:139 |
| C11 | flow | P1 | `_buyNow` với khách: đẩy `/login` rồi VẪN `pushNamed('/cart')` → double-nav. | `_addToCart` trả bool; chỉ push /cart khi thành công. | product_detail_screen.dart:744-745,649-657 |
| C12 | flow | P1 | Chọn size không khớp màu → fallback `variants.first` → **thêm nhầm màu** không báo. | Không có variant khớp size+color → báo hết hàng. | product_detail_screen.dart:686-694 |
| C13 | ux | P3 | Ảnh carousel/review `Image.network` không loadingBuilder. | Thêm loadingBuilder placeholder. | product_detail_screen.dart:272-286 |
| C14 | + | — ✅ | review_section/editor/size_guide xử lý đủ state; **size_guide rất tốt**. Không lỗi chặn. | — | product_review_section.dart:43-64 |

### cart (tab2)
States: loading/empty/list. Không error hiển thị.

| # | Type | Sev | Hiện trạng | Đề xuất | Evidence |
|---|------|-----|-----------|---------|----------|
| C15 | flow | P1 | `CartLoad` **không bao giờ được dispatch** (grep toàn repo) → mở app giỏ DB không hiện; chỉ có item thêm trong phiên. | Dispatch `CartLoad(userId)` lúc khởi động/đăng nhập + khi mở cart. | cart_bloc.dart:10 |
| C16 | flow | P1 ✅ | Sau COD checkout `clearCart` xóa DB nhưng **không phát `CartClear`** → state/badge stale. (Nhánh bank-paid có clear qua `_paidHandled` — đã kiểm: badge biến mất sau khi thanh toán ✅). | Dispatch `CartClear` sau đặt hàng cho **cả COD**. | checkout_bloc.dart:88; payment_bloc.dart:47 |
| C17 | ux | P3 | Tăng số lượng không kiểm tồn kho; ảnh không placeholder khi lỗi. | Kiểm tồn kho variant; errorBuilder ảnh. | cart_screen.dart:142-146,94 |
| C18 | ux | P3 | `state.error` không hiển thị. | Lắng nghe error → snackbar. | cart_screen.dart:21-25 |

### checkout
States: loading/success(dialog)/awaitingPayment(QR)/error.

| # | Type | Sev | Hiện trạng | Đề xuất | Evidence |
|---|------|-----|-----------|---------|----------|
| C19 | ux | P2 | Dialog thành công hiện `orderId.substring(0,8)` (UUID) dù đã có `state.orderNumber`. | Hiện `orderNumber ?? substring`. | checkout_screen.dart:81 |
| C20 | ux | P2 | Guard chặn user `mock-`/rỗng **sau khi** điền hết form → thất bại muộn. | Kiểm đăng nhập khi vào màn / disable nút. | checkout_screen.dart:330-336 |
| C21 | flow | P2 | Phí ship flat `1000đ` hardcode; `CheckoutCalculateShipping` (15k–70k) **không dispatch ở đâu** → 3 mô hình ship phân kỳ. | Thống nhất 1 nguồn phí ship. | checkout_screen.dart:31; checkout_bloc.dart:152-183 |

### payment_qr (SePay) ✅ TEST PASS
States: missing-args/QR/checking/paid(dialog)/error. Watch = Realtime + polling 3s + immediate check.

> **Test thanh toán tiền giả:** đặt đơn bank_transfer `CF-20260703-51CCCE` (21.000đ) → mô phỏng webhook SePay (POST `/functions/v1/sepay-webhook`, `Apikey`, `content=orderNumber`, `transferAmount=21000`) → app **tự** hiện "Thanh toán thành công!" (không cần bấm) → DB: order `confirmed`, payment `success`, paid_at set. **Cơ chế SePay đúng & chắc** (ảnh `c10`,`c11`,`c12`).

| # | Type | Sev | Hiện trạng | Đề xuất | Evidence |
|---|------|-----|-----------|---------|----------|
| C22 | flow | P1 | Không timeout/hết hạn phiên QR; "Quay lại" → đơn bank_transfer pending **không có đường quay lại QR** (xem C24). | Nút "Thanh toán lại" ở orders mở lại QR. | payment_qr_screen.dart:177-184 |
| C23 | ux | P3 | Sau `_paidHandled`, nút "Kiểm tra thanh toán" vẫn bấm được nhưng không phản hồi. | Disable nút sau khi paid. | payment_bloc.dart:59 |
| C24b | flow | P3 | 2 đơn pending cùng số tiền → phân biệt hoàn toàn dựa nội dung CK (des=orderNumber). Chấp nhận được nhưng nên lưu ý. | Giữ orderNumber unique + đối soát amount. | (thiết kế) |

### orders
States: loading/empty/list. Không error, không pull-to-refresh.

| # | Type | Sev | Hiện trạng | Đề xuất | Evidence |
|---|------|-----|-----------|---------|----------|
| C24 | flow | P1 ✅ | Không hủy/mua lại/thanh-toán-lại cho đơn pending → **thấy đơn bank_transfer #bae4dca4 (380k) kẹt "Chờ xác nhận"**, không quay lại QR được. | Thêm hành động theo status (pay-again/cancel/reorder). | orders_screen.dart:58-131 |
| C25 | ux | P2 | Không error state → lỗi tải hiện "Chưa có đơn hàng" sai lệch. | Nhánh `state.error` + retry. | orders_screen.dart:39-56 |
| C26 | ux | P2 | Không pull-to-refresh. | Bọc `RefreshIndicator`. | orders_screen.dart:58 |
| C27 | ux | P3 ✅ | Hiện `order.id.substring(0,8)` thay orderNumber. | Dùng `orderNumber`. | orders_screen.dart:78 |

### order_detail
States: loading OR order==null → spinner. Không error/not-found.

| # | Type | Sev | Hiện trạng | Đề xuất | Evidence |
|---|------|-----|-----------|---------|----------|
| C28 | flow | P1 | `OrderLoadDetail` dispatch trong `build()` (Stateless) → re-fire mỗi rebuild. | Chuyển Stateful + initState. | order_detail_screen.dart:16-17 |
| C29 | flow | P1 | Không error/not-found: `isLoading||order==null` → **xoay vô hạn** khi fail; `selectedOrder` cũ dính từ đơn trước. | Thêm nhánh error; reset selectedOrder khi load. | order_detail_screen.dart:25-27 |
| C30 | consistency | P2 ✅ | Badge trạng thái luôn màu `primary` bất kể status (khác orders dùng `_statusColor`). | Dùng cùng hàm màu theo status. | order_detail_screen.dart:47,53 |
| C31 | ux | P3 ✅ | Mã đơn hiện UUID substring ("EDBC36EB") thay orderNumber. | Dùng `orderNumber`. | order_detail_screen.dart:61 |

### favorites / profile / edit_profile
| # | Type | Sev | Hiện trạng | Đề xuất | Evidence |
|---|------|-----|-----------|---------|----------|
| C32 | dead | P2 ✅ | favorites hoạt động (empty state đẹp ✅) nhưng **không vào được từ Profile** (C34); chỉ qua bottom nav. | Nối menu Profile → /favorites. | favorites_screen.dart:44 |
| C33 | dead | P2 ✅ | Menu "Cửa hàng" mở **placeholder sheet** ("Bản đồ sẽ hiển thị tại đây") thay vì `/delivery-map`. | `onTap` → pushNamed('/delivery-map'). | profile_screen.dart:123-128,196-242 |
| C34 | dead | P2 | Menu "Sản phẩm yêu thích" **không có onTap** → nút chết. | Thêm `onTap → /favorites`. | profile_screen.dart:112-116 |
| C35 | flow | P1 | edit_profile: snackbar "Cập nhật thành công" hiện **vô điều kiện** + pop **trước** khi bloc xác nhận → lỗi update vô hình. | BlocListener chờ success/error rồi mới pop. | edit_profile_screen.dart:136-140 |
| C36 | dead | P2 | Nút camera avatar chỉ là Container trang trí, không nối picker. | Nối image_picker hoặc ẩn. | edit_profile_screen.dart:70-84 |

### notifications / chat / delivery_map
| # | Type | Sev | Hiện trạng | Đề xuất | Evidence |
|---|------|-----|-----------|---------|----------|
| C37 | flow | P2 | `NotificationLoad` dispatch trong `build()` → mark-read rebuild → reload toàn bộ. | Chuyển Stateful, load 1 lần. | notifications_screen.dart:15-19 |
| C38 | ux | P2 | Không "đánh dấu tất cả đã đọc". | Thêm action AppBar. | notifications_screen.dart:23-25 |
| C39 | ux | P2 | Tap notif chỉ mark-read, không điều hướng tới đơn/sản phẩm. | Điều hướng theo `type/refId`. | notifications_screen.dart:87-93 |
| C40 | ux | P2 ✅ | chat = **AI bot** ("BigStyle Bot / Trợ lý thời trang AI"), không phải chat quản lý. | Làm rõ nhãn hoặc bổ sung chat người thật. | chat_screen.dart:121-136 |
| C41 | dead | P2 ✅ | Nút ảnh chat chỉ snackbar "sẽ sớm cập nhật" (mock). | Nối image_picker hoặc ẩn. | chat_screen.dart:432-434 |
| C42 | consistency | P3 ✅ | Chấm "online" xanh hardcode `AppColors.success`. | Bỏ hoặc ràng trạng thái thật. | chat_screen.dart:126-132 |
| C43 | dead | P2 | delivery_map: route `/delivery-map` **không nơi nào điều hướng tới** (grep) → dead code. | Nối từ Profile "Cửa hàng" (C33) hoặc gỡ. | app_router.dart:51-52 |
| C44 | dead | P2 | Nút "Chỉ đường" chỉ snackbar mock, không mở maps. | url_launcher mở maps với toạ độ. | delivery_map_screen.dart:283-290 |
| C45 | consistency | P3 | Bảng phí ship riêng (15k/25k/35k/50k) khác checkout & bloc. | Gộp về nguồn phí ship chung (C21). | delivery_map_screen.dart:269-274 |

### Bloc/service (customer)
| # | Type | Sev | Hiện trạng | Đề xuất | Evidence |
|---|------|-----|-----------|---------|----------|
| C46 | flow | P2 | `createOrder` chèn orders rồi loop chèn từng order_item (không transaction) → lỗi giữa chừng = đơn mồ côi; N+1 write. | RPC/transaction hoặc bulk insert; rollback nếu fail. | order_service.dart:66-77 |
| C47 | ux | P3 | `ProductLoadFeatured` nuốt lỗi bằng `print`+stacktrace. | Emit error state thay vì print. | product_bloc.dart:48-52 |
| C48 | flow | P2 | order item lấy size/color từ `item.variant`; nếu variant null → size/color rỗng lưu vào đơn. | Đảm bảo cart luôn join variant trước khi đặt. | checkout_bloc.dart:42-50 |

---

## Actor: Manager

> Visual: flip `profiles.role`→manager, relaunch → landing `/manager` (session cũ tự đọc role mới). Đã trả role về `customer`. Ảnh `m01`–`m08`.

**Xác nhận trực tiếp (✅):** dashboard tap đơn gần đây → **mở nhầm màn CUSTOMER** (không có nút đổi trạng thái) — đúng M4; product_list AppBar **hồng** + branding **"CurveFit Admin"** — đúng M17/M19; create_product có **màu giả** (Đất nung/Xanh ngọc/Đen + "Thêm màu mới") + **dropdown Danh mục giả** ("Áo Thun") — đúng M23/M26; dashboard "Doanh thu hôm nay 0đ" dù có đơn confirmed hôm nay; "Khách hàng 0" (artifact do flip account customer duy nhất → manager).

### manager_shell / dashboard
| # | Type | Sev | Hiện trạng | Đề xuất | Evidence |
|---|------|-----|-----------|---------|----------|
| M1 | dead | P3 | `_PlaceholderScreen` khai báo không dùng. | Xóa hoặc dùng cho tab chưa xong. | manager_shell.dart:108-138 |
| M2 | consistency | P3 | Profile dùng `Colors.grey` cho email thay token. | `AppColors.textSecondary`. | manager_shell.dart:79 |
| M3 | ux | P3 | "Đăng xuất" không xác nhận. | Dialog confirm trước SignOut. | manager_shell.dart:88-90 |
| M4 | flow | P2 ✅ | Tap đơn gần đây mở `/order-detail` → **màn CUSTOMER** (không nút đổi trạng thái), không phải ManagerOrderDetailScreen. | Push `ManagerOrderDetailScreen(order)`. | manager_dashboard.dart:121-123; app_router.dart:41-42 |
| M5 | dead | P2 ✅ | 3 Quick Action ("Thêm SP","Danh mục","Khuyến mãi") đều coming-soon dù create SP đã có thật. | Nối "Thêm SP"→create; ẩn 2 nút chưa có. | manager_dashboard_widgets.dart:125-144 |
| M6 | consistency | P3 | Thẻ "Đơn chờ xác nhận" dùng màu `success` (xanh) cho pending. | Dùng `AppColors.warning`. | manager_dashboard_widgets.dart:33 |
| M6b | flow | P2 ✅ | **"Doanh thu hôm nay" = 0đ** dù có đơn confirmed hôm nay (21k + 380k). Nghi query doanh thu sai điều kiện (status/paid/ngày). | Rà lại query doanh thu; đối chiếu confirmed+paid theo ngày. | manager_dashboard.dart (cần xác minh) |

### manager_orders ⚠️
States: loading/error(retry)/empty/data + filter chips. **Quan sát bất thường (P1, cần xác minh).**

| # | Type | Sev | Hiện trạng | Đề xuất | Evidence |
|---|------|-----|-----------|---------|----------|
| M7 | flow | **P1** | Cập nhật trạng thái lỗi chỉ hiện khi `orders.isEmpty` → list có data thì `state.error` **bị nuốt** = cập nhật thất bại IM LẶNG. | `BlocListener` bắt error sau `isUpdatingStatus` bất kể list rỗng. | manager_orders_screen.dart:83-99; manager_bloc.dart:94-101 |
| M7b | flow/ui | **P1 ✅ cần xác minh** | **Tab Đơn hàng render trống hoàn toàn** — không card, không "Không có đơn hàng", không spinner — ở cả "Tất cả" + "Chờ xác nhận" + sau pull-to-refresh, DÙ dashboard liệt kê 3 đơn & products tab load bình thường (⇒ không phải RLS/session). Theo code lẽ ra phải hiện empty text → nghi `state.orders` non-empty nhưng `ManagerOrderCard` render rỗng, HOẶC race load (M40) do IndexedStack init sớm. **Chặn toàn bộ workflow đổi trạng thái qua tab này.** | Repro + log `state.orders` khi vào tab; kiểm ManagerOrderCard + thứ tự dispatch load dashboard vs orders. | manager_orders_screen.dart:23-26,79-104; ảnh m04,m05,m06 |
| M8 | ux | P3 | Filter chips không đếm badge; không cuộn về đầu khi đổi. | Minor. | manager_orders_screen.dart:52-77 |

### manager_order_detail / order_status_update_sheet
> 🖥 Không dựng được visual (không tới được list — M7b). Code-review:

| # | Type | Sev | Hiện trạng | Đề xuất | Evidence |
|---|------|-----|-----------|---------|----------|
| M9 | flow | P1 | Sau update, màn giữ `widget.order` bất biến → badge/nút **stale**. | `BlocBuilder<ManagerBloc>` lấy order mới nhất theo id, hoặc pop. | manager_order_detail_screen.dart:99,263-272 |
| M10 | flow | P2 | Query `payments` trực tiếp `Supabase.instance` trong widget (bypass service/bloc), trùng sheet. | Đưa vào `OrderService.getLatestPayment`. | manager_order_detail_screen.dart:35-52 |
| M11 | flow | P3 | Fetch payment lỗi → `catch(_)` hiện "Chưa xác định", không phân biệt lỗi vs không có. | State lỗi payment riêng + retry. | manager_order_detail_screen.dart:48-51 |
| M12 | ui | P3 | Ngày `${d}/${m}/${y}` không pad 0. | `DateFormat('dd/MM/yyyy')`. | manager_order_detail_screen.dart:148 |
| M13 | flow | P1 | Sheet `_confirm` dispatch rồi `pop()` ngay (không await/listener) → bloc emit error thì **không nơi hiển thị** (kết hợp M7 = thất bại hoàn toàn im lặng). | Giữ sheet + loading tới khi bloc xong; báo lỗi trước khi pop. | order_status_update_sheet.dart:84-89 |
| M14 | ux | P2 | Không xác nhận khi chọn `cancelled`/`refunded` (phá hủy 1 chạm). | Confirm dialog cho huỷ/hoàn. | order_status_update_sheet.dart:149-169 |
| M15 | flow | P2 | Query `payments` trực tiếp, trùng M10. | Tách service dùng chung. | order_status_update_sheet.dart:61-82 |

### product_list (manager)
| # | Type | Sev | Hiện trạng | Đề xuất | Evidence |
|---|------|-----|-----------|---------|----------|
| M16 | flow | P2 | `ManagerProductError` → builder để `products=[]` → hiện "Không tìm thấy" y như rỗng thật; lỗi chỉ chớp snackbar. | Nhánh error + retry trong builder. | manager_product_list_screen.dart:93-101,285-299 |
| M17 | consistency | P2 ✅ | Branding **"CurveFit Admin"** — sai tên app (BigStyle). | Đổi "BigStyle" / "Quản trị BigStyle". | manager_product_list_screen.dart:56 |
| M18 | dead | P2 ✅ | Hamburger no-op; 2 chevron phân trang no-op; footer "Hiển thị 15/15" phân trang giả. | Ẩn hoặc cài phân trang thật. | manager_product_list_screen.dart:48-51,474-486 |
| M19 | consistency | P1 ✅ | AppBar **hồng** (`primary`) trong khi mọi màn manager khác trắng (`surface`). | AppBar về surface trắng. | manager_product_list_screen.dart:46 |
| M20 | consistency | P2 | `.withOpacity` deprecated + `Colors.green/grey/black/white` hardcode lẫn token. | `.withValues(alpha:)` + token. | :142,198,231,321,395-420 |
| M21 | ui | P3 | Ảnh fallback `via.placeholder.com/150` (URL ngoài, dễ chết). | Asset nội bộ. | manager_product_list_screen.dart:352 |

### create_product / product_detail (edit)
| # | Type | Sev | Hiện trạng | Đề xuất | Evidence |
|---|------|-----|-----------|---------|----------|
| M23 | flow | P1 ✅ | Dropdown "Danh mục" chọn `_selectedCategory` nhưng **không gán vào ProductModel** → sản phẩm luôn không phân loại. | Map tên→categoryId, set vào model. | manager_create_product_screen.dart:28,543-545 |
| M24 | flow | P2 | `_saveProduct` không set `_isSaving` → không spinner; bấm Lưu nhiều lần → tạo trùng. | Set `_isSaving=true` + disable nút. | manager_create_product_screen.dart:145-194,723 |
| M25 | flow | P2 | Success message 'Tạo sản phẩm thành công!' nhưng listener match `contains('Thêm')||'tạo'` — **'Tạo' hoa không khớp** → màn không tự đóng sau tạo. | Dùng state/flag success, đừng match chuỗi VN. | manager_create_product_screen.dart:266-269 |
| M26 | dead | P2 ✅ | Swatch màu không lưu; `colorHex` hardcode `#914B34` mọi variant; "+ Thêm màu mới" coming-soon. | Nối colorHex thật vào từng variant hoặc bỏ. | :34,160,486-504,759-792 |
| M27 | ux | P2 | Validator giá chỉ `tryParse` → chấp nhận giá ≤0. | Kiểm `>0`. | manager_create_product_screen.dart:526 |
| M28 | ui | P2 | Ảnh mặc định URL Google `lh3...` hardcode. | Asset nội bộ / bắt buộc ≥1 ảnh. | manager_create_product_screen.dart:176-178 |
| M30 | ux | P3 | Cho phép tạo SP không variant nào. | Bắt buộc ≥1 variant hợp lệ. | manager_create_product_screen.dart:148-171 |
| M31 | flow | P2 | Sau XÓA, message 'Đã xóa...' không chứa 'Xóa' (hoa) → listener không pop; màn vẫn hiện SP đã xóa. | State/flag success cho delete rồi pop. | manager_product_detail_screen.dart:334-337 |
| M32 | flow | P1 | Sửa "Danh mục" khi edit không lưu (update dùng `widget.product.category`). | Map selection→categoryId khi build updatedProduct. | manager_product_detail_screen.dart:598-615,218-219 |
| M33 | ux | P2 | `_isDirty()` **luôn true** → dialog "Hủy thay đổi" luôn hiện dù không sửa. | So sánh thật với `widget.product`. | manager_product_detail_screen.dart:124-126 |
| M34 | consistency | P2 | ~90% code trùng create↔edit (~965/1033 dòng). | Tách `ProductFormBody` + widgets dùng chung. | (toàn 2 file) |
| M37 | ui | P2 | 2 ảnh fallback khác nhau (Google vs via.placeholder) giữa create/edit. | Dùng chung asset nội bộ. | manager_product_detail_screen.dart:208 |

### routing / role-guard
| # | Type | Sev | Hiện trạng | Đề xuất | Evidence |
|---|------|-----|-----------|---------|----------|
| M38 | flow | P2 | **Không có client role-guard**: `generateRoute` switch thuần, mọi route ai gọi cũng vào; chỉ redirect landing bảo vệ ngầm. **NHƯNG RLS Supabase là lớp bảo vệ thật (đã xác minh — xem Cross-cutting), nên KHÔNG phải P0.** Vẫn nên guard để UX/defense-in-depth. | Role check trong `generateRoute` → màn "không có quyền" nếu lệch. | app_router.dart:20-64 |
| M39 | flow | P2 | `ManagerBloc`+`ManagerProductBloc` provide ở gốc → sống suốt phiên khách (tốn tài nguyên, giữ data admin trong bộ nhớ). | Scope 2 bloc dưới `ManagerShell` hoặc lazy. | main.dart:66,75 |
| M40 | flow | P3 | `_onUpdateOrderStatus` dùng chung `_ordersRequestId` với `_onLoadOrders` → đổi filter đúng lúc update có thể huỷ lẫn nhau. (Nghi liên quan M7b.) | RequestId riêng cho update; transformer droppable. | manager_bloc.dart:82-86 |

**Điểm tốt (manager):** ManagerBloc có request-id chống race cho load dashboard/orders; sheet cảnh báo "đơn CK chưa thanh toán" trước khi xác nhận thủ công — thiết kế nghiệp vụ hợp lý.

---

## Cross-cutting

| # | Dimension | Sev | Hiện trạng | Đề xuất | Evidence |
|---|-----------|-----|-----------|---------|----------|
| X1 | RLS/security | — ✅ | **Đã xác minh:** RLS bật trên mọi bảng; `orders/payments/order_items` có policy "Managers manage all" (`is_manager()`) + "Users see own" (`auth.uid()`); `products/variants` "Anyone view" (products chỉ `is_active=true`). ⇒ Thiếu client role-guard (M38) **không phải lỗ hổng dữ liệu**; RLS chặn thật. | Giữ RLS; thêm client guard chỉ để UX. | pg_policies |
| X2 | orderNumber vs UUID | P2 | Khắp app hiển thị `id.substring(0,8)` thay `orderNumber` (checkout C19, orders C27, order_detail C31, manager dashboard dùng DH-<uuid>). | Chuẩn hoá dùng `orderNumber` mọi nơi. | (nhiều màn) |
| X3 | shipping | P2 | 3 mô hình phí ship phân kỳ (checkout flat 1000đ / CheckoutBloc distance 15–70k / delivery_map bảng khác); chỉ flat dùng. | Chốt 1 nguồn; xoá code chết còn lại. | C21,C45 |
| X4 | bloc-in-build | P1 | Nhiều màn dispatch load trong `build()` (order_detail C28, notifications C37) → re-fire liên tục. | Chuyển Stateful, load 1 lần. | C28,C37 |
| X5 | error/empty state | P1 | Lỗi tải bị đánh đồng với "rỗng" ở nhiều màn (home, cart, orders, manager product_list, manager orders) → user không phân biệt được. | Thêm nhánh error + retry chuẩn hoá. | C1,C18,C25,M16,M7b |
| X6 | design-system | P2 | Nhóm màn manager product lệch nặng (AppBar hồng, CurveFit, Colors.* hardcode, .withOpacity) so với phần còn lại. | Chuẩn hoá về token + AppBar trắng. | M17,M19,M20 |
| X7 | dead code/nút chết | P2 | ≥10 nút/màn chết: Share, camera avatar, "Sản phẩm yêu thích", "Cửa hàng"→placeholder, "Chỉ đường", delivery_map, hamburger, chevron phân trang, "Thêm màu mới", quick actions. | Nối chức năng hoặc ẩn để không hứa hão. | (rải rác) |
| X8 | data test | — | Còn nhiều đơn test (bae4dca4 pending 380k, 4d9a08a3, edbc36eb…) + giá test 10k/ship 1k. | Dọn trước khi bàn giao/demo thật. | orders |

---

## Top Priorities (sửa trước → sau)

| Ưu tiên | Mục | Vấn đề | Ghi chú |
|---------|-----|--------|---------|
| **P0** | splash (G1,G2) | Guest/first-launch **treo splash vĩnh viễn** (Equatable dedupe + không try/catch) | Chặn vào app — sửa đầu tiên |
| **P1** | manager orders (M7b) | **Tab Đơn hàng render trống** → không quản lý/đổi trạng thái đơn được | ✅ quan sát trực tiếp — cần repro & fix gấp |
| **P1** | status update (M7+M13+M9) | Chuỗi đổi trạng thái **thất bại im lặng** + không refresh | Rủi ro nghiệp vụ cao |
| **P1** | cart (C15,C16) | `CartLoad` không dispatch; COD không `CartClear` → giỏ/badge sai | |
| **P1** | product category (M23,M32) | Dropdown danh mục không lưu → **dữ liệu sản phẩm sai** | |
| **P1** | pending order recovery (C24,C22) | Đơn bank_transfer pending **kẹt**, không thanh toán lại | ✅ thấy đơn kẹt thật |
| **P1** | edit_profile (C35) | Báo "thành công" vô điều kiện → lỗi update vô hình | |
| **P1** | product_detail (C11,C12) | Double-nav "Mua ngay" + fallback nhầm màu | |
| **P1** | order_detail (C28,C29) | Load trong build + xoay vô hạn khi lỗi | |
| **P1** | product_list filter (C6,C7) | Lọc theo label/không nhận categoryId → lọc rỗng | |
| **P2** | design-system (M17,M19,X6) | AppBar hồng + "CurveFit Admin" | ✅ visual |
| **P2** | dead code (X7) | ≥10 nút/màn chết | |
| **P2** | orderNumber (X2), shipping (X3) | UUID thay orderNumber; 3 mô hình ship | |
| **P2** | role-guard (M38) | Thiếu client guard (RLS đã chặn data ✅) | Defense-in-depth |
| **P3** | cosmetic | date pad0, banner hardcode, chấm online, giá "150000.0"… | Polish cuối |

---

## Unresolved Questions

1. **M7b (tab Đơn hàng trống):** cần user xác nhận có phải bug thật trên máy user không, hay do tương tác flip-role giữa phiên. Ưu tiên repro.
2. **M6b (doanh thu 0đ):** query doanh thu tính theo status/paid/ngày nào? Cần xác minh.
3. Phí ship chốt mô hình nào (flat 1000đ hiện là giá test)? (C21/X3)
4. "Hỗ trợ & Chat" kỳ vọng AI bot hay chat quản lý thật? (C40)
5. Manager account: hiện tạo bằng cách flip `profiles.role` account customer duy nhất rồi trả về. Nếu cần manager cố định để demo → nên tạo tài khoản riêng (email khác) — nhưng login OTP cần inbox email đó.
