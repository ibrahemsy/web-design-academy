-- Cache auth.uid() per statement in public RLS policies and let administrators manage course media.
do $$
declare
  p record;
  v_sql text;
begin
  for p in
    select schemaname, tablename, policyname, qual, with_check
    from pg_policies
    where schemaname = 'public'
      and (coalesce(qual, '') like '%auth.uid()%' or coalesce(with_check, '') like '%auth.uid()%')
  loop
    v_sql := format('alter policy %I on %I.%I', p.policyname, p.schemaname, p.tablename);
    if p.qual is not null then
      v_sql := v_sql || format(' using (%s)', replace(p.qual, 'auth.uid()', '(select auth.uid())'));
    end if;
    if p.with_check is not null then
      v_sql := v_sql || format(' with check (%s)', replace(p.with_check, 'auth.uid()', '(select auth.uid())'));
    end if;
    execute v_sql;
  end loop;
end
$$;

drop policy if exists "teachers upload course videos" on storage.objects;
create policy "teachers upload course videos"
on storage.objects for insert to authenticated
with check (
  bucket_id = 'course-videos'
  and exists (
    select 1 from public.courses c
    where c.id::text = (storage.foldername(name))[1]
      and (c.teacher_id = (select auth.uid()) or private.is_admin())
      and c.status <> 'archived'::public.course_status
  )
);

drop policy if exists "teachers update course videos" on storage.objects;
create policy "teachers update course videos"
on storage.objects for update to authenticated
using (
  bucket_id = 'course-videos'
  and exists (
    select 1 from public.courses c
    where c.id::text = (storage.foldername(name))[1]
      and (c.teacher_id = (select auth.uid()) or private.is_admin())
      and c.status <> 'archived'::public.course_status
  )
)
with check (
  bucket_id = 'course-videos'
  and exists (
    select 1 from public.courses c
    where c.id::text = (storage.foldername(name))[1]
      and (c.teacher_id = (select auth.uid()) or private.is_admin())
      and c.status <> 'archived'::public.course_status
  )
);

drop policy if exists "teachers delete course videos" on storage.objects;
create policy "teachers delete course videos"
on storage.objects for delete to authenticated
using (
  bucket_id = 'course-videos'
  and exists (
    select 1 from public.courses c
    where c.id::text = (storage.foldername(name))[1]
      and (c.teacher_id = (select auth.uid()) or private.is_admin())
  )
);
