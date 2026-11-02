-- A preview flag must never make lessons in draft/archived courses visible.
drop policy if exists "lessons visible to eligible users" on public.lessons;
create policy "lessons visible to eligible users"
on public.lessons for select to authenticated
using (
  exists (
    select 1
    from public.courses c
    where c.id = lessons.course_id
      and (
        c.teacher_id = (select auth.uid())
        or private.is_admin()
        or (
          c.status = 'published'::public.course_status
          and (
            lessons.is_preview
            or exists (
              select 1
              from public.enrollments e
              where e.course_id = c.id
                and e.student_id = (select auth.uid())
            )
          )
        )
      )
  )
);
