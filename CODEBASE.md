# BigStyle — Codebase Overview

> **Project**: BigStyle — Big-size fashion e-commerce mobile app  
> **Course**: PRM393 - Mobile Application Development (Flutter)  
> **Group**: PRM393_Group5  
> **Tagline**: "Mặc đẹp không giới hạn" (Beauty Without Limits)

---

## 1. Tech Stack

| Layer | Technology |
|---|---|
| **Language** | Dart (Flutter 3.11.5+, SDK ^3.11.5) |
| **State Management** | flutter_bloc ^8.1.6 + bloc ^8.1.4 + equatable ^2.0.7 |
| **Backend** | Supabase BaaS (supabase_flutter ^2.8.3) |
| **Database** | PostgreSQL (via Supabase) |
| **Authentication** | Supabase Auth (Email OTP + Google OAuth) |
| **Storage** | Supabase Storage (products, avatars, reviews buckets) |
| **Fonts** | Playfair Display (headings) + DM Sans (body) via google_fonts |
| **Maps** | Google Maps Flutter + Directions API |
| **AI Chat** | Claude AI (Anthropic API) with mock fallback |
| **Others** | cached_network_image, shimmer, intl, image_picker, flutter_dotenv |

---

## 2. Project Structure

```
BigStyle/
├── BE/                              # (empty — backend is Supabase)
├── FE/                              # Flutter application
│   ├── lib/
│   │   ├── main.dart                # App entry + MultiBlocProvider setup
│   │   ├── blocs/                   # BLoC (Event → Bloc → State)
│   │   │   ├── auth/
│   │   │   ├── cart/
│   │   │   ├── chat/
│   │   │   ├── checkout/
│   │   │   ├── notification/
│   │   │   ├── order/
│   │   │   ├── product/
│   │   │   └── product_detail/
│   │   ├── config/
│   │   │   ├── app_config.dart
│   │   │   ├── routes/app_router.dart
│   │   │   ├── supabase/supabase_config.dart
│   │   │   └── theme/
│   │   │       ├── app_colors.dart
│   │   │       ├── app_spacing.dart
│   │   │       ├── app_theme.dart
│   │   │       └── app_typography.dart
│   │   ├── models/                  # 7 data models
│   │   ├── screens/                 # 14 screens
│   │   ├── services/                # 7 services (Supabase API layer)
│   │   └── widgets/                 # 9 reusable widgets
│   ├── schema.sql                   # Full Supabase schema (10 tables)
│   ├── seed_data.sql                # Seed data (15 products, ~95 variants)
│   ├── pubspec.yaml
│   └── assets/.env                  # (gitignored) Supabase + Google keys
├── PLAN.md                          # Project plan (Vietnamese)
└── README.md
```

---

## 3. Architecture — BLoC Pattern

Each feature follows **Event → Bloc → State**:

```
UI (Screen)  ──dispatches──>  Event  ──>  Bloc  ──>  State  ──>  UI rebuilds
                                      │
                                      └── calls ──> Service ──> Supabase API
```

All BLoCs & services are wired in `main.dart` via `MultiBlocProvider`:

```
AuthBloc(AuthService, GoogleAuthService)
ProductBloc(ProductService)
ProductDetailBloc(ProductService)
CartBloc(CartService)
OrderBloc(OrderService)
CheckoutBloc(OrderService, CartService)
NotificationBloc(NotificationService)
ChatBloc(ChatService)
```

---

## 4. Services (7)

Each service wraps `Supabase.instance.client` REST calls:

| Service | Key Methods |
|---|---|
| **AuthService** | `sendOtp()`, `verifyOtp()`, `signOut()`, `updateProfile()` |
| **GoogleAuthService** | `signInWithGoogle()`, `signOut()` |
| **ProductService** | `getProducts()`, `getProductById()`, `getCategories()` |
| **CartService** | `getCartItems()`, `addToCart()`, `updateQuantity()`, `removeFromCart()`, `clearCart()` |
| **OrderService** | `getOrders()`, `getOrderById()`, `createOrder()`, `updateOrderStatus()` |
| **NotificationService** | `getNotifications()`, `markAsRead()`, `getUnreadCount()` |
| **ChatService** | `getAiResponse()` (Claude API or mock), `saveMessage()`, `loadHistory()` |

