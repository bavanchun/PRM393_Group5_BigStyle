#!/usr/bin/env bash
#
# sepay-simulate-payment.sh — "sandbox" cho luồng thanh toán chuyển khoản.
#
# Gọi thẳng Edge Function sepay-webhook giả một giao dịch SePay để demo/test
# MÀ KHÔNG cần tiền thật, KHÔNG cần cấu hình webhook trên SePay dashboard.
#
# Dùng khi: đặt đơn bank_transfer trong app → màn QR đang chờ → chạy script này
# với order_number của đơn → app tự chuyển sang "thành công".
#
# KHÔNG hardcode secret ở đây. Đọc SEPAY_WEBHOOK_KEY từ biến môi trường.
#
# Cách dùng:
#   export SEPAY_WEBHOOK_KEY=<key đã set trong Supabase Edge Function secrets>
#   ./scripts/sepay-simulate-payment.sh <ORDER_NUMBER> <AMOUNT>
#
# Ví dụ:
#   ./scripts/sepay-simulate-payment.sh CF-20260703-ABC123 250000

set -euo pipefail

FUNCTION_URL="${SEPAY_FUNCTION_URL:-https://agbnpqgxsppdrpbqoipo.supabase.co/functions/v1/sepay-webhook}"

if [ -z "${SEPAY_WEBHOOK_KEY:-}" ]; then
  echo "ERROR: chưa set SEPAY_WEBHOOK_KEY. Chạy: export SEPAY_WEBHOOK_KEY=<key>" >&2
  exit 1
fi

ORDER_NUMBER="${1:-}"
AMOUNT="${2:-}"
if [ -z "$ORDER_NUMBER" ] || [ -z "$AMOUNT" ]; then
  echo "Cách dùng: $0 <ORDER_NUMBER> <AMOUNT>" >&2
  echo "Ví dụ:     $0 CF-20260703-ABC123 250000" >&2
  exit 1
fi

# Payload mô phỏng đúng shape webhook SePay gửi khi có tiền vào.
PAYLOAD=$(cat <<JSON
{
  "id": 900000,
  "gateway": "TPBank",
  "transactionDate": "2026-07-03 12:00:00",
  "accountNumber": "03010216099",
  "content": "CT DEN $ORDER_NUMBER thanh toan don hang",
  "transferType": "in",
  "transferAmount": $AMOUNT,
  "referenceCode": "SIM-$ORDER_NUMBER",
  "description": "sandbox simulate"
}
JSON
)

echo "→ Giả thanh toán $AMOUNT cho đơn $ORDER_NUMBER ..."
curl -s -X POST "$FUNCTION_URL" \
  -H "Content-Type: application/json" \
  -H "Authorization: Apikey $SEPAY_WEBHOOK_KEY" \
  --data-binary "$PAYLOAD"
echo
echo "→ Xong. Nếu đơn đang pending + đủ tiền, order sẽ chuyển 'confirmed'."
