---
date: 2026-06-20
session: phase-2-release-gating
---

# Journal: 2026-06-20 — Phase 2 Release Gating

## Context

Phase 2 removed the development-only mock-login path from release behavior while retaining it for local debug workflows.

## What happened

- Gated mock-login UI with `kReleaseMode`.
- Added a defense-in-depth release no-op for `MockLoginEvent`.
- Preserved real OTP, Google login, and debug mock-login behavior.

## Decisions

- Keep the mock-login helper in debug builds; exclude both its UI and event effect from release builds.
- Stop after Phase 2. Phase 3 starts only after explicit user approval.

## Verification

- Android release APK build passed.
- Analyzer: 0 errors, 0 warnings; four pre-existing informational lints remain.
- Existing widget test still fails at the known baseline because Supabase is not initialized before app startup.

## Next

- User smoke-test release and debug login behavior.
- Await approval before Phase 3.

## Unresolved Questions

None.
