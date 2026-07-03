// SePay webhook receiver for BigStyle.
//
// SePay giám sát tài khoản ngân hàng và POST về đây khi có chuyển khoản.
// Chức năng: khớp nội dung CK với order_number → cập nhật payments + confirm order.
// Deploy với verify_jwt=false (SePay không gửi JWT Supabase); tự verify bằng Apikey.
//
// Secrets cần set (Edge Function → Manage secrets): SEPAY_WEBHOOK_KEY
// Auto-có sẵn: SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY

import { createClient } from "jsr:@supabase/supabase-js@2";

// Chuẩn hoá để khớp: bỏ mọi ký tự không phải chữ/số, viết hoa.
// Ngân hàng thường strip dấu '-' trong nội dung CK nên phải normalize 2 phía.
const norm = (s: unknown) => String(s ?? "").toUpperCase().replace(/[^A-Z0-9]/g, "");

const ok = () =>
  new Response(JSON.stringify({ success: true }), {
    headers: { "Content-Type": "application/json" },
  });

const fail = (status: number, error: string) =>
  new Response(JSON.stringify({ success: false, error }), {
    status,
    headers: { "Content-Type": "application/json" },
  });

Deno.serve(async (req: Request) => {
  // 1. Verify Apikey (chống gọi trái phép). Secret chưa set → coi như unauthorized.
  const key = Deno.env.get("SEPAY_WEBHOOK_KEY");
  const auth = req.headers.get("Authorization") ?? "";
  if (!key || auth !== `Apikey ${key}`) {
    return fail(401, "unauthorized");
  }

  let body: Record<string, unknown>;
  try {
    body = await req.json();
  } catch {
    return fail(400, "invalid json");
  }

  // 2. Chỉ xử lý tiền vào
  if (body.transferType && body.transferType !== "in") return ok();

  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );

  // 3. Nội dung khớp: gộp content + code (một số bank để reference ở code)
  const contentNorm = norm(`${body.content ?? ""} ${body.code ?? ""}`);

  // 4. Tìm order trong 7 ngày gần nhất (MỌI status — cần cho nhánh idempotent/cancelled)
  const since = new Date(Date.now() - 7 * 24 * 3600 * 1000).toISOString();
  const { data: orders, error: oErr } = await supabase
    .from("orders")
    .select("id, order_number, status, total, user_id")
    .gte("created_at", since);

  if (oErr) {
    console.error("orders query failed", oErr);
    return ok(); // tránh SePay retry vô hạn
  }

  // order_number chuẩn hoá là token cố định 16 ký tự → không sợ false-positive containment
  const order = (orders ?? []).find(
    (o) => o.order_number && contentNorm.includes(norm(o.order_number)),
  );
  if (!order) {
    console.log("no order match for content:", body.content);
    return ok();
  }

  // 5. Lấy payment mới nhất của order
  const { data: pay } = await supabase
    .from("payments")
    .select("id, status")
    .eq("order_id", order.id)
    .order("created_at", { ascending: false })
    .limit(1)
    .maybeSingle();

  // Idempotent: đã success rồi thì thôi (SePay gửi lặp)
  if (pay && pay.status === "success") return ok();

  const amount = Number(body.transferAmount ?? 0);
  const total = Number(order.total ?? 0);
  const txId = String(body.referenceCode ?? body.id ?? "");

  // 6a. Thiếu tiền → ghi lại để đối soát, KHÔNG confirm
  if (amount < total) {
    if (pay) {
      await supabase
        .from("payments")
        .update({ gateway_response: body, transaction_id: txId })
        .eq("id", pay.id)
        .eq("status", "pending");
    }
    console.log("underpaid", order.order_number, amount, "of", total);
    return ok();
  }

  // 6b. Đủ tiền → cập nhật payment (conditional, chống double-webhook)
  if (pay) {
    await supabase
      .from("payments")
      .update({
        status: "success",
        paid_at: new Date().toISOString(),
        transaction_id: txId,
        gateway_response: body,
      })
      .eq("id", pay.id)
      .eq("status", "pending");
  } else {
    // Không có payment row (hiếm) → insert bản đối soát để không mất dữ liệu
    await supabase.from("payments").insert({
      order_id: order.id,
      user_id: order.user_id,
      method: "bank_transfer",
      amount: total,
      status: "success",
      paid_at: new Date().toISOString(),
      transaction_id: txId,
      gateway_response: body,
    });
  }

  // 6c. Confirm order CHỈ khi đang pending (không đè lên cancelled/đã đổi — chống race với manager)
  await supabase
    .from("orders")
    .update({ status: "confirmed" })
    .eq("id", order.id)
    .eq("status", "pending");

  return ok();
});
