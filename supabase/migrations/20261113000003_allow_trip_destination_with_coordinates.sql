alter table public.trips
  drop constraint if exists trips_location_check;

alter table public.trips
  add constraint trips_location_check
  check (
    destination_id is not null
    or (alarm_latitude is not null and alarm_longitude is not null)
  );
