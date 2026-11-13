alter table public.destinations
  add column if not exists deleted_at timestamptz;

do $$
begin
  if exists (
    select 1
    from information_schema.columns
    where table_schema = 'public'
      and table_name = 'destinations'
      and column_name = 'is_deleted'
  ) then
    execute '
      update public.destinations
      set deleted_at = coalesce(deleted_at, updated_at, now())
      where is_deleted = true and deleted_at is null
    ';
    execute 'alter table public.destinations drop column is_deleted';
  end if;
end $$;
