-- ============================================================
-- Migration: Thu gọn order_status enum + thêm cancellation_reason
-- ============================================================

-- 1. Xóa default của column status
alter table public.orders
  alter column status drop default;

-- 2. Tạo enum mới (bỏ processing, refunded)
create type order_status_new as enum (
  'pending',
  'confirmed',
  'shipping',
  'delivered',
  'cancelled'
);

-- 3. Cập nhật cột status
alter table public.orders
  alter column status type order_status_new
  using status::text::order_status_new;

-- 4. Xóa enum cũ
drop type order_status;

-- 5. Đổi tên enum mới
alter type order_status_new rename to order_status;

-- 6. Thêm default lại
alter table public.orders
  alter column status set default 'pending'::order_status;

-- 7. Thêm cột cancellation_reason
alter table public.orders
  add column cancellation_reason text;
