---
title: Git Branch Cleanup
description: ''
status: completed
priority: P2
branch: dev
tags:
  - git
  - branch-cleanup
  - hygiene
blockedBy: []
blocks: []
created: '2026-07-09T12:29:22.326Z'
createdBy: 'ck:plan'
source: skill
---

# Git Branch Cleanup

## Overview

Safely clean local and remote git branches after `dev`, `main`, `origin/dev`, and `origin/main` converged at `535724e fix(app): clear flutter analyzer issues`.

The cleanup is intentionally conservative: audit first, delete only branches proven merged into `main`, handle the temporary worktree with `git worktree` commands, and verify final branch/worktree state. No source code changes expected.

Current audit snapshot from 2026-07-09:

| Ref | Status | Cleanup Recommendation |
|-----|--------|------------------------|
| `dev` | active local branch, equals `origin/dev` and `origin/main` | keep |
| `main` | local default branch, equals `origin/main` | keep |
| `backup/main-before-dev-merge-20260709` | local backup, merged, 49 commits behind `main` | delete after final audit |
| `sync/merge-main` | local scratch merge branch, merged, 8 commits behind `main` | delete |
| `trial/dev-main-integration` | local trial branch in `/private/tmp/...`, merged but worktree has pending merge state | abort/remove worktree, then delete branch |
| `origin/feat/admin-panel-and-session-fix` | remote feature branch, merged, 42 commits behind `main` | delete if team agrees |
| `origin/feat/cart-improvements` | remote feature branch, merged, 6 commits behind `main` | delete if team agrees |

## Phases

| Phase | Name | Status |
|-------|------|--------|
| 1 | [Audit Branch State](./phase-01-audit-branch-state.md) | Completed |
| 2 | [Local Branch And Worktree Cleanup](./phase-02-local-branch-and-worktree-cleanup.md) | Completed |
| 3 | [Remote Branch Cleanup And Verification](./phase-03-remote-branch-cleanup-and-verification.md) | Completed |

## Dependencies

No cross-plan dependencies. Existing unfinished demo roadmap touches app behavior, while this plan touches only git refs/worktrees/remotes.

## Safety Rules

- Never force-push.
- Never use `rm -rf` on a git worktree.
- Use `git branch -d`, not `git branch -D`, unless a fresh audit proves the branch is merged.
- Use `git worktree remove` after aborting the pending merge in the trial worktree.
- Delete remote feature branches only after local verification confirms they are merged into `origin/main`.

## Acceptance Criteria

- [x] Project remains on `dev`; only plan/journal artifacts from this workflow are untracked.
- [x] Local branches left: `dev`, `main` only.
- [x] Worktree list has only project worktree.
- [x] Remote branches left: `origin/dev`, `origin/main`, `origin/HEAD -> origin/main`.
- [x] `git branch --merged main` shows no stale cleanup targets.
- [x] `git branch -r --merged origin/main` shows no stale remote feature targets.

## Completion Notes

Completed on 2026-07-09.

Deleted local refs:

- `backup/main-before-dev-merge-20260709`
- `sync/merge-main`
- `trial/dev-main-integration`

Removed worktree:

- `/private/tmp/PRM393_Group5_BigStyle-trial-dev-main`

Deleted remote refs:

- `origin/feat/admin-panel-and-session-fix`
- `origin/feat/cart-improvements`

Final branch state:

- local: `dev`, `main`
- remote: `origin/HEAD -> origin/main`, `origin/dev`, `origin/main`
- all point to `535724e fix(app): clear flutter analyzer issues`
