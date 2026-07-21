const supabase = require('../supabase');

async function autoGenerateIfNeeded() {
  // Kiểm tra nếu đã có campaign active thì không tạo mới
  const { data, error: checkError } = await supabase.rpc('get_current_flash_sale');
  if (checkError) {
    console.error('[FlashSale] Check error:', checkError.message);
    return null;
  }

  if (data) {
    console.log('[FlashSale] Active campaign found, skipping generate');
    return data.campaign.id;
  }

  // Không có campaign active → tạo mới
  console.log('[FlashSale] No active campaign, generating...');
  const durationMin = parseInt(process.env.FLASH_SALE_DURATION_MINUTES || '240', 10);
  const productCount = parseInt(process.env.FLASH_SALE_PRODUCT_COUNT || '6', 10);
  const discountMin = parseInt(process.env.FLASH_SALE_DISCOUNT_MIN || '30', 10);
  const discountMax = parseInt(process.env.FLASH_SALE_DISCOUNT_MAX || '50', 10);

  const { data: newId, error } = await supabase.rpc('auto_generate_flash_sale', {
    p_duration_minutes: durationMin,
    p_product_count: productCount,
    p_discount_min_percent: discountMin,
    p_discount_max_percent: discountMax,
  });

  if (error) {
    console.error('[FlashSale] Generate error:', error.message);
    throw error;
  }

  if (newId) {
    console.log(`[FlashSale] Campaign ${newId} created — ${productCount} products, ${durationMin}min`);
  } else {
    console.log('[FlashSale] No eligible products for campaign');
  }

  return newId;
}

async function autoGenerateCampaign() {
  // Legacy: force generate without checking (dùng cho POST /generate)
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

  if (data) {
    console.log(`[FlashSale] Campaign ${data} created — ${productCount} products, ${durationMin}min`);
  } else {
    console.log('[FlashSale] No eligible products for campaign');
  }

  return data;
}

module.exports = { autoGenerateIfNeeded, autoGenerateCampaign };
