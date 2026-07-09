---
phase: 2
title: Local Branch And Worktree Cleanup
status: completed
priority: P1
effort: 10m
dependencies:
  - 1
---

# Phase 2: Local Branch And Worktree Cleanup

## Overview

Remove local scratch/backup branches and the temporary trial worktree after Phase 1 proves they are merged.

## Requirements

- Functional: remove local stale refs and temporary worktree without touching `dev` or `main`.
- Non-functional: no destructive filesystem deletion; use git-native cleanup only.

## Architecture

Local cleanup order matters because `trial/dev-main-integration` is attached to a separate worktree. Clean the worktree state first, remove the worktree, then delete the branch.

## Related Code Files

- Modify: none
- Delete: none
- Git refs/worktrees:
  - Remove worktree: `/private/tmp/PRM393_Group5_BigStyle-trial-dev-main`
  - Delete local branches: `sync/merge-main`, `backup/main-before-dev-merge-20260709`, `trial/dev-main-integration`

## Implementation Steps

1. Confirm main project worktree is clean on `dev`.
2. Inspect trial worktree status:
   - `git -C /private/tmp/PRM393_Group5_BigStyle-trial-dev-main status --short --branch`
3. If trial worktree still has merge pending, run:
   - `git -C /private/tmp/PRM393_Group5_BigStyle-trial-dev-main merge --abort`
4. Remove trial worktree with:
   - `git worktree remove /private/tmp/PRM393_Group5_BigStyle-trial-dev-main`
5. Delete local merged branches:
   - `git branch -d trial/dev-main-integration`
   - `git branch -d sync/merge-main`
   - `git branch -d backup/main-before-dev-merge-20260709`
6. Run `git worktree prune` only if `git worktree list` shows stale metadata after removal.
7. Verify local state:
   - `git branch -vv`
   - `git worktree list`

## Success Criteria

- [x] Project remains on `dev`; only plan/journal artifacts from this workflow are untracked.
- [x] Temporary worktree path no longer appears in `git worktree list`.
- [x] Local branches `sync/merge-main`, `backup/main-before-dev-merge-20260709`, and `trial/dev-main-integration` no longer appear.
- [x] Local `dev` and `main` remain at `535724e` or newer same commit.

## Risk Assessment

Risk: `git merge --abort` could fail if worktree state changed. Mitigation: stop and report status; do not force remove. Risk: user wants to keep backup branch. Mitigation: backup branch is explicitly listed as optional; skip it if user changes decision.
