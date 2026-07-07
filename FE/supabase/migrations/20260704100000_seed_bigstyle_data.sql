-- ============================================================
-- Seed data: Categories, Products, Variants for BigStyle
-- Chạy file này trong Supabase > SQL Editor
-- ============================================================

-- Xóa dữ liệu cũ (products + variants + categories)
DELETE FROM public.product_variants;
DELETE FROM public.products;
DELETE FROM public.categories;

-- ============================================================
-- CATEGORIES (giới tính化)
-- ============================================================
INSERT INTO public.categories (id, name, slug, image_url, sort_order, is_active) VALUES
  ('c1000000-0000-0000-0000-000000000001', 'Áo Nam',     'ao-nam',     'https://images.unsplash.com/photo-1602810318383-e386cc2a3ccf?w=400', 1, true),
  ('c1000000-0000-0000-0000-000000000002', 'Áo Nữ',      'ao-nu',      'https://images.unsplash.com/photo-1562157873-818bc0726f68?w=400', 2, true),
  ('c1000000-0000-0000-0000-000000000003', 'Quần Nam',    'quan-nam',   'https://images.unsplash.com/photo-1473966968600-fa801b869a1a?w=400', 3, true),
  ('c1000000-0000-0000-0000-000000000004', 'Quần Nữ',     'quan-nu',    'https://images.unsplash.com/photo-1594938298603-c8148c4dae35?w=400', 4, true),
  ('c1000000-0000-0000-0000-000000000005', 'Đầm Nữ',     'dam-nu',     'https://images.unsplash.com/photo-1595777457583-95e059d581b8?w=400', 5, true),
  ('c1000000-0000-0000-0000-000000000006', 'Phụ Kiện',    'phu-kien',   'https://images.unsplash.com/photo-1611085583191-a3b181a88401?w=400', 6, true);

-- ============================================================
-- PRODUCTS (15 sản phẩm, mỗi category 2-3 sản phẩm)
-- store_id sẽ được cập nhật SAU khi manager đăng nhập
-- ============================================================

-- ---- ÁO NAM (3 sản phẩm) ----
INSERT INTO public.products (id, category_id, name, description, slug, images, base_price, sale_price, is_featured, is_active, material, elasticity) VALUES
('p1000000-0000-0000-0000-000000000001',
 'c1000000-0000-0000-0000-000000000001',
 'Áo Polo Nam Bigsize Cotton Premium',
 'Áo polo nam BigSize được làm từ 100% cotton cao cấp, thoáng khí, thấm hút mồ hôi tốt. Thiết kế phóng khoáng, phù hợp cho người mặc size lớn.',
 'ao-polo-nam-bigsize',
 ARRAY['https://images.unsplash.com/photo-1625910513413-5fc42835c135?w=600','https://images.unsplash.com/photo-1586363104862-3a5e2ab60d99?w=600'],
 320000, 280000, true, true, 'Cotton 100%', 'Co giãn nhẹ'),

('p1000000-0000-0000-0000-000000000002',
 'c1000000-0000-0000-0000-000000000001',
 'Áo Thun Oversize Nam Local Brand',
 'Áo thun oversize phong cách đường phố, form rộng thoải mái. Chất liệu cotton dày dặn, giữ form tốt sau nhiều lần giặt.',
 'ao-thun-oversize-nam',
 ARRAY['https://images.unsplash.com/photo-1521572163474-6864f9cf17ab?w=600','https://images.unsplash.com/photo-1618354691373-d851c5c3a990?w=600'],
 220000, null, false, true, 'Cotton 280gsm', 'Không co giãn'),

('p1000000-0000-0000-0000-000000000003',
 'c1000000-0000-0000-0000-000000000001',
 'Áo Sơ Mi Nam Lụa BigSize',
 'Áo sơ mi lụa thoáng mát, thiết kế thanh lịch cho quý ông BigSize. Phù hợp đi làm, đi sự kiện.',
 'ao-so-mi-nam-lua-bigsize',
 ARRAY['https://images.unsplash.com/photo-1596755094514-f87e34085b2c?w=600'],
 450000, 390000, true, true, 'Lụa tổng hợp', 'Co giãn nhẹ'),

