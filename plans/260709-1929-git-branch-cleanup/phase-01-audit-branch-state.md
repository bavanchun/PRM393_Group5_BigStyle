---
phase: 1
title: Audit Branch State
status: completed
priority: P1
effort: 10m
dependencies: []
---

# Phase 1: Audit Branch State

## Overview

Refresh remote refs and prove which branches are already merged into `main` before deleting anything.

## Requirements

- Functional: classify every local branch, remote branch, and worktree as keep/delete/review.
- Non-functional: no branch deletion, no worktree removal, no source code changes in this phase.

## Architecture

This phase reads only git metadata. It establishes the deletion allowlist used by later phases.

## Related Code Files

- Modify: none
- Delete: none
- Git refs inspected: local branches, `origin/*`, worktrees

## Implementation Steps

1. Run `git fetch --prune origin`.
2. Confirm current worktree state with `git status --short --branch`.
3. Record `git branch -a -vv`.
4. Record `git worktree list`.
5. Record merged status:
   - `git branch --merged main`
   - `git branch --no-merged main`
   - `git branch -r --merged origin/main`
   - `git branch -r --no-merged origin/main`
6. For each cleanup candidate, record divergence:
   - `git rev-list --left-right --count <branch>...main`
   - `git rev-list --left-right --count <remote-branch>...origin/main`
7. Stop if any cleanup candidate is not merged.

## Success Criteria

- [x] `dev`, `main`, `origin/dev`, `origin/main` all point to the same commit.
- [x] Every delete candidate is confirmed merged into `main` or `origin/main`.
- [x] Pending worktree state for `trial/dev-main-integration` is documented before cleanup.
- [x] No source file changed in this phase.

## Risk Assessment

Primary risk is deleting a branch that still contains useful commits. Mitigation: use merged/no-merged checks and divergence counts before any deletion.
