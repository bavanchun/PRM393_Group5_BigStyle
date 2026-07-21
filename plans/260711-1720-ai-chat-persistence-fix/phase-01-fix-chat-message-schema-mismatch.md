---
phase: 1
title: "Fix chat message schema mismatch"
status: completed
priority: P2
dependencies: []
---

# Phase 1: Fix chat message schema mismatch

## Overview
Align `ChatMessageModel`'s Supabase mapping with the live `chat_messages` schema so AI chat messages actually persist, instead of every insert silently failing.

## Requirements
- Functional: `toMap()` writes the real `role` column (`'user'` | `'assistant'`) instead of the nonexistent `is_from_ai`; `fromMap()` reads `role` back into the existing `isFromAi` bool. No change to the Dart-side `isFromAi` field itself — only the DB-boundary mapping.
- Functional: `ChatBloc._onSendMessage`'s two `saveMessage()` calls (currently fire-and-forget) are `await`ed — RT finding (Assumption Destroyer): today these are silent no-ops in a fixed order by accident (every insert fails), so ordering never mattered; once inserts actually succeed, unawaited calls become a real race if a user sends a second message before the first save completes. Awaiting is a one-line fix that removes the race outright.
- Functional (added — Validation V1): reject chat messages over 1000 characters in `ChatBloc._onSendMessage`, before calling `saveMessage`/`getAiResponse` — reuses the exact limit already established for user-generated text in `FE/lib/screens/product_detail/review_editor_sheet.dart:147` (`maxLength: 1000`), not a new arbitrary number. Emit an error state and return early, matching the existing empty-item early-return pattern in `CheckoutBloc._onPlaceOrder`.
- Non-functional: keep existing graceful-degradation behavior (chat must keep working even if a future save/load fails). `ChatService`'s catch blocks gain a narrower debug-visibility guard (Validation V2 — see Architecture) instead of the originally red-teamed-out blanket version.
- Non-goal (explicit): `metadata` jsonb column stays unused — no current feature reads/writes it; wiring it up now would be speculative (YAGNI).

