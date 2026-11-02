-- Consolidate permissive SELECT policies while preserving the existing access model.
drop policy if exists "admins read all profiles" on public.profiles;
drop policy if exists "profile read self" on public.profiles;
create policy "profiles visible to self and admins"
on public.profiles for select to authenticated
using (id = (select auth.uid()) or private.is_admin());

drop policy if exists "course teachers manage lessons" on public.lessons;
drop policy if exists "lessons visible to eligible users" on public.lessons;
create policy "lessons visible to eligible users"
on public.lessons for select to authenticated
using (
  is_preview
  or exists (
    select 1 from public.courses c
    where c.id = lessons.course_id
      and c.status = 'published'::public.course_status
      and (
        c.teacher_id = (select auth.uid())
        or private.is_admin()
        or exists (
          select 1 from public.enrollments e
          where e.course_id = c.id and e.student_id = (select auth.uid())
        )
      )
  )
);
create policy "course teachers insert lessons"
on public.lessons for insert to authenticated
with check (
  exists (select 1 from public.courses c
    where c.id = lessons.course_id
      and (c.teacher_id = (select auth.uid()) or private.is_admin()))
);
create policy "course teachers update lessons"
on public.lessons for update to authenticated
using (
  exists (select 1 from public.courses c
    where c.id = lessons.course_id
      and (c.teacher_id = (select auth.uid()) or private.is_admin()))
)
with check (
  exists (select 1 from public.courses c
    where c.id = lessons.course_id
      and (c.teacher_id = (select auth.uid()) or private.is_admin()))
);
create policy "course teachers delete lessons"
on public.lessons for delete to authenticated
using (
  exists (select 1 from public.courses c
    where c.id = lessons.course_id
      and (c.teacher_id = (select auth.uid()) or private.is_admin()))
);

drop policy if exists "course teachers manage quizzes" on public.quizzes;
drop policy if exists "quizzes visible to course teachers and enrolled students" on public.quizzes;
create policy "quizzes visible to eligible users"
on public.quizzes for select to authenticated
using (
  exists (
    select 1 from public.courses c
    where c.id = quizzes.course_id
      and (
        c.teacher_id = (select auth.uid())
        or private.is_admin()
        or (
          c.status = 'published'::public.course_status
          and exists (
            select 1 from public.enrollments e
            where e.course_id = c.id and e.student_id = (select auth.uid())
          )
        )
      )
  )
);
create policy "course teachers insert quizzes"
on public.quizzes for insert to authenticated
with check (
  exists (select 1 from public.courses c
    where c.id = quizzes.course_id
      and (c.teacher_id = (select auth.uid()) or private.is_admin()))
);
create policy "course teachers update quizzes"
on public.quizzes for update to authenticated
using (
  exists (select 1 from public.courses c
    where c.id = quizzes.course_id
      and (c.teacher_id = (select auth.uid()) or private.is_admin()))
)
with check (
  exists (select 1 from public.courses c
    where c.id = quizzes.course_id
      and (c.teacher_id = (select auth.uid()) or private.is_admin()))
);
create policy "course teachers delete quizzes"
on public.quizzes for delete to authenticated
using (
  exists (select 1 from public.courses c
    where c.id = quizzes.course_id
      and (c.teacher_id = (select auth.uid()) or private.is_admin()))
);

drop policy if exists "quiz questions visible to course teachers" on public.quiz_questions;
