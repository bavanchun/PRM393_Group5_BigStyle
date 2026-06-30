-- ============================================================
-- CurveFit — Seed Data
-- File: 02_seed_data.sql
-- Chạy file này SAU 01_schema.sql
-- Gồm: 5 categories, 15 sản phẩm, variants, 2 test profiles,
--       sample orders, reviews, notifications
-- ============================================================

-- ============================================================
-- CATEGORIES (5 danh mục)
-- ============================================================
insert into public.categories (id, name, slug, image_url, sort_order) values
  ('c1000000-0000-0000-0000-000000000001', 'Đầm',       'dam',       'https://images.unsplash.com/photo-1594938298603-c8148c4b1947?w=400', 1),
  ('c1000000-0000-0000-0000-000000000002', 'Áo',        'ao',        'https://images.unsplash.com/photo-1551488831-00ddcb6c6bd3?w=400', 2),
  ('c1000000-0000-0000-0000-000000000003', 'Quần',      'quan',      'https://images.unsplash.com/photo-1624378439575-d8705ad7ae80?w=400', 3),
  ('c1000000-0000-0000-0000-000000000004', 'Set đồ',    'set-do',    'https://images.unsplash.com/photo-1525507119028-ed4c629a60a3?w=400', 4),
  ('c1000000-0000-0000-0000-000000000005', 'Phụ kiện',  'phu-kien',  'https://images.unsplash.com/photo-1584917865442-de89df76afd3?w=400', 5);


-- ============================================================
-- PRODUCTS (15 sản phẩm bigsize)
-- ============================================================
insert into public.products (id, category_id, name, description, slug, images, base_price, sale_price, is_featured, body_type_fit, tags, avg_rating, review_count) values

-- ĐẦM (4 sp)
(
  'a1000000-0000-0000-0000-000000000001',
  'c1000000-0000-0000-0000-000000000001',
  'Đầm Hoa Nhí Tay Bồng',
  'Đầm hoa nhí tay bồng nhẹ nhàng, thiết kế đặc biệt giúp che khuyết điểm vùng bắp tay và tôn dáng phụ nữ bigsize. Chất liệu voan mềm mại, thoáng mát, phù hợp đi chơi và đi làm casual.',
  'dam-hoa-nhi-tay-bong',
  array[
    'https://images.unsplash.com/photo-1572804013309-59a88b7e92f1?w=600',
    'https://images.unsplash.com/photo-1515372039744-b8f02a3ae446?w=600'
  ],
  420000, 350000, true,
  array['pear','hourglass'],
  array['hoa nhí','tay bồng','đi chơi','mùa hè'],
  4.80, 24
),
(
  'a1000000-0000-0000-0000-000000000002',
  'c1000000-0000-0000-0000-000000000001',
  'Đầm Maxi Boho Tự Do',
  'Đầm maxi phong cách boho dài chấm gót, tạo cảm giác tự do và thoải mái. Thiết kế xẻ tà nhẹ giúp di chuyển dễ dàng. Phù hợp với mọi dáng người bigsize.',
  'dam-maxi-boho-tu-do',
  array[
    'https://images.unsplash.com/photo-1496747611176-843222e1e57c?w=600',
    'https://images.unsplash.com/photo-1469334031218-e382a71b716b?w=600'
  ],
  580000, null, true,
  array['apple','rectangle','pear','hourglass'],
  array['maxi','boho','dạo phố','mùa hè'],
  4.60, 18
),
(
  'a1000000-0000-0000-0000-000000000003',
  'c1000000-0000-0000-0000-000000000001',
  'Đầm Wrap Tôn Dáng Đồng Hồ Cát',
  'Đầm wrap kiểu dáng cổ điển, dây buộc eo linh hoạt tôn vóc dáng đồng hồ cát hoàn hảo. Chất liệu jersey co giãn 4 chiều cực kỳ thoải mái khi mặc cả ngày.',
  'dam-wrap-ton-dang',
  array[
    'https://images.unsplash.com/photo-1595777457583-95e059d581b8?w=600'
  ],
  490000, 420000, false,
  array['hourglass','apple'],
  array['wrap dress','công sở','sang trọng'],
  4.90, 31
),
(
  'a1000000-0000-0000-0000-000000000004',
  'c1000000-0000-0000-0000-000000000001',
  'Đầm Sơ Mi Kẻ Sọc Casual',
  'Đầm sơ mi kẻ sọc phong cách casual-chic. Cổ sơ mi tinh tế, hàng cúc giả trang trí, dây thắt eo kèm theo. Mặc thả hoặc buộc eo đều đẹp.',
  'dam-so-mi-ke-soc-casual',
  array[
    'https://images.unsplash.com/photo-1539008835657-9e8e9680c956?w=600'
  ],
  380000, null, false,
  array['rectangle','apple','pear'],
  array['sơ mi','kẻ sọc','casual','đi làm'],
  4.40, 12
),

