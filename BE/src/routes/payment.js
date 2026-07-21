const express = require('express');
const supabase = require('../supabase');
const vnpayService = require('../services/vnpay.service');

const router = express.Router();

const clientIp = (req) => {
  const forwarded = req.headers['x-forwarded-for'];
  if (typeof forwarded === 'string' && forwarded.length > 0) {
    return forwarded.split(',')[0].trim();
  }
  return req.socket?.remoteAddress || '127.0.0.1';
};

/**
 * POST /api/payments/vnpay-create
 * Body: { orderId, amount, orderNumber?, returnUrl? }
 * Creates/updates a pending payments row (method=vnpay) and returns paymentUrl.
 */
router.post('/vnpay-create', async (req, res) => {
  try {
    const { orderId, amount, orderNumber, returnUrl } = req.body || {};

    if (!orderId || amount == null || Number(amount) <= 0) {
      return res.status(400).json({
        success: false,
        message: 'orderId and positive amount are required',
      });
    }

    const { data: order, error: orderErr } = await supabase
      .from('orders')
      .select('id, user_id, total, order_number, payment_method, status')
      .eq('id', orderId)
      .maybeSingle();

    if (orderErr) throw orderErr;
    if (!order) {
      return res.status(404).json({ success: false, message: 'Order not found' });
    }

    const payAmount = Math.round(Number(amount));
    const txnRef = String(orderNumber || order.order_number || orderId)
      .replace(/[^a-zA-Z0-9]/g, '')
      .slice(0, 32);

    const { data: existing } = await supabase
      .from('payments')
      .select('id, status')
      .eq('order_id', orderId)
      .eq('status', 'pending')
      .order('created_at', { ascending: false })
      .limit(1)
      .maybeSingle();

    if (existing) {
      const { error: updErr } = await supabase
        .from('payments')
        .update({
          method: 'vnpay',
          amount: payAmount,
          transaction_id: txnRef,
        })
        .eq('id', existing.id);
      if (updErr) throw updErr;
    } else {
      const { error: insErr } = await supabase.from('payments').insert({
        order_id: orderId,
        user_id: order.user_id,
        method: 'vnpay',
        amount: payAmount,
        status: 'pending',
        transaction_id: txnRef,
      });
      if (insErr) throw insErr;
    }

    const paymentUrl = vnpayService.createPaymentUrl({
      amount: payAmount,
      ipAddr: clientIp(req),
      txnRef,
      returnUrl: returnUrl || undefined,
      orderInfo: `Thanh toan don hang ${orderNumber || order.order_number || orderId}`,
    });

    return res.json({
      success: true,
      paymentUrl,
      transactionId: txnRef,
      orderId,
    });
  } catch (err) {
    console.error('[vnpay-create]', err);
    return res.status(500).json({
      success: false,
      message: err.message || 'Failed to create VNPay payment',
    });
  }
});

async function confirmVnpayPayment(result) {
  if (!result.paid || !result.data?.txnRef) {
    return { confirmed: false, reason: result.message };
  }

  const txnRef = result.data.txnRef;
  const gateway = {
    responseCode: result.data.responseCode,
    transactionNo: result.data.transactionNo,
    bankCode: result.data.bankCode,
    payDate: result.data.payDate,
    amount: result.data.amount,
  };

  let { data, error } = await supabase
    .from('payments')
    .update({
      status: 'success',
      paid_at: new Date().toISOString(),
      gateway_response: gateway,
      transaction_id: txnRef,
    })
    .eq('status', 'pending')
    .eq('transaction_id', txnRef)
    .select('id, order_id')
    .maybeSingle();
  if (error) throw error;

  if (!data) {
    const retry = await supabase
      .from('payments')
      .update({
        status: 'success',
        paid_at: new Date().toISOString(),
        gateway_response: gateway,
        transaction_id: txnRef,
      })
      .eq('status', 'pending')
      .eq('order_id', txnRef)
      .select('id, order_id')
      .maybeSingle();
    if (retry.error) throw retry.error;
    data = retry.data;
  }

  return { confirmed: Boolean(data), payment: data };
}

/**
 * GET /api/payments/vnpay-return
 * Browser/WebView redirect target after the user finishes on VNPay.
 */
router.get('/vnpay-return', async (req, res) => {
  try {
    const result = vnpayService.verifyReturnUrl(req.query);
    console.log('[vnpay-return]', result.message, result.data?.txnRef);

    if (result.paid) {
      try {
        await confirmVnpayPayment(result);
      } catch (err) {
        console.error('[vnpay-return] confirm error:', err.message);
      }
    }

    const payload = encodeURIComponent(
      JSON.stringify({
        success: result.paid,
        message: result.message,
        txnRef: result.data?.txnRef || null,
        responseCode: result.data?.responseCode || null,
      }),
    );

    if (req.query.client === 'mobile') {
      return res.redirect(302, `bigstyle://vnpay-return?result=${payload}`);
    }

    const title = result.paid ? 'Thanh toán thành công' : 'Thanh toán thất bại';
    const color = result.paid ? '#2E6B47' : '#C0392B';
    return res
      .status(200)
      .type('html')
      .send(`<!DOCTYPE html>
<html lang="vi">
<head>
  <meta charset="utf-8"/>
  <meta name="viewport" content="width=device-width, initial-scale=1"/>
  <title>${title}</title>
  <style>
    body{font-family:system-ui,sans-serif;display:flex;align-items:center;justify-content:center;
      min-height:100vh;margin:0;background:#FBF6EF;color:#2A211E}
    .card{background:#fff;border-radius:16px;padding:32px 24px;text-align:center;
      box-shadow:0 8px 24px rgba(0,0,0,.08);max-width:320px}
    h1{font-size:20px;margin:0 0 8px;color:${color}}
    p{font-size:14px;color:#746159;margin:0}
  </style>
</head>
<body>
  <div class="card">
    <h1>${title}</h1>
    <p>${result.message}</p>
    <p style="margin-top:12px;font-size:12px">Bạn có thể đóng trang này và quay lại ứng dụng.</p>
  </div>
</body>
</html>`);
  } catch (err) {
    console.error('[vnpay-return]', err);
    return res.status(500).type('html').send('<h1>Lỗi xử lý thanh toán</h1>');
  }
});

/**
 * GET /api/payments/vnpay-ipn
 * Server-to-server notification from VNPay.
 */
router.get('/vnpay-ipn', async (req, res) => {
  try {
    const result = vnpayService.verifyReturnUrl(req.query);
    console.log('[vnpay-ipn]', result.message, result.data?.txnRef);

    if (!result.isValid) {
      return res.json({ RspCode: '97', Message: 'Invalid signature' });
    }

    if (result.paid) {
      try {
        await confirmVnpayPayment(result);
      } catch (err) {
        console.error('[vnpay-ipn] confirm error:', err.message);
        return res.json({ RspCode: '99', Message: 'Confirm error' });
      }
    }

    return res.json({ RspCode: '00', Message: 'Confirm Success' });
  } catch (err) {
    console.error('[vnpay-ipn]', err);
    return res.json({ RspCode: '99', Message: 'Unknown error' });
  }
});

module.exports = router;
