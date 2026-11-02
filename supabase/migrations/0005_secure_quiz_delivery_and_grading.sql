-- Secure quiz delivery and server-side grading.
-- Students never receive correct_option and cannot write scores directly.

drop policy if exists "students submit own quiz attempts" on public.quiz_attempts;
revoke insert, update on table public.quiz_attempts from anon, authenticated;

create or replace function private.get_quiz_for_student(p_quiz_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user_id uuid := auth.uid();
  v_result jsonb;
begin
  if v_user_id is null then
    raise exception 'Authentication required' using errcode = '28000';
  end if;

  select jsonb_build_object(
    'id', q.id,
    'title', q.title,
    'course_id', q.course_id,
    'questions', coalesce((
      select jsonb_agg(
        jsonb_build_object(
          'id', qq.id,
          'prompt', qq.prompt,
          'options', qq.options,
          'position', qq.position
        ) order by qq.position, qq.id
      )
      from public.quiz_questions qq
      where qq.quiz_id = q.id
    ), '[]'::jsonb)
  )
  into v_result
  from public.quizzes q
  join public.courses c on c.id = q.course_id
  where q.id = p_quiz_id
    and c.status = 'published'::public.course_status
    and exists (
      select 1 from public.enrollments e
      where e.course_id = c.id and e.student_id = v_user_id
    );

  if v_result is null then
    raise exception 'Quiz not found or enrollment required' using errcode = '42501';
  end if;

  return v_result;
end;
$$;

create or replace function private.submit_quiz_attempt(
  p_quiz_id uuid,
  p_answers jsonb
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user_id uuid := auth.uid();
  v_course_id uuid;
  v_question_count integer;
  v_answer_count integer;
  v_correct_count integer := 0;
  v_item record;
  v_selected integer;
  v_attempt_id uuid;
  v_score numeric(6,2);
begin
  if v_user_id is null then
    raise exception 'Authentication required' using errcode = '28000';
  end if;

  if p_answers is null or jsonb_typeof(p_answers) <> 'object' then
    raise exception 'Answers must be a JSON object' using errcode = '22023';
  end if;

  select q.course_id into v_course_id
  from public.quizzes q
  join public.courses c on c.id = q.course_id
  where q.id = p_quiz_id
    and c.status = 'published'::public.course_status
    and exists (
      select 1 from public.enrollments e
      where e.course_id = c.id and e.student_id = v_user_id
    );

  if v_course_id is null then
    raise exception 'Quiz not found or enrollment required' using errcode = '42501';
  end if;

  select count(*) into v_question_count
  from public.quiz_questions qq
  where qq.quiz_id = p_quiz_id;

  if v_question_count = 0 then
    raise exception 'This quiz has no questions' using errcode = '22023';
  end if;

  select count(*) into v_answer_count from jsonb_object_keys(p_answers);
  if v_answer_count <> v_question_count then
    raise exception 'Submit exactly one answer for each question' using errcode = '22023';
  end if;

  for v_item in
    select qq.id, qq.correct_option, qq.options
    from public.quiz_questions qq
    where qq.quiz_id = p_quiz_id
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

  insert into public.quiz_attempts (quiz_id, student_id, answers, score)
  values (p_quiz_id, v_user_id, p_answers, v_score)
  returning id into v_attempt_id;

  return jsonb_build_object(
    'attempt_id', v_attempt_id,
    'score', v_score,
    'correct_answers', v_correct_count,
    'total_questions', v_question_count
  );
end;
$$;

revoke all on function private.get_quiz_for_student(uuid) from public, anon;
revoke all on function private.submit_quiz_attempt(uuid, jsonb) from public, anon;
grant usage on schema private to authenticated;
grant execute on function private.get_quiz_for_student(uuid) to authenticated;
grant execute on function private.submit_quiz_attempt(uuid, jsonb) to authenticated;

create or replace function public.get_quiz_for_student(p_quiz_id uuid)
returns jsonb
language sql
security invoker
set search_path = ''
as $$
  select private.get_quiz_for_student(p_quiz_id);
$$;

create or replace function public.submit_quiz_attempt(p_quiz_id uuid, p_answers jsonb)
returns jsonb
language sql
security invoker
set search_path = ''
as $$
  select private.submit_quiz_attempt(p_quiz_id, p_answers);
$$;

revoke all on function public.get_quiz_for_student(uuid) from public, anon;
revoke all on function public.submit_quiz_attempt(uuid, jsonb) from public, anon;
grant execute on function public.get_quiz_for_student(uuid) to authenticated;
grant execute on function public.submit_quiz_attempt(uuid, jsonb) to authenticated;
