---
phase: 3
title: "Brand Direction & Tokens v2"
status: completed
effort: "M (1 day incl. user review)"
priority: P1
dependencies: [1]
---

# Phase 3: Brand Direction & Tokens v2

## Overview

Propose 2–3 complete visual-identity directions for BigStyle (fashion e-commerce, VN market), get exactly one approved by the user, and freeze it as a written design-tokens-v2 spec. This is the **user gate** of the whole pipeline: Phase 4 grades every screen against this spec, so changing direction later means re-grading.

## Requirements

- Functional: each direction = named concept + palette (light theme; note dark-theme feasibility) + typography pairing (must be `google_fonts`-available) + shape language (radius/elevation/border) + spacing rhythm + motion stance (Flutter implicit/explicit animations only) + 1 hero-screen visualization.
- Non-functional: spec doc only, no Dart changes; every token must be expressible in Flutter `ThemeData`/`ColorScheme` (Material 3) — no web-only constructs.

## Skill Routing

- `ck:ui-ux-pro-max` — style/color/typography intelligence, Flutter-aware; primary engine.
- `ck:design` — brand-identity structure (token naming, semantic tiers).
- Optional concept visuals: `ck:stitch` (UI mock — treat output as reference image, NOT code) and/or `ck:ai-artist` (moodboard). Pick per output quality at run time (open question from brainstorm).

## Implementation Steps

1. Input synthesis: Phase 1 inventory + current tokens v1 (`FE/lib/config/theme/`) + product context (fashion shop "BigStyle", plus-size hint from size guide M–5XL, VN audience, course-demo visibility).
2. Generate 3 candidate directions with distinct personalities (e.g. refined-editorial, warm-modern, bold-contemporary — final naming per skill output). One direction MAY be an evolved version of the current pink identity for comparison honesty.
3. For each: palette with WCAG AA contrast check on primary text/surface pairs; typography pairing from google_fonts; component shape sheet (button/card/input/sheet/chip); spacing scale; motion notes.
4. Produce 1 visual concept per direction (stitch/ai-artist or typographic spec sheet if generation quality is poor).
5. Present all directions to user via `AskUserQuestion` (visible analysis first, trade-offs per direction). User approves exactly 1 (or requests a merge — one iteration allowed).
6. **If merged: re-run the full WCAG AA contrast matrix on the final merged palette** — step 3 checked candidates individually; merged pairs (A's text on B's surface) were never checked. Freezing an unchecked merge is forbidden.
7. Freeze approved direction as `docs/design-tokens-v2.md`: full token table (semantic names → values), mapping table tokens-v1 → v2, explicit "grading rubric" section Phase 4 will use, and a **rubric version stamp** (`rubric-v1`, date) that Phase 4 must cite in every batch. Define the bounded re-grade rule: if the rubric changes after Phase 4 starts, only findings of the affected type(s) (e.g. `color`) are re-checked — not whole screens.

## Success Criteria

- [x] 3 directions presented (A Refined Rose, B Warm Terracotta, C Bold Editorial) with palette, type, shape, spacing, motion each. Visual reference = typographic spec sheet (structured preview per direction), per the documented fallback in step 4 — no stitch/ai-artist image generated (spec-sheet quality was sufficient for the decision).
- [x] All palette pairs used for text pass WCAG AA (4.5:1 body, 3:1 large) — computed via WCAG relative-luminance formula for all 3 candidates before presentation; `success`/`warning` deepened beyond the initial guess to clear AA (v1's originals failed AA as text — fixed in v2).
- [x] User approved exactly 1 direction (B — Warm Terracotta) via `AskUserQuestion`, recorded in `docs/design-tokens-v2.md`. No merge requested — re-run-on-merge step not triggered.
- [x] `docs/design-tokens-v2.md` written with v1→v2 mapping + Phase 4 grading rubric (`rubric-v1`) + version stamp + bounded re-grade rule.

## Risk Assessment

- **Direction churn after Phase 4 starts** → doc states the lock explicitly; re-grading cost called out at approval time.
- **Concept-image tools produce web-styled mocks** → label as mood reference only; the normative artifact is the token table, not the image.
- **Font not on google_fonts / heavy** → constraint checked at proposal time (step 3), not discovered during implementation.
