-- Add indexes for quiz-related foreign keys.
-- Safe to run repeatedly; indexes support joins and deletion/update checks.
create index if not exists quiz_attempts_quiz_id_idx
  on public.quiz_attempts (quiz_id);

create index if not exists quiz_attempts_student_id_idx
  on public.quiz_attempts (student_id);

create index if not exists quiz_questions_quiz_id_idx
  on public.quiz_questions (quiz_id);

create index if not exists quizzes_course_id_idx
  on public.quizzes (course_id);
