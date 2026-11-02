-- Validate quiz question options and restrict student visibility to published enrolled courses.

do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conrelid = 'public.quiz_questions'::regclass
      and conname = 'quiz_questions_options_array_check'
  ) then
    alter table public.quiz_questions
      add constraint quiz_questions_options_array_check
      check (jsonb_typeof(options) = 'array' and jsonb_array_length(options) >= 2);
  end if;

  if not exists (
    select 1 from pg_constraint
    where conrelid = 'public.quiz_questions'::regclass
      and conname = 'quiz_questions_correct_option_in_range_check'
  ) then
    alter table public.quiz_questions
      add constraint quiz_questions_correct_option_in_range_check
      check (correct_option >= 0 and correct_option < jsonb_array_length(options));
  end if;
end
$$;

drop policy if exists "quizzes visible for published enrolled courses" on public.quizzes;
create policy "quizzes visible to course teachers and enrolled students"
on public.quizzes
for select
to authenticated
using (
  exists (
    select 1
    from public.courses c
    where c.id = quizzes.course_id
      and (
        c.teacher_id = auth.uid()
        or private.is_admin()
        or (
          c.status = 'published'::public.course_status
          and exists (
            select 1 from public.enrollments e
            where e.course_id = c.id and e.student_id = auth.uid()
          )
        )
      )
  )
);
