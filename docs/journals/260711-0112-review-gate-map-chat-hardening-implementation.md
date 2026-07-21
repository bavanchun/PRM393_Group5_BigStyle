# Journal — Review gate, map, chat & auth hardening implementation

**Date:** 2026-07-11
**Plan:** `plans/260710-2235-review-gate-map-chat-hardening/`
**Branch flow:** per-phase `feat/*` → squash-merge to `dev`

## What shipped (5 of 6 phases)

| Phase | PR | Summary |
|-------|----|---------|
| 1 Review purchase-gate | #17 | Eligibility-bound RLS INSERT/UPDATE policies + one BEFORE INSERT OR UPDATE trigger (immutable provenance, server-recomputed `is_verified`); `update_product_rating` → SECURITY DEFINER; seed backfill/prune + aggregate recompute; delivered-order per-item review CTA. |
| 2 Cancel + defects | #18 | Repatriated `cancel_my_order` RPC (pending+confirmed) as repo migration; `OrderStatus.isCancellable` gate; D1–D6 (dead admin menu, mark-read error surfaced, categories-failure flag, dead `MockLoginEvent` removed, placeholder URLs dropped, manager badge from auth role). |
| 3 Delivery map | #19 | `DeliveryMapScreen` dual mode; all three `_customerLocation` producers respect delivery mode (no GPS fallback); shipping-order route CTA; external directions target order coord. |
| 6 Email-password auth | #20 | Password form default + OTP secondary; productionized sign-in (dead `kReleaseMode` guard removed); sign-up with duplicate-email + confirmation-pending handling; `full_name` via `handle_new_user` trigger metadata. |
| 4 Support chat | #21 | `support_conversations`/`support_messages`; all mutations via SECURITY DEFINER RPCs + triggers; SELECT/INSERT-only RLS with customer isolation; Realtime; screen-scoped thread bloc (switch-race stale-drop); app-scoped inbox with denormalized unread; manager nav tab + badge. |

## Verification (on `dev`)
`flutter analyze` 0 · hardcode-color guard 0 · `flutter test` **104 green** (was 64 at start; +40 new). Migrations written but not applied — Phase 5 applies + verifies live.

## Notable decisions / deviations
- **Phase 6 `droppable()` → manual guard.** Plan mandated `bloc_concurrency`'s `droppable()`. Adding it made an existing widget test (`favorites_screen_navigation_test`) hang `pumpAndSettle` for 10 min (empirically bisected: removing it → passes <1s). Replaced with a `_passwordAuthInFlight` bool guard (same double-submit-drop behavior, no dependency, no test hang).
- **Per-phase code review.** Each phase was reviewed by a subagent before merge; every accepted finding fixed pre-merge — notably: P1 order-detail review reused the tapped item id instead of the existing review's immutable `order_item_id` (multi-order purchasers would hit the provenance guard); P1 migration DELETE left stale product aggregates; P3 external directions button routed to shop not order coord; P6 session-established-but-profile-null misclassified as confirmation-pending; P4 client-settable `created_at`/`read_at` let a customer manipulate staff-inbox ordering (forced via BEFORE INSERT trigger).

## Not done — Phase 5 (live)
Emulator + hosted Supabase runbook: apply all migrations, adversarial REST probes (review forgery, chat leak/tamper), realtime two-session round-trip, map render with mock location, junk-row cleanup (per-row user confirmation), auth device checks, and the pre-existing verification backlog. Requires a device + hosted DB + human confirmations — not automatable. Closing it also flips `260703-1750-bigstyle-demo-fix-roadmap` to completed.
