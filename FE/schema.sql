-- ============================================================
-- CurveFit — Supabase Schema
-- File: 01_schema.sql
-- Chạy file này TRƯỚC trong Supabase > SQL Editor
-- ============================================================

-- ============================================================
-- BẢNG 1: profiles (mở rộng auth.users)
-- ============================================================
create table public.profiles (
  id              uuid references auth.users(id) on delete cascade primary key,
  email           text not null,
  full_name       text,
  phone           text,
  avatar_url      text,
  role            text not null default 'customer'
                    check (role in ('customer', 'manager', 'admin')),
  brand_name      text,
  brand_logo_url  text,
  address         jsonb,
  -- address format: {"street":"123 Nguyễn Huệ","district":"Quận 1","city":"TP.HCM","lat":10.7769,"lng":106.7009}
  body_measurements jsonb,
  -- body_measurements format: {"bust":100,"waist":90,"hip":110}
  created_at      timestamptz default now(),
  updated_at      timestamptz default now()
);

-- Trigger: tự tạo profile khi có user mới đăng ký
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, email)
  values (new.id, new.email);
  return new;
end;
$$ language plpgsql security definer;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- Helper: check manager role without triggering RLS (avoids recursion on profiles)
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

-- RLS
alter table public.profiles enable row level security;

create policy "Users can view own profile"
  on public.profiles for select
  using (auth.uid() = id);

create policy "Users can update own profile"
  on public.profiles for update
  using (auth.uid() = id);

create policy "Managers can view all profiles"
  on public.profiles for select
  using (public.is_manager());


-- ============================================================
-- BẢNG 2: categories
-- ============================================================
create table public.categories (
  id          uuid default gen_random_uuid() primary key,
  name        text not null,
  slug        text not null unique,
  image_url   text,
  sort_order  int default 0,
  is_active   boolean default true,
  created_at  timestamptz default now()
);

alter table public.categories enable row level security;

create policy "Anyone can view active categories"
  on public.categories for select
  using (is_active = true);

create policy "Managers can manage categories"
  on public.categories for all
  using (public.is_manager());


-- ============================================================
-- BẢNG 3: products
-- ============================================================
create table public.products (
  id              uuid default gen_random_uuid() primary key,
  category_id     uuid references public.categories(id) on delete set null,
  store_id        uuid references public.profiles(id) on delete set null,
  name            text not null,
  description     text,
  slug            text not null unique,
  images          text[] default '{}',
  base_price      numeric(12,0) not null,
  sale_price      numeric(12,0),
  is_featured     boolean default false,
  is_active       boolean default true,
  material        text,
  elasticity      text,
  body_type_fit   text[] default '{}',
  -- body_type_fit values: 'apple','pear','hourglass','rectangle'
  tags            text[] default '{}',
  avg_rating      numeric(3,2) default 0,
  review_count    int default 0,
  created_at      timestamptz default now(),
  updated_at      timestamptz default now()
);

alter table public.products enable row level security;

create policy "Anyone can view active products"
  on public.products for select
  using (is_active = true);

create policy "Managers manage own products"
  on public.products for all
  using (public.is_manager() AND store_id = auth.uid());


-- ============================================================
-- BẢNG 4: product_variants
-- ============================================================
create table public.product_variants (
  id          uuid default gen_random_uuid() primary key,
  product_id  uuid references public.products(id) on delete cascade,
  size        text not null check (size in ('M','L','XL','2XL','3XL','4XL','5XL')),
  color       text not null,
  color_hex   text,
  stock_qty       int not null default 0 check (stock_qty >= 0),
  sku             text unique,
  height_range    text,
  weight_range    text,
  bust_range      text,
  waist_range     text,
  hips_range      text,
  arm_range       text,
  thigh_range     text,
  shoulder_range  text,
  created_at      timestamptz default now()
);

alter table public.product_variants enable row level security;

create policy "Anyone can view variants"
  on public.product_variants for select using (true);

create policy "Managers can manage variants"
  on public.product_variants for all
  using (public.is_manager());


-- ============================================================
-- BẢNG 5: cart + cart_items
-- ============================================================
create table public.cart (
  id              uuid default gen_random_uuid() primary key,
  user_id         uuid references public.profiles(id) on delete cascade unique,
  promo_code      text,
  discount_amount numeric(12,0) default 0,
  created_at      timestamptz default now(),
  updated_at      timestamptz default now()
);

create table public.cart_items (
  id          uuid default gen_random_uuid() primary key,
  cart_id     uuid references public.cart(id) on delete cascade,
  variant_id  uuid references public.product_variants(id) on delete cascade,
  quantity    int not null default 1 check (quantity > 0),
  added_at    timestamptz default now(),
  unique(cart_id, variant_id)
);

