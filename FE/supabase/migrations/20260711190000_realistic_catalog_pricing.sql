-- Catalog data cleanup: every product was priced at a uniform 10.000đ
-- test-junk placeholder. order_items has only two genuinely distinct
-- captured unit_price values (10000, 350000) — 10000 is the placeholder
-- itself, not real market data, so it's retired rather than reused;
-- 350000 is the one real differentiated price point and anchors the
-- ceiling of the new bands below. Bands are set per category (accessories
-- cheapest, dresses/sets priciest), matching typical Vietnamese fashion
-- e-commerce pricing. order_items.unit_price is captured at order time and
-- untouched by this — existing orders' totals are unaffected.

update public.products set base_price = 45000,  sale_price = null   where id = 'a1000000-0000-0000-0000-000000000015'; -- Thắt Lưng Vải Phối Màu
update public.products set base_price = 89000,  sale_price = 69000  where id = 'a1000000-0000-0000-0000-000000000014'; -- Túi Tote Canvas Local Brand

update public.products set base_price = 120000, sale_price = 89000  where id = 'a1000000-0000-0000-0000-000000000006'; -- Áo Thun Oversize Cotton Basic
update public.products set base_price = 180000, sale_price = null   where id = 'a1000000-0000-0000-0000-000000000007'; -- Áo Sơ Mi Linen Mát Mẻ
update public.products set base_price = 230000, sale_price = null   where id = 'a1000000-0000-0000-0000-000000000005'; -- Áo Kiểu Bèo Ngực Sang Trọng
update public.products set base_price = 350000, sale_price = 300000 where id = 'a1000000-0000-0000-0000-000000000008'; -- Áo Blazer Nữ Dáng Dài

update public.products set base_price = 160000, sale_price = null   where id = 'a1000000-0000-0000-0000-000000000009'; -- Quần Palazzo Lưng Thun Thoải Mái
update public.products set base_price = 190000, sale_price = null   where id = 'a1000000-0000-0000-0000-000000000011'; -- Quần Culottes Kẻ Caro Vintage
update public.products set base_price = 260000, sale_price = 220000 where id = 'a1000000-0000-0000-0000-000000000010'; -- Quần Jean Skinny Bigsize Cao Cổ

update public.products set base_price = 300000, sale_price = null   where id = 'a1000000-0000-0000-0000-000000000012'; -- Set Áo Croptop + Quần Ống Rộng
update public.products set base_price = 350000, sale_price = 300000 where id = 'a1000000-0000-0000-0000-000000000013'; -- Set Sơ Mi + Quần Lửng Kẻ Sọc

update public.products set base_price = 260000, sale_price = null   where id = 'a1000000-0000-0000-0000-000000000001'; -- Đầm Hoa Nhí Tay Bồng
update public.products set base_price = 290000, sale_price = null   where id = 'a1000000-0000-0000-0000-000000000004'; -- Đầm Sơ Mi Kẻ Sọc Casual
update public.products set base_price = 330000, sale_price = 280000 where id = 'a1000000-0000-0000-0000-000000000003'; -- Đầm Wrap Tôn Dáng Đồng Hồ Cát
update public.products set base_price = 350000, sale_price = null   where id = 'a1000000-0000-0000-0000-000000000002'; -- Đầm Maxi Boho Tự Do
