# Brainstorm Report — Skill Pipeline cho Big Plan Lột Xác UI/UX BigStyle

- **Date:** 2026-07-10 · **Branch:** dev · **Mode:** brainstorm (no flags)
- **Requester intent:** dùng /find-skills phân tích bộ skill phục vụ nhận diện + audit cho big plan update toàn bộ UI/UX, "lột xác hoàn toàn", chất lượng cao nhất.

## Problem Statement

App Flutter + Supabase (BLoC), ~141 file Dart, 44+ screens / 4 role (customer, manager 17 màn, admin, delivery). Design system mỏng (`FE/lib/config/theme/` 301 dòng), ~208 chỗ hardcode màu bypass token, chỉ 10 shared widgets. Đã có `docs/ux-flow-audit.md` (03/07, 111 findings P0–P3, flow/function-focused) — nhưng chưa có *design-language audit* trả lời "app nên trông thế nào". Cần pipeline audit chất lượng làm nền cho big plan reskin.

## User Decisions (chốt trong session)

| Quyết định | Lựa chọn |
|---|---|
| Phạm vi lột xác | **Visual reskin, giữ nguyên flow/navigation** (flow đã ổn định qua 10 plan fix) |
| Nguồn brand identity | **AI đề xuất 2–3 direction mới**, user duyệt 1 (hiện tại: hồng #C4517A / nền #FDF8F9) |
| Role coverage | **Toàn bộ 4 role** (customer, manager, admin, delivery) |
| Phương pháp audit | **Visual (emulator screenshot) + code**, kỹ nhất |
| Thứ tự pipeline | **B: Direction trước → audit thành gap-analysis** (screenshot chụp sớm vì không phụ thuộc direction) |

## Evaluated Approaches

- **A. Audit hiện trạng trước, direction sau** — rejected: audit không đích ra findings chung chung, lặp giá trị 111 findings cũ.
- **B. Direction trước, audit = gap-analysis so với đích** — **chosen**: mỗi finding là việc làm được trong plan; ai-multimodal chấm ảnh hiệu quả hơn khi có chuẩn so sánh; đúng tinh thần lột xác. Trade-off: đổi direction giữa chừng phải chấm lại gap.
- **C. Song song rồi merge** — rejected: tiết kiệm ít, điều phối phức tạp. Tinh chỉnh lấy từ C: bước chụp screenshot chạy sớm song song.

## Skill Routing (kết quả /find-skills, domain-routing)

**Bẫy cần tránh:** phần lớn skill UI trong catalog là web-first, KHÔNG áp trực tiếp cho Flutter: `frontend-design`, `ui-styling` (shadcn/Tailwind), `web-design-guidelines`, `frontend-development`, `react-best-practices`. `stitch` export Tailwind/HTML → chỉ dùng làm visual reference.

**Pipeline chốt:**

| Bước | Skill | Sản phẩm |
|---|---|---|
| 1. Inventory | `ck:scout` (mở rộng scout đã làm) | Bản đồ 44 màn × widget × nợ hardcode per screen |
| 2. Capture | emulator + adb screenshot (chạy sớm, song song) | Ảnh toàn bộ màn, 4 role, lưu `docs/audit-assets/` (gitignored) |
| 3. Direction | `ck:design` + `ck:ui-ux-pro-max` (+ `ck:stitch`/`ck:ai-artist` concept tham khảo) | 2–3 hướng identity (palette, typography, component style, motion) → user chọn 1 → **design tokens v2** |
| 4. Gap audit | `ck:ai-multimodal` (Gemini vision chấm ảnh) + `ck:ui-ux-pro-max` (design-system review, cover Flutter) | Gap-analysis từng màn vs direction; cross-ref 111 findings cũ (đánh dấu consistency items được absorb) |
| 5. Phản biện | `ck:predict` | 5 persona debate rủi ro trước khi cam kết |
| 6. Big plan | `ck:plan` | Phase: tokens v2 → shared components → migrate theo cụm màn → QA |
| QA lưới | `ck:scenario` + `ck:test` | Regression net cho 44 màn × 4 role |

Skill phụ khi implement: `ck:mobile-development` (Flutter patterns), `ck:preview`/`ck:tech-graph` (trình bày). Không áp dụng: `agent-browser` (mobile, không phải browser).

## Implementation Considerations & Risks

- **Kế thừa, không lặp:** audit mới chỉ làm design-language gap; 111 findings cũ giữ nguyên vai trò flow/bug backlog. Consistency P3 cũ sẽ được absorb vào migration checklist.
- **Regression risk:** reskin giữ flow nhưng đụng 44 màn — bắt buộc có scenario net trước khi migrate hàng loạt.
- **Screenshot phụ thuộc emulator hoạt động** + session per role (manager cần flip role; guest cần logout → mất session, cần OTP — đã ghi nhận từ audit cũ).
- **Hardcode debt 208 chỗ** = migration phải đi kèm lint/guard (cấm `Colors.*` mới) để không tái nợ.
- **Direction lock:** đổi direction sau bước 4 → chấm lại gap. Chốt kỹ ở bước 3.

## Success Metrics

- Design tokens v2 được duyệt, có file spec.
- Gap-analysis cover 100% màn của 4 role, mỗi finding gắn effort + màn + token/component liên quan.
- 0 hardcode màu mới sau migrate (guard bằng lint/grep gate).
- Big plan chia phase thực thi độc lập, mỗi phase có QA scenario.

## Next Steps

1. Handoff sang `/ck:plan` với report này làm context — plan hoá 6 bước pipeline (bước 1–4 là "audit plan", bước 6 là big plan riêng sau khi audit xong).
2. Chuẩn bị emulator + account 4 role cho bước capture.

## Unresolved Questions

- Concept visual bước 3 dùng `ck:stitch` (UI mock) hay `ck:ai-artist` (moodboard) hay cả hai — quyết khi chạy, tuỳ chất lượng output.
- Delivery role chỉ 1 màn — có đáng redesign riêng hay gộp vào cụm manager.
- Motion/animation scope (GSAP không áp dụng cho Flutter; dùng implicit animations Flutter) — mức đầu tư quyết trong bước direction.