---

## 5. Data Models (7)

| Model | Key Fields |
|---|---|
| **UserModel** | id, email, fullName, phone, avatarUrl, role (enum), address, createdAt |
| **ProductModel** | id, name, description, price, originalPrice, images, sizes, category, stock, rating, reviewCount, isFeatured |
| **CategoryModel** | id, name, imageUrl, productCount |
| **CartItemModel** | id, productId, product, size, quantity, addedAt |
| **OrderModel** | id, userId, items, subtotal, shippingFee, total, status (enum), address, lat/lng, createdAt |
| **NotificationModel** | id, userId, title, body, imageUrl, isRead, createdAt |
| **ChatMessageModel** | id, userId, content, isFromAi, createdAt |

---

## 6. Database Schema (10 tables)

| Table | Key Columns | RLS |
|---|---|---|
| **profiles** | id (uuid FK→auth.users), email, role, body_measurements (jsonb) | Users view/update own; managers view all |
| **categories** | id (uuid PK), name, slug, image_url, sort_order | Anyone view active; managers manage |
| **products** | id (uuid PK), category_id (FK), name, slug, images[], base_price, sale_price, body_type_fit[], tags[], avg_rating | Anyone view active; managers manage |
| **product_variants** | id (uuid PK), product_id (FK), size, color, color_hex, stock_qty, sku | Anyone view; managers manage |
| **cart** | id (uuid PK), user_id (FK unique), promo_code | Users own |
| **cart_items** | id (uuid PK), cart_id (FK), variant_id (FK), quantity | Users own |
| **orders** | id (uuid PK), order_number (auto), user_id (FK), status (enum), shipping_address (jsonb), total | Users see own; managers all |
| **order_items** | id (uuid PK), order_id (FK), variant_id (FK), product_name, size, quantity, unit_price | Users see own; managers all |
| **payments** | id (uuid PK), order_id (FK), method, amount, status | Users see own; managers all |
| **notifications** | id (uuid PK), user_id (FK), title, body, type, is_read | Users manage own |
| **reviews** | id (uuid PK), product_id (FK), user_id (FK), rating, comment, size_feedback | Anyone view; users insert/update own |
| **chat_messages** | id (uuid PK), user_id (FK), role, content | Users manage own |

**Auto Triggers:**
- `handle_new_user()` — create profile on auth signup
- `notify_order_update()` — notification on order status change
- `update_product_rating()` — recalc avg_rating on review insert/update

**Storage Buckets:** `products` (public), `avatars` (private), `reviews` (public)

---

## 7. Routing (OnGenerateRoute)

| Route | Screen |
|---|---|
| `/` | SplashScreen |
| `/login` | LoginScreen |
| `/home` | HomeScreen (customer) |
| `/products` | ProductListScreen |
| `/product-detail` | ProductDetailScreen |
| `/cart` | CartScreen |
| `/checkout` | CheckoutScreen |
| `/orders` | OrdersScreen |
| `/order-detail` | OrderDetailScreen |
| `/profile` | ProfileScreen |
| `/edit-profile` | EditProfileScreen |
| `/chat` | ChatScreen |
| `/notifications` | NotificationsScreen |
| `/delivery-map` | DeliveryMapScreen |
| `/manager` | ManagerShell |

**Flow:** `Splash → (Login or Home/Manager) → Products → Detail → Cart → Checkout → Orders`

---

## 8. Screens (14)

