import 'package:flutter_test/flutter_test.dart';
import 'package:bigstyle_app/utils/currency_format.dart';

void main() {
  group('formatVnd', () {
    test('zero renders as 0đ', () {
      expect(formatVnd(0), '0đ');
    });

    test('thousands get a dot separator', () {
      expect(formatVnd(10000), '10.000đ');
    });

    test('the funnel example 350000 groups correctly', () {
      expect(formatVnd(350000), '350.000đ');
    });

    test('millions get multiple separators', () {
      expect(formatVnd(1234567), '1.234.567đ');
    });

    test('integral double amounts render without decimals', () {
      expect(formatVnd(40000.0), '40.000đ');
    });
  });
}