-- ÁO (4 sp)
(
  'a1000000-0000-0000-0000-000000000005',
  'c1000000-0000-0000-0000-000000000002',
  'Áo Kiểu Bèo Ngực Sang Trọng',
  'Áo kiểu bèo ngực tinh tế, che khuyết điểm vùng bụng và tôn vòng 1. Chất voan cao cấp, không nhăn, dễ phối với quần âu hoặc chân váy.',
  'ao-kieu-beo-nguc-sang-trong',
  array[
    'https://images.unsplash.com/photo-1614251055880-ee96e4803393?w=600'
  ],
  320000, 280000, true,
  array['apple','rectangle'],
  array['bèo ngực','công sở','sang trọng'],
  4.70, 22
),
(
  'a1000000-0000-0000-0000-000000000006',
  'c1000000-0000-0000-0000-000000000002',
  'Áo Thun Oversize Cotton Basic',
  'Áo thun oversize 100% cotton combed co giãn 2 chiều. Basic nhưng thời trang, phù hợp phối với mọi loại quần. Có 8 màu sắc đa dạng.',
  'ao-thun-oversize-cotton-basic',
  array[
    'https://images.unsplash.com/photo-1521572163474-6864f9cf17ab?w=600'
  ],
  180000, null, false,
  array['apple','pear','hourglass','rectangle'],
  array['thun','oversize','basic','daily'],
  4.50, 45
),
(
  'a1000000-0000-0000-0000-000000000007',
  'c1000000-0000-0000-0000-000000000002',
  'Áo Sơ Mi Linen Mát Mẻ',
  'Áo sơ mi chất liệu linen tự nhiên, thấm hút mồ hôi tốt, cực kỳ phù hợp khí hậu Việt Nam. Phom rộng thoải mái, không lộ khuyết điểm.',
  'ao-so-mi-linen-mat-me',
  array[
    'https://images.unsplash.com/photo-1598033129183-c4f50c736f10?w=600'
  ],
  350000, 290000, false,
  array['apple','rectangle','pear'],
  array['linen','sơ mi','thoáng mát','đi làm'],
  4.60, 19
),
(
  'a1000000-0000-0000-0000-000000000008',
  'c1000000-0000-0000-0000-000000000002',
  'Áo Blazer Nữ Dáng Dài',
  'Blazer dáng dài qua hông, che eo bụng khéo léo. Chất liệu kate Nhật cao cấp, giữ form tốt. Màu đen kinh điển phù hợp mọi dịp.',
  'ao-blazer-nu-dang-dai',
  array[
    'https://images.unsplash.com/photo-1591085686350-798c0f9faa7f?w=600'
  ],
  650000, 520000, true,
  array['apple','rectangle'],
  array['blazer','công sở','thanh lịch','layer'],
  4.80, 27
),

