-- Increase public certificate-code entropy from 48 bits to 128 random bits.
-- Existing certificate codes remain valid; only certificates issued after this
-- migration use the longer random suffix.
create or replace function private.issue_course_certificate(p_course_id uuid)
returns jsonb language plpgsql security definer set search_path = ''
as $function$
declare
  v_user_id uuid := auth.uid();
  v_course public.courses%rowtype;
  v_student_name text;
  v_total_lessons integer;
  v_completed_lessons integer;
  v_required_quizzes integer;
  v_passed_quizzes integer;
  v_certificate private.course_certificates%rowtype;
begin
  if v_user_id is null then
    raise exception 'Authentication required' using errcode = '28000';
  end if;
  if p_course_id is null then
    raise exception 'Course is required' using errcode = '22023';
  end if;
  select * into v_course from public.courses c
  where c.id = p_course_id and c.status = 'published' for update;
  if not found then
    raise exception 'Published course not found' using errcode = 'P0002';
  end if;
  if not exists (select 1 from public.enrollments e
    where e.course_id = p_course_id and e.student_id = v_user_id) then
    raise exception 'You must be enrolled in this course' using errcode = '42501';
  end if;
  select p.display_name into v_student_name
  from public.profiles p where p.id = v_user_id;
  if v_student_name is null then
    raise exception 'Student profile not found' using errcode = 'P0002';
  end if;
  select count(*)::integer into v_total_lessons
  from public.lessons l where l.course_id = p_course_id;
  if v_total_lessons = 0 then
    raise exception 'This course has no lessons yet' using errcode = '55000';
  end if;
  select count(*)::integer into v_completed_lessons
  from public.lessons l join public.lesson_progress lp
    on lp.lesson_id = l.id and lp.student_id = v_user_id and lp.completed = true
  where l.course_id = p_course_id;
  if v_completed_lessons <> v_total_lessons then
    raise exception 'Complete every lesson before requesting a certificate (% of % completed)',
      v_completed_lessons, v_total_lessons using errcode = '55000';
  end if;
  select count(*)::integer into v_required_quizzes
  from public.quizzes q where q.course_id = p_course_id;
  select count(*)::integer into v_passed_quizzes
  from public.quizzes q where q.course_id = p_course_id
    and exists (select 1 from public.quiz_attempts a
      where a.quiz_id = q.id and a.student_id = v_user_id and a.passed = true);
  if v_passed_quizzes <> v_required_quizzes then
    raise exception 'Pass every course quiz before requesting a certificate (% of % passed)',
      v_passed_quizzes, v_required_quizzes using errcode = '55000';
  end if;
  insert into private.course_certificates (
    student_id, course_id, certificate_code, completed_lessons,
    total_lessons, required_quizzes, passed_quizzes,
    student_name_snapshot, course_title_snapshot
  ) values (
    v_user_id, p_course_id,
    'WDA-' || upper(encode(gen_random_bytes(16), 'hex')),
    v_completed_lessons, v_total_lessons, v_required_quizzes, v_passed_quizzes,
    v_student_name, v_course.title
  ) on conflict (student_id, course_id) do nothing;
  select * into v_certificate from private.course_certificates cc
  where cc.student_id = v_user_id and cc.course_id = p_course_id;
  return jsonb_build_object(
    'certificate_code', v_certificate.certificate_code,
    'course_title', v_certificate.course_title_snapshot,
    'student_name', v_certificate.student_name_snapshot,
    'issued_at', v_certificate.issued_at,
    'completed_lessons', v_certificate.completed_lessons,
    'total_lessons', v_certificate.total_lessons,
    'passed_quizzes', v_certificate.passed_quizzes,
    'required_quizzes', v_certificate.required_quizzes
  );
end;
$function$;
