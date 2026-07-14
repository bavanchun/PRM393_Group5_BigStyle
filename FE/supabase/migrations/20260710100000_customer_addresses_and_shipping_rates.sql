-- customer_addresses: multiple addresses per customer (like Shopee)
CREATE TABLE public.customer_addresses (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  label TEXT NOT NULL DEFAULT 'Nhà',
  full_name TEXT NOT NULL,
  phone TEXT,
  address TEXT NOT NULL,
  province TEXT NOT NULL,
  district TEXT,
  ward TEXT,
  latitude DOUBLE PRECISION,
  longitude DOUBLE PRECISION,
  is_default BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- shipping_rates: admin-managed province-to-province rates
CREATE TABLE public.shipping_rates (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  from_province TEXT NOT NULL,
  to_province TEXT NOT NULL,
  base_fee NUMERIC NOT NULL DEFAULT 30000,
  free_threshold NUMERIC DEFAULT 0,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(from_province, to_province)
);

-- RLS: users can only CRUD their own addresses
ALTER TABLE public.customer_addresses ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users view own addresses"
  ON public.customer_addresses FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users insert own addresses"
  ON public.customer_addresses FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users update own addresses"
  ON public.customer_addresses FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Users delete own addresses"
  ON public.customer_addresses FOR DELETE
  USING (auth.uid() = user_id);

-- RLS: everyone can read shipping rates, only admin can manage
ALTER TABLE public.shipping_rates ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view active shipping rates"
  ON public.shipping_rates FOR SELECT
  USING (is_active = true);

CREATE POLICY "Admin can manage shipping rates"
  ON public.shipping_rates FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- updated_at trigger for customer_addresses
CREATE OR REPLACE FUNCTION public.set_customer_addresses_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER customer_addresses_set_updated_at
  BEFORE UPDATE ON public.customer_addresses
  FOR EACH ROW
  EXECUTE FUNCTION public.set_customer_addresses_updated_at();

-- Seed shipping rates (Vietnam major routes)
INSERT INTO public.shipping_rates (from_province, to_province, base_fee, free_threshold) VALUES
-- Nội thành
('Hà Nội', 'Hà Nội', 15000, 500000),
('TP.HCM', 'TP.HCM', 15000, 500000),
('Đà Nẵng', 'Đà Nẵng', 15000, 500000),
-- Miền Bắc
('Hà Nội', 'Hải Phòng', 25000, 700000),
('Hà Nội', 'Quảng Ninh', 25000, 700000),
('Hà Nội', 'Bắc Ninh', 20000, 600000),
('Hà Nội', 'Hưng Yên', 20000, 600000),
-- Miền Trung
('Hà Nội', 'Nghệ An', 30000, 800000),
('Hà Nội', 'Thanh Hóa', 28000, 800000),
('Hà Nội', 'Huế', 35000, 900000),
('Hà Nội', 'Đà Nẵng', 35000, 900000),
-- Miền Nam
('Hà Nội', 'TP.HCM', 40000, 1000000),
('Hà Nội', 'Đồng Nai', 38000, 900000),
('Hà Nội', 'Bình Dương', 38000, 900000),
('TP.HCM', 'Đồng Nai', 20000, 500000),
('TP.HCM', 'Bình Dương', 20000, 500000),
('TP.HCM', 'Vũng Tàu', 25000, 600000),
('TP.HCM', 'Tây Ninh', 25000, 600000),
('TP.HCM', 'Cần Thơ', 30000, 700000),
('TP.HCM', 'An Giang', 30000, 700000),
('Đà Nẵng', 'TP.HCM', 35000, 900000),
('Đà Nẵng', 'Quảng Nam', 15000, 400000),
('Đà Nẵng', 'Quảng Ngãi', 20000, 500000),
('Đà Nẵng', 'Huế', 20000, 500000),
-- Cross routes
('TP.HCM', 'Hà Nội', 40000, 1000000),
('TP.HCM', 'Hải Phòng', 40000, 1000000),
('TP.HCM', 'Đà Nẵng', 35000, 900000);