> ⚠️ **RED-TEAM OVERRIDE (2 reviewers, 2026-07-11).** Both reviewers independently flagged: `chat_messages` has NO tracked `CREATE TABLE` migration anywhere in `FE/supabase/migrations/` — it only exists in the known-stale `FE/schema.sql`. Live verification (this session) confirms the table IS correctly configured on prod (RLS policy `"Users manage own chat messages"`, `cmd=ALL`, `qual=(select auth.uid())=user_id`, `with_check=NULL` — which Postgres defaults to reusing `qual` for ALL-command policies, so INSERT is already correctly restricted to the caller's own `user_id`; plus a `role` CHECK constraint restricting values to `'user'|'assistant'` that independently backstops this fix's mapping). The security concern itself is REFUTED by this live check — but the repo/prod drift is real (same pattern as the `vouchers` table closed in the full-app-improvement plan's Phase 01). Step 0 below repatriates it.

## Architecture
`chat_messages` table schema is already correct on prod (confirmed live) — `id uuid`, `user_id uuid` (FK→`profiles.id` cascade), `role text not null check (role in ('user','assistant'))`, `content text not null`, `metadata jsonb`, `created_at timestamptz default now()`. No schema CHANGE needed. But per the red-team override above, a **repatriation migration** (Step 0) is needed to close the repo/prod drift before the mapping fix. `chat_message_model.dart`'s `toMap()`/`fromMap()` need to change:

```dart
Map<String, dynamic> toMap() => {
      'id': id,
      'user_id': userId,
      'content': content,
      'role': isFromAi ? 'assistant' : 'user',
      'created_at': createdAt.toIso8601String(),
    };

factory ChatMessageModel.fromMap(Map<String, dynamic> map) =>
    ChatMessageModel(
      id: map['id'] ?? '',
      userId: map['user_id'] ?? '',
      content: map['content'] ?? '',
      isFromAi: map['role'] == 'assistant',
      createdAt:
          DateTime.tryParse(map['created_at'] ?? '') ?? DateTime.now(),
    );
```

`ChatService.saveMessage()`/`loadHistory()` (`chat_service.dart:118-142`) — per Validation V2, catch `PostgrestException` specifically (a real DB-level error: schema mismatch, constraint violation, RLS denial) and `assert(false, ...)` only on that branch; a separate bare `catch (_) {}` below it keeps swallowing everything else (network timeouts, connectivity) silently. This is narrower than the originally red-teamed-out blanket assert (both reviewers correctly flagged that version as conflating transient I/O with schema drift) while still closing the actual gap this bug exposed — a `PostgrestException` from a bad column name is exactly what would have caught this bug immediately in any debug/test run:

```dart
Future<void> saveMessage(ChatMessageModel message) async {
  if (!_hasSession) return;
  try {
    await _client.from('chat_messages').insert(message.toMap());
  } on PostgrestException catch (e) {
    assert(false, 'ChatService.saveMessage: $e');
  } catch (_) {
    // Network/transient errors: swallow silently, chat must keep working.
  }
}
```
(mirror the same two-tier catch in `loadHistory()`; `PostgrestException` is already available via the existing `package:supabase_flutter/supabase_flutter.dart` import, same as `checkout_screen.dart`'s existing usage.)

## Related Code Files
- Create: `FE/supabase/migrations/20260711200000_repatriate_chat_messages.sql` — idempotent repatriation of `chat_messages` (table, RLS policy, grants) matching the live prod definition captured this session, closing the repo/prod drift both red-team reviewers flagged. Mirrors the `vouchers`-table repatriation pattern from the full-app-improvement plan's Phase 01.
- Modify: `FE/lib/models/chat_message_model.dart` (`toMap`/`fromMap`)
- Modify: `FE/lib/blocs/chat/chat_bloc.dart` (`_onSendMessage` — `await` both `saveMessage()` calls, lines 57 and 79; add the 1000-char length guard before the existing logic)
- Modify: `FE/lib/services/chat_service.dart` (`saveMessage`/`loadHistory` — narrower `PostgrestException`-only debug assert, per Validation V2)
- Tests: new `FE/test/models/chat_message_model_test.dart`; new `FE/test/blocs/chat_bloc_test.dart` (confirmed no existing file — this bloc currently has zero test coverage) for the length-guard early-return, mirroring `checkout_bloc_test.dart`'s "blocks empty item checkout" pattern

## Implementation Steps (TDD)
0. Apply the repatriation migration (idempotent `create table if not exists` + `create policy`/`alter policy` matching live prod exactly + grants) — no-op on prod (already exists there), makes a fresh environment built from repo migrations alone match reality.
1. Write failing tests in `chat_message_model_test.dart`:
   - `ChatMessageModel(isFromAi: true, ...).toMap()` contains `'role': 'assistant'`, does NOT contain `is_from_ai`.
   - `ChatMessageModel(isFromAi: false, ...).toMap()` contains `'role': 'user'`.
   - `ChatMessageModel.fromMap({'role': 'assistant', ...}).isFromAi == true`.
   - `ChatMessageModel.fromMap({'role': 'user', ...}).isFromAi == false`.
   Also write a failing bloc test: `ChatSendMessage` with content > 1000 chars emits an error state and never calls the injected order/save creator (mirrors `checkout_bloc_test.dart`'s empty-item test).
2. Fix `toMap()`/`fromMap()` in `chat_message_model.dart` per the Architecture section.
3. In `chat_bloc.dart:_onSendMessage`: add the length guard (`event.content.trim().length > 1000` → emit error, return early, matching `CheckoutBloc._onPlaceOrder`'s empty-item pattern) before the existing logic; `await` both `_chatService.saveMessage(...)` calls (lines 57, 79).
4. In `chat_service.dart`: split `saveMessage`/`loadHistory`'s catch into `on PostgrestException catch (e) { assert(false, ...) }` + `catch (_) {}` per the Architecture section.
5. Run `flutter analyze` + full `flutter test` — confirm 0 issues, all green, no regressions in other model/bloc tests.
6. Live re-verification (web, customer test account): send a message in "Hỗ trợ & Chat" (AI bot), confirm via Supabase query that both the user message and the AI reply land in `chat_messages` with correct `role` values; reload the chat screen and confirm prior history renders (not just the static welcome message).
7. Live negative-RLS check (rollback-wrapped, per this session's established pattern): under a fabricated stranger UUID JWT, attempt an INSERT into `chat_messages` with a real user's `user_id` — confirm RLS rejects it (0 rows / policy violation), closing Security Adversary's "no negative test" finding.

## Success Criteria
- [x] Repatriation migration applied; no-op on prod, closes repo/prod drift.
- [x] New tests lock the `role`-based mapping in both directions; all pass (4 model tests).
- [x] New bloc test: message content > 1000 chars is rejected client-side before any save/API call.
- [x] Live: sending one message creates 2 real rows (`role='user'`, `role='assistant'`) in `chat_messages`.
- [x] Live: reloading the chat screen after sending shows prior messages, not the reset welcome message.
- [x] Live: cross-user INSERT attempt on `chat_messages` is rejected by RLS (`42501` error, confirmed via rollback-wrapped transaction).
- [x] `flutter analyze` 0; full `flutter test` green — 116/116 (was 109 before this fix).

## Risk Assessment
Low (upgraded from "very low" post-red-team — the repatriation migration and `chat_bloc.dart` await fix add real but small surface). No schema CHANGE (repatriation is descriptive of what already exists, not a new migration in the mutating sense). RLS verified live as already correctly scoped (`WITH CHECK` defaults to `qual` for the `ALL`-command policy — `auth.uid() = user_id`), so the persistence fix cannot enable cross-user writes. `chat_service.dart` confirmed the only consumer of `ChatMessageModel.toMap()`/`fromMap()`; `chat_bloc.dart` is the only caller of `saveMessage()` (both grepped this session). Worst case if the fix is wrong: chat messages still fail to save (same as current broken state).

Full red-team findings table: see `plan.md` `## Red Team Review` (authoritative).

## Post-Implementation Code Review
Score 8/10 (independent re-verification of `flutter analyze`/`flutter test`, RLS `WITH CHECK` semantics against PostgreSQL docs, call-site grep — all confirmed sound). One Medium finding, fixed same session: the length guard checked `event.content.trim().length` but persisted/transmitted the untrimmed `event.content`, so a whitespace-padded message (e.g. 2000 leading spaces + 3 real chars) could trim under the limit while the raw string blew past it downstream. Fixed by trimming once (`final content = event.content.trim();`) and reusing that single trimmed value for the length check, persistence, and the AI request — closes the gap. Added a dedicated regression test (`chat_bloc_test.dart`: "measures the length limit against trimmed content...") locking this. Re-verified: 116/116 tests green, 0 analyze issues.