-- QUẦN (3 sp)
(
  'a1000000-0000-0000-0000-000000000009',
  'c1000000-0000-0000-0000-000000000003',
  'Quần Palazzo Lưng Thun Thoải Mái',
  'Quần palazzo ống rộng lưng thun co giãn, cạp cao che bụng hiệu quả. Vải voan nhẹ bay bổng tạo dáng đi duyên dáng. Hot trend mùa này!',
  'quan-palazzo-lung-thun',
  array[
    'https://images.unsplash.com/photo-1509631179647-0177331693ae?w=600'
  ],
  280000, 240000, true,
  array['apple','pear','rectangle'],
  array['palazzo','ống rộng','thoải mái','che bụng'],
  4.70, 38
),
(
  'a1000000-0000-0000-0000-000000000010',
  'c1000000-0000-0000-0000-000000000003',
  'Quần Jean Skinny Bigsize Cao Cổ',
  'Quần jean skinny cạp cao đặc chế cho dáng bigsize. Chất denim co giãn 4 chiều, tôn dáng chân thon, che khuyết điểm đùi. Bền màu sau nhiều lần giặt.',
  'quan-jean-skinny-bigsize-cao-co',
  array[
    'https://images.unsplash.com/photo-1541099649105-f69ad21f3246?w=600'
  ],
  450000, null, false,
  array['pear','hourglass'],
  array['jean','skinny','cạp cao','denim'],
  4.40, 16
),
(
  'a1000000-0000-0000-0000-000000000011',
  'c1000000-0000-0000-0000-000000000003',
  'Quần Culottes Kẻ Caro Vintage',
  'Quần culottes ống lửng kẻ caro phong cách vintage-retro. Cạp cao định hình eo, ống rộng vừa phải che đùi khéo léo. Phối áo tuck in cực đẹp.',
  'quan-culottes-ke-caro-vintage',
  array[
    'https://images.unsplash.com/photo-1548690596-f1722c190938?w=600'
  ],
  320000, 270000, false,
  array['pear','apple'],
  array['culottes','caro','vintage','ống lửng'],
  4.55, 9
),

-- SET ĐỒ (2 sp)
(
  'a1000000-0000-0000-0000-000000000012',
  'c1000000-0000-0000-0000-000000000004',
  'Set Áo Croptop + Quần Ống Rộng',
  'Set đôi áo croptop dài tay + quần ống rộng cùng màu. Phối sẵn, mặc là đẹp. Chất cotton modal siêu mềm, co giãn tốt. 5 màu pastel trendy.',
  'set-ao-croptop-quan-ong-rong',
  array[
    'https://images.unsplash.com/photo-1562572159-4efc207f5aff?w=600'
  ],
  520000, 450000, true,
  array['hourglass','rectangle'],
  array['set đôi','croptop','ống rộng','pastel','trendy'],
  4.90, 42
),
(
  'a1000000-0000-0000-0000-000000000013',
  'c1000000-0000-0000-0000-000000000004',
  'Set Sơ Mi + Quần Lửng Kẻ Sọc',
  'Set đồng bộ sơ mi ngắn tay + quần lửng kẻ sọc ngang. Phong cách hè tươi trẻ, năng động. Chất cotton thoáng mát.',
  'set-so-mi-quan-lung-ke-soc',
  array[
    'https://images.unsplash.com/photo-1513094735237-8f2714d57c13?w=600'
  ],
  480000, null, false,
  array['rectangle','pear'],
  array['set đôi','sơ mi','kẻ sọc','hè'],
  4.30, 7
),

-- PHỤ KIỆN (2 sp)
(
  'a1000000-0000-0000-0000-000000000014',
  'c1000000-0000-0000-0000-000000000005',
  'Túi Tote Canvas Local Brand',
  'Túi tote canvas dày dặn, in logo CurveFit minimal. Quai da PU chắc chắn, ngăn kéo khóa tiện lợi. Đủ chỗ đựng đồ đi làm cả ngày.',
  'tui-tote-canvas-local-brand',
  array[
    'https://images.unsplash.com/photo-1584917865442-de89df76afd3?w=600'
  ],
  220000, null, false,
  array['apple','pear','hourglass','rectangle'],
  array['tote','canvas','phụ kiện','đi làm'],
  4.60, 33
),
(
  'a1000000-0000-0000-0000-000000000015',
  'c1000000-0000-0000-0000-000000000005',
  'Thắt Lưng Vải Phối Màu',
  'Thắt lưng vải phối màu pastel, tạo điểm nhấn và định hình eo hiệu quả. Phù hợp với đầm dài, áo sơ mi, blazer. Chiều dài điều chỉnh được.',
  'that-lung-vai-phoi-mau',
  array[
    'https://images.unsplash.com/photo-1624222247344-551fb3c2e1d4?w=600'
  ],
  95000, null, false,
  array['apple','pear','hourglass','rectangle'],
  array['thắt lưng','phụ kiện','tôn dáng'],
  4.20, 11
);


