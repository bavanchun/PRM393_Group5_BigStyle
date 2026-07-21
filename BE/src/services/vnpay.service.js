const crypto = require('crypto');

const phpUrlEncode = (str) => {
  return encodeURIComponent(String(str)).replace(/%20/g, '+');
};

const sortObject = (obj) => {
  const sorted = {};
  const keys = Object.keys(obj).sort();
  for (const key of keys) {
    sorted[key] = obj[key];
  }
  return sorted;
};

const buildHashData = (params) => {
  const sorted = sortObject(params);
  return Object.entries(sorted)
    .map(([key, value]) => `${phpUrlEncode(key)}=${phpUrlEncode(value)}`)
    .join('&');
};

const buildQueryString = (params) => {
  const sorted = sortObject(params);
  return Object.entries(sorted)
    .map(([key, value]) => `${phpUrlEncode(key)}=${phpUrlEncode(value)}`)
    .join('&');
};

const createSignature = (hashData, secretKey) => {
  return crypto
    .createHmac('sha512', secretKey)
    .update(Buffer.from(hashData, 'utf-8'))
    .digest('hex');
};

const formatDate = (date) => {
  const d = date || new Date();
  const pad = (n) => String(n).padStart(2, '0');
  return (
    `${d.getFullYear()}${pad(d.getMonth() + 1)}${pad(d.getDate())}` +
    `${pad(d.getHours())}${pad(d.getMinutes())}${pad(d.getSeconds())}`
  );
};

/**
 * Build a VNPay sandbox/production payment URL.
 * amount is VND integer (e.g. 150000); VNPay expects amount * 100.
 */
const createPaymentUrl = ({ amount, ipAddr, txnRef, returnUrl: customReturnUrl, orderInfo }) => {
  const tmnCode = process.env.VNP_TMNCODE;
  const secretKey = process.env.VNP_HASHSECRET;
  const vnpUrl = process.env.VNP_URL;
  const vnpReturnUrl = process.env.VNP_RETURN_URL;

  if (!tmnCode || !secretKey || !vnpUrl) {
    throw new Error('Missing VNPay config: VNP_TMNCODE, VNP_HASHSECRET, VNP_URL');
  }

  const createDate = formatDate();
  const orderId =
    txnRef || `${formatDate()}_${Math.random().toString(36).slice(2, 8)}`;
  const normalizedIp = (ipAddr || '127.0.0.1').replace(/^::ffff:/, '');
  const returnUrl = customReturnUrl || vnpReturnUrl;

  if (!returnUrl) {
    throw new Error('Missing VNPay return URL (VNP_RETURN_URL or customReturnUrl)');
  }

  const vnpParams = {
    vnp_Version: '2.1.0',
    vnp_Command: 'pay',
    vnp_TmnCode: tmnCode,
    vnp_Locale: 'vn',
    vnp_CurrCode: 'VND',
    vnp_TxnRef: orderId,
    vnp_OrderInfo: orderInfo || `Thanh toan don hang ${orderId}`,
    vnp_OrderType: 'other',
    vnp_Amount: Math.round(Number(amount)) * 100,
    vnp_ReturnUrl: returnUrl,
    vnp_IpAddr: normalizedIp,
    vnp_CreateDate: createDate,
  };

  const hashData = buildHashData(vnpParams);
  const secureHash = createSignature(hashData, secretKey);
  const queryString = buildQueryString(vnpParams);

  return `${vnpUrl}?${queryString}&vnp_SecureHash=${secureHash}`;
};

/**
 * Verify a VNPay return/IPN query string (HMAC-SHA512).
 * isValid = signature ok; paid = signature ok AND response codes are 00.
 */
const verifyReturnUrl = (queryParams) => {
  const secretKey = process.env.VNP_HASHSECRET;
  if (!secretKey) {
    throw new Error('Missing VNPay config: VNP_HASHSECRET');
  }

  const vnpParams = {};
  for (const key of Object.keys(queryParams)) {
    if (
      key.startsWith('vnp_') &&
      key !== 'vnp_SecureHash' &&
      key !== 'vnp_SecureHashType'
    ) {
      vnpParams[key] = queryParams[key];
    }
  }

  const vnpSecureHash = queryParams.vnp_SecureHash;
  if (!vnpSecureHash) {
    return { isValid: false, paid: false, message: 'Missing vnp_SecureHash in return data' };
  }

  const hashData = buildHashData(vnpParams);
  const computedHash = createSignature(hashData, secretKey);
  const isValid = computedHash === vnpSecureHash;
  const responseCode = vnpParams.vnp_ResponseCode;
  const transactionStatus = vnpParams.vnp_TransactionStatus;
  const paid =
    isValid &&
    responseCode === '00' &&
    (transactionStatus == null || transactionStatus === '00');

  return {
    isValid,
    paid,
    message: isValid
      ? paid
        ? 'Payment success'
        : `Payment not successful (code=${responseCode})`
      : 'Invalid signature',
    data: {
      txnRef: vnpParams.vnp_TxnRef,
      amount: vnpParams.vnp_Amount,
      orderInfo: vnpParams.vnp_OrderInfo,
      responseCode,
      transactionNo: vnpParams.vnp_TransactionNo,
      bankCode: vnpParams.vnp_BankCode,
      payDate: vnpParams.vnp_PayDate,
      transactionStatus,
    },
  };
};

module.exports = { createPaymentUrl, verifyReturnUrl };
