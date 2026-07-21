# AI Chat Persistence Fix — Test Verification Report

**Date:** 2026-07-11 | **Branch:** fix/ai-chat-persistence | **Project:** BigStyle (FE)

## Test Execution Summary

| Metric | Result |
|--------|--------|
| Total Tests | 115 / 115 (was 109 before fix) |
| Passed | 115 |
| Failed | 0 |
| Lint Issues | 0 (flutter analyze) |
| Status | ✓ PASS |

New test count: +6 (4 model tests + 2 bloc tests = +6 delta from baseline)

## New Tests — Quality Verification

### ChatMessageModel tests (4 tests)
- **toMap writes role, not is_from_ai:** Verifies the critical fix — table column name change from nonexistent `is_from_ai` to `role`. Asserts `map['role'] === 'assistant'` and `containsKey('is_from_ai') === false`. Non-trivial: proves old key is gone.
- **toMap maps user to role "user":** Validates inverse case (isFromAi=false → role='user'). Meaningful.
- **fromMap reads "assistant" to isFromAi=true:** Tests read-path correctness. Ensures bidirectional mapping.
- **fromMap reads "user" to isFromAi=false:** Completes read-path coverage.

All 4 model tests are **meaningful** — they verify the core persistence bug fix (mapping to correct DB column).

### ChatBloc tests (2 tests)
1. **Rejects >1000 char message before save/AI call:**
   - Creates `_FakeChatService` (extends `ChatService`) passing dummy `SupabaseClient` to constructor.
   - Constructor safely avoids touching `Supabase.instance` singleton (verified: lines 10–16 pass explicit client, no static access).
   - Adds 1001-char message; asserts:
     - Emits state with error set, isSending=false
     - `fakeService.saveMessageCalls === 0`
     - `fakeService.getAiResponseCalls === 0`
   - Confirms early-return at ChatBloc line 45-49 prevents both calls (non-trivial path exercise).

2. **Accepts exactly 1000 char message:**
   - Validates boundary: 1000 chars should proceed (not reject).
   - Asserts `getAiResponseCalls === 1` (proves call happened).
   - Ensures guard doesn't over-reject at boundary.

Both bloc tests are **meaningful** — they verify the new length guard works and that the early-return path genuinely blocks downstream calls.

## Constructor Injection Validation

**ChatService constructor:**
```dart
ChatService({SupabaseClient? client})
  : _client = client ?? Supabase.instance.client;
```

Checked for all callers of `ChatService()`:
- **Prod:** `lib/main.dart:133` — uses no-arg call (defaults to `Supabase.instance.client`). ✓ Safe.
- **Tests:** Only `_FakeChatService()` in `chat_bloc_test.dart` uses the new optional param. No other tests break. ✓ Safe.
- **Pattern consistency:** Matches existing `SupportChatService` + `OrderService` injectable constructors. ✓ Established.

## Coverage Observations

Critical paths now tested:
- Persistence mapping (`role` ↔ `isFromAi`) — 4 tests
- Message length guard → early-return → blocks save+AI — 1 test  
- Boundary case (1000 char accepted) — 1 test

No untested branches detected in changed code paths.

## Lint & Build Status

- **flutter analyze:** 0 issues (1.8s)
- **No syntax errors, no deprecation warnings**
- **Migration file present & idempotent** (20260711200000_repatriate_chat_messages.sql already applied to prod)

## Conclusion

**Status: APPROVED** ✓

All 115 tests pass (6 new). New tests are meaningful and non-trivial (verify real behavior, not tautologies). Constructor injection is safe and consistent with codebase patterns. No lint issues. Fix is production-ready.

---

**Unresolved questions:** None.
