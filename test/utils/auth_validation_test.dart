import 'package:flutter_test/flutter_test.dart';
import 'package:web_design_academy/utils/auth_validation.dart';

void main() {
  group('isValidPasswordPair', () {
    test('accepts matching passwords with the minimum supported length', () {
      expect(isValidPasswordPair('123456', '123456'), isTrue);
      expect(isValidPasswordPair('longer-secure-pass', 'longer-secure-pass'), isTrue);
    });

    test('rejects passwords shorter than six characters', () {
      expect(isValidPasswordPair('12345', '12345'), isFalse);
    });

    test('rejects mismatched confirmation', () {
      expect(isValidPasswordPair('123456', '654321'), isFalse);
    });

    test('does not trim or silently alter password input', () {
      expect(isValidPasswordPair(' 123456', '123456'), isFalse);
    });
  });
}
