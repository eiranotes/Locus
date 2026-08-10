import 'package:flutter_test/flutter_test.dart';
import 'package:reality_diorama/src/ui/number_format.dart';

void main() {
  test('formats UI counts with stable thousands separators', () {
    expect(formatNumber(0), '0');
    expect(formatNumber(999), '999');
    expect(formatNumber(1000), '1,000');
    expect(formatNumber(1234567), '1,234,567');
    expect(formatNumber(-12000), '-12,000');
  });
}
