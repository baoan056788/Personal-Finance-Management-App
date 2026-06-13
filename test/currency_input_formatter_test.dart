import 'package:flutter_test/flutter_test.dart';
import 'package:personal_finance_management_app/utils/currency_input_formatter.dart';

void main() {
  group('CurrencyInputFormatter', () {
    test('formats digits with Vietnamese thousands separators', () {
      final formatter = CurrencyInputFormatter();

      final result = formatter.formatEditUpdate(
        TextEditingValue.empty,
        const TextEditingValue(text: '100000'),
      );

      expect(result.text, '100.000');
      expect(result.selection.baseOffset, result.text.length);
    });

    test('parses a formatted amount', () {
      expect(parseCurrencyInput('1.250.000'), 1250000);
    });

    test('returns null for an empty amount', () {
      expect(parseCurrencyInput(''), isNull);
    });
  });
}
