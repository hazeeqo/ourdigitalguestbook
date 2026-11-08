-- Run this in Supabase Dashboard > SQL Editor after creating the
-- public "guest-photos" Storage bucket (512 KB limit, image/jpeg only).

create table if not exists public.guestbook_photos (
  id uuid primary key default gen_random_uuid(),
  guest_name text not null default 'A wedding guest'
    check (char_length(guest_name) <= 40),
  caption text not null default ''
    check (char_length(caption) <= 240),
  photo_path text not null unique,
  thumb_path text not null unique,
  filter_name text not null default 'flash'
    check (filter_name in ('flash', 'vintage', 'golden', 'mono', 'original')),
  created_at timestamptz not null default now()
);

alter table public.guestbook_photos enable row level security;
grant select, insert on public.guestbook_photos to anon;

drop policy if exists "Anyone can view wedding guest photos"
  on public.guestbook_photos;
create policy "Anyone can view wedding guest photos"
  on public.guestbook_photos for select to anon using (true);

drop policy if exists "Guests can add wedding guest photos"
  on public.guestbook_photos;
create policy "Guests can add wedding guest photos"
  on public.guestbook_photos for insert to anon with check (
    char_length(guest_name) <= 40
    and char_length(caption) <= 240
    and filter_name in ('flash', 'vintage', 'golden', 'mono', 'original')
  );

-- Keep the shared album at 1,000 photo entries. The transaction lock
-- serializes simultaneous inserts so guests cannot race past the cap.
create or replace function public.enforce_guestbook_photo_cap()
returns trigger
language plpgsql
as $$
begin
  perform pg_advisory_xact_lock(874130042);
  if (select count(*) from public.guestbook_photos) >= 1000 then
    raise exception 'The wedding album has reached its 1,000 photo limit';
  end if;
  return new;
end;
$$;

revoke all on function public.enforce_guestbook_photo_cap() from public;
drop trigger if exists guestbook_photo_cap on public.guestbook_photos;
create trigger guestbook_photo_cap
  before insert on public.guestbook_photos
  for each row execute function public.enforce_guestbook_photo_cap();

-- Allow the gallery to refresh automatically when a guest adds a photo.
do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'guestbook_photos'
  ) then
    alter publication supabase_realtime add table public.guestbook_photos;
  end if;
end;
$$;

-- Upload permission applies only to the public guest-photos bucket.
-- Cap the bucket at 2,000 JPEG objects (one photo and one thumbnail per entry).
-- The transaction lock keeps concurrent guest uploads from racing past the cap.
create or replace function public.allow_guestbook_upload()
returns boolean
language plpgsql
security definer
set search_path = ''
as $$
declare
  object_total bigint;
begin
  perform pg_catalog.pg_advisory_xact_lock(874130043);
  select count(*) into object_total
    from storage.objects
    where bucket_id = 'guest-photos'
      and name like 'wedding/%';
  return object_total < 2000;
end;
$$;

revoke all on function public.allow_guestbook_upload() from public;
grant execute on function public.allow_guestbook_upload() to anon;

drop policy if exists "Guests can upload wedding photos"
  on storage.objects;
create policy "Guests can upload wedding photos"
  on storage.objects for insert to anon
  with check (
    bucket_id = 'guest-photos'
    and (storage.foldername(name))[1] = 'wedding'
    and (select public.allow_guestbook_upload())
  );

-- Guests can upload and view, but cannot edit or delete other guests' files.
