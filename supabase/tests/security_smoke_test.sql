-- Supabase security smoke test for Web Design Academy.
-- Run AFTER applying migrations 0001-0026 in the Supabase SQL Editor.
-- Read-only: this script creates no objects and changes no data.
do $audit$
declare
  v_rls_enabled boolean;
  v_definition text;
  v_public_definition text;
  v_bucket_ok boolean;
  v_storage_policy_count integer;
begin
  -- Video storage must remain private and restricted to the supported formats.
  select (
    b.public = false
    and b.file_size_limit = 524288000
    and b.allowed_mime_types @> array['video/mp4', 'video/webm', 'video/quicktime']::text[]
  ) into v_bucket_ok
  from storage.buckets b
  where b.id = 'course-videos';

  if coalesce(v_bucket_ok, false) is not true then
    raise exception 'FAIL: course-videos bucket must be private, limited to 500 MiB, and allow only configured video formats';
  end if;

  select count(*) into v_storage_policy_count
  from pg_policies
  where schemaname = 'storage'
    and tablename = 'objects'
    and policyname in (
      'eligible users read course videos',
      'teachers delete course videos',
      'teachers update course videos',
      'teachers upload course videos'
    );

  if v_storage_policy_count <> 4 then
    raise exception 'FAIL: expected all four scoped course video storage policies';
  end if;

  -- Certificate records must remain protected by RLS and direct table grants.
  select c.relrowsecurity into v_rls_enabled
  from pg_class c
  join pg_namespace n on n.oid = c.relnamespace
  where n.nspname = 'private' and c.relname = 'course_certificates';

  if coalesce(v_rls_enabled, false) is not true then
    raise exception 'FAIL: private.course_certificates must have RLS enabled';
  end if;

  if has_table_privilege('anon', 'private.course_certificates', 'SELECT')
     or has_table_privilege('authenticated', 'private.course_certificates', 'SELECT') then
    raise exception 'FAIL: anon/authenticated must not read private.course_certificates directly';
  end if;

  -- Public RPC surface: students can request their own certificate; anonymous
  -- visitors can only verify a code, never issue or list certificates.
  if not has_function_privilege('authenticated', 'public.issue_course_certificate(uuid)', 'EXECUTE') then
    raise exception 'FAIL: authenticated role must execute issue_course_certificate';
  end if;
  if has_function_privilege('anon', 'public.issue_course_certificate(uuid)', 'EXECUTE') then
    raise exception 'FAIL: anon role must not execute issue_course_certificate';
  end if;
  if not has_function_privilege('authenticated', 'public.get_my_course_certificates()', 'EXECUTE') then
    raise exception 'FAIL: authenticated role must list its own certificates';
  end if;
  if has_function_privilege('anon', 'public.get_my_course_certificates()', 'EXECUTE') then
    raise exception 'FAIL: anon role must not list certificates';
  end if;
  if not has_function_privilege('anon', 'public.verify_course_certificate(text)', 'EXECUTE')
     or not has_function_privilege('authenticated', 'public.verify_course_certificate(text)', 'EXECUTE') then
    raise exception 'FAIL: public certificate verification must be available through the public RPC';
  end if;
  if has_function_privilege('anon', 'private.verify_course_certificate(text)', 'EXECUTE')
     or has_function_privilege('authenticated', 'private.verify_course_certificate(text)', 'EXECUTE') then
    raise exception 'FAIL: private certificate verification implementation must not be directly executable';
  end if;

  select pg_get_functiondef(p.oid) into v_public_definition
  from pg_proc p
  join pg_namespace n on n.oid = p.pronamespace
  where n.nspname = 'public'
    and p.proname = 'verify_course_certificate'
    and p.pronargs = 1;

  if v_public_definition is null
     or position('SECURITY DEFINER' in upper(v_public_definition)) = 0
     or position($needle$SET search_path TO ''$needle$ in v_public_definition) = 0 then
    raise exception 'FAIL: public certificate verification RPC must use SECURITY DEFINER and an empty search_path';
  end if;
  -- Certificate reports are private to the owning teacher or an administrator.
  if not has_function_privilege('authenticated', 'public.get_course_certificate_report(uuid)', 'EXECUTE') then
    raise exception 'FAIL: authenticated role must execute the guarded course certificate report';
  end if;
  if has_function_privilege('anon', 'public.get_course_certificate_report(uuid)', 'EXECUTE') then
    raise exception 'FAIL: anon role must not execute the course certificate report';
  end if;
  if has_function_privilege('anon', 'private.get_course_certificate_report(uuid)', 'EXECUTE')
     or has_function_privilege('authenticated', 'private.get_course_certificate_report(uuid)', 'EXECUTE') then
    raise exception 'FAIL: private certificate report implementation must not be directly executable';
  end if;

  -- Confirm that the installed issuance function uses a 32-hex-character
  -- cryptographically random suffix (122 random bits), rather than the former 12-character UUID suffix.
  select pg_get_functiondef(p.oid) into v_definition
  from pg_proc p
  join pg_namespace n on n.oid = p.pronamespace
  where n.nspname = 'private'
    and p.proname = 'issue_course_certificate'
    and p.pronargs = 1;

  if v_definition is null or position('pg_catalog.gen_random_uuid()' in v_definition) = 0 then
    raise exception 'FAIL: certificate issuance function is missing the 122-bit UUIDv4 code generator';
  end if;

  raise notice 'PASS: private video bucket, storage policies, certificate RLS, direct grants, RPC roles, and 122-bit UUIDv4 code generation';
end;
$audit$;

-- Review output: the following should show RLS enabled and no direct table
-- grants for anon/authenticated.
select
  n.nspname as schema_name,
  c.relname as table_name,
  c.relrowsecurity as rls_enabled,
  has_table_privilege('anon', c.oid, 'SELECT') as anon_can_select,
  has_table_privilege('authenticated', c.oid, 'SELECT') as authenticated_can_select
from pg_class c
join pg_namespace n on n.oid = c.relnamespace
where n.nspname = 'private' and c.relname = 'course_certificates';
