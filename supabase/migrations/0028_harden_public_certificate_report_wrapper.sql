-- Keep the private report implementation inaccessible to client roles.
-- The public wrapper runs as its owner, while the private implementation
-- independently verifies auth.uid() and course ownership/admin status.
create or replace function public.get_course_certificate_report(p_course_id uuid)
returns jsonb
language sql
security definer
set search_path = ''
as $function$
  select private.get_course_certificate_report(p_course_id);
$function$;

revoke all on function public.get_course_certificate_report(uuid)
  from public;
grant execute on function public.get_course_certificate_report(uuid)
  to authenticated;
