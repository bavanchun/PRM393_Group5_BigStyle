# Phase 4 Gap Findings — Admin (rubric-v1)

Vision model: gemini-2.5-flash, batch of 4. Screenshots: `docs/audit-assets/overhaul/admin/`.

## AdminDashboard (`06`, code: `FE/lib/screens/admin/admin_dashboard_screen.dart`)

| Type | Sev | Finding |
|---|---|---|
| color | L | AppBar solid v1 pink `#C4517A` |
| typography | L×2 | Headings ("Admin Panel", "Thống kê", "Thao tác nhanh") + body/numbers on v1 fonts |
| shape | M×2 | Cards ~16dp, bottom-nav selected-item bg ~12-14dp — both below v2 (20/24) |
| contrast | M | White text on v1 pink AppBar is 4.23:1 — **still fails AA even after swapping to v2 primary `#9A3F35`**; needs a dedicated `onPrimary` text-contrast check, not just a color swap |

## AdminUsers (`10`, code: `FE/lib/screens/admin/admin_users_screen.dart`)

| Type | Sev | Finding |
|---|---|---|
| color | L | AppBar, FAB, active filter chip, active bottom-nav tab all v1 pink |
| typography | L | AppBar title + all body text (names/emails/buttons) on v1 fonts |
| shape | M | List cards, search input, FAB, filter chips, badges all off v2 radii |
| status-badge | M | "Admin" role badge solid-fill pink + white text — tonal violation |
| touch-target | M | Filter chips + per-row overflow menu icons look under 48dp |
| contrast | M | Active "Tất cả" filter chip white-on-pink is 2.89:1, fails AA outright |

## AdminProfile (`11`, inline `_AdminProfileScreen` in `admin_shell.dart:83`)

| Type | Sev | Finding |
|---|---|---|
| color | L | AppBar, logout button border/text, active bottom-nav item all v1 pink |
| typography | L | All text on v1 fonts |
| color | M | Background is off-white/light-grey, not `#FBF6EF` |
| color | M | "Đăng xuất" uses primary-like pink/red instead of semantic `error` `#C0392B` — same class as ManagerProfile's finding |
| shape | M | Bottom-nav "Cá nhân" selected chip ~12-16dp, needs 24 |
| shape | S | Logout button radius ~12-16dp, needs `buttonRadius` 14 |

## AdminCategories (`16b`, code: `FE/lib/screens/admin/admin_categories_screen.dart`)

| Type | Sev | Finding |
|---|---|---|
| color | L | AppBar, FAB, active switches, bottom-nav active icon all v1 pink |
| color | M | Background white, not `#FBF6EF` |
| typography | M×2 | Headings + body/nav-label text on v1 fonts |
| shape | M | Cards + FAB below v2 radii (16/12 → 20/14) |
| touch-target | S | Per-row overflow menu icon likely under 48dp |

## Cross-Screen Pattern

**Full color/typography sweep needed on 4/4 admin screens** — matches Phase 1's finding that admin is 100% bespoke (0/4 shared-widget use). **AppBar white-on-primary contrast (4.23:1) fails AA even with the new v2 primary** — this is a NEW finding not visible under v1 (v1's pink is closer to white-safe by luck); the reskin needs an explicit `onPrimary` token, not an assumption that white text is always safe on `primary`. Same "Đăng xuất → error token" pattern as ManagerProfile — 1 shared fix.

## Screen Verdict

All 4 admin screens: **real findings**, none token-swap-only — matches Phase 1 tier prediction (AdminDashboard/AdminUsers = T3, AdminCategories/AdminProfile = T2).
