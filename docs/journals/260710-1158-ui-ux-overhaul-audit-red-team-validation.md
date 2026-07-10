# UI/UX Overhaul Audit — Red-Team Validation & Plan Hardening

**Date**: 2026-07-10 · 05:06–17:30 UTC  
**Branch**: dev  
**Plan**: `plans/260710-1158-ui-ux-overhaul-audit-pipeline/`

---

## What Happened

Planned a 5-phase UI/UX audit pipeline (inventory → capture → brand direction → gap audit → consolidation). Ran brainstorm → `/ck:plan` draft → red-team review (3 hostile reviewers, evidence-mandatory). Red team found 2 Critical factual errors embedded in both brainstorm output and user-approved plan.md. 21 raw findings → 13 after dedupe; all 13 accepted and applied. User approved Gemini key, validated no hard dev freeze needed.

---

## The Brutal Truth

I wrote this plan with **confident factual claims copied straight from brainstorm assumptions, then never grepped the code to verify them.** The role model ("delivery" is a role), account seeding status, and screen counts were all stated as fact without file:line evidence.

Red team was hostile by design — they opened `FE/lib/models/user_model.dart:4` and found the enum has only `customer, manager, admin`. They traced `delivery_map_screen.dart` to `profile_screen.dart:128` and found it's a customer navigation destination, not a role. They asked: "Where is the seeded manager account?" and found Phase 1 of the demo-fix roadmap is still **in-progress with 'manager OTP login not done'** — this plan confidently assumed it existed.

That's the exhaustion of this session: a plan that would have wasted days assuming infrastructure that isn't there, all because I didn't pair planning claims with code verification.

---

## Technical Details

**2 Critical findings (accepted):**
- Finding #1: "Delivery" is not a role — 3 roles exist (customer/manager/admin), plus guest. `delivery_map_screen` is customer-profile navigation.
- Finding #2: Manager account NOT seeded; demo-fix Phase 1 incomplete ("manager OTP login not done"). Phase 2 capture step now explicitly gates on account verification.

**Other high-severity accepted findings:**
- Real-customer PII shipped to Gemini free-tier (fixed: all captures now use seeded demo-customer only).
- No commit-SHA pinning (Phase 2/4/5 now pin to HEAD at capture time; delta-recapture rule for dev-branch hot-merge).
- Screen counts inflated by ~35% (file counts vs. actual route destinations + shell tabs; Phase 1 now defines "screen" authoritatively).
- Debug password login in `login_screen.dart:21–31` initially missed, now adopted as safer login method than OTP cycle in audit phase.

**Gemini setup (verified):**
- `GEMINI_API_KEY` provided by user, verified (HTTP 200 on models endpoint), stored in local `~/.zshenv` only — never in repo.

---

## Decisions Applied

- All customer-role screenshots captured from seeded "Khách Demo" account, not real customer session (PII policy hardened).
- No soft dev freeze; rely on SHA pinning + delta-recapture for hot dev branch.
- Skill routing corrected: web-first UI skills (frontend-design, ui-styling, shadcn, react-best-practices) are **traps for Flutter**. Correct stack = ui-ux-pro-max + ai-multimodal + design + predict + scenario.

---

## Lessons Learned

**Assumption ≠ verified fact.** Planner confidence is a bias. Confident claims need file:line evidence before they ship into a plan that's already been user-approved. Brainstorm output is generative, not factual — red-team gates (mandatory evidence, adversarial scope) catch what self-review misses because self-review has the same blindspots as the planner.

**Code path tracing before claiming scope.** Before saying "manager account exists," check where it's provisioned. Before saying "4 roles," `grep -r "enum UserRole"`. Before saying "44 screens," define what a screen is (route destination? shell tab? inline widget?), then enumerate from the router and shell, not from file counts.

---

## Next Steps

1. **User:** Review Phase 1 findings in plan.md; kick off Phase 1 inventory when ready (no blocking dependencies).
2. **User:** Run `/clear` + `/ck:cook` on the plan to execute phases 1–5 sequentially.
3. **Team:** Cross-check Phase 1 results against actual route table + shell tabs (not file counts).

---

**Status**: DONE  
**Summary**: Red-team audit caught 2 Critical factual errors (role model, seeded-account assumption) + 11 other findings; plan hardened with SHA pinning, PII policy, debug login strategy, and corrected scope. All 13 findings accepted; handoff to execution ready.
