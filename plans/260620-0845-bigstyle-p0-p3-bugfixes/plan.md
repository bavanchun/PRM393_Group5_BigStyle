---
title: "BigStyle P0-P3 Bugfixes & Features"
description: ""
status: in-progress
priority: P2
branch: "main"
tags: []
blockedBy: []
blocks: []
created: "2026-06-20T01:47:39.633Z"
createdBy: "ck:plan"
source: skill
---

# BigStyle P0-P3 Bugfixes & Features

## Overview

Fix all P0→P3 issues found in the runtime trace of BigStyle FE (Flutter + BLoC + Supabase). P0 fixes the only broken step in the standard customer purchase flow (cart writes a corrupt `user_id`); P1 removes a dev-only auth bypass from release builds; P2 wires the Manager module (100% mock today) to real Supabase; P3 implements Reviews (Create/Read/Update) and the Wishlist feature (no backend exists yet).

**Execution rules (per user request):**
- Each phase ships with **≥ 1 commit** via the `/vchun-git prc` skill (commit → push → PR pipeline) when the phase is done.
- All Flutter/Dart implementation uses the `/mobile-development` skill.
- Phases run **sequentially** (1→5); each is independently shippable.
- `flutter analyze` must be clean before each phase's commit.

**Verified facts source:** runtime trace + schema scout from this session (file:line cited inside each phase). RLS recursion bug already fixed earlier; Supabase connection confirmed live (15 products / 87 variants).

## Phases

| Phase | Name | Priority | Status |
|-------|------|----------|--------|
| 1 | [Cart user_id & checkout guard](./phase-01-cart-user-id-checkout-guard.md) | P0 | Done (code; runtime write pending auth smoke-test) |
| 2 | [Mock-login release gating](./phase-02-mock-login-release-gating.md) | P1 | Completed |
| 3 | [Manager real data](./phase-03-manager-real-data.md) | P2 | Completed (runtime manager smoke pending) |
| 4 | [Reviews CRU](./phase-04-reviews-cru.md) | P3 | Pending |
| 5 | [Wishlist full-stack](./phase-05-wishlist-full-stack.md) | P3 | Pending |

## User-action blockers (DDL via SQL Editor)

Anon key cannot run DDL. Two phases need a migration the user pastes into Supabase → SQL Editor:
- **Phase 5 (Wishlist):** `create table wishlist_items` + RLS (migration provided in phase).
- **Phase 4 (optional):** a DELETE policy on `reviews` IF true delete is wanted (default scope = CRU only, no migration needed).

## Dependencies

No cross-plan dependencies (no other unfinished plans). Phase order is the only internal dependency chain.
