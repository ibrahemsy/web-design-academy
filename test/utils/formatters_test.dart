// Copyright (c) 2026 Ibrahim Zainab. All rights reserved.
// GitHub: https://github.com/ibrahemsy

import 'package:flutter_test/flutter_test.dart';
import 'package:web_design_academy/utils/formatters.dart';

void main() {
  group('csvCell', () {
    test('wraps values in quotes', () {
      expect(csvCell('student'), '"student"');
    });

    test('escapes embedded quotes per CSV rules', () {
      expect(csvCell('A "quote", here'), '"A ""quote"", here"');
    });

    test('handles null and non-string values', () {
      expect(csvCell(null), '""');
      expect(csvCell(42), '"42"');
      expect(csvCell(true), '"true"');
    });
  });

  group('htmlEscapeText', () {
    test('escapes all HTML-sensitive characters', () {
      expect(
        htmlEscapeText('<script title="x">A & B\'s</script>'),
        '&lt;script title=&quot;x&quot;&gt;A &amp; B&#39;s&lt;/script&gt;',
      );
    });

    test('handles null and ordinary text', () {
      expect(htmlEscapeText(null), '');
      expect(htmlEscapeText('دورة تصميم المواقع'), 'دورة تصميم المواقع');
    });
  });
}
