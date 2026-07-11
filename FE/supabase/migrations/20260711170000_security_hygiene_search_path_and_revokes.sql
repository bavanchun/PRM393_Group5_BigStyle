-- Security hygiene (Supabase security advisor):
--   1. Pin search_path on notify_order_update / update_sold_count (the two
--      SECURITY DEFINER trigger functions the earlier
--      harden_secdef_search_path migration missed).
--   2. REVOKE EXECUTE on trigger-only functions from anon/authenticated —
--      they only ever need to run as triggers (owner-context, unaffected by
--      these grants), not be callable via /rest/v1/rpc/<name>. Scope is
--      deliberately narrow: handle_new_user is EXCLUDED even though the
--      advisor flags it — it's also trigger-only, but revoking EXECUTE on
--      an AFTER INSERT trigger function is a no-op at best (triggers fire
--      as owner regardless of API grants) and a real risk at worst if its
--      SECURITY DEFINER body is ever changed to do something grant-checked.
--      is_admin/is_manager/is_staff are also excluded — those are meant to
--      be called directly (client code and RLS policies both use them as
--      "can I do X" checks), not just trigger plumbing.
--   Confirmed via grep: no FE/lib code calls any of the revoked functions
--   through .rpc(), so this only removes an unused REST surface.

alter function public.notify_order_update() set search_path = public;
alter function public.update_sold_count() set search_path = public;

-- REVOKE FROM PUBLIC, not just anon/authenticated: these functions were
-- created with Postgres's default EXECUTE-to-PUBLIC grant, which every role
-- (including anon/authenticated) inherits regardless of a per-role revoke.
revoke execute on function public.bump_support_conversation() from public;
revoke execute on function public.notify_order_update() from public;
revoke execute on function public.update_product_rating() from public;
revoke execute on function public.prevent_profile_role_self_escalation() from public;
revoke execute on function public.update_sold_count() from public;
revoke execute on function public.restock_on_order_cancel() from public;
