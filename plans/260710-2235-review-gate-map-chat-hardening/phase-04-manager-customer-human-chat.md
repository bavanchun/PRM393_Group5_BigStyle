---
phase: 4
title: "Manager-Customer Human Chat"
status: completed
priority: P2
dependencies: []
effort: "L"
---

# Phase 4: Manager-Customer Human Chat

## Overview
Human support chat alongside the existing AI bot: one conversation per customer, shared manager inbox (any manager/admin replies), Supabase Realtime both directions. New tables `support_conversations`/`support_messages` (prefixed to avoid clashing with legacy AI `chat_messages`).

## Requirements
- Functional: customer opens "Chat với nhân viên" (profile tile, next to AI chat entry) → conversation created via RPC (1/customer) → send/receive live. Manager entry = **new bottom-nav tab "Tin nhắn" with unread badge** (user decision at validation, overriding the lighter dashboard-card option). This explicitly scopes a nav refactor: de-const the `BottomNavigationBarItem` list in `FE/lib/widgets/manager_bottom_nav.dart:50-60`, wire an unread-count badge (BlocBuilder on `SupportInboxBloc` wrapping the item icon), and add `ManagerSupportInboxScreen` to the `IndexedStack` `_screens` list in `FE/lib/screens/manager/manager_shell.dart:27,38`. Inbox sorts by `last_message_at`, per-conversation unread badge, opens thread, replies live.
- Non-functional: subscriptions cancelled deterministically (thread bloc is **screen-scoped**, not app-scoped); RLS enforced; hand-fake test pattern via service DI.

## Architecture

**DB migration** (`FE/supabase/migrations/<ts>_support_chat.sql`, also append to `FE/schema.sql`; include rollback block):
```sql
create table support_conversations (
  id uuid primary key default gen_random_uuid(),
  customer_id uuid not null references auth.users(id) on delete cascade unique, -- 1 per customer
  status text not null default 'open',
  last_message_at timestamptz not null default now(),
  last_message_preview text,          -- denormalized, trigger-maintained (kills inbox N+1)
  unread_for_staff int not null default 0,     -- denormalized unread counters
  unread_for_customer int not null default 0,
  created_at timestamptz not null default now()
);
create table support_messages (
  id uuid primary key default gen_random_uuid(),
  conversation_id uuid not null references support_conversations(id) on delete cascade,
  sender_id uuid not null references auth.users(id) on delete cascade,
  content text not null,
  created_at timestamptz not null default now(),
  read_at timestamptz
);
create index on support_messages(conversation_id, created_at desc, id);
-- Publication add guarded against re-run (red-team: manual debug application causes duplicate_object)
do $$ begin
  alter publication supabase_realtime add table support_messages;
exception when duplicate_object then null; end $$;
do $$ begin
  alter publication supabase_realtime add table support_conversations;
exception when duplicate_object then null; end $$;
```
- **All conversation mutations via SECURITY DEFINER (red-team: RLS kills both trigger and upsert otherwise):**
  - `get_or_create_my_conversation()` RPC, SECURITY DEFINER, `set search_path = public`: returns existing row for `auth.uid()` or inserts. **No client upsert** — the ON CONFLICT UPDATE path would need a customer UPDATE policy we refuse to grant (returning customer would hard-fail otherwise).
  - Trigger fn `bump_support_conversation()` `after insert on support_messages`, **SECURITY DEFINER**: updates `last_message_at`, `last_message_preview`, increments `unread_for_staff` (customer sender) or `unread_for_customer` (staff sender). Invoker-rights version would silently no-op / abort under RLS.
  - `mark_conversation_read(p_conversation_id uuid)` RPC, SECURITY DEFINER: sets `read_at` on counterpart messages + zeroes caller's unread counter, after verifying caller is participant (customer of the conversation, or staff). **No direct UPDATE grant on `support_messages` at all** — red-team: a participant UPDATE policy lets customers rewrite manager message content via REST (per-column enforcement exists, but the RPC is simpler and removes the surface entirely).
- **RLS (SELECT/INSERT only for clients):** reuse existing `is_manager()` SECURITY DEFINER helper (exists per `FE/fix_rls_profiles_recursion.sql` — extend/create `is_staff()` covering admin). Conversations: customer SELECT own (`customer_id = auth.uid()`); staff SELECT all. Messages: customer SELECT/INSERT own conversation (`sender_id = auth.uid()` AND conversation ownership subquery); staff SELECT all, INSERT with `is_staff() and sender_id = auth.uid()`. **No UPDATE/DELETE policies for either role.**
- Realtime respects RLS; verified explicitly in Phase 5 (leak probe), not assumed.

