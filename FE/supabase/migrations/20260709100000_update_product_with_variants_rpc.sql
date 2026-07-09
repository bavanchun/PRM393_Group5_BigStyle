-- ============================================================
-- Atomic manager product update with replacement variants
-- ============================================================

create or replace function public.update_product_with_variants(
  p_product_id uuid,
  p_product jsonb,
  p_variants jsonb default '[]'::jsonb
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid;
  v_role text;
  v_store_id uuid;
  v_variant jsonb;
begin
  v_user_id := auth.uid();
  if v_user_id is null then
    raise exception 'Not authenticated';
  end if;

  select role
  into v_role
  from public.profiles
  where id = v_user_id;

  if v_role not in ('manager', 'admin') then
    raise exception 'Not authorized';
  end if;

  select store_id
  into v_store_id
  from public.products
  where id = p_product_id
  for update;

  if not found then
    raise exception 'Product % not found', p_product_id;
  end if;

  if v_role <> 'admin' and v_store_id is distinct from v_user_id then
    raise exception 'Not authorized for product %', p_product_id;
  end if;

  update public.products
  set
    name = coalesce(p_product->>'name', name),
    description = case
      when p_product ? 'description' then p_product->>'description'
      else description
    end,
    base_price = case
      when p_product ? 'base_price' then (p_product->>'base_price')::numeric
      else base_price
    end,
    sale_price = case
      when p_product ? 'sale_price' then (p_product->>'sale_price')::numeric
      else sale_price
    end,
    images = case
      when p_product ? 'images' then array(
        select jsonb_array_elements_text(coalesce(p_product->'images', '[]'::jsonb))
      )
      else images
    end,
    category_id = case
      when p_product ? 'category_id' then nullif(p_product->>'category_id', '')::uuid
      else category_id
    end,
    avg_rating = case
      when p_product ? 'avg_rating' then (p_product->>'avg_rating')::numeric
      else avg_rating
    end,
    review_count = case
      when p_product ? 'review_count' then (p_product->>'review_count')::int
      else review_count
    end,
    is_featured = case
      when p_product ? 'is_featured' then (p_product->>'is_featured')::boolean
      else is_featured
    end,
    is_active = case
      when p_product ? 'is_active' then (p_product->>'is_active')::boolean
      else is_active
    end,
    material = case
      when p_product ? 'material' then p_product->>'material'
      else material
    end,
    elasticity = case
      when p_product ? 'elasticity' then p_product->>'elasticity'
      else elasticity
    end,
    store_id = case
      when v_role = 'admin' and p_product ? 'store_id'
        then nullif(p_product->>'store_id', '')::uuid
      else store_id
    end,
    updated_at = now()
  where id = p_product_id;

  delete from public.product_variants
  where product_id = p_product_id;

  for v_variant in
    select *
    from jsonb_array_elements(coalesce(p_variants, '[]'::jsonb))
  loop
    insert into public.product_variants (
      product_id,
      size,
      color,
      color_hex,
      stock_qty,
      sku,
      height_range,
      weight_range,
      bust_range,
      waist_range,
      hips_range,
      arm_range,
      thigh_range,
      shoulder_range
    ) values (
      p_product_id,
      v_variant->>'size',
      v_variant->>'color',
      v_variant->>'color_hex',
      coalesce((v_variant->>'stock_qty')::int, 0),
      nullif(v_variant->>'sku', ''),
      nullif(v_variant->>'height_range', ''),
      nullif(v_variant->>'weight_range', ''),
      nullif(v_variant->>'bust_range', ''),
      nullif(v_variant->>'waist_range', ''),
      nullif(v_variant->>'hips_range', ''),
      nullif(v_variant->>'arm_range', ''),
      nullif(v_variant->>'thigh_range', ''),
      nullif(v_variant->>'shoulder_range', '')
    );
  end loop;

  return p_product_id;
end;
$$;
