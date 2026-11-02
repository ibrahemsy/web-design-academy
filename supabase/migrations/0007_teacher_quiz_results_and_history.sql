-- Teacher-only quiz result summary RPC; does not return answer payloads.
create or replace function private.get_quiz_results_for_teacher(p_quiz_id uuid)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare
  v_user_id uuid := auth.uid();
  v_results jsonb;
begin
  if v_user_id is null then
    raise exception 'Authentication required' using errcode = '28000';
  end if;
  if not exists (
    select 1 from public.quizzes q
    join public.courses c on c.id = q.course_id
    where q.id = p_quiz_id
      and (c.teacher_id = v_user_id or private.is_admin())
  ) then
    raise exception 'Not allowed' using errcode = '42501';
  end if;
  select coalesce(jsonb_agg(jsonb_build_object(
    'attempt_id', a.id,
    'student_id', a.student_id,
    'student_name', coalesce(nullif(p.display_name, ''), 'طالب'),
    'score', a.score,
    'submitted_at', a.submitted_at
  ) order by a.submitted_at desc), '[]'::jsonb)
  into v_results
  from public.quiz_attempts a
  join public.profiles p on p.id = a.student_id
  where a.quiz_id = p_quiz_id;
  return v_results;
end;
$$;
revoke all on function private.get_quiz_results_for_teacher(uuid) from public, anon;
grant usage on schema private to authenticated;
grant execute on function private.get_quiz_results_for_teacher(uuid) to authenticated;

create or replace function public.get_quiz_results_for_teacher(p_quiz_id uuid)
returns jsonb language sql security invoker set search_path = '' as $$
  select private.get_quiz_results_for_teacher(p_quiz_id);
$$;
revoke all on function public.get_quiz_results_for_teacher(uuid) from public, anon;
grant execute on function public.get_quiz_results_for_teacher(uuid) to authenticated;

create index if not exists quiz_attempts_quiz_submitted_at_idx
on public.quiz_attempts (quiz_id, submitted_at desc);
