const express = require('express');
const supabase = require('../supabase');

const router = express.Router();

// GET /api/flash-sale/current
router.get('/current', async (_req, res) => {
  try {
    const { data, error } = await supabase.rpc('get_current_flash_sale');

    if (error) throw error;

    if (!data) {
      return res.json({ campaign: null, products: [], server_time: new Date().toISOString() });
    }

    const campaign = {
      id: data.campaign.id,
      title: data.campaign.title,
      start_at: data.campaign.start_at,
      end_at: data.campaign.end_at,
    };

    const products = (data.products || []).map((p) => ({
      id: p.product_id,
      flash_sale_id: p.id,
      name: p.name,
      image_url: p.images?.[0] || '',
      sale_price: p.sale_price,
      original_price: p.original_price,
      stock_qty: p.stock_qty,
      sold_qty: p.sold_qty,
      sizes: p.sizes || [],
      sold_percent: p.stock_qty > 0 ? +(p.sold_qty / p.stock_qty).toFixed(2) : 0,
      is_sold_out: p.sold_qty >= p.stock_qty,
    }));

    res.json({
      campaign,
      products,
      server_time: new Date().toISOString(),
    });
  } catch (err) {
    console.error('GET /flash-sale/current error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// POST /api/flash-sale/generate (manual trigger)
router.post('/generate', async (_req, res) => {
  try {
    const durationMin = parseInt(process.env.FLASH_SALE_DURATION_MINUTES || '240', 10);
    const productCount = parseInt(process.env.FLASH_SALE_PRODUCT_COUNT || '6', 10);
    const discountMin = parseInt(process.env.FLASH_SALE_DISCOUNT_MIN || '30', 10);
    const discountMax = parseInt(process.env.FLASH_SALE_DISCOUNT_MAX || '50', 10);

    const { data, error } = await supabase.rpc('auto_generate_flash_sale', {
      p_duration_minutes: durationMin,
      p_product_count: productCount,
      p_discount_min_percent: discountMin,
      p_discount_max_percent: discountMax,
    });

    if (error) throw error;

    res.json({ campaign_id: data, message: data ? 'Campaign created' : 'No eligible products' });
  } catch (err) {
    console.error('POST /flash-sale/generate error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// GET /api/flash-sale/health
router.get('/health', (_req, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

module.exports = router;