-- ---- ÁO NỮ (3 sản phẩm) ----
('p1000000-0000-0000-0000-000000000004',
 'c1000000-0000-0000-0000-000000000002',
 'Áo Croptop Nữ BigSize Form Rộng',
 'Áo croptop BigSize cho nữ, form rộng thoải mái, không bó sát. Chất liệu thun mềm mại, phù hợp mùa hè nóng bức.',
 'ao-croptop-nu-bigsize',
 ARRAY['https://images.unsplash.com/photo-1583846783214-7229a91b20ed?w=600','https://images.unsplash.com/photo-1515886657613-9f3515b0c78f?w=600'],
 195000, null, false, true, 'Thun cotton', 'Co giãn tốt'),

('p1000000-0000-0000-0000-000000000005',
 'c1000000-0000-0000-0000-000000000002',
 'Áo Kiêu Nữ BigSize Sang Trọng',
 'Áo kiểu nữ BigSize thiết kế sang trọng, phối nơ cổ. Phù hợp đi tiệc, hẹn hò.',
 'ao-kieu-nu-bigsize',
 ARRAY['https://images.unsplash.com/photo-1614251055880-ee96e4803393?w=600'],
 380000, 320000, true, true, 'Kate cao cấp', 'Co giãn nhẹ'),

('p1000000-0000-0000-0000-000000000006',
 'c1000000-0000-0000-0000-000000000002',
 'Áo Blazer Nữ BigSize Dài',
 'Áo blazer nữ BigSize form dài, chất liệu vải đanh. Phù hợp mặc đi làm, tạo phong cách chuyên nghiệp.',
 'ao-blazer-nu-bigsize',
 ARRAY['https://images.unsplash.com/photo-1591085686350-798c0f9faa7f?w=600'],
 650000, null, false, true, 'Polyester pha', 'Không co giãn'),

-- ---- QUẦN NAM (3 sản phẩm) ----
('p1000000-0000-0000-0000-000000000007',
 'c1000000-0000-0000-0000-000000000003',
 'Quần Jean Nam BigSize Cao Cấp',
 'Quần jean nam BigSize dạng regular fit, co giãn nhẹ. Chất liệu denim bền đẹp, phù hợp mọi hoạt động.',
 'quan-jean-nam-bigsize',
 ARRAY['https://images.unsplash.com/photo-1542272604-787c3835535d?w=600','https://images.unsplash.com/photo-1475178626620-a4d074967571?w=600'],
 450000, 399000, true, true, 'Denim co giãn', 'Co giãn 2%'),

('p1000000-0000-0000-0000-000000000008',
 'c1000000-0000-0000-0000-000000000003',
 'Quần Short Nam BigSize Thể Thao',
 'Quần short nam BigSize thể thao, chất liệu thun thấm hút mồ hôi. Phù hợp đi chơi, thể thao, mặc nhà.',
 'quan-short-nam-bigsize',
 ARRAY['https://images.unsplash.com/photo-1591195853828-11db59a44f6b?w=600'],
 180000, null, false, true, 'Polyester thun', 'Co giãn tốt'),

('p1000000-0000-0000-0000-000000000009',
 'c1000000-0000-0000-0000-000000000003',
 'Quần Kaki Nam BigSize Office',
 'Quần kaki nam BigSize form regular, chất liệu kaki bền đẹp. Phù hợp đi làm công sở, lịch sự.',
 'quan-kaki-nam-bigsize',
 ARRAY['https://images.unsplash.com/photo-1473966968600-fa801b869a1a?w=600'],
 350000, 299000, false, true, 'Kaki cotton', 'Co giãn nhẹ'),

