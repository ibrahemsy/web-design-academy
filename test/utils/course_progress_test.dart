import 'package:flutter_test/flutter_test.dart';
import 'package:web_design_academy/utils/course_progress.dart';

void main() {
  group('calculateCourseProgress', () {
    test('returns zero when a course has no lessons', () {
      expect(calculateCourseProgress(completedLessons: 0, totalLessons: 0), 0);
    });

    test('returns zero when no lesson is complete', () {
      expect(calculateCourseProgress(completedLessons: 0, totalLessons: 8), 0);
    });

    test('calculates a fractional completion ratio', () {
      expect(calculateCourseProgress(completedLessons: 3, totalLessons: 8), 0.375);
    });

    test('clamps inconsistent completed counts to one', () {
      expect(calculateCourseProgress(completedLessons: 12, totalLessons: 8), 1);
    });

    test('treats negative counts as zero progress', () {
      expect(calculateCourseProgress(completedLessons: -2, totalLessons: 8), 0);
      expect(calculateCourseProgress(completedLessons: 2, totalLessons: -8), 0);
    });
  });
}
