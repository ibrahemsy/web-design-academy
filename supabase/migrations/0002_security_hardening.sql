-- Keep role-check helpers outside the exposed public API schema.
-- Security-definer functions are callable only by authenticated sessions through RLS.
create schema if not exists private;
revoke all on schema private from public, anon;
grant usage on schema private to authenticated, anon;

create or replace function private.is_admin()
returns boolean language sql stable security definer set search_path = ''
as $$
 select exists (select 1 from public.profiles p where p.id = (select auth.uid()) and p.role = 'admin'::public.user_role);
$$;

create or replace function private.is_teacher_or_admin()
returns boolean language sql stable security definer set search_path = ''
as $$
 select exists (select 1 from public.profiles p where p.id = (select auth.uid()) and p.role in ('teacher'::public.user_role,'admin'::public.user_role));
$$;

revoke all on function private.is_admin() from public, anon;
revoke all on function private.is_teacher_or_admin() from public, anon;
grant execute on function private.is_admin() to authenticated, anon;
grant execute on function private.is_teacher_or_admin() to authenticated;

alter policy "admins read all profiles" on public.profiles using (private.is_admin());
alter policy "published courses visible" on public.courses using (status = 'published' or teacher_id = auth.uid() or private.is_admin());
alter policy "teachers create own courses" on public.courses with check (teacher_id = auth.uid() and private.is_teacher_or_admin());
alter policy "lessons visible to eligible users" on public.lessons using (
 is_preview or (
  exists (select 1 from public.courses c where c.id = course_id and c.status = 'published')
  and (exists (select 1 from public.courses c where c.id = course_id and c.teacher_id = auth.uid())
   or exists (select 1 from public.enrollments e where e.course_id = course_id and e.student_id = auth.uid())
   or private.is_admin())
 ));
alter policy "course teachers manage lessons" on public.lessons
using (exists (select 1 from public.courses c where c.id = course_id and (c.teacher_id = auth.uid() or private.is_admin())))
with check (exists (select 1 from public.courses c where c.id = course_id and (c.teacher_id = auth.uid() or private.is_admin())));
alter policy "enrollments read self or course owner" on public.enrollments
using (student_id = auth.uid() or exists (select 1 from public.courses c where c.id = course_id and c.teacher_id = auth.uid()) or private.is_admin());
alter policy "quizzes visible for published enrolled courses" on public.quizzes
using (exists (select 1 from public.courses c where c.id = course_id and (c.teacher_id = auth.uid() or exists (select 1 from public.enrollments e where e.course_id = c.id and e.student_id = auth.uid()) or private.is_admin())));
alter policy "course teachers manage quizzes" on public.quizzes
using (exists (select 1 from public.courses c where c.id = course_id and (c.teacher_id = auth.uid() or private.is_admin())))
with check (exists (select 1 from public.courses c where c.id = course_id and (c.teacher_id = auth.uid() or private.is_admin())));
alter policy "quiz questions visible to course teachers" on public.quiz_questions
using (exists (select 1 from public.quizzes q join public.courses c on c.id = q.course_id where q.id = quiz_id and (c.teacher_id = auth.uid() or private.is_admin())));
alter policy "quiz questions managed by course teachers" on public.quiz_questions
using (exists (select 1 from public.quizzes q join public.courses c on c.id = q.course_id where q.id = quiz_id and (c.teacher_id = auth.uid() or private.is_admin())))
with check (exists (select 1 from public.quizzes q join public.courses c on c.id = q.course_id where q.id = quiz_id and (c.teacher_id = auth.uid() or private.is_admin())));
alter policy "enrolled students and course owners read videos" on storage.objects
using (bucket_id = 'course-videos' and (
 exists (select 1 from public.courses c where c.id::text = (storage.foldername(name))[1] and c.teacher_id = auth.uid())
 or exists (select 1 from public.enrollments e where e.course_id::text = (storage.foldername(name))[1] and e.student_id = auth.uid())
 or private.is_admin()));
revoke all on function public.handle_new_user() from public, anon, authenticated;
revoke all on function public.guard_profile_role() from public, anon, authenticated;
drop function if exists public.is_admin();
drop function if exists public.is_teacher_or_admin();