alter table public.cart enable row level security;
alter table public.cart_items enable row level security;

create policy "Users own their cart"
  on public.cart for all
  using (auth.uid() = user_id);

create policy "Users own their cart items"
  on public.cart_items for all
  using (
    exists (
      select 1 from public.cart
      where id = cart_id and user_id = auth.uid()
    )
  );


-- ============================================================
-- BẢNG 6: orders + order_items
-- ============================================================
create type order_status as enum (
  'pending',
  'confirmed',
  'processing',
  'shipping',
  'delivered',
  'cancelled',
  'refunded'
);

create table public.orders (
  id               uuid default gen_random_uuid() primary key,
  order_number     text unique default
                     'CF-' || to_char(now(), 'YYYYMMDD') || '-' ||
                     upper(substr(gen_random_uuid()::text, 1, 6)),
  user_id          uuid references public.profiles(id) on delete set null,
  status           order_status default 'pending',
  shipping_address jsonb not null,
  -- {"name":"Nguyễn A","phone":"0912345678","street":"123 Lê Lợi","district":"Q.1","city":"TP.HCM","lat":10.7769,"lng":106.7009}
  shipping_fee     numeric(12,0) default 0,
  subtotal         numeric(12,0) not null,
  discount_amount  numeric(12,0) default 0,
  total            numeric(12,0) not null,
  payment_method   text check (payment_method in ('cod','vnpay','momo')),
  notes            text,
  created_at       timestamptz default now(),
  updated_at       timestamptz default now()
);

create table public.order_items (
  id            uuid default gen_random_uuid() primary key,
  order_id      uuid references public.orders(id) on delete cascade,
  variant_id    uuid references public.product_variants(id) on delete set null,
  product_name  text not null,
  product_image text,
  size          text not null,
  color         text not null,
  quantity      int not null check (quantity > 0),
  unit_price    numeric(12,0) not null
);

alter table public.orders enable row level security;
alter table public.order_items enable row level security;

create policy "Users see own orders"
  on public.orders for select
  using (auth.uid() = user_id);

create policy "Users can insert orders"
  on public.orders for insert
  with check (auth.uid() = user_id);

create policy "Managers manage all orders"
  on public.orders for all
  using (public.is_manager());

create policy "Users see own order items"
  on public.order_items for select
  using (
    exists (
      select 1 from public.orders
      where id = order_id and user_id = auth.uid()
    )
  );

create policy "Users can insert order items"
  on public.order_items for insert
  with check (
    exists (
      select 1 from public.orders
      where id = order_id and user_id = auth.uid()
    )
  );

create policy "Managers see all order items"
  on public.order_items for all
  using (public.is_manager());


-- ============================================================
-- BẢNG 7: payments
-- ============================================================
create table public.payments (
  id               uuid default gen_random_uuid() primary key,
  order_id         uuid references public.orders(id) on delete cascade,
  user_id          uuid references public.profiles(id) on delete set null,
  method           text not null check (method in ('cod','vnpay','momo')),
  amount           numeric(12,0) not null,
  status           text default 'pending'
                     check (status in ('pending','success','failed','refunded')),
  transaction_id   text,
  gateway_response jsonb,
  paid_at          timestamptz,
  created_at       timestamptz default now()
);

alter table public.payments enable row level security;

create policy "Users see own payments"
  on public.payments for select
  using (auth.uid() = user_id);

create policy "Managers manage all payments"
  on public.payments for all
  using (public.is_manager());


-- ============================================================
-- BẢNG 8: notifications
-- ============================================================
create table public.notifications (
  id          uuid default gen_random_uuid() primary key,
  user_id     uuid references public.profiles(id) on delete cascade,
  title       text not null,
  body        text not null,
  type        text check (type in ('order_update','promotion','system','new_product')),
  data        jsonb,
  is_read     boolean default false,
  created_at  timestamptz default now()
);

alter table public.notifications enable row level security;

create policy "Users manage own notifications"
  on public.notifications for all
  using (auth.uid() = user_id);