-- ---- QUẦN NỮ (3 sản phẩm) ----
('p1000000-0000-0000-0000-000000000010',
 'c1000000-0000-0000-0000-000000000004',
 'Quần Jean Nữ BigSize Skinny',
 'Quần jean nữ BigSize dạng skinny co giãn, ôm nhẹ thoải mái. Chất liệu denim柔软, phù hợp phối đồ đa dạng.',
 'quan-jean-nu-bigsize',
 ARRAY['https://images.unsplash.com/photo-1541099649105-f69ad21f3246?w=600'],
 420000, 369000, true, true, 'Denim co giãn 4%', 'Co giãn tốt'),

('p1000000-0000-0000-0000-000000000011',
 'c1000000-0000-0000-0000-000000000004',
 'Quần Culottes Nữ BigSize Caro',
 'Quần culottes nữ BigSize họa tiết caro vintage, form rộng thoải mái. Phù hợp đi chơi, dạo phố.',
 'quan-culottes-nu-bigsize',
 ARRAY['https://images.unsplash.com/photo-1548690596-f1722c190938?w=600'],
 320000, null, false, true, 'Kate caro', 'Không co giãn'),

('p1000000-0000-0000-0000-000000000012',
 'c1000000-0000-0000-0000-000000000004',
 'Quần Palazzo Nữ BigSize Thun',
 'Quần palazzo nữ BigSize ống rộng thun nhẹ, thoải mái tối đa. Phù hợp mùa hè, đi biển, dạo phố.',
 'quan-palazzo-nu-bigsize',
 ARRAY['https://images.unsplash.com/photo-1509631179647-0177331693ae?w=600'],
 280000, 249000, false, true, 'Thun lụa', 'Co giãn tốt'),

-- ---- ĐẦM NỮ (2 sản phẩm) ----
('p1000000-0000-0000-0000-000000000013',
 'c1000000-0000-0000-0000-000000000005',
 'Đầm Maxi Nữ BigSize Boho',
 'Đầm maxi nữ BigSize phong cách bohemian, form rộng bay bổng. Chất liệu voan nhẹ nhàng, phù hợp đi biển, dạo phố.',
 'dam-maxi-nu-bigsize',
 ARRAY['https://images.unsplash.com/photo-1496747611176-843222e1e57c?w=600','https://images.unsplash.com/photo-1572804013309-59a88b7e92f1?w=600'],
 520000, 449000, true, true, 'Voan polyester', 'Co giãn nhẹ'),

('p1000000-0000-0000-0000-000000000014',
 'c1000000-0000-0000-0000-000000000005',
 'Đầm Wrap Nữ BigSize Thêu Hoa',
 'Đầm wrap nữ BigSize thêu hoa tay bồng, thiết kế wrap kín đáo. Phù hợp đi tiệc, sự kiện.',
 'dam-wrap-nu-bigsize',
 ARRAY['https://images.unsplash.com/photo-1515372039744-b8f02a3ae446?w=600'],
 480000, null, false, true, 'Cotton thêu', 'Co giãn nhẹ'),

-- ---- PHỤ KIỆN (1 sản phẩm) ----
('p1000000-0000-0000-0000-000000000015',
 'c1000000-0000-0000-0000-000000000006',
 'Túi Tote Canvas BigSize',
 'Túi tote canvas BigSize đựng được nhiều đồ, phù hợp đi làm, đi chơi. Chất liệu canvas dày dặn.',
 'tui-tote-canvas-bigsize',
 ARRAY['https://images.unsplash.com/photo-1584917865442-de89df76afd3?w=600'],
 180000, 150000, false, true, 'Canvas', 'Không co giãn');

-- ============================================================
-- PRODUCT VARIANTS (sizes bigsize: M, L, XL, 2XL, 3XL)
-- ============================================================

