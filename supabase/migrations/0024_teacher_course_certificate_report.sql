create or replace function private.get_course_certificate_report(p_course_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_user_id uuid := auth.uid();
  v_report jsonb;
begin
  if v_user_id is null then
    raise exception 'Authentication required' using errcode = '28000';
  end if;

  if not exists (
    select 1
    from public.courses c
    where c.id = p_course_id
      and (c.teacher_id = v_user_id or private.is_admin())
  ) then
    raise exception 'Not allowed to view certificates for this course'
      using errcode = '42501';
  end if;

  select coalesce(jsonb_agg(jsonb_build_object(
    'student_name', coalesce(nullif(p.display_name, ''), 'طالب'),
    'enrolled_at', e.enrolled_at,
    'certificate_issued', cc.id is not null,
    'certificate_code', cc.certificate_code,
    'issued_at', cc.issued_at
  ) order by e.enrolled_at desc), '[]'::jsonb)
  into v_report
  from public.enrollments e
  join public.profiles p on p.id = e.student_id
  left join private.course_certificates cc
    on cc.student_id = e.student_id
   and cc.course_id = e.course_id
  where e.course_id = p_course_id;

  return v_report;
end;
$function$;

create or replace function public.get_course_certificate_report(p_course_id uuid)
returns jsonb
language sql
set search_path = ''
as $function$
  select private.get_course_certificate_report(p_course_id);
$function$;

revoke all on function private.get_course_certificate_report(uuid)
  from public, anon, authenticated;
grant execute on function private.get_course_certificate_report(uuid)
  to authenticated;
revoke all on function public.get_course_certificate_report(uuid)
  from public, anon;
grant execute on function public.get_course_certificate_report(uuid)
  to authenticated;
