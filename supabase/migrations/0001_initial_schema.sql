-- Web Design Academy: initial Supabase schema
-- Run this file in Supabase SQL Editor or with the Supabase CLI.

create extension if not exists pgcrypto;

create type public.user_role as enum ('student', 'teacher', 'admin');
create type public.course_status as enum ('draft', 'published', 'archived');

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text not null default '',
  avatar_url text,
  role public.user_role not null default 'student',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.courses (
  id uuid primary key default gen_random_uuid(),
  teacher_id uuid not null references public.profiles(id) on delete restrict,
  title text not null check (char_length(title) between 3 and 160),
  description text not null default '',
  cover_url text,
  level text not null default 'beginner' check (level in ('beginner','intermediate','advanced')),
  status public.course_status not null default 'draft',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.lessons (
  id uuid primary key default gen_random_uuid(),
  course_id uuid not null references public.courses(id) on delete cascade,
  title text not null check (char_length(title) between 2 and 160),
  description text not null default '',
  video_path text,
  position integer not null default 0,
  is_preview boolean not null default false,
  created_at timestamptz not null default now(),
  unique(course_id, position)
);

create table public.enrollments (
  id uuid primary key default gen_random_uuid(),
  course_id uuid not null references public.courses(id) on delete cascade,
  student_id uuid not null references public.profiles(id) on delete cascade,
  enrolled_at timestamptz not null default now(),
  unique(course_id, student_id)
);

create table public.lesson_progress (
  id uuid primary key default gen_random_uuid(),
  lesson_id uuid not null references public.lessons(id) on delete cascade,
  student_id uuid not null references public.profiles(id) on delete cascade,
  completed boolean not null default false,
  watched_seconds integer not null default 0 check (watched_seconds >= 0),
  updated_at timestamptz not null default now(),
  unique(lesson_id, student_id)
);

create table public.quizzes (
  id uuid primary key default gen_random_uuid(),
  course_id uuid not null references public.courses(id) on delete cascade,
  title text not null,
  created_at timestamptz not null default now()
);

create table public.quiz_questions (
  id uuid primary key default gen_random_uuid(),
  quiz_id uuid not null references public.quizzes(id) on delete cascade,
  prompt text not null,
  options jsonb not null default '[]'::jsonb,
  -- Correct answers should not be exposed to students in a client-readable table.
  correct_option integer not null check (correct_option >= 0),
  position integer not null default 0
);

create table public.quiz_attempts (
  id uuid primary key default gen_random_uuid(),
  quiz_id uuid not null references public.quizzes(id) on delete cascade,
  student_id uuid not null references public.profiles(id) on delete cascade,
  answers jsonb not null default '{}'::jsonb,
  score numeric(5,2),
  submitted_at timestamptz not null default now()
);

create index courses_teacher_idx on public.courses(teacher_id);
create index courses_status_idx on public.courses(status);
create index lessons_course_idx on public.lessons(course_id, position);
create index enrollments_student_idx on public.enrollments(student_id);
create index progress_student_idx on public.lesson_progress(student_id);

-- Create a profile for each newly registered Auth user. Role is always student.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.profiles (id, display_name, role)
  values (
    new.id,
    coalesce(new.raw_user_meta_data ->> 'display_name', ''),
    'student'::public.user_role
  );
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- Keep updated_at current.
create or replace function public.set_updated_at()
returns trigger language plpgsql set search_path = ''
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger profiles_updated_at before update on public.profiles
for each row execute procedure public.set_updated_at();
create trigger courses_updated_at before update on public.courses
for each row execute procedure public.set_updated_at();

-- A user cannot promote themselves by editing their profile.
create or replace function public.guard_profile_role()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare caller_role public.user_role;
begin
  if new.role is distinct from old.role then
    select p.role into caller_role
    from public.profiles p where p.id = auth.uid();

    -- Permit project-owner SQL Editor bootstrap when no end-user JWT is present.
    -- Normal client requests always require an authenticated admin profile.
    if auth.uid() is not null and caller_role is distinct from 'admin'::public.user_role then
      raise exception 'Only an administrator can change account roles';
    elsif auth.uid() is null and current_user not in ('postgres', 'supabase_admin') then
      raise exception 'Role changes require an administrator';
    end if;
  end if;
  return new;
end;
$$;

create trigger profiles_role_guard before update of role on public.profiles
for each row execute procedure public.guard_profile_role();

alter table public.profiles enable row level security;
alter table public.courses enable row level security;
alter table public.lessons enable row level security;
alter table public.enrollments enable row level security;
alter table public.lesson_progress enable row level security;
alter table public.quizzes enable row level security;
alter table public.quiz_questions enable row level security;
alter table public.quiz_attempts enable row level security;

-- SECURITY DEFINER helpers avoid recursive profile-table RLS checks in policies.
create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = ''
as $
  select exists (
    select 1 from public.profiles p
    where p.id = auth.uid() and p.role = 'admin'::public.user_role
  );
$;

create or replace function public.is_teacher_or_admin()
returns boolean
language sql
stable
security definer
set search_path = ''
as $
  select exists (
    select 1 from public.profiles p
    where p.id = auth.uid()
      and p.role in ('teacher'::public.user_role, 'admin'::public.user_role)
  );
$;

-- Profiles: users can read their own profile; teachers/admins can see enrolled learners
-- through application-specific reporting added in a later migration.
create policy "profile read self" on public.profiles
for select to authenticated using (id = auth.uid());
create policy "admins read all profiles" on public.profiles
for select to authenticated using (public.is_admin());
create policy "profile update self" on public.profiles
for update to authenticated using (id = auth.uid()) with check (id = auth.uid());

-- Published courses are discoverable. Owners and admins can manage courses.
create policy "published courses visible" on public.courses
for select to anon, authenticated
using (status = 'published' or teacher_id = auth.uid()
  or public.is_admin());
create policy "teachers create own courses" on public.courses
for insert to authenticated
with check (teacher_id = auth.uid() and public.is_teacher_or_admin());
create policy "teachers update own courses" on public.courses
for update to authenticated
using (teacher_id = auth.uid() or exists (
  select 1 from public.profiles p where p.id = auth.uid() and p.role = 'admin'
))
with check (teacher_id = auth.uid() or exists (
  select 1 from public.profiles p where p.id = auth.uid() and p.role = 'admin'
));
create policy "teachers delete own courses" on public.courses
for delete to authenticated
using (teacher_id = auth.uid() or exists (
  select 1 from public.profiles p where p.id = auth.uid() and p.role = 'admin'
));

-- Lessons: published course lessons are visible to enrolled learners; preview lessons are public.
create policy "lessons visible to eligible users" on public.lessons
for select to anon, authenticated
using (
  is_preview
  or exists (select 1 from public.courses c where c.id = course_id and c.status = 'published')
  and (
    exists (select 1 from public.courses c where c.id = course_id and c.teacher_id = auth.uid())
    or exists (select 1 from public.enrollments e where e.course_id = course_id and e.student_id = auth.uid())
    or public.is_admin()
  )
);
create policy "course teachers manage lessons" on public.lessons
for all to authenticated
using (exists (select 1 from public.courses c where c.id = course_id and
  (c.teacher_id = auth.uid() or public.is_admin())))
with check (exists (select 1 from public.courses c where c.id = course_id and
  (c.teacher_id = auth.uid() or public.is_admin())));

-- Students can enroll themselves in published courses. Teachers/admins can inspect course enrollments.
create policy "enrollments read self or course owner" on public.enrollments
for select to authenticated
using (student_id = auth.uid() or exists (
  select 1 from public.courses c where c.id = course_id and c.teacher_id = auth.uid()
) or public.is_admin());
create policy "students enroll themselves" on public.enrollments
for insert to authenticated
with check (student_id = auth.uid() and exists (
  select 1 from public.courses c where c.id = course_id and c.status = 'published'
));
create policy "students withdraw own enrollment" on public.enrollments
for delete to authenticated using (student_id = auth.uid());

create policy "students manage own progress" on public.lesson_progress
for all to authenticated
using (student_id = auth.uid())
with check (student_id = auth.uid() and exists (
  select 1 from public.lessons l join public.enrollments e on e.course_id = l.course_id
  where l.id = lesson_id and e.student_id = auth.uid()
));

create policy "quizzes visible for published enrolled courses" on public.quizzes
for select to authenticated
using (exists (select 1 from public.courses c where c.id = course_id and
  (c.teacher_id = auth.uid() or exists (select 1 from public.enrollments e where e.course_id = c.id and e.student_id = auth.uid())
   or public.is_admin())));
create policy "course teachers manage quizzes" on public.quizzes
for all to authenticated
using (exists (select 1 from public.courses c where c.id = course_id and
  (c.teacher_id = auth.uid() or public.is_admin())))
with check (exists (select 1 from public.courses c where c.id = course_id and
  (c.teacher_id = auth.uid() or public.is_admin())));

-- Do not expose correct answers to student clients. A later API/RPC can grade attempts.
create policy "quiz questions visible to course teachers" on public.quiz_questions
for select to authenticated
using (exists (select 1 from public.quizzes q join public.courses c on c.id = q.course_id
  where q.id = quiz_id and (c.teacher_id = auth.uid()
    or public.is_admin())));
create policy "quiz questions managed by course teachers" on public.quiz_questions
for all to authenticated
using (exists (select 1 from public.quizzes q join public.courses c on c.id = q.course_id
  where q.id = quiz_id and (c.teacher_id = auth.uid()
    or public.is_admin())))
with check (exists (select 1 from public.quizzes q join public.courses c on c.id = q.course_id
  where q.id = quiz_id and (c.teacher_id = auth.uid()
    or public.is_admin())));

create policy "students read own quiz attempts" on public.quiz_attempts
for select to authenticated using (student_id = auth.uid());
create policy "students submit own quiz attempts" on public.quiz_attempts
for insert to authenticated with check (student_id = auth.uid());

-- Private video bucket. Store objects under: <course_uuid>/<filename>.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('course-videos', 'course-videos', false, 524288000,
  array['video/mp4','video/webm','video/quicktime'])
on conflict (id) do update set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

create policy "enrolled students and course owners read videos"
on storage.objects for select to authenticated
using (
  bucket_id = 'course-videos' and (
    exists (
      select 1 from public.courses c
      where c.id::text = (storage.foldername(name))[1]
      and c.teacher_id = auth.uid()
    )
    or exists (
      select 1 from public.enrollments e
      where e.course_id::text = (storage.foldername(name))[1]
      and e.student_id = auth.uid()
    )
    or public.is_admin()
  )
);

create policy "teachers upload course videos"
on storage.objects for insert to authenticated
with check (
  bucket_id = 'course-videos' and exists (
    select 1 from public.courses c
    where c.id::text = (storage.foldername(name))[1]
      and c.teacher_id = auth.uid()
      and c.status <> 'archived'
  )
);

create policy "teachers update course videos"
on storage.objects for update to authenticated
using (bucket_id = 'course-videos' and exists (
  select 1 from public.courses c
  where c.id::text = (storage.foldername(name))[1] and c.teacher_id = auth.uid()
))
with check (bucket_id = 'course-videos' and exists (
  select 1 from public.courses c
  where c.id::text = (storage.foldername(name))[1] and c.teacher_id = auth.uid()
));

create policy "teachers delete course videos"
on storage.objects for delete to authenticated
using (bucket_id = 'course-videos' and exists (
  select 1 from public.courses c
  where c.id::text = (storage.foldername(name))[1] and c.teacher_id = auth.uid()
));

-- Bootstrap the first administrator manually after registering an account:
-- update public.profiles set role = 'admin' where id = '<AUTH_USER_UUID>';
-- Run that statement only in the Supabase SQL Editor as the project owner.
