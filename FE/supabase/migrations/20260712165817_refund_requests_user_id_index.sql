-- order_id already gets an implicit index from its unique constraint;
-- user_id is filtered directly in the "Customers view own refund requests"
-- RLS policy and has no covering index yet — matches the rls_perf_fk_indexes
-- precedent (additive, zero behavior change).
create index if not exists idx_refund_requests_user_id on public.refund_requests (user_id);
