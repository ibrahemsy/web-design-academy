// Copyright (c) 2026 Ibrahim Zainab. All rights reserved.
// GitHub: https://github.com/ibrahemsy

import 'package:flutter_test/flutter_test.dart';
import 'package:web_design_academy/utils/progress.dart';

void main() {
  group('buildLessonProgressPayload', () {
    final updatedAt = DateTime.utc(2026, 11, 2, 12, 30);

    test('serializes every database field with a stable timestamp', () {
      expect(buildLessonProgressPayload(
        lessonId: 'lesson-1',
        studentId: 'student-1',
        completed: true,
        watchedSeconds: 125,
        updatedAt: updatedAt,
      ), {
        'lesson_id': 'lesson-1',
        'student_id': 'student-1',
        'completed': true,
        'watched_seconds': 125,
        'updated_at': '2026-11-02T12:30:00.000Z',
      });
    });

    test('normalizes a negative playback position to zero', () {
      final payload = buildLessonProgressPayload(
        lessonId: 'lesson-2',
        studentId: 'student-2',
        completed: false,
        watchedSeconds: -9,
        updatedAt: updatedAt,
      );
      expect(payload['watched_seconds'], 0);
    });

    test('preserves zero position and incomplete state', () {
      final payload = buildLessonProgressPayload(
        lessonId: 'lesson-3',
        studentId: 'student-3',
        completed: false,
        watchedSeconds: 0,
        updatedAt: updatedAt,
      );
      expect(payload['watched_seconds'], 0);
      expect(payload['completed'], isFalse);
    });
  });
}
