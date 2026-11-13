create table if not exists public.trips (
  id text primary key,
  user_id uuid not null references auth.users (id) on delete cascade,
  destination_id text references public.destinations (id) on delete set null,
  destination_name text not null,
  destination_address text,
  alarm_latitude double precision not null check (alarm_latitude between -90 and 90),
  alarm_longitude double precision not null check (alarm_longitude between -180 and 180),
  radius_meters integer not null,
  warning_distance_meters integer not null,
  vibration_enabled boolean not null default true,
  repeat_alarm boolean not null default true,
  snooze_minutes integer not null default 5,
  alarm_sound text not null default 'WakeWay alarm',
  custom_alarm_sound_path text,
  use_advance_point boolean not null default false,
  status text not null default 'active',
  alarm_triggered boolean not null default false,
  started_at timestamptz not null,
  completed_at timestamptz,
  updated_at timestamptz not null default now()
);

create index if not exists trips_user_id_updated_at_idx
  on public.trips (user_id, updated_at desc);

alter table public.trips enable row level security;

drop policy if exists "Users can read own trips" on public.trips;
create policy "Users can read own trips"
  on public.trips for select to authenticated
  using ((select auth.uid()) = user_id);

drop policy if exists "Users can add own trips" on public.trips;
create policy "Users can add own trips"
  on public.trips for insert to authenticated
  with check ((select auth.uid()) = user_id);

drop policy if exists "Users can update own trips" on public.trips;
create policy "Users can update own trips"
  on public.trips for update to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

drop policy if exists "Users can delete own trips" on public.trips;
create policy "Users can delete own trips"
  on public.trips for delete to authenticated
  using ((select auth.uid()) = user_id);

grant select, insert, update, delete on public.trips to authenticated;
