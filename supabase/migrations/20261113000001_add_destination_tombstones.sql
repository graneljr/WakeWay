alter table public.destinations
  add column if not exists is_deleted boolean not null default false;
