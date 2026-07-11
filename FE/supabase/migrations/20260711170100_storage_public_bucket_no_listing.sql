-- Public buckets (products, reviews) serve individual objects via the
-- public object URL without consulting storage.objects RLS at all — that's
-- what bucket.public=true means. The broad "Public can view … images"
-- SELECT policy on storage.objects therefore grants nothing that public
-- object GET needs; its only real effect is letting anyone list/enumerate
-- every file in the bucket via the storage list API or a table query.
-- Dropping it removes that listing surface while leaving object URL access
-- (what the app actually uses — FE/lib renders product/review images by
-- URL, never by listing the bucket) untouched.

drop policy if exists "Public can view product images" on storage.objects;
drop policy if exists "Public can view review images" on storage.objects;
