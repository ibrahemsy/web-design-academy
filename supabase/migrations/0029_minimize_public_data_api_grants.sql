-- Harden current Data API grants and future defaults in the public schema.
-- RLS remains enabled; grants are reduced to the operations used by the app.
-- Existing public RPC grants and the private certificate schema are unchanged.

-- Anonymous visitors only need the published course catalogue read path.
revoke all privileges on all tables in schema public from anon;
grant select on public.courses, public.lessons to anon;

-- Remove broad default table privileges (including TRUNCATE/REFERENCES/TRIGGER)
-- before granting each authenticated table only the operations the app uses.
revoke all privileges on all tables in schema public from authenticated;

grant select, update on public.profiles to authenticated;
grant select, insert, update, delete on
  public.courses,
  public.lessons,
  public.quizzes,
  public.quiz_questions
to authenticated;
grant select, insert, delete on public.enrollments to authenticated;
grant select, insert, update on public.lesson_progress to authenticated;
grant select on public.quiz_attempts to authenticated;

-- Trigger functions are not Data API endpoints and must not be directly callable.
revoke all privileges on function public.set_updated_at() from public, anon, authenticated, service_role;

-- New objects created by the postgres migration owner must not become API
-- endpoints or writable tables merely because they were created in public.
alter default privileges for role postgres in schema public
  revoke all on tables from anon, authenticated, service_role;
alter default privileges for role postgres in schema public
  revoke execute on functions from public, anon, authenticated, service_role;
alter default privileges for role postgres in schema public
  revoke all on sequences from anon, authenticated, service_role;
