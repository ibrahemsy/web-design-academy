// Copyright (c) 2026 Ibrahim Zainab. All rights reserved.
// GitHub: https://github.com/ibrahemsy

/// Calculates a safe course completion ratio from lesson counts.
/// Empty courses have no progress; inconsistent counts are clamped to [0, 1].
double calculateCourseProgress({
  required int completedLessons,
  required int totalLessons,
}) {
  if (totalLessons <= 0 || completedLessons <= 0) return 0;
  return (completedLessons / totalLessons).clamp(0.0, 1.0).toDouble();
}
