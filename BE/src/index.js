require('dotenv').config();
const express = require('express');
const cors = require('cors');
const cron = require('node-cron');
const flashSaleRoutes = require('./routes/flashSale');
const paymentRoutes = require('./routes/payment');
const { autoGenerateIfNeeded } = require('./cron/flashSaleCron');

const app = express();
const PORT = process.env.PORT || 3001;

app.use(cors());
app.use(express.json());

app.use('/api/flash-sale', flashSaleRoutes);
app.use('/api/payments', paymentRoutes);

// Kiểm tra & tạo campaign mỗi 30 phút (nếu hết hạn thì tạo cái mới)
const checkSchedule = '*/30 * * * *';
cron.schedule(checkSchedule, () => {
  console.log(`[Cron] Checking campaign at ${new Date().toISOString()}`);
  autoGenerateIfNeeded().catch((err) => console.error('[Cron] Error:', err));
});

// Tạo campaign ngay khi khởi động (nếu chưa có)
(async () => {
  console.log('[Startup] Checking for active campaign...');
  await autoGenerateIfNeeded();
})();

app.listen(PORT, () => {
  console.log(`BigStyle Flash Sale API running on port ${PORT}`);
  console.log(`Check schedule: every 30 minutes`);
});
