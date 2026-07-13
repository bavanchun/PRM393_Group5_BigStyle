# BigStyle — Codebase Overview

> **Project**: BigStyle — Big-size fashion e-commerce mobile app
> **Course**: PRM393 - Mobile Application Development (Flutter)
> **Group**: PRM393_Group5
> **Tagline**: "Mặc đẹp không giới hạn" (Beauty Without Limits)
>
> Quick orientation only — full detail (flows, schema, security) in
> [docs/system-architecture.md](docs/system-architecture.md). Counts last
> verified 2026-07-13.

---

## 1. Tech Stack

| Layer | Technology |
|---|---|
| **Language** | Dart (SDK `^3.11.5`), Flutter |
| **State Management** | flutter_bloc ^8.1.6 + equatable |
| **Backend** | Supabase BaaS (supabase_flutter ^2.8.3) — no custom server |
| **Database** | PostgreSQL + RLS (via Supabase) |
| **Authentication** | Supabase Auth: Email OTP + email/password + Google OAuth |
| **Storage** | Supabase Storage: `products` (public), `avatars` (private), `reviews` (public) |
| **Realtime** | Supabase Realtime: payment confirmation, support chat |
| **Payments** | SePay VietQR (Edge Function webhook) + COD |
| **Maps** | google_maps_flutter ^2.12.0 + Directions API + geolocator |
| **AI Chat** | Claude API (Anthropic) with mock fallback |
| **Fonts/UI** | Playfair Display + DM Sans (google_fonts), cached_network_image, shimmer |

---

## 2. Project Structure

```
PRM393_Group5_BigStyle/
├── FE/                          # Flutter application (all app code)
│   ├── lib/
│   │   ├── main.dart            # entry: .env load, Supabase init, MultiBlocProvider
│   │   ├── blocs/               # 20 BLoC groups (Event → Bloc → State)
│   │   ├── config/              # app_config, routes/app_router (21 routes),
│   │   │                        # supabase config, theme tokens
│   │   ├── models/              # 17 files: 13 models (product, order, cart, chat, refund_request, …) + enums/value objects
│   │   ├── screens/             # 57 screen files in 16 feature groups
│   │   ├── services/            # 15 services (Supabase API layer)
│   │   ├── utils/               # currency_format, validators, slug, haptics
│   │   └── widgets/             # 14 reusable widgets
│   ├── supabase/
│   │   ├── migrations/          # canonical schema history (YYYYMMDDHHMMSS_slug.sql)
│   │   └── functions/           # edge functions: sepay-webhook, admin-invite-user
│   ├── schema.sql               # readable schema snapshot (see migrations for truth)
│   ├── test/                    # 36 test files / 140 tests
│   └── scripts/                 # setup.sh, check_hardcoded_colors.sh, sepay simulate
├── docs/                        # system-architecture, design-tokens-v2, ux-flow-audit
├── plans/                       # plan-driven workflow history + reports
├── PLAN.md                      # original course project plan (Vietnamese)
└── README.md                    # setup / run / team
```

---

## 3. Architecture — BLoC Pattern

Each feature follows **Event → Bloc → State**; blocs call services, services wrap
`Supabase.instance.client`. All wired in `main.dart` via `MultiBlocProvider`.

BLoC groups (20): admin, auth, cart, chat (AI), checkout, manager,
manager_category, manager_product, manager_voucher, notification, order,
payment, product, product_detail, refund_request, review, search, support_chat,
support_inbox, wishlist.

Services (15): auth, google_auth, product, category, cart, order, payment,
voucher, wishlist, review, notification, chat (AI), support_chat, refund_request,
admin.

---

## 4. Database (17 tables)

Domain groups — RLS enabled everywhere; staff checks via `is_staff()`/`is_manager()`:

- **Identity**: `profiles` (role customer/manager/admin; self-role-escalation blocked)
- **Catalog**: `categories`, `products`, `product_variants`, `vouchers`
- **Shopping**: `cart`, `cart_items`, `wishlist_items`
- **Orders**: `orders`, `order_items`, `payments`, `refund_requests`
- **Social**: `reviews` (purchase-verified gate)
- **Comms**: `notifications`, `chat_messages` (AI), `support_conversations`, `support_messages`

Key server logic: `create_order` RPC (server-side pricing, stock check/decrement),
`cancel_my_order`, voucher validate/redeem, review gate triggers
(`enforce_review_gate`, `update_product_rating`), support-chat triggers (unread
counters, server timestamps), `notify_order_update`. All SECURITY DEFINER
functions have pinned `search_path`.

---

## 5. Screens by Role

- **Customer**: splash, auth (OTP/password/Google), home, search, product list +
  detail (variants, reviews), favorites, cart, checkout (COD / SePay VietQR QR),
  orders + cancel + delivery map, notifications, profile, AI chat, support chat.
- **Manager** (18 files): shell + dashboard (revenue/customers/pending/products),
  products + variants CRUD, categories, vouchers, order pipeline
  (confirm→shipping→delivered), support inbox (realtime, unread badges).
- **Admin** (4 files): shell + dashboard, categories, users (invite manager via
  edge function).

Post-login routing by `profiles.role`: `/home` · `/manager` · `/admin`.

---

## 6. Features Status

| Feature | Status |
|---|---|
| Auth (OTP + password + Google), role routing | ✅ |
| Catalog: list/search/filter/sort, detail + variants | ✅ |
| Wishlist / favorites | ✅ |
| Cart CRUD + badge | ✅ |
| Checkout: COD + SePay VietQR (webhook + realtime confirm) | ✅ |
| Vouchers (validate/redeem + manager CRUD) | ✅ |
| Orders: list/detail, cancel, pay-again, delivery map route | ✅ |
| Reviews: purchase-verified gate + rating aggregates | ✅ |
| Notifications (order status trigger) | ✅ |
| AI chat (Claude + mock fallback, persisted) | ✅ |
| Support chat customer ↔ staff (realtime, unread) | ✅ |
| Manager dashboard + product/category/voucher/order management | ✅ |
| Admin dashboard + user invite | ✅ |
| Notification badge realtime updates | ✅ (code complete, device e2e pending) |
| Password reset via email + deep link | ✅ (code complete, device e2e pending) |
| Customer refund request flow | ✅ (code complete, device e2e pending) |
| Manager/Admin UX polish (state handling, tokens) | ✅ |
| Push notifications (FCM) | 🔜 planned |

---

## 7. Environment

`FE/.env` (gitignored; template `FE/.env.example`) — names only:
`SUPABASE_URL`, `SUPABASE_ANON_KEY`, `GOOGLE_WEB_CLIENT_ID`,
`GOOGLE_MAPS_API_KEY` (Directions REST), `CLAUDE_API_KEY`, `SEPAY_BANK`,
`SEPAY_ACC`. Native Maps SDK key lives separately in
`FE/android/local.properties`. QA debug login uses `--dart-define` (see FE/README.md).

---

## 8. Key Architecture Decisions

1. **No custom backend** — Supabase Auth/DB/Storage/Realtime/Edge Functions direct from Flutter.
2. **Server-trusted money & permissions** — pricing, stock, payment status, role
   changes, review verification all enforced in Postgres/Edge Functions, never client.
3. **BLoC + service layer** — UI never touches Supabase client directly.
4. **OnGenerateRoute** string routing (no go_router).
5. **All UI in Vietnamese**; currency formatted with thousand separators.
6. **Quality gates**: `flutter analyze` = 0, `flutter test` green (116),
   `scripts/check_hardcoded_colors.sh` = 0 (theme-token-only colors).
