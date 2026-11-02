-- Preserve the pass threshold used at submission time for historical accuracy.
alter table public.quiz_attempts
  add column passing_score_snapshot integer not null default 50
    check (passing_score_snapshot between 0 and 100),
  add column passed boolean not null default false;

update public.quiz_attempts a
set passing_score_snapshot = q.passing_score,
    passed = coalesce(a.score, 0) >= q.passing_score
from public.quizzes q
where q.id = a.quiz_id;

create or replace function private.submit_quiz_attempt(p_quiz_id uuid, p_answers jsonb)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user_id uuid := auth.uid();
  v_course_id uuid;
  v_passing_score integer;
  v_max_attempts integer;
  v_attempts_used integer := 0;
  v_question_count integer;
  v_answer_count integer;
  v_correct_count integer := 0;
  v_item record;
  v_selected integer;
  v_attempt_id uuid;
  v_score numeric(6,2);
  v_passed boolean;
begin
  if v_user_id is null then
    raise exception 'Authentication required' using errcode = '28000';
  end if;
  if p_answers is null or jsonb_typeof(p_answers) <> 'object' then
    raise exception 'Answers must be a JSON object' using errcode = '22023';
  end if;

  select q.course_id, q.passing_score, q.max_attempts
  into v_course_id, v_passing_score, v_max_attempts
  from public.quizzes q
  join public.courses c on c.id = q.course_id
  where q.id = p_quiz_id
    and c.status = 'published'::public.course_status
    and exists (
      select 1 from public.enrollments e
      where e.course_id = c.id and e.student_id = v_user_id
    )
  for update of q;

  if v_course_id is null then
    raise exception 'Quiz not found or enrollment required' using errcode = '42501';
  end if;

  select count(*)::integer into v_attempts_used
  from public.quiz_attempts a
  where a.quiz_id = p_quiz_id and a.student_id = v_user_id;
  if v_max_attempts is not null and v_attempts_used >= v_max_attempts then
    raise exception 'Maximum number of attempts reached' using errcode = '42501';
  end if;

  select count(*) into v_question_count
  from public.quiz_questions qq where qq.quiz_id = p_quiz_id;
  if v_question_count = 0 then
    raise exception 'This quiz has no questions' using errcode = '22023';
  end if;

  select count(*) into v_answer_count from jsonb_object_keys(p_answers);
  if v_answer_count <> v_question_count then
    raise exception 'Submit exactly one answer for each question' using errcode = '22023';
  end if;

  for v_item in
    select qq.id, qq.correct_option, qq.options
    from public.quiz_questions qq where qq.quiz_id = p_quiz_id
  loop
    if not (p_answers ? v_item.id::text) then
      raise exception 'A question answer is missing' using errcode = '22023';
    end if;
    begin
      v_selected := (p_answers ->> v_item.id::text)::integer;
    exception when others then
      raise exception 'Each answer must be an option index' using errcode = '22023';
    end;
    if v_selected < 0 or v_selected >= jsonb_array_length(v_item.options) then
      raise exception 'An answer option is out of range' using errcode = '22023';
    end if;
    if v_selected = v_item.correct_option then
      v_correct_count := v_correct_count + 1;
    end if;
  end loop;

  v_score := round((v_correct_count::numeric / v_question_count::numeric) * 100, 2);
  v_passed := v_score >= v_passing_score;

  insert into public.quiz_attempts (
    quiz_id, student_id, answers, score, passing_score_snapshot, passed
  )
  values (
    p_quiz_id, v_user_id, p_answers, v_score, v_passing_score, v_passed
  )
  returning id into v_attempt_id;

  v_attempts_used := v_attempts_used + 1;
  return jsonb_build_object(
    'attempt_id', v_attempt_id,
    'score', v_score,
    'correct_answers', v_correct_count,
    'total_questions', v_question_count,
    'passing_score', v_passing_score,
    'passed', v_passed,
    'attempts_used', v_attempts_used,
    'attempts_remaining', case
      when v_max_attempts is null then null
      else greatest(v_max_attempts - v_attempts_used, 0)
    end
  );
end;
$$;

create or replace function private.get_quiz_results_for_teacher(p_quiz_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
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
    raise exception 'You are not allowed to view these results' using errcode = '42501';
  end if;

  select coalesce(jsonb_agg(jsonb_build_object(
    'student_name', coalesce(nullif(p.display_name, ''), 'طالب'),
    'score', a.score,
    'passing_score', a.passing_score_snapshot,
    'passed', a.passed,
    'submitted_at', a.submitted_at
  ) order by a.submitted_at desc), '[]'::jsonb)
  into v_results
  from public.quiz_attempts a
  join public.profiles p on p.id = a.student_id
  where a.quiz_id = p_quiz_id;
  return v_results;
end;
$$;

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
    'passing_score', a.passing_score_snapshot,
    'passed', a.passed,
    'submitted_at', a.submitted_at
  ) order by a.submitted_at desc), '[]'::jsonb)
  into v_history
  from public.quiz_attempts a
  join public.quizzes q on q.id = a.quiz_id
  where a.student_id = v_user_id;
  return v_history;
end;
$$;