-- ============================================================
-- PRODUCT VARIANTS (sizes & colors cho từng sản phẩm)
-- ============================================================

-- Helper: tạo variants cho nhiều sản phẩm cùng lúc
-- Mỗi sản phẩm có 2-3 màu × 4-5 size = 8-15 variants

-- Đầm Hoa Nhí Tay Bồng (p001)
insert into public.product_variants (product_id, size, color, color_hex, stock_qty, sku) values
  ('a1000000-0000-0000-0000-000000000001', 'XL',  'Hồng Phấn', '#FFB6C1', 15, 'CF-DAM001-XL-HONG'),
  ('a1000000-0000-0000-0000-000000000001', '2XL', 'Hồng Phấn', '#FFB6C1', 20, 'CF-DAM001-2XL-HONG'),
  ('a1000000-0000-0000-0000-000000000001', '3XL', 'Hồng Phấn', '#FFB6C1', 12, 'CF-DAM001-3XL-HONG'),
  ('a1000000-0000-0000-0000-000000000001', 'XL',  'Xanh Nhạt', '#B0E0E6', 10, 'CF-DAM001-XL-XANH'),
  ('a1000000-0000-0000-0000-000000000001', '2XL', 'Xanh Nhạt', '#B0E0E6', 18, 'CF-DAM001-2XL-XANH'),
  ('a1000000-0000-0000-0000-000000000001', '3XL', 'Xanh Nhạt', '#B0E0E6',  8, 'CF-DAM001-3XL-XANH'),
  ('a1000000-0000-0000-0000-000000000001', '4XL', 'Hồng Phấn', '#FFB6C1',  6, 'CF-DAM001-4XL-HONG'),
  ('a1000000-0000-0000-0000-000000000001', '4XL', 'Xanh Nhạt', '#B0E0E6',  4, 'CF-DAM001-4XL-XANH');

-- Đầm Maxi Boho (p002)
insert into public.product_variants (product_id, size, color, color_hex, stock_qty, sku) values
  ('a1000000-0000-0000-0000-000000000002', 'L',   'Trắng Kem', '#FFF8DC', 10, 'CF-DAM002-L-KEM'),
  ('a1000000-0000-0000-0000-000000000002', 'XL',  'Trắng Kem', '#FFF8DC', 15, 'CF-DAM002-XL-KEM'),
  ('a1000000-0000-0000-0000-000000000002', '2XL', 'Trắng Kem', '#FFF8DC', 20, 'CF-DAM002-2XL-KEM'),
  ('a1000000-0000-0000-0000-000000000002', '3XL', 'Trắng Kem', '#FFF8DC', 12, 'CF-DAM002-3XL-KEM'),
  ('a1000000-0000-0000-0000-000000000002', 'XL',  'Nâu Đất',  '#8B4513', 8,  'CF-DAM002-XL-NAU'),
  ('a1000000-0000-0000-0000-000000000002', '2XL', 'Nâu Đất',  '#8B4513', 14, 'CF-DAM002-2XL-NAU'),
  ('a1000000-0000-0000-0000-000000000002', '3XL', 'Nâu Đất',  '#8B4513',  7, 'CF-DAM002-3XL-NAU');