| Screen | Description |
|---|---|
| **SplashScreen** | Logo, session check → auto-navigate (1.5s) |
| **LoginScreen** | Email OTP + Google Sign-In + Mock Login (dev) |
| **HomeScreen** | Search bar, banner carousel, category chips, featured + new products grid, bottom nav |
| **ProductListScreen** | Search, filter chips, sort sheet, product grid (2 cols), pull-to-refresh |
| **ProductDetailScreen** | Image carousel, color/size selector, reviews, DraggableScrollableSheet, "Add to Cart" / "Buy Now" |
| **CartScreen** | Items list, quantity +/-, delete, subtotal, checkout button |
| **CheckoutScreen** | Address form, order summary, notes, total breakdown, "Place Order" |
| **OrdersScreen** | Orders list with status badges, tap → detail |
| **OrderDetailScreen** | Order info, items, price breakdown, address |
| **ProfileScreen** | Avatar, name/email, menu items, logout |
| **EditProfileScreen** | Avatar camera, name/phone/address fields |
| **ChatScreen** | AI chatbot with quick replies, typing indicator |
| **NotificationsScreen** | Notification list, tap to mark read |
| **DeliveryMapScreen** | Google Maps, shop ↔ customer route, polyline, fee calculation |
| **ManagerShell** | 4-tab dashboard: Dashboard stats, Products (placeholder), Orders, Profile (placeholder) |

---

## 9. Reusable Widgets (9)

- **AppBottomNav** — 5-tab customer bottom nav with cart badge
- **ManagerBottomNav** — 4-tab manager bottom nav
- **ProductCard** — Grid card: image, sale badge, wishlist heart, name, sizes, price
- **AppButton** — Gradient primary / outlined with loading state
- **AppCard** — Card container with shadow & inkwell
- **AppTextField** — Form input with label, hint, validation
- **SectionHeader** — Title + optional "Xem tất cả" link
- **ExpandableText** — Collapsible text (read more/less)
- **SizeSelector** — Horizontal animated size chips

---

## 10. Theme

- **Primary**: `#C4517A` (rose), **Dark**: `#A03560`
- **Secondary**: `#F7C0D0` (light pink)
- **Background**: `#FDF8F9`, **Surface**: `#FFFFFF`
- **Typography**: Playfair Display (headings) + DM Sans (body)
- **Radii**: Cards 16, Buttons 12, BottomSheet 24, Inputs 12, Chips 20

---

## 11. Features Status

| Feature | Status |
|---|---|
| Splash / App Start | ✅ Complete |
| Auth (Email OTP + Google + Mock) | ✅ Complete |
| Product List (filters, search, sort) | ✅ Complete |
| Product Detail (carousel, colors, sizes, reviews) | ✅ Complete |
| Cart (CRUD, quantity, badge) | ✅ Complete |
| Checkout (address, order summary) | ✅ Complete |
| Orders List & Detail | ✅ Complete |
| Profile & Edit Profile | ✅ Complete |
| Notifications (read/unread, relative time) | ✅ Complete |
| Chat / AI Support (Claude API + mock) | ✅ Complete |
| Delivery Map (Google Maps, route, polyline) | ✅ Complete |
| Manager Dashboard (stats grid) | ⚡ Partial |
| Manager Orders (filter + mock data) | ⚡ Partial |
| Wishlist / Favorites | ❌ Not implemented |
| Payment (VNPay / MoMo) | ❌ Schema only |
| Reviews CRUD | ❌ Schema only, mock in detail |

---

## 12. Environment Variables

Required in `assets/.env` (not committed):

```
SUPABASE_URL=https://pqsykhrizakeodcbgesx.supabase.co
SUPABASE_ANON_KEY=eyJ...
GOOGLE_MAPS_API_KEY=
CLAUDE_API_KEY=
```

---

## 13. Key Architecture Decisions

1. **No custom backend** — Supabase handles Auth, DB, Storage, RLS directly from Flutter
2. **BLoC pattern** over Provider (despite PLAN.md mentioning Provider)
3. **OnGenerateRoute** — centralized string-based routing (no go_router)
4. **Mock login for dev** — quick buttons to bypass real auth
5. **All UI in Vietnamese** — products, bot responses, enum labels
6. **Minimal testing** — only 1 widget test exists
