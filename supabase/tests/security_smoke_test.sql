-- Supabase security smoke test for Web Design Academy.
-- Run AFTER applying migrations 0001-0029 in the Supabase SQL Editor.
-- Read-only: this script creates no objects and changes no data.
do $audit$
declare
  v_rls_enabled boolean;
  v_definition text;
  v_public_definition text;
  v_report_definition text;
  v_bucket_ok boolean;
  v_storage_policy_count integer;
  v_role_policy_count integer;
  v_role_guard_count integer;
  v_role_guard_definition text;
  v_default_acl_count integer;
begin
  -- Video storage must remain private and restricted to the supported formats.
  select (
    b.public = false
    and b.file_size_limit = 524288000
    and b.allowed_mime_types = array['video/mp4', 'video/webm', 'video/quicktime']::text[]
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

  -- Critical role/profile/progress policies must remain installed.
  select count(*) into v_role_policy_count
  from pg_policies
  where (schemaname = 'public' and (
      (tablename = 'profiles' and policyname in ('profiles visible to self and admins', 'profile update self'))
      or (tablename = 'courses' and policyname = 'published courses visible')
      or (tablename = 'lesson_progress' and policyname = 'students manage own progress')
    ))
    or (schemaname = 'storage' and tablename = 'objects'
      and policyname in ('eligible users read course videos', 'teachers upload course videos'));

  if v_role_policy_count <> 6 then
    raise exception 'FAIL: expected profile, published-course, own-progress, and scoped video policies';
  end if;

  select count(*) into v_role_guard_count
  from pg_trigger t
  join pg_class c on c.oid = t.tgrelid
  join pg_namespace n on n.oid = c.relnamespace
  where n.nspname = 'public'
    and c.relname = 'profiles'
    and t.tgname = 'profiles_role_guard'
    and not t.tgisinternal;

  if v_role_guard_count <> 1 then
    raise exception 'FAIL: profile role changes must be protected by the role guard trigger';
  end if;

  select pg_get_functiondef(p.oid) into v_role_guard_definition
  from pg_proc p
  join pg_namespace n on n.oid = p.pronamespace
  where n.nspname = 'public' and p.proname = 'guard_profile_role' and p.pronargs = 0;

  if v_role_guard_definition is null
     or position('SECURITY DEFINER' in upper(v_role_guard_definition)) = 0
     or position($needle$SET search_path TO ''$needle$ in v_role_guard_definition) = 0 then
    raise exception 'FAIL: profile role guard must be SECURITY DEFINER with an empty search_path';
  end if;

  -- Anonymous users must not receive table-write or truncate privileges.
  if has_table_privilege('anon', 'public.courses', 'INSERT')
     or has_table_privilege('anon', 'public.courses', 'UPDATE')
     or has_table_privilege('anon', 'public.courses', 'DELETE')
     or has_table_privilege('anon', 'public.courses', 'TRUNCATE')
     or has_table_privilege('anon', 'public.profiles', 'SELECT') then
    raise exception 'FAIL: anon must not write public tables or read private profiles';
  end if;

  if not has_table_privilege('anon', 'public.courses', 'SELECT') then
    raise exception 'FAIL: anon must retain the published course catalogue read grant';
  end if;

  -- Authenticated users must not bypass server-side quiz grading or truncate data.
  if has_table_privilege('authenticated', 'public.quiz_attempts', 'INSERT')
     or has_table_privilege('authenticated', 'public.quiz_attempts', 'UPDATE')
     or has_table_privilege('authenticated', 'public.quiz_attempts', 'DELETE')
     or has_table_privilege('authenticated', 'public.quiz_attempts', 'TRUNCATE')
     or has_table_privilege('authenticated', 'public.profiles', 'DELETE')
     or has_table_privilege('authenticated', 'public.profiles', 'INSERT') then
    raise exception 'FAIL: authenticated direct table grants exceed the academy application access model';
  end if;

  if not has_table_privilege('authenticated', 'public.lesson_progress', 'INSERT')
     or not has_table_privilege('authenticated', 'public.lesson_progress', 'UPDATE')
     or not has_table_privilege('authenticated', 'public.enrollments', 'INSERT')
     or not has_table_privilege('authenticated', 'public.courses', 'INSERT') then
    raise exception 'FAIL: authenticated users are missing required app table grants';
  end if;

  if has_function_privilege('anon', 'public.set_updated_at()', 'EXECUTE')
     or has_function_privilege('authenticated', 'public.set_updated_at()', 'EXECUTE') then
    raise exception 'FAIL: trigger-only set_updated_at function must not be directly executable';
  end if;

  -- Future public objects must not inherit API grants from the postgres owner.
  select count(*) into v_default_acl_count
  from pg_default_acl d
  join pg_namespace n on n.oid = d.defaclnamespace
  cross join lateral aclexplode(d.defaclacl) acl
  where d.defaclrole = 'postgres'::regrole
    and n.nspname = 'public'
    and (
      acl.grantee in (
        'anon'::regrole::oid,
        'authenticated'::regrole::oid,
        'service_role'::regrole::oid
      )
      or (d.defaclobjtype = 'f' and acl.grantee = 0 and acl.privilege_type = 'EXECUTE')
    );

  if v_default_acl_count <> 0 then
    raise exception 'FAIL: postgres default privileges still expose new public objects to API roles or PUBLIC';
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

  select pg_get_functiondef(p.oid) into v_report_definition
  from pg_proc p
  join pg_namespace n on n.oid = p.pronamespace
  where n.nspname = 'public'
    and p.proname = 'get_course_certificate_report'
    and p.pronargs = 1;

  if v_report_definition is null
     or position('SECURITY DEFINER' in upper(v_report_definition)) = 0
     or position($needle$SET search_path TO ''$needle$ in v_report_definition) = 0 then
    raise exception 'FAIL: public certificate report RPC must use SECURITY DEFINER and an empty search_path';
  end if;

  -- Confirm that the installed issuance function uses a 32-hex-character
  -- cryptographically random suffix (122 random bits), rather than the former 12-character UUID suffix.
  select pg_get_functiondef(p.oid) into v_definition
  from pg_proc p
  join pg_namespace n on n.oid = p.pronamespace
  where n.nspname = 'private'
    and p.proname = 'issue_course_certificate'
    and p.pronargs = 1;

  if v_definition is null
     or position('pg_catalog.gen_random_uuid()' in v_definition) = 0
     or position('substr(replace(pg_catalog.gen_random_uuid()::text, ''-'', ''''), 1, 32)' in v_definition) = 0 then
    raise exception 'FAIL: certificate issuance function must use a 32-hex-character UUIDv4 suffix (122 random bits)';
  end if;

  raise notice 'PASS: private video bucket, least-privilege Data API grants, locked-down future defaults, role/profile/progress policies, role guard, certificate RLS, RPC roles, hardened public wrappers, and 122-bit UUIDv4 code generation';
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
