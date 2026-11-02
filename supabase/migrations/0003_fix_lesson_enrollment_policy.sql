drop policy if exists "lessons visible to eligible users" on public.lessons;

create policy "lessons visible to eligible users"
on public.lessons
for select
to authenticated
using (
  is_preview
  or (
    exists (
      select 1 from public.courses c
      where c.id = lessons.course_id
        and c.status = 'published'
    )
    and (
      exists (
        select 1 from public.courses c
        where c.id = lessons.course_id
          and c.teacher_id = (select auth.uid())
      )
      or exists (
        select 1 from public.enrollments e
        where e.course_id = lessons.course_id
          and e.student_id = (select auth.uid())
      )
      or private.is_admin()
    )
  )
);
