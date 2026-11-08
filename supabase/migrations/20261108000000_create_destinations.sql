create table if not exists public.destinations (
  id text primary key,
  user_id uuid not null references auth.users (id) on delete cascade,
  name text not null,
  address text not null default '',
  latitude double precision not null check (latitude between -90 and 90),
  longitude double precision not null check (longitude between -180 and 180),
  updated_at timestamptz not null default now()
);

alter table public.destinations
  add column if not exists updated_at timestamptz not null default now();

create index if not exists destinations_user_id_idx
  on public.destinations (user_id, updated_at desc);

alter table public.destinations enable row level security;

drop policy if exists "Users can read own destinations"
  on public.destinations;
create policy "Users can read own destinations"
  on public.destinations for select to authenticated
  using ((select auth.uid()) = user_id);

drop policy if exists "Users can add own destinations"
  on public.destinations;
create policy "Users can add own destinations"
  on public.destinations for insert to authenticated
  with check ((select auth.uid()) = user_id);

drop policy if exists "Users can update own destinations"
  on public.destinations;
create policy "Users can update own destinations"
  on public.destinations for update to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

drop policy if exists "Users can delete own destinations"
  on public.destinations;
create policy "Users can delete own destinations"
  on public.destinations for delete to authenticated
  using ((select auth.uid()) = user_id);

grant select, insert, update, delete on public.destinations to authenticated;
