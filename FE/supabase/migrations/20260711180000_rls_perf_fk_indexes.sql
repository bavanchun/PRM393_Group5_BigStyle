-- Performance advisor: 7 foreign keys without a covering index.
-- Additive, zero behavior change — safe to do unconditionally.

create index if not exists idx_cart_items_variant_id on public.cart_items (variant_id);
create index if not exists idx_order_items_variant_id on public.order_items (variant_id);
create index if not exists idx_payments_user_id on public.payments (user_id);
create index if not exists idx_reviews_order_item_id on public.reviews (order_item_id);
create index if not exists idx_reviews_user_id on public.reviews (user_id);
create index if not exists idx_support_messages_sender_id on public.support_messages (sender_id);
create index if not exists idx_wishlist_items_product_id on public.wishlist_items (product_id);
