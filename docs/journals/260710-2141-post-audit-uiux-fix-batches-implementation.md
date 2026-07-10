# Post-audit UI/UX fix batches — implementation

**Date:** 2026-07-10
**Branch:** `dev` (`fab9a26` → `41cfb1a`)
**Plan:** `plans/260710-1906-post-audit-ui-ux-fix-batches/`

## What shipped

Five phases (each its own commit; analyze 0 / `flutter test` green / hardcode-guard 0 at every boundary). Test count 43 → 64.

| Commit | Phase |
|--------|-------|
| `8083ff0` | Shared `formatVnd()` (`FE/lib/utils/currency_format.dart`); 17 raw `toStringAsFixed(0)đ` sites + 4 local formatters → one `10.000đ` style |
| `cf5d616` | Unique `heroTag` on all 6 FloatingActionButtons |
| `55bc5ca` | Manager stat cards → design tokens (bold `textPrimary` value, `textSecondary` label, pending→warning, product-count→info) |
| `2d9c334` | OTP entry rework: paste / backspace / re-submit / `_verifyInFlight` gating |
| `696dbd1` | Resend cooldown + `validateEmail` + `_otpEmail` verify targeting + rate-limit message |
| `41cfb1a` | Follow-up: restore OTP focus after a failed verify (code-review nit) |

## Notable decisions & surprises

- **`digitsOnly` formatter dropped (phase 4).** The plan sketched `FilteringTextInputFormatter.digitsOnly`, but input formatters run *before* `onChanged`, stripping the separators the standalone-`\b\d{6}\b`-run paste heuristic needs. With the formatter, noisy clipboard `10/07/2026 — mã: 483920` resolves to `100720` instead of `483920`. Solution: omit the formatter, sanitize single-char input to a digit inside `_handleChanged`. Regression test pins the noisy-paste case.
- **Overtype vs short-paste ambiguity.** A multi-char `onChanged` under 6 digits is either an overtype of a filled box or a short paste into an empty one — indistinguishable from the payload alone. Resolved by tracking prior box contents (`_prev`): non-empty prior ⇒ overtype (keep newest digit), empty prior ⇒ ignore (matches the "paste `12ab` unchanged" requirement).
- **Backspace propagation.** `Focus(canRequestFocus:false, onKeyEvent:)` wrapping each field receives the backspace key from the focused empty `TextField` and the widget test drives it via `sendKeyEvent`. (Soft-keyboard backspace on some OEM keyboards remains a known best-effort, no worse than before.)
- **Two plan-census misses caught by the guard greps.** Voucher `_formatVnd` had a *second* call site (`:192` min-order) beyond the listed `:152`; and `manager_product_list_screen.dart` also used `intl`'s `DateFormat`, so the `intl` import stayed after `_formatPrice` was deleted. Both surfaced immediately from `flutter analyze` + the leftover-formatter grep.

## Verification

Code-reviewer subagent audited the full `fab9a26..HEAD` diff (focus: auth path): no critical/high/medium findings. Confirmed single OTP dispatch, no timer leak (`_startCooldown` cancel-before-create + `dispose` cancel + mounted guard), wrong-email verify fixed via `_otpEmail`, currency sign/`đ` preserved, deleted helpers fully dereferenced. The one low nit (focus after failed verify) was applied as `41cfb1a`.

## Out of scope / residual

- `AuthBloc` (bloc 8.1.4) default concurrent transformer — bloc-level overlapping send/verify still possible app-wide; phase 4 only closes the login-UI window. `droppable()` transformer is a separate-plan candidate.
- Cooldown is client-side courtesy only; server rate limits are the real guard. `shouldCreateUser` stays at its default (OTP send auto-creates accounts) — service change out of scope.
- `validateEmail` requires a dotted domain (rejects `user@localhost`) — fine for a consumer app; no internal flow relies on dotless addresses.
