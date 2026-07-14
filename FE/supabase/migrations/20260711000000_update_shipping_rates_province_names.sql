-- Update shipping_rates province names to match provinces.open-api.vn format
-- "TP. Hồ Chí Minh" → "Thành phố Hồ Chí Minh"
-- "Hà Nội" → "Thành phố Hà Nội", etc.

UPDATE public.shipping_rates
SET from_province = 'Thành phố Hồ Chí Minh'
WHERE from_province = 'TP. Hồ Chí Minh';

UPDATE public.shipping_rates
SET to_province = 'Thành phố Hồ Chí Minh'
WHERE to_province = 'TP. Hồ Chí Minh';

UPDATE public.shipping_rates
SET from_province = 'Thành phố Hà Nội'
WHERE from_province = 'Hà Nội';

UPDATE public.shipping_rates
SET to_province = 'Thành phố Hà Nội'
WHERE to_province = 'Hà Nội';

UPDATE public.shipping_rates
SET from_province = 'Thành phố Đà Nẵng'
WHERE from_province = 'Đà Nẵng';

UPDATE public.shipping_rates
SET to_province = 'Thành phố Đà Nẵng'
WHERE to_province = 'Đà Nẵng';

UPDATE public.shipping_rates
SET from_province = 'Thành phố Hải Phòng'
WHERE from_province = 'Hải Phòng';

UPDATE public.shipping_rates
SET to_province = 'Thành phố Hải Phòng'
WHERE to_province = 'Hải Phòng';

UPDATE public.shipping_rates
SET from_province = 'Thành phố Cần Thơ'
WHERE from_province = 'Cần Thơ';

UPDATE public.shipping_rates
SET to_province = 'Thành phố Cần Thơ'
WHERE to_province = 'Cần Thơ';

UPDATE public.shipping_rates
SET from_province = 'Tỉnh Bình Dương'
WHERE from_province = 'Bình Dương';

UPDATE public.shipping_rates
SET to_province = 'Tỉnh Bình Dương'
WHERE to_province = 'Bình Dương';

UPDATE public.shipping_rates
SET from_province = 'Tỉnh Đồng Nai'
WHERE from_province = 'Đồng Nai';

UPDATE public.shipping_rates
SET to_province = 'Tỉnh Đồng Nai'
WHERE to_province = 'Đồng Nai';

UPDATE public.shipping_rates
SET from_province = 'Tỉnh Long An'
WHERE from_province = 'Long An';

UPDATE public.shipping_rates
SET to_province = 'Tỉnh Long An'
WHERE to_province = 'Long An';

UPDATE public.shipping_rates
SET from_province = 'Tỉnh Bà Rịa - Vũng Tàu'
WHERE from_province = 'Bà Rịa - Vũng Tàu';

UPDATE public.shipping_rates
SET to_province = 'Tỉnh Bà Rịa - Vũng Tàu'
WHERE to_province = 'Bà Rịa - Vũng Tàu';

UPDATE public.shipping_rates
SET from_province = 'Tỉnh Quảng Ninh'
WHERE from_province = 'Quảng Ninh';

UPDATE public.shipping_rates
SET to_province = 'Tỉnh Quảng Ninh'
WHERE to_province = 'Quảng Ninh';
