import { createClient } from "jsr:@supabase/supabase-js@2";

const jsonHeaders = { "Content-Type": "application/json" };
const allowedRoles = new Set(["customer", "manager", "admin"]);

const json = (status: number, body: Record<string, unknown>) =>
  new Response(JSON.stringify(body), { status, headers: jsonHeaders });

const clean = (value: unknown) => String(value ?? "").trim();
const inviteErrorMessage = (error: unknown) => {
  const raw = error instanceof Error
    ? error.message
    : error && typeof error === "object" && "message" in error
    ? String(error.message)
    : typeof error === "string"
    ? error
    : "";
  const message = raw.toLowerCase();
  if (message.includes("already") || message.includes("duplicate")) {
    return "duplicate email";
  }
  if (
    message.includes("send") || message.includes("email") ||
    message === "{}"
  ) {
    return "invite delivery failed";
  }
  return "invite failed";
};

const isJsonObject = (value: unknown): value is Record<string, unknown> =>
  Boolean(value) && typeof value === "object" && !Array.isArray(value);

function parseBody(body: Record<string, unknown>) {
  const email = clean(body.email).toLowerCase();
  const fullName = clean(body.fullName);
  const role = clean(body.role);
  const brandName = clean(body.brandName);

  if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) {
    return { error: "invalid email" };
  }
  if (!fullName) return { error: "fullName is required" };
  if (!allowedRoles.has(role)) return { error: "invalid role" };

  return {
    value: {
      email,
      fullName,
      role,
      brandName: brandName || null,
    },
  };
}

Deno.serve(async (req: Request) => {
  if (req.method !== "POST") return json(405, { error: "method not allowed" });

  const authHeader = req.headers.get("Authorization") ?? "";
  if (!authHeader.startsWith("Bearer ")) {
    return json(401, { error: "missing bearer token" });
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const anonKey = Deno.env.get("SUPABASE_ANON_KEY");
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!supabaseUrl || !anonKey || !serviceRoleKey) {
    return json(500, { error: "server misconfigured" });
  }

  const callerClient = createClient(supabaseUrl, anonKey, {
    global: { headers: { Authorization: authHeader } },
  });
  const adminClient = createClient(supabaseUrl, serviceRoleKey);

  const token = authHeader.replace("Bearer ", "");
  const { data: authData, error: authError } = await callerClient.auth.getUser(
    token,
  );
  const caller = authData.user;
  if (authError || !caller) return json(401, { error: "unauthorized" });

  const { data: callerProfile, error: profileError } = await adminClient
    .from("profiles")
    .select("role")
    .eq("id", caller.id)
    .maybeSingle();
  if (profileError) return json(500, { error: "profile lookup failed" });
  if (callerProfile?.role !== "admin") {
    return json(403, { error: "admin required" });
  }

  let rawBody: unknown;
  try {
    rawBody = await req.json();
  } catch {
    return json(400, { error: "invalid json" });
  }
  if (!isJsonObject(rawBody)) return json(400, { error: "invalid json" });

  const parsed = parseBody(rawBody);
  if ("error" in parsed) return json(400, { error: parsed.error });
  const invite = parsed.value;

  const { data: existingProfile, error: existingError } = await adminClient
    .from("profiles")
    .select("id")
    .eq("email", invite.email)
    .maybeSingle();
  if (existingError) return json(500, { error: "profile lookup failed" });
  if (existingProfile) return json(409, { error: "duplicate email" });

  const { data: invited, error: inviteError } = await adminClient.auth.admin
    .inviteUserByEmail(invite.email, {
      data: { role: invite.role, full_name: invite.fullName },
    });
  if (inviteError) {
    console.error("admin invite failed");
    return json(400, { error: inviteErrorMessage(inviteError) });
  }

  const userId = invited.user?.id;
  if (!userId) return json(500, { error: "invite did not return user" });

  const profile = {
    id: userId,
    email: invite.email,
    full_name: invite.fullName,
    role: invite.role,
    ...(invite.brandName ? { brand_name: invite.brandName } : {}),
  };
  const { error: upsertError } = await adminClient
    .from("profiles")
    .upsert(profile, { onConflict: "id" });
  if (upsertError) return json(500, { error: "profile update failed" });

  return json(200, {
    success: true,
    user: { id: userId, email: invite.email, role: invite.role },
  });
});
