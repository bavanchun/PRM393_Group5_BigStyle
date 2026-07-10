# Audit — Demo Fix Roadmap Checkbox Reconcile

Plan: `plans/260703-1750-bigstyle-demo-fix-roadmap/`
Date: 2026-07-10 · Method: code cross-ref (Grep/Read on `FE/`), `git log`, `flutter analyze` (No issues found). No DB access (code-only per constraint).

## Per-item verdicts

### Phase 1 — Demo Environment & Seed Data (status → in-progress)
| Item | Verdict | Evidence |
|------|---------|----------|
| Manager email logs in → /manager | open | runbook: manager OTP login NOT performed (explicit open item) |
| "Khách hàng" ≥ 2 | open | DB state; unverifiable code-only |
| confirmed+delivered-today orders seeded | open | DB state; unverifiable code-only |
| Test-junk removed | open | DB state; unverifiable code-only |
| seed SQL committed, no secrets | done | `git ls-files FE/seed_demo_accounts_and_orders.sql`; secret scan clean |

### Phase 2 — Splash & Auth Unblock (status → completed)
| Item | Verdict | Evidence |
|------|---------|----------|
| No-session cold start → /login | done | auth_bloc.dart:39 AuthUnauthenticated; splash_screen.dart:64-68 |
| Session → /home or /manager by role | done | splash_screen.dart:58-63 |
| getCurrentUser failure → error+retry | done | auth_bloc.dart:41-47; splash_screen.dart:48-51,41-44 |
| No used-after-dispose | done | _navigated + if(!mounted) return (splash_screen.dart:47,52,81) |
| analyze clean | done | "No issues found!" |

### Phase 3 — Customer Purchase-Flow (status → completed)
| Item | Verdict | Evidence |
|------|---------|----------|
| Persisted cart loads (C15) | done | main.dart:146 CartLoad on AuthSuccess |
| COD+bank cart clears (C16) | done | checkout_screen.dart:331; payment_qr_screen.dart:116 |
| Buy-now once / out-of-stock (C11/C12) | done | product_detail_screen.dart:722,749,765,701 |
| Category filter (C6/C7) | done | product_list_screen.dart:52-66,419 |
| Order detail error/retry (C28/C29) | done | order_detail_screen.dart:14,36,64,41 |
| Edit profile success-guard (C35) | done | edit_profile_screen.dart:89-98 |
| Pending pay-again (C24/C22) | done | orders_screen.dart:154-181 |
| analyze clean | done | "No issues found!" |

### Phase 4 — Manager Operations (status → completed)
| Item | Verdict | Evidence |
|------|---------|----------|
| Orders tab lists + reload-on-entry (M7b) | done | manager_shell.dart:46-47 |
| Status feedback spinner/success/error + detail refresh (M7/M13/M40/M9) | done | manager_bloc.dart:51,80; manager_orders_screen.dart:38-44; manager_order_detail_screen.dart:105-107 |
| Cancel/refund confirm (M14) | done | order_status_update_sheet.dart:93-94 |
| Non-zero today revenue (M6b) | done | revenue_recognition.dart:2; manager_dashboard_stats.dart:24 |
| Dashboard recent-order → manager detail (M4) | done | manager_dashboard.dart:134 |
| Create/edit saves category (M23/M31) | done | manager_create_product_screen.dart:211; manager_product_detail_screen.dart:233 |
| analyze clean | done | "No issues found!" |

### Phase 5 — On-Camera Polish (status → in-progress)
| Item | Verdict | Evidence |
|------|---------|----------|
| Manager product branding/no dead nav (M17/M18/M19) | done | manager_product_list_screen.dart:47,53; footer:558 static count; no hamburger |
| orderNumber everywhere incl COD (X2) | done | checkout_screen.dart:356; orders_screen.dart:99; order_detail_screen.dart:103; manager_order_detail_screen.dart:116; manager_order_card.dart:50; payment_qr_screen.dart:90 |
| One shipping fee, no divergent code (X3/C21) | open | flat 30000 done (checkout_screen.dart:49) + checkout_bloc distance logic removed, BUT delivery_map_screen.dart:280-283 keeps divergent tiered getter |
| Chat honest label/no fake dot/no mock image (C40/C41/C42) | done | chat_screen.dart:121-124; no AppColors.success dot; no mock image button |
| No demo-path dead buttons + favorites (X7) | open | favorites (profile_screen.dart:116) + camera (edit_profile_screen.dart:118) wired, BUT product_detail_screen.dart:163 Share `onPressed: () {}` still dead |
| analyze clean | done | "No issues found!" |

## Final statuses
- Phase 1: **in-progress** (1/5 code-verifiable done; rest DB-state / manual login open)
- Phase 2: **completed**
- Phase 3: **completed**
- Phase 4: **completed**
- Phase 5: **in-progress** (X3 + X7 open)
- **Plan: partial** (kept) — Phases 1 and 5 not genuinely complete.

## Whole-plan acceptance criteria
Checked: logged-out→/login (G1/G2), customer flow (C15/C16/C11/C12), manager ops (M7b/M7/M6b/M13), category save (M23/M31), analyze clean. Left open: "no on-camera dead buttons" — product-detail Share button still dead (X7).

## Unresolved questions
1. Phase 1 DB-seed criteria (customer count, confirmed/delivered-today orders, test-junk cleanup) are unverifiable code-only — need a Supabase read or live manager login to confirm. Runbook claims done via MCP but that is not independently verified here.
2. X3: is delivery_map's tiered shipping getter intentionally kept (separate delivery-map UX) or should it be repointed to the flat 30000 constant? If kept intentionally, the criterion wording ("no divergent unused code") should be relaxed.
3. X7 Share button: hide or wire `share_plus` to close the criterion.