-- Trigger: tự động tạo notification khi order status thay đổi
create or replace function public.notify_order_update()
returns trigger as $$
begin
  if old.status is distinct from new.status then
    insert into public.notifications (user_id, title, body, type, data)
    values (
      new.user_id,
      'Cập nhật đơn hàng ' || new.order_number,
      case new.status
        when 'confirmed'   then '✅ Đơn hàng đã được xác nhận!'
        when 'processing'  then '⚙️ Đơn hàng đang được chuẩn bị'
        when 'shipping'    then '🚚 Đơn hàng đang trên đường giao đến bạn'
        when 'delivered'   then '🎉 Đơn hàng đã được giao thành công!'
        when 'cancelled'   then '❌ Đơn hàng đã bị hủy'
        when 'refunded'    then '💰 Đơn hàng đã được hoàn tiền'
        else 'Trạng thái đơn hàng: ' || new.status::text
      end,
      'order_update',
      jsonb_build_object('order_id', new.id, 'status', new.status::text, 'order_number', new.order_number)
    );
  end if;
  return new;
end;
$$ language plpgsql security definer;

create trigger on_order_status_change
  after update on public.orders
  for each row execute procedure public.notify_order_update();


-- ============================================================
-- BẢNG 9: reviews
-- ============================================================
create table public.reviews (
  id            uuid default gen_random_uuid() primary key,
  product_id    uuid references public.products(id) on delete cascade,
  user_id       uuid references public.profiles(id) on delete set null,
  order_item_id uuid references public.order_items(id) on delete set null,
  rating        int not null check (rating between 1 and 5),
  comment       text,
  images        text[] default '{}',
  size_feedback text check (size_feedback in ('smaller','true_to_size','larger')),
  is_verified   boolean default false,
  created_at    timestamptz default now(),
  unique(product_id, user_id)
);

alter table public.reviews enable row level security;

create policy "Anyone can view reviews"
  on public.reviews for select using (true);

create policy "Users insert own reviews"
  on public.reviews for insert
  with check (auth.uid() = user_id);

create policy "Users update own reviews"
  on public.reviews for update
  using (auth.uid() = user_id);

-- Trigger: tự động cập nhật avg_rating trên products
create or replace function public.update_product_rating()
returns trigger as $$
begin
  update public.products set
    avg_rating   = (select round(avg(rating)::numeric, 2) from public.reviews where product_id = new.product_id),
    review_count = (select count(*)                        from public.reviews where product_id = new.product_id),
    updated_at   = now()
  where id = new.product_id;
  return new;
end;
$$ language plpgsql;

create trigger on_review_insert
  after insert on public.reviews
  for each row execute procedure public.update_product_rating();

create trigger on_review_update
  after update on public.reviews
  for each row execute procedure public.update_product_rating();


-- ============================================================
-- BẢNG 10: chat_messages
-- ============================================================
create table public.chat_messages (
  id          uuid default gen_random_uuid() primary key,
  user_id     uuid references public.profiles(id) on delete cascade,
  role        text not null check (role in ('user','assistant')),
  content     text not null,
  metadata    jsonb,
  created_at  timestamptz default now()
);

alter table public.chat_messages enable row level security;

create policy "Users manage own chat messages"
  on public.chat_messages for all
  using (auth.uid() = user_id);


-- ============================================================
-- STORAGE BUCKETS
-- ============================================================
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values
  ('products', 'products', true,  5242880, array['image/jpeg','image/png','image/webp']),
  ('avatars',  'avatars',  false, 2097152, array['image/jpeg','image/png','image/webp']),
  ('reviews',  'reviews',  true,  5242880, array['image/jpeg','image/png','image/webp'])
on conflict (id) do nothing;

-- Storage RLS policies
create policy "Public can view product images"
  on storage.objects for select
  using (bucket_id = 'products');

create policy "Managers upload product images"
  on storage.objects for insert
  with check (
    bucket_id = 'products' and
    public.is_manager()
  );

create policy "Users manage own avatars"
  on storage.objects for all
  using (bucket_id = 'avatars' and auth.uid()::text = (storage.foldername(name))[1]);

create policy "Public can view review images"
  on storage.objects for select
  using (bucket_id = 'reviews');

create policy "Users upload review images"
  on storage.objects for insert
  with check (bucket_id = 'reviews' and auth.role() = 'authenticated');


-- ============================================================
-- INDEXES (tăng tốc query)
-- ============================================================
create index idx_products_category    on public.products(category_id);
create index idx_products_is_active   on public.products(is_active);
create index idx_products_is_featured on public.products(is_featured);
create index idx_products_name_search on public.products using gin(to_tsvector('simple', name));
create index idx_variants_product     on public.product_variants(product_id);
create index idx_cart_items_cart      on public.cart_items(cart_id);
create index idx_orders_user          on public.orders(user_id);
create index idx_orders_status        on public.orders(status);
create index idx_order_items_order    on public.order_items(order_id);
create index idx_notifications_user   on public.notifications(user_id, is_read, created_at desc);
create index idx_reviews_product      on public.reviews(product_id);
create index idx_chat_user            on public.chat_messages(user_id, created_at desc);