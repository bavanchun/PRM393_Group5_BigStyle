import 'package:bigstyle_app/utils/validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('validateEmail', () {
    test('accepts ordinary and country-tld addresses', () {
      expect(validateEmail('x@y.vn'), isNull);
      expect(validateEmail('user@example.com'), isNull);
    });

    test('accepts +alias addresses (team test accounts)', () {
      expect(validateEmail('hoangbavan4478+admin@gmail.com'), isNull);
      expect(validateEmail('hoangbavan4478+manager@gmail.com'), isNull);
    });

    test('trims surrounding whitespace before validating', () {
      expect(validateEmail('  user@example.com  '), isNull);
    });

    test('rejects empty or null', () {
      expect(validateEmail(null), 'Vui lòng nhập email');
      expect(validateEmail(''), 'Vui lòng nhập email');
      expect(validateEmail('   '), 'Vui lòng nhập email');
    });

    test('rejects malformed addresses', () {
      expect(validateEmail('a@'), 'Email không hợp lệ');
      expect(validateEmail('@b'), 'Email không hợp lệ');
      expect(validateEmail('a b@c.d'), 'Email không hợp lệ');
      expect(validateEmail('not-an-email'), 'Email không hợp lệ');
      expect(validateEmail('user@nodot'), 'Email không hợp lệ');
    });
  });
}
