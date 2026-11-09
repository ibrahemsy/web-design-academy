// Copyright (c) 2026 Ibrahim Zainab. All rights reserved.
// GitHub: https://github.com/ibrahemsy

import 'package:flutter_test/flutter_test.dart';
import 'package:web_design_academy/utils/roles.dart';

void main() {
  group('academy roles', () {
    test('accepts only the three supported roles', () {
      expect(isSupportedAcademyRole('student'), isTrue);
      expect(isSupportedAcademyRole('teacher'), isTrue);
      expect(isSupportedAcademyRole('admin'), isTrue);
      expect(isSupportedAcademyRole('owner'), isFalse);
      expect(isSupportedAcademyRole(null), isFalse);
      expect(isSupportedAcademyRole(1), isFalse);
    });

    test('only teachers and admins can manage courses', () {
      expect(canManageAcademyCourses('teacher'), isTrue);
      expect(canManageAcademyCourses('admin'), isTrue);
      expect(canManageAcademyCourses('student'), isFalse);
      expect(canManageAcademyCourses(null), isFalse);
    });
  });
}
