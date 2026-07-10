# Đánh giá UI/UX hiện tại — BigStyle (post-reskin)

- **Ngày:** 2026-07-10 · **Branch:** `dev` @ `fab9a26` · **Type:** brainstorm/assessment
- **Nguồn:** QA emulator audit hôm nay (`qa-260710-1827-post-reskin-full-app-emulator-audit-report.md`) + đối chiếu 111 findings `docs/ux-flow-audit.md` (03/07, pre-reskin) bằng code-verification + screenshots live cả 3 role.
- **Mục đích:** chọn đợt fix tiếp theo.

---

## Verdict tổng

**App đã vượt qua giai đoạn "nhiều lỗi chặn nghiệp vụ" → giai đoạn "polish".** Audit 03/07 có 2×P0 + ~12 cụm P1; hiện tại **0 P0, 0 P1 flow-breaker còn sống**. Nợ còn lại là 1 lỗi trình bày diện rộng (giá tiền), 1 lỗi tiềm ẩn (Hero tag), và các cụm polish (OTP UX, consistency manager).

Điểm theo dimension (thang 5, đánh giá thực trạng, không nể nang):

| Dimension | Điểm | Căn cứ |
|---|---|---|
| Design system / visual | **4.5** | Tokens v2 phủ 100% (hardcode 206→0, guard script), palette WCAG pre-verified, Cormorant/Montserrat render đúng diacritics. Trừ: stat-card manager lệch token, AppBar 2 kiểu. |
| Core flows (mua hàng, quản lý đơn) | **4** | Checkout/SePay/status-update đã QA live pass; orderNumber thật; pay-again cho đơn pending; category lưu đúng. Trừ: giá `10000đ` không phân cách — ngay tại điểm ra quyết định mua. |
| Error handling / feedback | **3.5** | `AppErrorState` chuẩn hoá ở 5 màn customer (home/list/cart/orders/notifications) + bloc tests chống silent-fail manager. Trừ: manager product list chưa dùng (M16), OTP không loading feedback. |
| Auth / onboarding | **2.5** | **Yếu nhất còn lại.** Chức năng chạy nhưng friction cao: OTP không paste được (G14), không backspace lùi ô (G13), không cooldown resend (G10), không loading khi verify (G18), lỗi giữ số cũ (G11), email validate chỉ `contains('@')` (G8 — xác minh code hôm nay, vẫn thế). |
| Navigation integrity | **4** | Nút chết cũ đã nối gần hết (share, favorites, cửa hàng→map, quick actions, camera avatar). Trừ: Hero collision 5 FAB (assertion thật trong log), map tiles chờ API key (external). |
| Nhất quán role/copy | **3.5** | "CurveFit Admin" đã thành "BigStyle" nhưng badge "Quản trị" hiện với manager (sai nghĩa role); pending stat màu success-xanh (M6 — vẫn trong code `manager_dashboard_widgets.dart:33`). |

---

## Đối chiếu 111 findings cũ — trạng thái hiện tại

