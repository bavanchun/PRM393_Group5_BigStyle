# PM Status Report — BigStyle (2026-07-12 16:35)

## Snapshot

- Repo: `PRM393_Group5_BigStyle`, branch `dev`, sync với `origin/dev` (0 unpushed commit; chỉ dư `.claude/` untracked).
- Latest merged: #33 Flagship UX-depth customer flow, #32 AI chat persistence fix, #24–#31 full-app improvement (money path, RLS, security hygiene, pricing).
- Test/health tại lần verify gần nhất: `flutter analyze` 0, `flutter test` 104 green, hardcode-color guard 0.

## Plan Inventory (17 plans)

| Plan | Status | Note |
|------|--------|------|
| 260620 p0-p3-bugfixes | completed | — |
| 260703 role-based-ux-audit | completed | checkboxes chưa sync (0/26) |
| 260703 demo-fix-roadmap | **partial** | chờ Phase 5 của review-gate plan absorb nốt seed items |
| 260703 manager-category-mgmt | completed | checkboxes chưa sync |
| 260703 app-feature-gap-closure | completed | checkboxes chưa sync |
| 260709 git-branch-cleanup | completed | 18/18 |
| 260709 stability-hardening | completed | 64/65 |
| 260709 remote-data-testability | completed | checkboxes chưa sync (6/33) |
| 260710 role-ops-hardening | completed | 40/41 |
| 260710 qa-findings-fix | completed | 23/24 |
| 260710 ui-ux-overhaul-audit | completed | 33/33 |
| 260710 visual-reskin | completed (merged to dev) | checkboxes chưa sync (7/73) |
| 260710 post-audit-ui-ux-batches | done | checkboxes chưa sync |
| **260710 review-gate-map-chat-hardening** | **in-progress** | duy nhất còn dở — xem dưới |
| 260711 full-app-improvement | completed | 22/34 (phần còn lại là verify items) |
| 260711 ai-chat-persistence-fix | completed | 15/15 |
| 260711 flagship-ux-depth | completed | 33/34 |

## Việc còn lại duy nhất: review-gate-map-chat-hardening Phase 5

Phases 1,2,3,4,6 done (PR #17–#21 merged). Phase 5: **DB pass done** (migrations applied, gate/chat triggers verified live 2026-07-11); **device pass pending — 32 items unchecked**, nhóm chính:

1. Seed/cleanup data: ≥2 customer profiles, orders confirmed/delivered hôm nay, xoá test-junk (cần user confirm từng row), seed shipping order có lat/lng.
2. Review gate probes: REST insert/patch với non-purchaser, forged order_item_id, is_verified spoof, avg_rating trigger.
3. Map: route shop→đúng toạ độ order, recenter không re-anchor GPS.
4. Human chat: realtime 2 chiều, unread badge, RLS/realtime leak probes.
5. Auth: đăng ký/đăng nhập password, duplicate-email, manager redirect.
6. Smoke: full purchase COD + bank transfer, manager product edit, currency separators, hero-tag log, dashboard stat cards.

Blocker đã biết: emulator native test cần `sudo modprobe kvm_amd` trước khi chạy.

Hoàn tất Phase 5 → flip plan này `completed` **và** đóng luôn demo-fix-roadmap (partial).

## Hygiene Findings

- ~6 plan "completed" có checkbox chưa sync-back (lịch sử cook cũ đánh status qua frontmatter, không tick box). Không ảnh hưởng tiến độ thực; nếu muốn sạch, chạy 1 pass sync-back.
- `FE/plans/` còn 2 plan dir cũ (auth-otp-google-fix, sepay-payment) — legacy location, cân nhắc di dời/archive về `plans/`.

## Unresolved Questions

1. Có muốn chạy device pass (Phase 5) session tới không? Cần emulator + `sudo modprobe kvm_amd` + xác nhận xoá từng row test-junk.
2. Có cần sync-back checkbox cho các plan completed cũ không (thẩm mỹ, không chặn gì)?
