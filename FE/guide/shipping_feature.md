# Hướng dẫn tính năng Phí vận chuyển

## Tổng quan

Tính năng tính phí vận chuyển theo mô hình **tỉnh → tỉnh** (giống Shopee), admin quản lý bảng giá, khách hàng chọn địa chỉ đã lưu khi checkout.

---

## Cấu trúc Database

### 1. Bảng `customer_addresses` (Địa chỉ khách hàng)

```sql
CREATE TABLE public.customer_addresses (
  id          uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id     uuid REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  label       text NOT NULL DEFAULT 'Nhà',  -- Nhà, Cơ quan, Khác
  full_name   text NOT NULL,
  phone       text,
  address     text NOT NULL,  -- Địa chỉ cụ thể (số nhà, đường...)
  province    text NOT NULL,  -- Tỉnh/Thành phố
  district    text,           -- Quận/Huyện
  ward        text,           -- Phường/Xã
  latitude    double precision,
  longitude   double precision,
  is_default  boolean DEFAULT false,
  created_at  timestamptz DEFAULT now()
);
```

- **RLS**: Khách chỉ CRUD được địa chỉ của mình (`user_id = auth.uid()`)
- Mỗi khách có nhiều địa chỉ, 1 địa chỉ `is_default = true`

### 2. Bảng `shipping_rates` (Bảng giá vận chuyển)

```sql
CREATE TABLE public.shipping_rates (
  id              uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  from_province   text NOT NULL,
  to_province     text NOT NULL,
  base_fee        double precision NOT NULL DEFAULT 30000,
  free_threshold  double precision DEFAULT 0,  -- Miễn ship từ đơn này
  is_active       boolean DEFAULT true,
  updated_at      timestamptz DEFAULT now(),
  UNIQUE(from_province, to_province)
);
```

- **RLS**: Chỉ admin mới CRUD được (xem `profiles.role = 'admin'`)
- 27 tuyến đã seed sẵn cho các tỉnh thành lớn

### 3. Seed Data (27 tuyến)

| Tuyến | Phí (VND) | Miễn ship từ |
|-------|-----------|--------------|
| HCM → Hà Nội | 35,000 | 500,000 |
| HCM → Đà Nẵng | 30,000 | 400,000 |
| HCM → Hải Phòng | 35,000 | 500,000 |
| HCM → Cần Thơ | 20,000 | 250,000 |
| HCM → Bình Dương | 15,000 | 200,000 |
| HCM → Đồng Nai | 18,000 | 250,000 |
| HCM → Long An | 15,000 | 200,000 |
| HCM → Bà Rịa - Vũng Tàu | 15,000 | 200,000 |
| Hà Nội → HCM | 35,000 | 500,000 |
| Hà Nội → Đà Nẵng | 25,000 | 350,000 |
| Hà Nội → Hải Phòng | 15,000 | 200,000 |
| Hà Nội → Quảng Ninh | 20,000 | 300,000 |
| Đà Nẵng → HCM | 30,000 | 400,000 |
| Đà Nẵng → Hà Nội | 25,000 | 350,000 |
| *...và 13 tuyến nữa* | | |

**Tuyến nội tỉnh** (cùng tỉnh): 15,000đ

---

## Flow hoạt động

### 1. Khách hàng lưu địa chỉ

```
Profile → Địa chỉ giao hàng → Thêm địa chỉ mới
```

- Chọn nhãn: Nhà / Cơ quan / Khác
- Nhập: Họ tên, SĐT, Địa chỉ cụ thể, Tỉnh/TP, Quận/Huyện, Phường/Xã
- Đặt làm mặc định (optional)

### 2. Checkout - Chọn địa chỉ

```
CheckoutScreen
├── Danh sách địa chỉ đã lưu (Radio buttons)
│   ├── [Nhà] Nguyễn Văn A - 0912... - 123 Lê Lợi, Q.1, HCM
│   ├── [Cơ quan] Nguyễn Văn A - 0912... - 456 Nguyễn Huệ, Q.3, HCM
│   └── [Nhập tay] (text field)
├── Nút "Vị trí hiện tại" (GPS → reverse geocode)
└── Tính phí ship tự động theo tỉnh
```

- Chọn địa chỉ → `ShippingService.calculateShippingFee()` lookup theo `from_province → to_province`
- Subtotal >= `free_threshold` → **Miễn ship** (phí = 0)
- Fallback: `AppConfig.flatShippingFee = 30,000đ`

### 3. Admin quản lý bảng giá

```
Admin Shell → Tab "Vận chuyển"
├── Danh sách tuyến vận chuyển
├── Thêm tuyến mới (dropdown tỉnh → tỉnh + phí + ngưỡng miễn ship)
├── Sửa / Tắt / Bật / Xóa tuyến
```

---

## Code Reference

### Files mới tạo

