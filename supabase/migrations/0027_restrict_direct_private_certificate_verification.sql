-- Expose certificate verification only through the guarded public RPC.
create or replace function public.verify_course_certificate(p_certificate_code text)
returns jsonb
language sql
security definer
set search_path = ''
as $function$
  select private.verify_course_certificate(p_certificate_code);
$function$;

revoke all on function private.verify_course_certificate(text)
  from public, anon, authenticated;
revoke all on function public.verify_course_certificate(text)
  from public;
grant execute on function public.verify_course_certificate(text)
  to anon, authenticated;
