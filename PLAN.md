# PRM393_Group5_BigStyle - Kế Hoạch Phát Triển

## Giới Thiệu
- **Môn học**: PRM393 - Mobile Application Development (Flutter)
- **Đề tài**: Thời trang Bigsize (BigStyle)
- **Công nghệ**: Flutter (FE) + REST API / Firebase (BE)
- **State Management**: Provider

---

## Kiến Trúc Thư Mục FE

```
FE/bigstyle_app/
├── lib/
│   ├── models/           # Data models
│   ├── providers/        # State management
│   ├── screens/          # Màn hình (UI)
│   ├── widgets/          # Component tái sử dụng
│   ├── services/         # API, database calls
│   ├── utils/            # Helpers, constants
│   └── main.dart
├── test/                 # Unit tests + Widget tests
└── pubspec.yaml
```

---

## Danh Sách Màn Hình & Chức Năng

| # | Màn hình | Mô tả | Ghi chú |
|---|----------|-------|---------|
| 1 | **Login** | Email + OTP authentication | 2 role: Manager & Customer |
| 2 | **Product List** | Grid/list sản phẩm bigsize | Filter theo size, category |
| 3 | **Product Detail** | Ảnh, size, mô tả, add to cart | |
| 4 | **Shopping Cart** | CRUD giỏ hàng | |
| 5 | **Checkout/Billing** | Form địa chỉ + thanh toán | Tính phí ship từ map |
| 6 | **Notifications** | Thông báo theo role | |
| 7 | **Map (Store Location)** | Bản đồ cửa hàng | Tính khoảng cách → phí ship |
| 8 | **Messaging/Chat** | Chat + AI chatbot | Gemini/OpenAI API |

---

## Database Design (7-8 bảng)

1. **users** — id, email, password, role, name, phone, address
2. **categories** — id, name, image
3. **products** — id, category_id, name, description, price, sizes, images, stock
4. **carts** — id, user_id, product_id, quantity, size
5. **orders** — id, user_id, total, status, shipping_fee, address, created_at
6. **order_items** — id, order_id, product_id, quantity, size, price
7. **notifications** — id, user_id, title, body, type, is_read, created_at
8. **messages** — id, user_id, content, is_from_ai, created_at

---

## Luồng Xử Lý Chính

```
Login → Product List → Product Detail → Cart → Checkout (Map) → Order Complete
         ↑                                   ↓
         └──────────── Notifications ←───────┘
                                ↓
                          Chat/AI Support
```

---

## Công Nghệ Dự Kiến

| Thành phần | Lựa chọn |
|------------|----------|
| Ngôn ngữ | Dart (Flutter) |
| State Management | Provider |
| Database | Firebase Firestore hoặc REST API |
| Authentication | Firebase Auth / Custom OTP |
| Map | Google Maps Flutter |
| Chat AI | Gemini API / OpenAI API |
| Notifications | Firebase Cloud Messaging |
| HTTP Client | Dio / http package |

---

## Testing

- **Unit Test**: Kiểm tra business logic (cart calculation, validation)
- **Widget Test**: Kiểm tra UI components (product card, login form)

---

## Timeline Gợi Ý

1. Khởi tạo project + cấu trúc thư mục
2. Xây dựng models + services (kết nối DB/BE)
3. Màn hình Login + Product List + Product Detail
4. Cart + Checkout + Map
5. Notifications + Chat
6. Testing + Build Release APK
7. Slide + Demo
