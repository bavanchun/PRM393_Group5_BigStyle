# Stale Checkbox Sync-Back — 6 Completed Plans (2026-07-12)

Scope: tick `- [ ]` → `- [x]` only with evidence (git log/show, code/tests/migrations read, committed reports/journals, or re-run checks). Runtime items without device evidence got `<!-- deferred to device pass (plans/260712-1644 Phase 1) -->` annotations. No frontmatter touched. Did NOT touch 260710-2235 or 260712-1644.

Fresh re-verification run this session (counts as current evidence): `flutter analyze` = 0 issues; `flutter test` = 116/116 pass; `./scripts/check_hardcoded_colors.sh` = exit 0; currency + FAB census greps re-run clean.

## Per plan

| Plan | Before | Ticked now | Annotated (left unticked) |
|---|---|---|---|
| 260703-1537 role-based-ux-flow-audit | 0/26 | 19 | 7 |
| 260703-2035 manager-category-management | 0/25 | 22 | 3 |
| 260703-2142 app-feature-gap-closure | 0/33 | 25 | 8 |
| 260709-2231 remote-data-testability-hardening | 6/33 | 30 | 3 |
| 260710-1342 visual-reskin-implementation | 7/73 (+1 `[~]`) | 46 | 27 |
| 260710-1906 post-audit-ui-ux-fix-batches | 0/22 | 17 | 5 |

## Evidence highlights (why ticks are safe)

- **Audit plan (1537):** deliverable `docs/ux-flow-audit.md` (commit 036c282) documents the emulator method itself (emulator-5554, 17+8 screenshots, live SePay webhook test, ✅/🖥 per-screen markers) — emulator items ticked on that documentary basis, not assumed.
- **Category mgmt (2035):** journal 260703 records emulator run (slug `qa-danh-muc-test-5o3b`, no 23502/FK, roles restored); code artifacts all present (bloc/service/model/screens/slug util).
- **Gap closure (2142):** voucher money path prod-verified post PR #24 (BEGIN/ROLLBACK RPC tests, tester-260711-1505); cancel gate + color_hex mapping unit-tested; facets code-verified; map tiles+marker live-verified (666a7e6).
- **Remote hardening (2231):** own smoke report + PM completion report cover nearly everything (COD order CF-20260709-54E569 end-to-end on device).
- **Reskin (1342):** per-phase completion notes + guard 206→0 + post-merge emulator audit (qa-260710-1827); repo-wide guard still exits 0 today.
- **Fix batches (1906):** all guard greps re-run 0 today; behaviors pinned by widget/unit tests (otp_input_test ×7, validators, manager_stats_grid, currency_format).

## Notable honest gaps (annotated, not ticked)

- **Audit COD walk:** audit only walked bank_transfer; COD device-verified later (260709 smoke) — outside the audit's own scope.
- **Category edit-save:** `updateCategory` was code-review-verified only (plan's own closeout says so) — never device-run.
- **Avatar upload:** code path complete (incl. avatars-bucket RLS fix) but end-to-end pick→save→display never verified on device or in DB anywhere.
- **"Chỉ đường" external Maps handoff:** launchUrl code exists; the handoff itself never observed on device.
- **Positive order-cancel:** only the RPC reject-path was live-tested; a real customer cancel (DB row + notification) never demonstrated.
- **Reskin regression checklists:** plan's own closeout admits none of the per-cluster manual walk-throughs happened (no role creds that session); post-merge QA only covered Home/Detail/Cart + manager/admin partials — 20+ walk-through boxes carry deferral notes instead of ticks.
- **QA password rotation (reskin phase-07 closeout): NOT done** — journal says "flagged for user, not rotated"; the next QA session re-set the same shared password (`BigStyleQA2026!` — printed in qa-260710-1827) on the QA-alias accounts. Still open. Security hygiene loose end.
- **Pre-merge full-app smoke (reskin):** merge d5bd510 landed after analyze/test/guard only; the mandated pre-merge smoke never ran (post-merge audit ran same day instead).
- **Remote hardening:** smoke report text contains `hoangbavan4478(+manager)@gmail.com` despite the "no personal email in reports" criterion; per-URL image audit listing never kept; local seed migration never updated after remote-only image repairs.
- **Fix batches emulator sub-clauses:** currency separator walk, post-fix hero-exception log check, and OTP manual smoke were never documented (later "phase 09 native/emulator verification" is still pending per journal 260711-1403) — code/grep/test halves verified, device halves deferred.
