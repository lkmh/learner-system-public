-- Run this once in the Supabase SQL editor for your project (Dashboard > SQL Editor > New query).
-- After this, run seed.sql to add placeholder testimonials to launch with.

create extension if not exists pgcrypto;

create table if not exists testimonials (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  title text not null,
  company text not null,
  class_attended text not null,
  stars integer not null default 5 check (stars between 1 and 5),
  quote text not null,
  photo_url text,
  approved boolean not null default false,
  created_at timestamptz not null default now()
);

alter table testimonials enable row level security;

-- Anyone (anonymous visitors) can submit a testimonial. `to public` (not
-- just `to anon`) so this keeps working even if the same browser also has
-- an authenticated session active for something else on this project (e.g.
-- the live-quiz host login) — see live-quiz/schema.sql for the same fix.
create policy "Anyone can submit a testimonial"
  on testimonials for insert
  to public
  with check (true);

-- Anyone can read only testimonials that have been approved.
create policy "Anyone can read approved testimonials"
  on testimonials for select
  to public
  using (approved = true);

-- Public bucket for selfie photos. Create via Dashboard > Storage > New bucket
-- named "testimonial-photos" with "Public bucket" turned on, or run this:
insert into storage.buckets (id, name, public)
values ('testimonial-photos', 'testimonial-photos', true)
on conflict (id) do nothing;

-- Anyone can upload a photo into that bucket (but can't overwrite/delete others').
create policy "Anyone can upload a testimonial photo"
  on storage.objects for insert
  to public
  with check (bucket_id = 'testimonial-photos');

-- Anyone can view photos in that bucket (needed for the public wall page).
create policy "Public can view testimonial photos"
  on storage.objects for select
  to public
  using (bucket_id = 'testimonial-photos');

-- To moderate: in Dashboard > Table Editor > testimonials, flip `approved`
-- to true on rows you want to show on the wall.


-- ============================================================
-- Migration — run this instead if your database already has the original
-- (role_or_company, no stars/class_attended) version of this table.
-- ============================================================
--
-- alter table testimonials rename column role_or_company to title;
-- alter table testimonials add column if not exists company text;
-- alter table testimonials add column if not exists class_attended text;
-- alter table testimonials add column if not exists stars integer not null default 5 check (stars between 1 and 5);
--
-- drop policy if exists "Anyone can submit a testimonial" on testimonials;
-- drop policy if exists "Anyone can read approved testimonials" on testimonials;
-- create policy "Anyone can submit a testimonial" on testimonials for insert to public with check (true);
-- create policy "Anyone can read approved testimonials" on testimonials for select to public using (approved = true);
--
-- drop policy if exists "Anyone can upload a testimonial photo" on storage.objects;
-- drop policy if exists "Public can view testimonial photos" on storage.objects;
-- create policy "Anyone can upload a testimonial photo" on storage.objects for insert to public with check (bucket_id = 'testimonial-photos');
-- create policy "Public can view testimonial photos" on storage.objects for select to public using (bucket_id = 'testimonial-photos');


-- ============================================================
-- Second migration — title/company/class_attended became required fields.
-- Run this if your table already has the stars/class_attended columns but
-- they're still nullable. Clears any incomplete test rows first, since a
-- NOT NULL constraint can't be added while rows violate it — re-run
-- seed.sql after this if that's what you're clearing out.
-- ============================================================
--
-- delete from testimonials where title is null or company is null or class_attended is null;
-- alter table testimonials
--   alter column title set not null,
--   alter column company set not null,
--   alter column class_attended set not null;
