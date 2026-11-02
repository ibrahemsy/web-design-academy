-- Archiving a course must revoke new signed-video reads for enrolled students.
drop policy if exists "eligible users read course videos" on storage.objects;
create policy "eligible users read course videos"
on storage.objects for select to authenticated
using (
  bucket_id = 'course-videos'
  and (
    exists (
      select 1 from public.courses c
      where c.id::text = (storage.foldername(name))[1]
        and c.teacher_id = (select auth.uid())
    )
    or exists (
      select 1
      from public.enrollments e
      join public.courses c on c.id = e.course_id
      where e.course_id::text = (storage.foldername(name))[1]
        and e.student_id = (select auth.uid())
        and c.status = 'published'::public.course_status
    )
    or private.is_admin()
    or exists (
      select 1
      from public.lessons l
      join public.courses c on c.id = l.course_id
      where l.video_path = objects.name
        and l.is_preview = true
        and c.status = 'published'::public.course_status
    )
  )
);
