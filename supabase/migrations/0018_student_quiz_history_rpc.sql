-- Give students a safe, complete history view, including attempts from archived courses.
create or replace function private.get_my_quiz_history()
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user_id uuid := auth.uid();
  v_history jsonb;
begin
  if v_user_id is null then
    raise exception 'Authentication required' using errcode = '28000';
  end if;

  select coalesce(jsonb_agg(jsonb_build_object(
    'quiz_title', q.title,
    'score', a.score,
    'submitted_at', a.submitted_at
  ) order by a.submitted_at desc), '[]'::jsonb)
  into v_history
  from public.quiz_attempts a
  join public.quizzes q on q.id = a.quiz_id
  where a.student_id = v_user_id;

  return v_history;
end;
$$;

revoke all on function private.get_my_quiz_history() from public, anon;
grant usage on schema private to authenticated;
grant execute on function private.get_my_quiz_history() to authenticated;

create or replace function public.get_my_quiz_history()
returns jsonb
language sql
security invoker
set search_path = ''
as $$
  select private.get_my_quiz_history();
$$;

revoke all on function public.get_my_quiz_history() from public, anon;
grant execute on function public.get_my_quiz_history() to authenticated;