```
FE/lib/models/customer_address_model.dart    - Model địa chỉ khách hàng
FE/lib/models/shipping_rate_model.dart       - Model bảng giá ship
FE/lib/services/address_service.dart         - CRUD địa chỉ
FE/lib/services/shipping_service.dart        - Lookup phí ship + admin CRUD
FE/lib/screens/profile/addresses_screen.dart - Danh sách địa chỉ (Shopee-style)
FE/lib/screens/profile/address_form_screen.dart - Form thêm/sửa địa chỉ
FE/lib/screens/admin/admin_shipping_screen.dart - Admin quản lý bảng giá
```

### Files sửa đổi

```
FE/lib/screens/profile/profile_screen.dart   - Thêm menu "Địa chỉ giao hàng"
FE/lib/screens/checkout/checkout_screen.dart - Chọn địa chỉ + tính ship realtime
FE/lib/config/routes/app_router.dart         - Thêm route /addresses, /address-form
FE/lib/screens/admin/admin_shell.dart        - Thêm tab "Vận chuyển"
```

### Migration

```
FE/supabase/migrations/20260710100000_customer_addresses_and_shipping_rates.sql
```

---

## API Reference

### AddressService

```dart
// Lấy danh sách địa chỉ (sorted: default trước, mới nhất trước)
Future<List<CustomerAddressModel>> getAddresses(String userId)

// Lấy địa chỉ mặc định
Future<CustomerAddressModel?> getDefaultAddress(String userId)

// Tạo địa chỉ mới
Future<CustomerAddressModel> createAddress(CustomerAddressModel address)

// Cập nhật địa chỉ
Future<CustomerAddressModel> updateAddress(CustomerAddressModel address)

// Xóa địa chỉ
Future<void> deleteAddress(String addressId)

// Đặt mặc định
Future<void> setDefault(String addressId, String userId)
```

### ShippingService

```dart
// Tính phí ship theo tuyến tỉnh
Future<double> calculateShippingFee({
  required String fromProvince,
  required String toProvince,
  required double subtotal,  // Dùng để check free_threshold
})

// Admin: Lấy tất cả tuyến
Future<List<ShippingRateModel>> getAllRates()

// Admin: Thêm/sửa tuyến (upsert on conflict from_province,to_province)
Future<ShippingRateModel> upsertRate(ShippingRateModel rate)

// Admin: Bật/tắt tuyến
Future<void> toggleRate(String rateId, bool isActive)

// Admin: Xóa tuyến
Future<void> deleteRate(String rateId)
```

---

## Quy tắc tính phí

```
1. Tìm tuyến (from_province, to_province) trong shipping_rates
2. Nếu không tìm thấy → dùng flatShippingFee (30,000đ)
3. Nếu subtotal >= free_threshold → phí = 0 (miễn ship)
4. Ngược lại → phí = base_fee
```

---

---

## API Tỉnh/Thành phố

Sử dụng API miễn phí: **https://provinces.open-api.vn/**

| Endpoint | Mô tả |
|----------|-------|
| `GET /api/p/` | Danh sách tỉnh/thành |
| `GET /api/p/{code}?depth=2` | Tỉnh + danh sách quận/huyện |
| `GET /api/d/{code}?depth=2` | Quận/huyện + danh sách phường/xã |

**Định dạng tên tỉnh từ API:**
- "Thành phố Hồ Chí Minh", "Thành phố Hà Nội", "Thành phố Đà Nẵng"
- "Tỉnh Bình Dương", "Tỉnh Đồng Nai"

→ `shipping_rates` lưu tên khớp hoàn toàn với format này (đã update migration).

**File liên quan:**
- `FE/lib/services/vietnam_address_service.dart` — Province, District, Ward models + API fetcher
- `FE/lib/screens/profile/address_form_screen.dart` —Dropdown cascade khi thêm/sửa địa chỉ

---

## Cách thêm tỉnh mới

1. Vào Admin Shell → Tab "Vận chuyển"
2. Nhấn "+" (thêm tuyến)
3. Chọn From → To, nhập phí, ngưỡng miễn ship
4. Lưu

Hoặc SQL trực tiếp:

```sql
INSERT INTO shipping_rates (from_province, to_province, base_fee, free_threshold)
VALUES ('Bình Định', 'TP. Hồ Chí Minh', 28000, 350000);
```

---

## Thêm tuyến cho shop manager

Hiện tại shop mặc định là **TP. Hồ Chí Minh**. Nếu shop chuyển vị trí:

```sql
UPDATE shop_profiles
SET address = '{"province": "Hà Nội"}'::jsonb
WHERE id = 'manager-uuid';
```

Rồi thêm tuyến từ Hà Nội:

```sql
INSERT INTO shipping_rates (from_province, to_province, base_fee, free_threshold)
VALUES ('Hà Nội', 'TP. Hồ Chí Minh', 35000, 500000);
```

---

## Lưu ý

- `customer_addresses` thay thế `profiles.address` (jsonb) cũ - hiện profiles.address không dùng
- `orders.shipping_fee` đang lưu 30,000 fixed - sẽ cập nhật để lưu dynamic fee từ checkout
- `create_order` RPC hiện dùng `p_address` text - tương lai có thể thêm `p_shipping_address_id`
- Nominatim reverse geocode cần header `User-Agent: 'BigStyle/1.0 (bigstyle-app)'`
