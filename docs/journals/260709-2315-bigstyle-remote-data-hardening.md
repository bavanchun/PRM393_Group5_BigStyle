# BigStyle Remote Data Hardening

---
date: 2026-07-09
plan: 260709-2231-bigstyle-remote-data-testability-hardening
status: completed
---

## Context

Android smoke found remote blockers after local stability fixes: missing RPC,
orphan seed products, unreliable test sessions, and broken image URLs.

## What Happened

- Applied `update_product_with_variants` to remote Supabase and repaired grants
  so `anon` cannot execute it.
- Assigned 15 seed products to `hoangbavan4478+manager@gmail.com`.
- Added debug-only real Supabase password login via `--dart-define`, hidden in
  release and hidden unless runtime defines are present.
- Replaced a remote SVG Google button image with a local Material icon after
  Flutter Android failed to decode SVG via `Image.network`.
- Fixed two HTTP 404 image URLs and verified active seed image URLs return 200.
- Verified manager product list/edit-readiness and customer cart -> COD
  checkout -> order detail on Android emulator.

## Decisions

- Keep QA credentials out of source and docs; only pass them at runtime.
- Do not save product edit from UI without explicit demo-data mutation approval;
  verify RPC save path through a rollback transaction instead.
- Leave broader Supabase advisor findings for a separate hardening pass.

## Next

- Rotate QA account password if the project is shared outside the current demo
  team.
- Add direct tests for debug-only login if it remains beyond QA/demo workflow.
- Consider a follow-up Supabase security pass for existing functions and
  storage policies.
