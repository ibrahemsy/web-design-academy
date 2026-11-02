-- Return only course enrollment and learning-progress summaries to the course owner/admin.
create or replace function private.get_course_students(p_course_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user_id uuid := auth.uid();
  v_students jsonb;
begin
  if v_user_id is null then
    raise exception 'Authentication required' using errcode = '28000';
  end if;

  if not exists (
    select 1 from public.courses c
    where c.id = p_course_id
      and (c.teacher_id = v_user_id or private.is_admin())
  ) then
    raise exception 'Not allowed to view this course roster' using errcode = '42501';
  end if;

  select coalesce(jsonb_agg(
    jsonb_build_object(
      'student_id', e.student_id,
      'student_name', coalesce(nullif(p.display_name, ''), 'طالب'),
      'enrolled_at', e.enrolled_at,
      'completed_lessons', coalesce(progress.completed_lessons, 0),
      'total_lessons', coalesce(total.total_lessons, 0)
    ) order by e.enrolled_at desc
  ), '[]'::jsonb)
  into v_students
  from public.enrollments e
  join public.profiles p on p.id = e.student_id
  left join lateral (
    select count(*)::integer as completed_lessons
    from public.lesson_progress lp
    join public.lessons l on l.id = lp.lesson_id
    where lp.student_id = e.student_id
      and l.course_id = p_course_id
      and lp.completed = true
  ) progress on true
  left join lateral (
    select count(*)::integer as total_lessons
    from public.lessons l
    where l.course_id = p_course_id
  ) total on true
  where e.course_id = p_course_id;

  return v_students;
end;
$$;

revoke all on function private.get_course_students(uuid) from public, anon;
grant usage on schema private to authenticated;
grant execute on function private.get_course_students(uuid) to authenticated;

create or replace function public.get_course_students(p_course_id uuid)
returns jsonb
language sql
security invoker
set search_path = ''
as $$
  select private.get_course_students(p_course_id);
$$;

revoke all on function public.get_course_students(uuid) from public, anon;
grant execute on function public.get_course_students(uuid) to authenticated;