-- Áo Polo Nam
INSERT INTO public.product_variants (product_id, size, color, color_hex, stock_qty, height_range, weight_range, bust_range, waist_range) VALUES
('p1000000-0000-0000-0000-000000000001', 'XL',  'Trắng',    '#FFFFFF', 20, '170-178', '80-90',  '106-112', '96-102'),
('p1000000-0000-0000-0000-000000000001', '2XL', 'Trắng',    '#FFFFFF', 25, '175-183', '85-95',  '112-118', '102-108'),
('p1000000-0000-0000-0000-000000000001', '3XL', 'Đen',      '#000000', 15, '178-186', '90-100', '118-124', '108-114'),
('p1000000-0000-0000-0000-000000000001', '2XL', 'Xanh Navy','#1B2A4A', 18, '175-183', '85-95',  '112-118', '102-108'),
('p1000000-0000-0000-0000-000000000001', '4XL', 'Trắng',    '#FFFFFF', 10, '180-188', '95-105', '124-130', '114-120'),

-- Áo Thun Oversize Nam
('p1000000-0000-0000-0000-000000000002', 'XL',  'Đen',      '#000000', 30, '170-178', '80-90',  '106-112', '96-102'),
('p1000000-0000-0000-0000-000000000002', '2XL', 'Trắng',    '#FFFFFF', 25, '175-183', '85-95',  '112-118', '102-108'),
('p1000000-0000-0000-0000-000000000002', '3XL', 'Xám','#808080', 20, '178-186', '90-100', '118-124', '108-114'),

-- Áo Sơ Mi Nam Lụa
('p1000000-0000-0000-0000-000000000003', 'XL',  'Trắng',    '#FFFFFF', 15, '170-178', '80-90',  '106-112', '96-102'),
('p1000000-0000-0000-0000-000000000003', '2XL', 'Xanh Nhạt','#B0D4F1', 12, '175-183', '85-95',  '112-118', '102-108'),
('p1000000-0000-0000-0000-000000000003', '3XL', 'Hồng',     '#FFB6C1', 10, '178-186', '90-100', '118-124', '108-114'),

-- Áo Croptop Nữ
('p1000000-0000-0000-0000-000000000004', 'XL',  'Trắng',    '#FFFFFF', 20, '160-168', '70-80',  '100-106', '86-92'),
('p1000000-0000-0000-0000-000000000004', '2XL', 'Hồng Phấn','#FFB6C1', 18, '165-173', '75-85',  '106-112', '92-98'),
('p1000000-0000-0000-0000-000000000004', '3XL', 'Đen',      '#000000', 15, '168-176', '80-90',  '112-118', '98-104'),

-- Áo Kiêu Nữ
('p1000000-0000-0000-0000-000000000005', 'XL',  'Đỏ',       '#DC143C', 12, '160-168', '70-80',  '100-106', '86-92'),
('p1000000-0000-0000-0000-000000000005', '2XL', 'Xanh Rêu', '#556B2F', 10, '165-173', '75-85',  '106-112', '92-98'),

-- Áo Blazer Nữ
('p1000000-0000-0000-0000-000000000006', 'XL',  'Đen',      '#000000', 8,  '160-168', '70-80',  '100-106', '86-92'),
('p1000000-0000-0000-0000-000000000006', '2XL', 'Xám','#808080', 6,  '165-173', '75-85',  '106-112', '92-98'),

-- Quần Jean Nam
('p1000000-0000-0000-0000-000000000007', 'XL',  'Xanh Đậm', '#1560BD', 20, '170-178', '80-90',  '-', '96-102'),
('p1000000-0000-0000-0000-000000000007', '2XL', 'Xanh Nhạt','#87CEEB', 18, '175-183', '85-95',  '-', '102-108'),
('p1000000-0000-0000-0000-000000000007', '3XL', 'Đen',      '#000000', 15, '178-186', '90-100', '-', '108-114'),
('p1000000-0000-0000-0000-000000000007', '4XL', 'Xanh Đậm', '#1560BD', 10, '180-188', '95-105', '-', '114-120'),

