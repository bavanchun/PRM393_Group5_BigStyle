# Brainstorm — Hướng hợp nhất `dev` ↔ `main` (BigStyle PRM393)

Ngày: 2026-07-07 | Nhánh: `sync/merge-main` | Tiếp nối: scout-260707-1714-dev-main-sync-analysis-report.md

## Vấn đề
Merge `dev` (32 commit) + `main` (8 commit nhóm) đã xong trên `sync/merge-main`, `flutter analyze` = 0 error. Cần chọn hướng đưa code hợp nhất về team an toàn, không mất/không vỡ, và tránh tái diễn divergence.

## Phát hiện then chốt
Wishlist (dev) và Favorites (nhóm) **KHÔNG trùng** — `favorites_screen.dart` dùng lại `WishlistBloc` của dev. Vòng lặp add→view chạy được qua: heart ở product detail (dev) → WishlistBloc → màn Favorites (nhóm). Merge mạch lạc.

## Các hướng đã cân nhắc
| Hướng | Ưu | Nhược | Chọn |
|---|---|---|---|
| A. PR `dev`→`main` | Team review, main = nguồn chân lý, đồng bộ 2 chiều | Cần test trước khi merge PR | ✅ |
| B. Merge local vào dev, PR sau | Nhanh, dev đủ code ngay | main vẫn lệch tới khi PR | — |
| C. Merge thẳng main | — | Mất review, dễ đạp nhau | ❌ |

## Phương án thống nhất (trình tự)
1. **Verify runtime**: `flutter run` trên `sync/merge-main`; test login/OTP, danh sách+detail SP, giỏ→checkout, wishlist+Favorites, profile+edit avatar, manager dashboard, admin panel. Lỗi → sửa trên `sync/merge-main`, `dev` vẫn an toàn.
2. **Fast-forward** (chỉ khi B1 pass): `git switch dev && git merge sync/merge-main`.
3. **Push + PR**: `git push origin dev` → PR `dev`→`main`.
4. **DB migrate** (sau cùng): áp 4 migration nhóm (`add_brand_to_manager`, `add_admin_role`, `add_sold_count`, `seed_bigstyle_data`) lên `bigstyle-prm393`; rà `seed_bigstyle_data` vs seed demo dev tránh trùng.

Quyết định phụ: wishlist trên thẻ product-list = **bỏ qua** (KISS) — vòng lặp đã đủ qua detail + Favorites.

## Rủi ro & giảm thiểu
- **Runtime lỗi ẩn** (analyze không bắt): test luồng chính ở B1 trước khi FF.
- **seed_bigstyle_data đụng seed dev**: rà thủ công trước khi chạy (B4).
- **/favorites có lối vào UI?**: bottom nav nhóm trỏ `/orders`, cần xác nhận Favorites reachable khi test B1 — nếu không, thêm entry point (việc nhỏ).

## Tiêu chí thành công
- App chạy, đủ luồng khách + manager + admin, không mất tính năng dev (payment SePay, category, voucher, avatar upload, wishlist).
- `main` sau PR chứa cả code dev + nhóm; team pull về không lệch.
- DB `bigstyle-prm393` có đủ cột brand/admin/sold_count.

## Bước tiếp / phụ thuộc
- B1 phụ thuộc `.env` trỏ đúng `bigstyle-prm393` + emulator/device.
- B4 phụ thuộc B3 merge xong.

## Câu hỏi chưa giải quyết
- Màn Favorites có entry point trên Uch UI chưa (xác nhận lúc test B1)?
- Team có muốn giữ luôn cả `FE/migrations/` (dev) lẫn `FE/supabase/migrations/` (nhóm) hay hợp nhất 1 chuẩn thư mục migration về sau?
