-- Performance advisor: 21 RLS policies re-evaluate auth.uid() per row
-- instead of once per query. Wrap every bare auth.uid() call in
-- `(select auth.uid())` so Postgres can cache it as an InitPlan. Pure
-- mechanical rewrite — every USING/WITH CHECK expression is otherwise
-- byte-for-byte identical to its current definition (verified against
-- pg_policies before writing this). is_admin()/is_manager()/is_staff()
-- calls are untouched — they're separate STABLE functions, not the bare
-- auth.<function>() pattern the advisor flags. Policy consolidation
-- (120 "multiple permissive policies" warnings) is explicitly OUT of
-- scope for this migration — cut per red-team review (max blast radius,
-- silent RLS broadening risk, no real benefit at this project's scale).

alter policy "Users can view own profile" on public.profiles
  using ((select auth.uid()) = id);

alter policy "Users can update own profile" on public.profiles
  using ((select auth.uid()) = id);

alter policy "Users own their cart" on public.cart
  using ((select auth.uid()) = user_id);

alter policy "Users own their cart items" on public.cart_items
  using (exists (
    select 1 from public.cart
    where cart.id = cart_items.cart_id and cart.user_id = (select auth.uid())
  ));

alter policy "Users see own orders" on public.orders
  using ((select auth.uid()) = user_id);

alter policy "Users can insert orders" on public.orders
  with check ((select auth.uid()) = user_id);

alter policy "Purchasers update own verified reviews" on public.reviews
  using ((select auth.uid()) = user_id)
  with check (
    (select auth.uid()) = user_id
    and exists (
      select 1
      from public.order_items oi
      join public.orders o on o.id = oi.order_id
      join public.product_variants pv on pv.id = oi.variant_id
      where oi.id = reviews.order_item_id
        and o.user_id = (select auth.uid())
        and o.status = 'delivered'::order_status
        and pv.product_id = reviews.product_id
    )
  );

alter policy "Users see own order items" on public.order_items
  using (exists (
    select 1 from public.orders
    where orders.id = order_items.order_id and orders.user_id = (select auth.uid())
  ));

alter policy "Users can insert order items" on public.order_items
  with check (exists (
    select 1 from public.orders
    where orders.id = order_items.order_id and orders.user_id = (select auth.uid())
  ));

alter policy "Users see own payments" on public.payments
  using ((select auth.uid()) = user_id);

alter policy "Users manage own notifications" on public.notifications
  using ((select auth.uid()) = user_id);

alter policy "Users manage own chat messages" on public.chat_messages
  using ((select auth.uid()) = user_id);

alter policy "Purchasers insert own verified reviews" on public.reviews
  with check (
    (select auth.uid()) = user_id
    and exists (
      select 1
      from public.order_items oi
      join public.orders o on o.id = oi.order_id
      join public.product_variants pv on pv.id = oi.variant_id
      where oi.id = reviews.order_item_id
        and o.user_id = (select auth.uid())
        and o.status = 'delivered'::order_status
        and pv.product_id = reviews.product_id
    )
  );

alter policy "Users manage own wishlist" on public.wishlist_items
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

alter policy "Users can insert own payments" on public.payments
  with check ((select auth.uid()) = user_id);

alter policy "Managers manage own products" on public.products
  using (is_manager() and store_id = (select auth.uid()));

alter policy "Managers manage own variants" on public.product_variants
  using (exists (
    select 1 from public.products
    where products.id = product_variants.product_id
      and products.store_id = (select auth.uid())
  ));

alter policy "Customer sees own conversation" on public.support_conversations
  using (customer_id = (select auth.uid()));

alter policy "Participants see conversation messages" on public.support_messages
  using (
    is_staff()
    or exists (
      select 1 from public.support_conversations c
      where c.id = support_messages.conversation_id and c.customer_id = (select auth.uid())
    )
  );

alter policy "Customer sends to own conversation" on public.support_messages
  with check (
    sender_id = (select auth.uid())
    and exists (
      select 1 from public.support_conversations c
      where c.id = support_messages.conversation_id and c.customer_id = (select auth.uid())
    )
  );

alter policy "Staff sends to any conversation" on public.support_messages
  with check (is_staff() and sender_id = (select auth.uid()));
