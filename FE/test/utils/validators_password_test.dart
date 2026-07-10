import 'package:bigstyle_app/utils/validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('validatePassword', () {
    test('rejects empty', () {
      expect(validatePassword(''), isNotNull);
      expect(validatePassword(null), isNotNull);
    });

    test('rejects fewer than 6 characters', () {
      expect(validatePassword('12345'), isNotNull);
    });

    test('accepts 6 or more characters', () {
      expect(validatePassword('123456'), isNull);
      expect(validatePassword('a-long-password'), isNull);
    });
  });
}