-- Đầm Wrap (p003)
insert into public.product_variants (product_id, size, color, color_hex, stock_qty, sku) values
  ('a1000000-0000-0000-0000-000000000003', 'XL',  'Đen',      '#2D2D2D', 25, 'CF-DAM003-XL-DEN'),
  ('a1000000-0000-0000-0000-000000000003', '2XL', 'Đen',      '#2D2D2D', 30, 'CF-DAM003-2XL-DEN'),
  ('a1000000-0000-0000-0000-000000000003', '3XL', 'Đen',      '#2D2D2D', 20, 'CF-DAM003-3XL-DEN'),
  ('a1000000-0000-0000-0000-000000000003', '4XL', 'Đen',      '#2D2D2D', 10, 'CF-DAM003-4XL-DEN'),
  ('a1000000-0000-0000-0000-000000000003', 'XL',  'Đỏ Đô',   '#8B0000', 12, 'CF-DAM003-XL-DO'),
  ('a1000000-0000-0000-0000-000000000003', '2XL', 'Đỏ Đô',   '#8B0000', 18, 'CF-DAM003-2XL-DO'),
  ('a1000000-0000-0000-0000-000000000003', '3XL', 'Đỏ Đô',   '#8B0000',  9, 'CF-DAM003-3XL-DO');

-- Đầm Sơ Mi Kẻ Sọc (p004)
insert into public.product_variants (product_id, size, color, color_hex, stock_qty, sku) values
  ('a1000000-0000-0000-0000-000000000004', 'L',   'Xanh-Trắng', '#4169E1', 10, 'CF-DAM004-L-XANHTR'),
  ('a1000000-0000-0000-0000-000000000004', 'XL',  'Xanh-Trắng', '#4169E1', 15, 'CF-DAM004-XL-XANHTR'),
  ('a1000000-0000-0000-0000-000000000004', '2XL', 'Xanh-Trắng', '#4169E1', 20, 'CF-DAM004-2XL-XANHTR'),
  ('a1000000-0000-0000-0000-000000000004', '3XL', 'Xanh-Trắng', '#4169E1',  8, 'CF-DAM004-3XL-XANHTR');

-- Áo Kiểu Bèo Ngực (p005)
insert into public.product_variants (product_id, size, color, color_hex, stock_qty, sku) values
  ('a1000000-0000-0000-0000-000000000005', 'XL',  'Trắng',    '#FFFFFF', 20, 'CF-AO005-XL-TR'),
  ('a1000000-0000-0000-0000-000000000005', '2XL', 'Trắng',    '#FFFFFF', 25, 'CF-AO005-2XL-TR'),
  ('a1000000-0000-0000-0000-000000000005', '3XL', 'Trắng',    '#FFFFFF', 15, 'CF-AO005-3XL-TR'),
  ('a1000000-0000-0000-0000-000000000005', 'XL',  'Đen',      '#2D2D2D', 18, 'CF-AO005-XL-DEN'),
  ('a1000000-0000-0000-0000-000000000005', '2XL', 'Đen',      '#2D2D2D', 22, 'CF-AO005-2XL-DEN'),
  ('a1000000-0000-0000-0000-000000000005', '3XL', 'Đen',      '#2D2D2D', 10, 'CF-AO005-3XL-DEN'),
  ('a1000000-0000-0000-0000-000000000005', '4XL', 'Trắng',    '#FFFFFF',  5, 'CF-AO005-4XL-TR');

