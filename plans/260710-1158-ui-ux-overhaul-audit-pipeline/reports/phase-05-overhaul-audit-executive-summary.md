---
phase: 5
title: "Consolidation & Reskin Plan Handoff — Executive Summary"
date: 2026-07-10
sha: 6e77ccfcc7572621729fd67efca277ef4d65dab4
---

# Executive Summary — BigStyle UI/UX Overhaul Audit Pipeline

## Outcome

4-phase audit (inventory → capture → brand direction → gap audit) complete. Approved direction: **Warm Terracotta** (`docs/design-tokens-v2.md`, `rubric-v1`) — rust/terracotta + ivory, replacing the current pink identity. 30 screens inventoried, 26 captured (87%), ~150 gap findings graded against the frozen rubric. Reskin implementation plan authored: `plans/260710-1342-bigstyle-visual-reskin-implementation/`.

## Effort by Cluster (from Phase 4)

| Cluster | Screens | Skew |
|---|---|---|
| Auth/Guest | 2 | Mixed (Login=L, Splash=S) |
| Customer-shop | 8 | Mixed, ProductDetail is the outlier (L) |
| Customer-account | 7 | Mostly M, 2×L (Profile, Chat) |
| Manager | 9 | Skews L — matches Phase 1's debt-tier prediction |
| Admin | 4 | Skews L — 2×T3, 2×T2 |

Manager + admin (13/30 screens) are the highest-leverage, highest-cost work: 100% bespoke (zero shared-widget use per Phase 1), so every screen needs both token AND component-adoption work, not just a color swap.

## Top Risks

1. **2 tap-target bugs block 3 screens from ever being captured/verified** (cart checkout CTA, manager "add product" FAB — both reproduced 3-4× during Phase 2). Real code bugs, not audit gaps. Reskin plan flags these as an early-phase prerequisite check.
2. **Gemini's cited contrast-ratio numbers are unreliable** (Phase 4 spot-check: 4 different numbers for the same pairing). Qualitative flags are trustworthy; specific ratios are not — reskin plan requires re-measuring with a real contrast tool during implementation, not coding against audit-cited numbers.
3. **Manager/admin 100% bespoke** — highest migration cost, lowest current reuse. New `StatusBadge` component alone closes ~13 of ~21 status-badge findings pipeline-wide — highest-leverage single build item.
4. **4 screens ungraded visually** (Splash, Checkout, PaymentQr, ManagerCreateProduct) — inferred from Phase 1 code metrics only, not visually verified. Reskin plan's first phase re-diffs against the pinned SHA and should attempt a delta-recapture once the tap-target bugs are checked.

## Old Audit Disposition (`docs/ux-flow-audit.md`, checklist-scale, not a workstream)

16/16 findings dispositioned, 0 orphaned:
- ✅ **5 already-fixed**: C3, C30, C42, M17, M19 (list-screen instance only)
- 🔄 **6 absorbed-by-v2-migration**: G12, C45(partial), M2, M6, M19(detail-screen instance), M20
- ⚠️ **5 still-open-outside-scope** (real code bugs, not token issues — reskin plan does NOT fix these, flagged for separate follow-up): G16 (OTP focus-state logic), M12 (date padding), M21/M28/M37 (broken external placeholder image URLs), M34 (~90% code duplication between ManagerCreateProduct/ManagerProductDetail)

This is a small, bounded inheritance as the pipeline plan predicted going in — not a substantive second workstream.

## Adversarial Persona Debate (`ck:predict`-style, simulated)

Constraint respected: brand direction (Warm Terracotta) is a locked Phase 3 user gate — no persona challenges the identity choice itself, only execution/sequencing.

| Persona | Objection | Disposition |
|---|---|---|
| **Regression Risk / QA lead** | Token + component swap across ~30 screens with only 26 visually verified risks silent breakage on the 4 ungraded screens, especially ManagerCreateProduct (highest-debt manager screen, 928 LOC). | **Accepted, mitigated**: reskin plan's manager-cluster phase treats ManagerCreateProduct as inheriting ManagerProductDetail's findings (same form family, M34) but requires a live capture+smoke-check before marking that screen done — not silently shipped on inference alone. |
| **Performance engineer** | Swapping `google_fonts` families (Playfair Display+DM Sans → Cormorant+Montserrat) means new font downloads/caching on first run; 30 screens' worth of `Theme.of(context)` lookups if the new `StatusBadge` isn't built on the `section_header.dart` pattern (`ColorScheme`-driven) could mean widget rebuild cost creep. | **Resolved**: reskin plan requires `StatusBadge` to follow the `section_header.dart` gold-standard pattern (Phase 4 finding) explicitly, not the direct-`AppColors`-reference pattern the other 9 widgets use — costs nothing extra to specify now. Font swap is a one-time asset-cache cost, not a recurring one; not blocking. |
| **Accessibility auditor** | Given the contrast-ratio-number unreliability (risk #2 above), how confident are we v2 actually clears AA everywhere? | **Accepted, mitigated**: reskin plan's QA net requires a real WCAG tool re-check (not vision-model citation) on every screen's primary text/surface/button pairing during implementation — this was already true for the core palette per Phase 3's own precomputed table (verified independently, matches), the open question is only per-screen edge cases (icons on tinted backgrounds etc.), which get the same real-tool check. |
| **Pragmatic PM (course-demo deadline)** | 30-screen full reskin in remaining course time is a lot; can it ship partially and still look coherent? | **Resolved by existing plan structure**: cluster ordering is demo-visibility-first (customer-shop → customer-account → manager → admin → auth/guest) specifically so partial completion still upgrades what graders see first. No change needed — this was already the phase's own design intent, confirmed sound. |
| **Maintainability** | New `StatusBadge` + reworked `size_selector`/`product_card` add surface area — worth it for a course project? | **Accepted, mitigated**: `StatusBadge` closes 13 findings in one component (highest ROI in the whole audit); `size_selector`/`product_card` reworks are 1-file, ≤10-line-diff fixes (Phase 4 cited exact `file:line`s), not new abstractions. Net complexity reduction (fewer bespoke one-off implementations), not increase. |

No blocking objections survive — all 5 resolved or explicitly accepted with mitigation already designed into the reskin plan's structure.

## Unresolved Questions

None — all decisions in this pipeline were either user-gated (brand direction, approved) or resolved above.
