-- ============================================================
-- FIX: infinite recursion in RLS policy for "profiles"
-- ============================================================
-- Nguyên nhân: policy manager trên bảng profiles tự SELECT lại
-- profiles để check role => đệ quy vô hạn (mã lỗi 42P17). Mọi bảng
-- check role manager qua subquery profiles cũng bị kéo theo => app
-- không đọc được dữ liệu.
--
-- Cách fix chuẩn Supabase: dùng hàm SECURITY DEFINER chạy với quyền
-- owner (bỏ qua RLS) nên không kích hoạt lại policy của profiles.
-- Chạy toàn bộ file này trong Supabase Dashboard > SQL Editor.
-- ============================================================

-- 1) Helper: kiểm tra user hiện tại có phải manager (bỏ qua RLS)
create or replace function public.is_manager()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.profiles
    where id = auth.uid() and role = 'manager'
  );
$$;

-- 2) Bảng profiles — thay policy đệ quy
drop policy if exists "Managers can view all profiles" on public.profiles;
create policy "Managers can view all profiles"
  on public.profiles for select
  using (public.is_manager());

-- 3) Các bảng khác — đổi sang dùng is_manager() cho gọn & an toàn
drop policy if exists "Managers can manage categories" on public.categories;
create policy "Managers can manage categories"
  on public.categories for all
  using (public.is_manager());

drop policy if exists "Managers can manage products" on public.products;
create policy "Managers can manage products"
  on public.products for all
  using (public.is_manager());

drop policy if exists "Managers can manage variants" on public.product_variants;
create policy "Managers can manage variants"
  on public.product_variants for all
  using (public.is_manager());

drop policy if exists "Managers manage all orders" on public.orders;
create policy "Managers manage all orders"
  on public.orders for all
  using (public.is_manager());

drop policy if exists "Managers see all order items" on public.order_items;
create policy "Managers see all order items"
  on public.order_items for select
  using (public.is_manager());

drop policy if exists "Managers manage all payments" on public.payments;
create policy "Managers manage all payments"
  on public.payments for all
  using (public.is_manager());

-- 4) Storage: ảnh sản phẩm do manager upload
drop policy if exists "Managers upload product images" on storage.objects;
create policy "Managers upload product images"
  on storage.objects for insert
  with check (bucket_id = 'products' and public.is_manager());
