-- Keep the implementation callable only through the guarded public RPC wrapper.
revoke all on function private.get_course_certificate_report(uuid)
  from public, anon, authenticated;
