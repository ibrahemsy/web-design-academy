-- Private certificate ledger: never expose the table through the Data API.
create table if not exists private.course_certificates (
  id uuid primary key default gen_random_uuid(),
  student_id uuid not null references auth.users(id) on delete restrict,
  course_id uuid not null references public.courses(id) on delete restrict,
  certificate_code text not null unique,
  issued_at timestamptz not null default now(),
  completed_lessons integer not null check (completed_lessons > 0),
  total_lessons integer not null check (total_lessons > 0),
  required_quizzes integer not null check (required_quizzes >= 0),
  passed_quizzes integer not null check (passed_quizzes >= 0),
  constraint course_certificates_student_course_unique unique (student_id, course_id),
  constraint course_certificates_progress_check check (completed_lessons = total_lessons),
  constraint course_certificates_quiz_check check (passed_quizzes = required_quizzes)
);

alter table private.course_certificates enable row level security;
revoke all on table private.course_certificates from public, anon, authenticated, service_role;
create index if not exists course_certificates_course_issued_idx
  on private.course_certificates (course_id, issued_at desc);
create index if not exists course_certificates_student_issued_idx
  on private.course_certificates (student_id, issued_at desc);

create or replace function private.issue_course_certificate(p_course_id uuid)
returns jsonb language plpgsql security definer set search_path = ''
as $function$
declare
  v_user_id uuid := auth.uid();
  v_course public.courses%rowtype;
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
  where c.id = p_course_id and c.status = 'published';
  if not found then
    raise exception 'Published course not found' using errcode = 'P0002';
  end if;
  if not exists (select 1 from public.enrollments e
    where e.course_id = p_course_id and e.student_id = v_user_id) then
    raise exception 'You must be enrolled in this course' using errcode = '42501';
  end if;
  select count(*)::integer into v_total_lessons
  from public.lessons l where l.course_id = p_course_id;
  if v_total_lessons = 0 then
    raise exception 'This course has no lessons yet' using errcode = '55000';
  end if;
  select count(*)::integer into v_completed_lessons
  from public.lessons l
  join public.lesson_progress lp on lp.lesson_id = l.id
    and lp.student_id = v_user_id and lp.completed = true
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
    total_lessons, required_quizzes, passed_quizzes
  ) values (
    v_user_id, p_course_id,
    'WDA-' || upper(substr(replace(gen_random_uuid()::text, '-', ''), 1, 12)),
    v_completed_lessons, v_total_lessons, v_required_quizzes, v_passed_quizzes
  ) on conflict (student_id, course_id) do nothing;
  select * into v_certificate from private.course_certificates cc
  where cc.student_id = v_user_id and cc.course_id = p_course_id;
  return jsonb_build_object(
    'certificate_code', v_certificate.certificate_code,
    'course_title', v_course.title,
    'student_name', (select p.display_name from public.profiles p where p.id = v_user_id),
    'issued_at', v_certificate.issued_at,
    'completed_lessons', v_certificate.completed_lessons,
    'total_lessons', v_certificate.total_lessons,
    'passed_quizzes', v_certificate.passed_quizzes,
    'required_quizzes', v_certificate.required_quizzes
  );
end;
$function$;

create or replace function private.get_my_course_certificates()
returns jsonb language sql security definer set search_path = ''
as $function$
  select coalesce(jsonb_agg(jsonb_build_object(
    'certificate_code', cc.certificate_code,
    'course_title', c.title,
    'issued_at', cc.issued_at,
    'completed_lessons', cc.completed_lessons,
    'total_lessons', cc.total_lessons,
    'passed_quizzes', cc.passed_quizzes,
    'required_quizzes', cc.required_quizzes
  ) order by cc.issued_at desc), '[]'::jsonb)
  from private.course_certificates cc
  join public.courses c on c.id = cc.course_id
  where cc.student_id = auth.uid() and auth.uid() is not null;
$function$;

create or replace function private.verify_course_certificate(p_certificate_code text)
returns jsonb language sql security definer set search_path = ''
as $function$
  select case when cc.id is null then jsonb_build_object('valid', false)
    else jsonb_build_object(
      'valid', true, 'certificate_code', cc.certificate_code,
      'student_name', p.display_name, 'course_title', c.title,
      'issued_at', cc.issued_at
    ) end
  from (select upper(trim(coalesce(p_certificate_code, ''))) as code) input
  left join private.course_certificates cc on cc.certificate_code = input.code
  left join public.profiles p on p.id = cc.student_id
  left join public.courses c on c.id = cc.course_id;
$function$;

create or replace function public.issue_course_certificate(p_course_id uuid)
returns jsonb language sql set search_path = ''
as $function$ select private.issue_course_certificate(p_course_id); $function$;
create or replace function public.get_my_course_certificates()
returns jsonb language sql set search_path = ''
as $function$ select private.get_my_course_certificates(); $function$;
create or replace function public.verify_course_certificate(p_certificate_code text)
returns jsonb language sql set search_path = ''
as $function$ select private.verify_course_certificate(p_certificate_code); $function$;

revoke all on function private.issue_course_certificate(uuid) from public, anon, authenticated;
revoke all on function private.get_my_course_certificates() from public, anon, authenticated;
revoke all on function private.verify_course_certificate(text) from public, anon, authenticated;
grant execute on function private.issue_course_certificate(uuid) to authenticated;
grant execute on function private.get_my_course_certificates() to authenticated;
grant execute on function private.verify_course_certificate(text) to anon, authenticated;
revoke all on function public.issue_course_certificate(uuid) from public, anon;
revoke all on function public.get_my_course_certificates() from public, anon;
revoke all on function public.verify_course_certificate(text) from public;
grant execute on function public.issue_course_certificate(uuid) to authenticated;
grant execute on function public.get_my_course_certificates() to authenticated;
grant execute on function public.verify_course_certificate(text) to anon, authenticated;