-- Quần Short Nam
('p1000000-0000-0000-0000-000000000008', 'XL',  'Đen',      '#000000', 25, '170-178', '80-90',  '-', '96-102'),
('p1000000-0000-0000-0000-000000000008', '2XL', 'Xám','#808080', 20, '175-183', '85-95',  '-', '102-108'),
('p1000000-0000-0000-0000-000000000008', '3XL', 'Xanh Navy','#1B2A4A', 15, '178-186', '90-100', '-', '108-114'),

-- Quần Kaki Nam
('p1000000-0000-0000-0000-000000000009', 'XL',  'Be',       '#F5F5DC', 15, '170-178', '80-90',  '-', '96-102'),
('p1000000-0000-0000-0000-000000000009', '2XL', 'Nâu',      '#8B4513', 12, '175-183', '85-95',  '-', '102-108'),
('p1000000-0000-0000-0000-000000000009', '3XL', 'Đen',      '#000000', 10, '178-186', '90-100', '-', '108-114'),

-- Quần Jean Nữ
('p1000000-0000-0000-0000-000000000010', 'XL',  'Xanh Nhạt','#87CEEB', 18, '160-168', '70-80',  '-', '86-92'),
('p1000000-0000-0000-0000-000000000010', '2XL', 'Xanh Đậm', '#1560BD', 15, '165-173', '75-85',  '-', '92-98'),
('p1000000-0000-0000-0000-000000000010', '3XL', 'Đen',      '#000000', 12, '168-176', '80-90',  '-', '98-104'),

-- Quần Culottes Nữ
('p1000000-0000-0000-0000-000000000011', 'XL',  'Caro Đỏ',  '#8B0000', 10, '160-168', '70-80',  '-', '86-92'),
('p1000000-0000-0000-0000-000000000011', '2XL', 'Caro Xanh', '#2F4F4F', 8,  '165-173', '75-85',  '-', '92-98'),

-- Quần Palazzo Nữ
('p1000000-0000-0000-0000-000000000012', 'XL',  'Đen',      '#000000', 20, '160-168', '70-80',  '-', '86-92'),
('p1000000-0000-0000-0000-000000000012', '2XL', 'Trắng',    '#FFFFFF', 15, '165-173', '75-85',  '-', '92-98'),
('p1000000-0000-0000-0000-000000000012', '3XL', 'Be',       '#F5F5DC', 10, '168-176', '80-90',  '-', '98-104'),

-- Đầm Maxi Nữ
('p1000000-0000-0000-0000-000000000013', 'XL',  'Hoa Anh Đào','#FFB7C5', 12, '160-168', '70-80',  '100-106', '86-92'),
('p1000000-0000-0000-0000-000000000013', '2XL', 'Xanh Biển', '#4682B4', 10, '165-173', '75-85',  '106-112', '92-98'),
('p1000000-0000-0000-0000-000000000013', '3XL', 'Đen',      '#000000', 8,  '168-176', '80-90',  '112-118', '98-104'),

-- Đầm Wrap Nữ
('p1000000-0000-0000-0000-000000000014', 'XL',  'Hồng',     '#FFB6C1', 10, '160-168', '70-80',  '100-106', '86-92'),
('p1000000-0000-0000-0000-000000000014', '2XL', 'Trắng',    '#FFFFFF', 8,  '165-173', '75-85',  '106-112', '92-98'),

-- Túi Tote Canvas
('p1000000-0000-0000-0000-000000000015', 'XL',  'Trắng',    '#FFFFFF', 30, '-', '-', '-', '-'),
('p1000000-0000-0000-0000-000000000015', 'XL',  'Đen',      '#000000', 25, '-', '-', '-', '-');

-- ============================================================
-- ASSIGN PRODUCTS TO MANAGER
-- Chạy SAU khi manager đã đăng nhập lần đầu qua app
-- Thay '<MANAGER_UUID>' bằng UUID thực tế từ profiles table
-- ============================================================
-- Cách lấy UUID: SELECT id FROM profiles WHERE email = 'luanhbaokhang.fptshop@gmail.com';
-- UPDATE public.products SET store_id = '<MANAGER_UUID>' WHERE store_id IS NULL;