**Đã fix & xác minh (code/test/live) — ~45 findings có ý nghĩa, gồm TẤT CẢ P0 và gần hết P1:**
- Splash G1–G4 (AuthUnauthenticated + try/catch + `_navigated` + mounted — xác minh code; cold-start no-session hôm nay vào login ngon)
- Cart C15/C16-bank (CartLoad dispatch ở main.dart + cart screen; CartClear ở payment_qr)
- Filter C6/C7 (map label→categoryId thật, đọc route arguments)
- Product detail C10/C11/C12 (share_plus thật; buy-now guard bool; hết fallback variants.first)
- Orders C22/C24/C27/C28/C29/C30/C31 + X2 (pay-again mở lại QR; StatefulWidget+initState; error branch; StatusBadge theo status; DH-CF-orderNumber mọi nơi)
- Profile C32/C33/C34/C35/C36 (favorites nav + test; cửa hàng→map; ImagePicker thật; BlocListener guarded)
- Notifications C37 (initState), X5/C1/C18/C25 (AppErrorState 5 màn)
- Manager M4/M5/M6b/M7b/M7/M13/M14/M17/M19/M20/M23/M26/M32 (route đúng ManagerOrderDetail; quick actions thật + voucher manager mới; revenue có test; orders tab render + status update QA live pass; cancel có dialog + reason; branding BigStyle; AppBar surface; token sạch; categoryId lưu ở cả create/edit; swatch màu thật per-variant + RPC preserve test)
- Hạ tầng: create_order RPC (C46), shipping thống nhất (#13 — C21/C45/X3), RLS verified + trigger chặn self-escalate role (X1), orders.updated_at trigger, customer-name denormalization, dashboard refresh race fix

**Còn sống (xác minh lại hôm nay):**

| Nhóm | Findings | Sev đề xuất |
|---|---|---|
| **Giá tiền không phân cách nghìn** | MỚI (QA hôm nay) — 16 call sites `toStringAsFixed(0)đ` / 12 files, phủ product card→detail→cart→checkout→orders→delivery. Chỉ 2 file manager dùng `NumberFormat` | **P1** (trust + readability tại funnel mua) |
| **Hero tag collision** | MỚI — 5 FAB không `heroTag` (2 admin cùng sống trong IndexedStack → assertion thật; 3 manager rủi ro khi push route) | **P1** (latent crash-class) |
| **Cụm OTP/auth UX** | G8, G10, G11, G13–G16, G18 — nguyên trạng, chưa đợt fix nào đụng | **P2 cụm** (friction cao nhất còn lại, đường vào app) |
| **Manager consistency** | M6 (pending=success xanh — vẫn ở `manager_dashboard_widgets.dart:33`) + MỚI: stat-card serif/tinted/caption-hint lệch hẳn Admin cùng pattern | **P2** |
| Manager error conflation | M16 — AppErrorState chưa phủ manager product list | P2 |
| Notifications depth | C38 (mark-all-read), C39 (tap không deep-link tới đơn/SP), C5 (bell không badge — thấy live hôm nay) | P2/P3 |
| Copy/role | MỚI: badge "Quản trị" hiện với manager; C2 greeting "Xin chào!" tĩnh (thấy live); C3 banner 30% hardcode | P3 |
| Arch/hygiene | M38 (client role-guard — RLS đã chặn data), M39 (ManagerBloc root-scope — xác minh main.dart:118,132), M34 (duplication create/edit còn dù đã tách variants table + swatches), M12 (date pad 0), M21/M28/M37 (ảnh fallback URL ngoài) | P3 |
| Chat/labeling | C40 (AI bot labeling), C41 (nút ảnh chat mock) — chưa xác minh lại | P3? |
| Ops | X8: đơn test (DH-CF 40k/21k/11k, giá 10k) còn trong DB prod-demo; Maps API key chưa provision (external) | ops |

---

## Đề xuất đợt fix tiếp theo (theo ROI)

**Batch 1 — "1 ngày, đóng cả 2 High + Medium của QA report":**
1. Helper format tiền tệ chung (tái dùng `NumberFormat('#,###','vi_VN')` cạnh `formatOrderCurrency` trong `order_model.dart`) → thay 16 call sites. Nửa ngày, impact lớn nhất/effort.
2. `heroTag` unique cho 5 FAB. ~15'.
3. Manager stat-card: value về bold `textPrimary`, label về `textSecondary` (khớp Admin), pending đổi `success`→`warning` (đóng luôn M6). ~30'.

**Batch 2 — "ngày auth funnel" (đóng cụm friction lớn nhất):**
4. OTP input: paste 6 số, backspace lùi ô, border focus, loading khi verify, reset khi fail (G11/G13–G16/G18).
5. Resend cooldown 30–60s + đếm ngược (G10); email regex chuẩn (G8).

**Batch 3 — polish chọn lọc (làm khi rảnh, không chặn demo):**
6. AppErrorState cho manager product list (M16); notifications mark-all + deep-link (C38/C39) + bell badge (C5).
7. Copy: bỏ/sửa badge "Quản trị", greeting theo tên user (C2), quyết định AppBar 1 kiểu/shell.

**Ops trước demo:** dọn đơn/giá test (X8); provision Maps key (blocker external, ngoài code).

**Không đề xuất làm:** M38 client role-guard (RLS đã chặn thật, YAGNI cho demo course); M34 refactor tiếp (đã giảm, còn lại là nợ chấp nhận được); M39 (tối ưu memory chưa cần).

---

## Unresolved Questions
1. AppBar gradient (Admin) vs plain (Manager) — chủ đích phân biệt role hay vô tình? Quyết định trước khi "fix" consistency.
2. C40: chat giữ AI-bot hay cần chat người thật? (ảnh hưởng labeling)
3. Đơn test trong DB: dọn ngay hay giữ làm data demo môn học?
