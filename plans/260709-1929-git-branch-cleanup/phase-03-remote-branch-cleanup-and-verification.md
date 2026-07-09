---
phase: 3
title: Remote Branch Cleanup And Verification
status: completed
priority: P2
effort: 10m
dependencies:
  - 2
---

# Phase 3: Remote Branch Cleanup And Verification

## Overview

Delete remote feature branches that are already merged into `origin/main`, then verify final local/remote branch hygiene.

## Requirements

- Functional: remove remote feature refs only if Phase 1 confirms merged status.
- Non-functional: no force push, no deletion of `origin/dev` or `origin/main`.

## Architecture

Remote cleanup uses normal branch deletion pushes. Final verification fetches with prune to ensure local remote-tracking refs match GitHub.

## Related Code Files

- Modify: none
- Delete: none
- Remote refs:
  - Delete: `origin/feat/admin-panel-and-session-fix`
  - Delete: `origin/feat/cart-improvements`
  - Keep: `origin/dev`, `origin/main`, `origin/HEAD`

## Implementation Steps

1. Re-run remote merged check:
   - `git fetch --prune origin`
   - `git branch -r --merged origin/main`
2. Delete merged remote feature branches:
   - `git push origin --delete feat/admin-panel-and-session-fix`
   - `git push origin --delete feat/cart-improvements`
3. Fetch/prune again:
   - `git fetch --prune origin`
4. Verify final state:
   - `git status --short --branch`
   - `git branch -a -vv`
   - `git worktree list`
   - `git rev-list --left-right --count dev...origin/main`
   - `git rev-list --left-right --count dev...origin/dev`
5. Report final branch list and any skipped branches.

## Success Criteria

- [x] Remote feature branches no longer appear in `git branch -r`.
- [x] `origin/dev` and `origin/main` remain present and equal.
- [x] Local `dev` equals `origin/dev` and `origin/main`.
- [x] Final report lists deleted refs and retained refs.

## Risk Assessment

Risk: remote feature branches may be useful for PR history navigation. Code is safe because commits are already in `main`, but branch names disappear from GitHub. Mitigation: delete only after explicit user approval and merged verification.