-- Áo Thun Oversize (p006) — nhiều màu
insert into public.product_variants (product_id, size, color, color_hex, stock_qty, sku) values
  ('a1000000-0000-0000-0000-000000000006', 'L',   'Đen',      '#2D2D2D', 30, 'CF-AO006-L-DEN'),
  ('a1000000-0000-0000-0000-000000000006', 'XL',  'Đen',      '#2D2D2D', 40, 'CF-AO006-XL-DEN'),
  ('a1000000-0000-0000-0000-000000000006', '2XL', 'Đen',      '#2D2D2D', 35, 'CF-AO006-2XL-DEN'),
  ('a1000000-0000-0000-0000-000000000006', '3XL', 'Đen',      '#2D2D2D', 25, 'CF-AO006-3XL-DEN'),
  ('a1000000-0000-0000-0000-000000000006', '4XL', 'Đen',      '#2D2D2D', 15, 'CF-AO006-4XL-DEN'),
  ('a1000000-0000-0000-0000-000000000006', 'XL',  'Trắng',    '#FFFFFF', 35, 'CF-AO006-XL-TR'),
  ('a1000000-0000-0000-0000-000000000006', '2XL', 'Trắng',    '#FFFFFF', 30, 'CF-AO006-2XL-TR'),
  ('a1000000-0000-0000-0000-000000000006', '3XL', 'Trắng',    '#FFFFFF', 20, 'CF-AO006-3XL-TR'),
  ('a1000000-0000-0000-0000-000000000006', 'XL',  'Hồng Pastel','#FFB6C1',28,'CF-AO006-XL-HONG'),
  ('a1000000-0000-0000-0000-000000000006', '2XL', 'Hồng Pastel','#FFB6C1',22,'CF-AO006-2XL-HONG'),
  ('a1000000-0000-0000-0000-000000000006', '3XL', 'Hồng Pastel','#FFB6C1',15,'CF-AO006-3XL-HONG');

-- Áo Sơ Mi Linen (p007)
insert into public.product_variants (product_id, size, color, color_hex, stock_qty, sku) values
  ('a1000000-0000-0000-0000-000000000007', 'XL',  'Trắng Sữa','#FFFDD0', 20, 'CF-AO007-XL-TRSUA'),
  ('a1000000-0000-0000-0000-000000000007', '2XL', 'Trắng Sữa','#FFFDD0', 25, 'CF-AO007-2XL-TRSUA'),
  ('a1000000-0000-0000-0000-000000000007', '3XL', 'Trắng Sữa','#FFFDD0', 15, 'CF-AO007-3XL-TRSUA'),
  ('a1000000-0000-0000-0000-000000000007', 'XL',  'Xanh Sage','#B2AC88', 12, 'CF-AO007-XL-SAGE'),
  ('a1000000-0000-0000-0000-000000000007', '2XL', 'Xanh Sage','#B2AC88', 18, 'CF-AO007-2XL-SAGE'),
  ('a1000000-0000-0000-0000-000000000007', '3XL', 'Xanh Sage','#B2AC88',  8, 'CF-AO007-3XL-SAGE');

-- Áo Blazer (p008)
insert into public.product_variants (product_id, size, color, color_hex, stock_qty, sku) values
  ('a1000000-0000-0000-0000-000000000008', 'XL',  'Đen',      '#2D2D2D', 10, 'CF-AO008-XL-DEN'),
  ('a1000000-0000-0000-0000-000000000008', '2XL', 'Đen',      '#2D2D2D', 15, 'CF-AO008-2XL-DEN'),
  ('a1000000-0000-0000-0000-000000000008', '3XL', 'Đen',      '#2D2D2D',  8, 'CF-AO008-3XL-DEN'),
  ('a1000000-0000-0000-0000-000000000008', '4XL', 'Đen',      '#2D2D2D',  4, 'CF-AO008-4XL-DEN'),
  ('a1000000-0000-0000-0000-000000000008', 'XL',  'Kem',      '#FFF8DC',  8, 'CF-AO008-XL-KEM'),
  ('a1000000-0000-0000-0000-000000000008', '2XL', 'Kem',      '#FFF8DC', 12, 'CF-AO008-2XL-KEM');

