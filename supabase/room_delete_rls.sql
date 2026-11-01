-- Allow a signed-in staff member to delete only rooms they own.
-- The application sends the Supabase user access token, so auth.uid() is
-- the same UUID stored in room.staff_id.

begin;

alter table public.room enable row level security;
alter table public.room_photo enable row level security;

-- Keep existing policies intact; replace only the policies owned by this fix.
drop policy if exists "staff_can_delete_own_rooms" on public.room;
drop policy if exists "staff_can_delete_own_room_photos" on public.room_photo;

create policy "staff_can_delete_own_rooms"
on public.room
for delete
to authenticated
using (staff_id = auth.uid());

create policy "staff_can_delete_own_room_photos"
on public.room_photo
for delete
to authenticated
using (
	exists (
		select 1
		from public.room r
		where r.id = room_photo.room_id
		  and r.staff_id = auth.uid()
	)
);

-- PostgREST must have table privileges in addition to passing RLS.
grant delete on table public.room to authenticated;
grant delete on table public.room_photo to authenticated;

-- Room photo rows are read by the application before deleting their storage
-- objects. Add the narrow read policy only if one is not already present.
drop policy if exists "staff_can_read_own_room_photos" on public.room_photo;
create policy "staff_can_read_own_room_photos"
on public.room_photo
for select
to authenticated
using (
	exists (
		select 1
		from public.room r
		where r.id = room_photo.room_id
		  and r.staff_id = auth.uid()
	)
);

grant select on table public.room_photo to authenticated;

-- Storage objects are named <room-uuid>/<generated-file-name> by the app.
-- This allows deletion of only files belonging to the caller's own room.
drop policy if exists "staff_can_delete_own_room_photo_objects" on storage.objects;
create policy "staff_can_delete_own_room_photo_objects"
on storage.objects
for delete
to authenticated
using (
	bucket_id = 'room-photos'
	and exists (
		select 1
		from public.room r
		where r.id::text = split_part(storage.objects.name, '/', 1)
		  and r.staff_id = auth.uid()
	)
);

grant delete on table storage.objects to authenticated;

commit;
