---
phase: 4
title: "FCM Push Notifications"
status: pending
effort: "large"
---

# Phase 4: FCM Push Notifications

## Overview

Push notifications when app is background/killed: order status changes and
chat messages. Heaviest phase — Firebase infra + token lifecycle + edge
function sender + deep-link tap handling. Depends on Phase 3 (badge/notification
plumbing). Firebase account resolved: Gmail cá nhân hoangbavan4478@gmail.com.

## Requirements

- Functional: push arrives on order-status change + new chat message when app backgrounded; tapping opens the right screen (order detail / chat thread).
- Non-functional: token registered per user+device, cleaned on sign-out; no push for events user triggered themselves; server key never in client code.

## Architecture

- Client: `firebase_core` + `firebase_messaging` (via `flutterfire configure`); foreground messages ignored for display (in-app realtime badge from Phase 3 covers it) — background/terminated only.
- DB: new `fcm_tokens` table (`user_id`, `token` unique, `platform`, `updated_at`) + RLS (owner insert/update/delete own rows).
- Sender: Supabase edge function `send-push` using FCM HTTP v1 (service-account JSON in edge function secrets). Triggered by DB webhook on `notifications` insert (order events already write there) + `support_chat` message insert; function looks up recipient tokens, sends, prunes invalid tokens.
- Tap routing: `FirebaseMessaging.onMessageOpenedApp` + `getInitialMessage` → parse `data.type/id` → navigate via existing router.

## Related Code Files

<!-- Updated: Validation Session 1 - paths corrected to FE/supabase, Firebase account + push policy confirmed -->
- Create: `FE/lib/services/push_notification_service.dart`, `FE/supabase/functions/send-push/` (edge function), migration `FE/supabase/migrations/YYYYMMDDHHMMSS_fcm_tokens.sql`
- Modify: `FE/pubspec.yaml`, `FE/lib/main.dart` (init + background handler), `FE/android/app/build.gradle` + `google-services.json` (gitignored), auth sign-in/out flow (token register/unregister), `FE/lib/config/routes/app_router.dart` (tap routing)

## Implementation Steps

1. Create Firebase project bằng Gmail cá nhân hoangbavan4478@gmail.com (user-confirmed), mời thành viên nhóm làm editor; `flutterfire configure` for Android. Android `google-services.json` is safe to commit (public identifiers) but confirm team policy; service-account JSON (server) NEVER committed, stored as edge function secret.
2. Migration: `fcm_tokens` + RLS in `FE/supabase/migrations/` (naming `YYYYMMDDHHMMSS_slug.sql`); apply via Supabase MCP/CLI following existing migration conventions.
3. Client service: request permission, obtain/refresh token, upsert row on sign-in + `onTokenRefresh`, delete on sign-out.
4. Edge function `send-push`: FCM v1 auth, recipient token lookup, payload (`type`, `id`, title/body vi-VN), invalid-token pruning; DB webhooks on `notifications` + chat message inserts; skip when actor == recipient.
5. Background handler (top-level fn) + tap routing to order detail / chat thread.
6. Test on real device (emulator push unreliable): order status change by manager → push on customer device; chat both directions; tap navigation from killed state.
7. Gate: `flutter analyze` 0, `flutter test` xanh (new service behind interface so tests don't need Firebase), color guard 0.

## Success Criteria

- [ ] Push received background + killed states (real device)
- [ ] Tap opens correct order/chat screen from killed state
- [ ] Token lifecycle: no push to signed-out device; invalid tokens pruned
- [ ] No server credentials in repo
- [ ] Analyze/test/color gates pass

## Risk Assessment

- FCM HTTP v1 setup friction (service account, OAuth scope) → follow current Firebase docs via docs-seeker at implementation time.
- Emulator lacks reliable FCM → require real device for acceptance; document in phase notes.
- Duplicate notifications (in-app + push when foregrounded) → display pushes only when backgrounded; foreground relies on Phase 3 realtime.
