-- Support per-student attempt-limit checks and ordered student history queries.
create index if not exists quiz_attempts_quiz_student_idx
  on public.quiz_attempts (quiz_id, student_id);

create index if not exists quiz_attempts_student_submitted_at_idx
  on public.quiz_attempts (student_id, submitted_at desc);