**Flutter:**
- Models: `FE/lib/models/support_message_model.dart`, `support_conversation_model.dart`.
- Service `FE/lib/services/support_chat_service.dart` (DI `SupabaseClient`): `getOrCreateConversation()` (calls RPC), `sendMessage`, `messagesStream(conversationId)` → `.stream(primaryKey:['id']).eq('conversation_id', id).order('created_at')`, `conversationsStream()` (staff inbox — stream on `support_conversations`; unread + preview come denormalized from the row, **no per-conversation count queries**), `markRead(conversationId)` (calls RPC), `myConversationStream()` (customer unread badge on profile tile, optional).
- Blocs:
  - `SupportChatBloc` (thread): **screen-scoped** — provided via `BlocProvider(create:)` in the route builder, NOT `main.dart` (red-team: app-scoped singleton + manager switching threads A→B races late stream events of A into B's view, and `close()` never runs for singletons). Additionally: subscribe handler cancels-and-awaits prior subscription and tags emissions with `conversationId`, dropping stale ones.
  - `SupportInboxBloc` (staff inbox): app-scoped in `main.dart` is acceptable (single logical stream) — register there.
- Screens: `FE/lib/screens/chat/support_chat_screen.dart` (reuse bubble styling from `chat_screen.dart`), `FE/lib/screens/manager/support/manager_support_inbox_screen.dart`. Routes: `/support-chat` (customer thread); manager inbox lives as a `ManagerShell` tab (no route needed), thread opens via pushed route with screen-scoped bloc. Entries: `profile_screen.dart` tile (customer); **manager bottom-nav tab** with `unread_for_staff` sum badge (nav refactor scoped in Requirements).

## Related Code Files
- Create: migration sql; 2 models; `support_chat_service.dart`; 2 blocs (+events/states); 2 screens
- Modify: `FE/schema.sql`, `FE/lib/main.dart` (SupportInboxBloc only), `FE/lib/config/routes/app_router.dart` (thread route + screen-scoped BlocProvider), `FE/lib/screens/profile/profile_screen.dart`, `FE/lib/widgets/manager_bottom_nav.dart` (de-const + badge), `FE/lib/screens/manager/manager_shell.dart` (tab + screen)
- Tests: `FE/test/blocs/support_chat_bloc_test.dart`, `support_inbox_bloc_test.dart` with `FakeSupportChatService` (StreamController-driven), model tests

## Implementation Steps (TDD)
1. **Tests first:** models fromMap/toMap; SupportChatBloc — subscribe emits from fake stream, send appends, markRead on open, subscription cancelled on close (fake exposes `cancelCount`), **conversation-switch test: subscribe(A) → subscribe(B) → late A-stream event → state contains only B messages**; SupportInboxBloc — list ordered by last_message_at, denormalized unread surfaced. Red.
2. Models + service → blocs green against fakes.
3. Screens + routes (thread bloc scoped in route builder) + entry points; theme tokens (color guard applies).
4. Migration SQL (tables, guarded publication, SECURITY DEFINER RPCs + trigger, RLS) + schema.sql; `flutter analyze`, full `flutter test`, color guard.
5. Live realtime + adversarial REST checks → Phase 5 runbook.

## Success Criteria
- [ ] Customer ↔ manager round-trip live on two sessions; returning customer reopens chat without error (RPC path, no upsert).
- [ ] `last_message_at`/preview/unread bump on every message (SECURITY DEFINER trigger verified live).
- [ ] Customer cannot read others' threads, cannot INSERT into another's conversation, cannot UPDATE any message content (REST probes, Phase 5).
- [ ] Inbox sorts by last_message_at; unread badge from denormalized counters; clears via mark_conversation_read.
- [ ] Bloc tests prove cleanup + switch-race handling; analyze 0; tests green; color guard 0.

## Risk Assessment
- RLS recursion on profiles lookup — mitigated by existing SECURITY DEFINER helper precedent.
- Realtime publication drift on re-run — guarded with `duplicate_object` exception blocks.
- Legacy AI `chat_messages` model/schema mismatch (`is_from_ai` vs `role`, `FE/schema.sql:423-430`) — adjacent tech debt, out of scope (new tables independent); tracked in plan-level open questions.
- Scope creep (typing indicators, attachments, per-manager assignment) — explicitly excluded, YAGNI. Bottom-nav tab + badge IS in scope (user decision).
- Nav refactor files (`manager_bottom_nav.dart`, `manager_shell.dart`) are disjoint from Phase 2 D6 files (`manager_product_list_screen.dart`) — no file collision; recommended execution order 2 before 4 is convention, not a hard dependency.