-- Quần Palazzo (p009)
insert into public.product_variants (product_id, size, color, color_hex, stock_qty, sku) values
  ('a1000000-0000-0000-0000-000000000009', 'XL',  'Đen',      '#2D2D2D', 25, 'CF-QUAN009-XL-DEN'),
  ('a1000000-0000-0000-0000-000000000009', '2XL', 'Đen',      '#2D2D2D', 30, 'CF-QUAN009-2XL-DEN'),
  ('a1000000-0000-0000-0000-000000000009', '3XL', 'Đen',      '#2D2D2D', 20, 'CF-QUAN009-3XL-DEN'),
  ('a1000000-0000-0000-0000-000000000009', '4XL', 'Đen',      '#2D2D2D', 10, 'CF-QUAN009-4XL-DEN'),
  ('a1000000-0000-0000-0000-000000000009', 'XL',  'Navy',     '#1F305E', 15, 'CF-QUAN009-XL-NAVY'),
  ('a1000000-0000-0000-0000-000000000009', '2XL', 'Navy',     '#1F305E', 20, 'CF-QUAN009-2XL-NAVY'),
  ('a1000000-0000-0000-0000-000000000009', '3XL', 'Navy',     '#1F305E', 12, 'CF-QUAN009-3XL-NAVY');

-- Quần Jean Skinny (p010)
insert into public.product_variants (product_id, size, color, color_hex, stock_qty, sku) values
  ('a1000000-0000-0000-0000-000000000010', 'XL',  'Xanh đậm', '#1560BD', 12, 'CF-QUAN010-XL-XD'),
  ('a1000000-0000-0000-0000-000000000010', '2XL', 'Xanh đậm', '#1560BD', 18, 'CF-QUAN010-2XL-XD'),
  ('a1000000-0000-0000-0000-000000000010', '3XL', 'Xanh đậm', '#1560BD', 10, 'CF-QUAN010-3XL-XD'),
  ('a1000000-0000-0000-0000-000000000010', 'XL',  'Đen',      '#2D2D2D', 15, 'CF-QUAN010-XL-DEN'),
  ('a1000000-0000-0000-0000-000000000010', '2XL', 'Đen',      '#2D2D2D', 20, 'CF-QUAN010-2XL-DEN');

-- Quần Culottes (p011)
insert into public.product_variants (product_id, size, color, color_hex, stock_qty, sku) values
  ('a1000000-0000-0000-0000-000000000011', 'XL',  'Đen-Trắng','#808080', 10, 'CF-QUAN011-XL-DENTRANG'),
  ('a1000000-0000-0000-0000-000000000011', '2XL', 'Đen-Trắng','#808080', 15, 'CF-QUAN011-2XL-DENTRANG'),
  ('a1000000-0000-0000-0000-000000000011', '3XL', 'Đen-Trắng','#808080',  8, 'CF-QUAN011-3XL-DENTRANG');

-- Set Áo Croptop + Quần Ống Rộng (p012)
insert into public.product_variants (product_id, size, color, color_hex, stock_qty, sku) values
  ('a1000000-0000-0000-0000-000000000012', 'XL',  'Xanh Mint','#AAF0D1', 12, 'CF-SET012-XL-MINT'),
  ('a1000000-0000-0000-0000-000000000012', '2XL', 'Xanh Mint','#AAF0D1', 18, 'CF-SET012-2XL-MINT'),
  ('a1000000-0000-0000-0000-000000000012', '3XL', 'Xanh Mint','#AAF0D1', 10, 'CF-SET012-3XL-MINT'),
  ('a1000000-0000-0000-0000-000000000012', 'XL',  'Tím Lavender','#967BB6', 10, 'CF-SET012-XL-TIM'),
  ('a1000000-0000-0000-0000-000000000012', '2XL', 'Tím Lavender','#967BB6', 15, 'CF-SET012-2XL-TIM'),
  ('a1000000-0000-0000-0000-000000000012', '3XL', 'Tím Lavender','#967BB6',  8, 'CF-SET012-3XL-TIM'),
  ('a1000000-0000-0000-0000-000000000012', '4XL', 'Xanh Mint','#AAF0D1',   5, 'CF-SET012-4XL-MINT');

