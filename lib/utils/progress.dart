// Copyright (c) 2026 Ibrahim Zainab. All rights reserved.
// GitHub: https://github.com/ibrahemsy

/// Builds the stable Supabase payload for a learner's lesson progress.
/// Negative positions are normalized to zero to satisfy the database constraint.
Map<String, dynamic> buildLessonProgressPayload({
  required String lessonId,
  required String studentId,
  required bool completed,
  required int watchedSeconds,
  required DateTime updatedAt,
}) => {
  'lesson_id': lessonId,
  'student_id': studentId,
  'completed': completed,
  'watched_seconds': watchedSeconds < 0 ? 0 : watchedSeconds,
  'updated_at': updatedAt.toIso8601String(),
};
