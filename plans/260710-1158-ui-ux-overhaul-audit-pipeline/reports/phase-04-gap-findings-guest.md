# Phase 4 Gap Findings — Guest (rubric-v1)

Vision model: gemini-2.5-flash. Screenshots: `docs/audit-assets/overhaul/guest/`.

## Login (`02-Login-default.png`, code: `FE/lib/screens/auth/login_screen.dart`)

| Type | Sev | Finding |
|---|---|---|
| color | L | AppBar-less full-screen background + accents (logo, "Gửi mã OTP" button, test-login chip borders) use v1 pink `#C4517A` — swap to `primary` `#9A3F35` |
| color | L | Screen background is v1 light pink gradient — swap to `background` `#FBF6EF` |
| typography | L | All text on v1 fonts (Playfair Display / DM Sans) — swap to Cormorant (display) / Montserrat (body) |
| shape | M | Card, primary button, input field, Google button, test-login chip radii all on v1 scale — swap to v2 (20/14/14/24) |
| contrast | M | Slogan text "TỰ TIN VỚI PHONG CÁCH RIÊNG CỦA BẠN" on light-pink background reads low-contrast — verify against v2 `background`/`textPrimary` pair post-migration (pre-existing v1 issue, not introduced by v2) |
| color | M | Secondary text (slogan, "hoặc" divider, email placeholder) uses lighter pink/grey — swap to `textSecondary` `#746159` |

**Splash** — not captured (routes instantly when session cached, per phase-02 log); not gradeable visually. Code-read: `splash_screen.dart` (167 LOC, 7 hardcode lines per Phase 1) — same token-swap-only profile expected as Login given its T2 tier and 0 shared-widget use; treat as token-swap-only pending a future capture opportunity (e.g. cold-launch with cleared session).

## Screen Verdict

| Screen | Verdict |
|---|---|
| Login | Real findings (6) — color/typography/shape sweep + 1 pre-existing contrast issue, not a token-swap-only screen |
| Splash | Not captured — inferred token-swap-only from code metrics, unverified visually |