-- Set Sơ Mi + Quần Lửng (p013)
insert into public.product_variants (product_id, size, color, color_hex, stock_qty, sku) values
  ('a1000000-0000-0000-0000-000000000013', 'XL',  'Xanh-Trắng','#4682B4', 10, 'CF-SET013-XL-XTR'),
  ('a1000000-0000-0000-0000-000000000013', '2XL', 'Xanh-Trắng','#4682B4', 14, 'CF-SET013-2XL-XTR'),
  ('a1000000-0000-0000-0000-000000000013', '3XL', 'Xanh-Trắng','#4682B4',  8, 'CF-SET013-3XL-XTR');

-- Túi Tote (p014) — không có size clothing
insert into public.product_variants (product_id, size, color, color_hex, stock_qty, sku) values
  ('a1000000-0000-0000-0000-000000000014', 'XL', 'Kem',   '#FFF8DC', 40, 'CF-TUI014-KEM'),
  ('a1000000-0000-0000-0000-000000000014', 'XL', 'Đen',   '#2D2D2D', 35, 'CF-TUI014-DEN'),
  ('a1000000-0000-0000-0000-000000000014', 'XL', 'Hồng',  '#FFB6C1', 30, 'CF-TUI014-HONG');

-- Thắt Lưng (p015)
insert into public.product_variants (product_id, size, color, color_hex, stock_qty, sku) values
  ('a1000000-0000-0000-0000-000000000015', 'XL', 'Hồng-Tím',  '#C4517A', 25, 'CF-TL015-HONGTIM'),
  ('a1000000-0000-0000-0000-000000000015', 'XL', 'Xanh-Trắng','#87CEEB', 20, 'CF-TL015-XANHTR'),
  ('a1000000-0000-0000-0000-000000000015', 'XL', 'Đen-Vàng',  '#FFD700', 18, 'CF-TL015-DENVANG');


-- ============================================================
-- SAMPLE REVIEWS (để app có data sẵn khi demo)
-- Lưu ý: reviews cần user_id hợp lệ — phần này chỉ là template
-- Uncomment và thay uuid sau khi có test users thật
-- ============================================================

-- Uncomment sau khi có user IDs thật từ Supabase Auth:
/*
insert into public.reviews (product_id, user_id, rating, comment, size_feedback, is_verified) values
  ('a1000000-0000-0000-0000-000000000001', '<user_uuid_1>', 5, 'Đầm đẹp lắm, vải mềm mại, mặc mát. Size 2XL vừa vặn với mình 85kg. Rất hài lòng!', 'true_to_size', true),
  ('a1000000-0000-0000-0000-000000000001', '<user_uuid_2>', 5, 'Màu hồng cute y hình, giao hàng nhanh. Shop đóng gói cẩn thận.', 'true_to_size', true),
  ('a1000000-0000-0000-0000-000000000003', '<user_uuid_1>', 5, 'Đầm wrap tôn dáng siêu luôn, che bụng cực kỳ hiệu quả. Mua thêm màu đỏ rồi!', 'true_to_size', true),
  ('a1000000-0000-0000-0000-000000000006', '<user_uuid_2>', 4, 'Áo thun mềm, màu giữ tốt sau khi giặt. Size lên 1 so với bình thường.', 'larger', true),
  ('a1000000-0000-0000-0000-000000000009', '<user_uuid_1>', 5, 'Quần palazzo đẹp và thoải mái, đi làm văn phòng rất hợp. Vải không nhăn.', 'true_to_size', true),
  ('a1000000-0000-0000-0000-000000000012', '<user_uuid_2>', 5, 'Set đồ cute cực, màu mint tươi tắn. Mặc đi chụp ảnh đẹp lắm. Ship nhanh!', 'true_to_size', true);
*/


-- ============================================================
-- VERIFICATION — kiểm tra data sau khi insert
-- ============================================================
-- Chạy các query sau để kiểm tra:

-- select count(*) from public.categories;        -- phải là 5
-- select count(*) from public.products;           -- phải là 15
-- select count(*) from public.product_variants;   -- phải là ~95
-- select name, count(pv.id) as variant_count
--   from public.products p
--   join public.product_variants pv on p.id = pv.product_id
--   group by p.name order by p.name;
