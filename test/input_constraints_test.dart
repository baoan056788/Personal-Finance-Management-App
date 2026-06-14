import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_finance_management_app/utils/input_constraints.dart';

TextEditingValue _applyFormatters(
  List<TextInputFormatter> formatters,
  String value,
) {
  var oldValue = const TextEditingValue();
  var newValue = TextEditingValue(
    text: value,
    selection: TextSelection.collapsed(offset: value.length),
  );
  for (final formatter in formatters) {
    newValue = formatter.formatEditUpdate(oldValue, newValue);
    oldValue = newValue;
  }
  return newValue;
}

void main() {
  test('email formatter removes Vietnamese and whitespace characters', () {
    final result = _applyFormatters(
      emailInputFormatters(),
      'tú user@example.com',
    );

    expect(result.text, 'tuser@example.com');
  });

  test('phone formatter keeps only supported phone characters', () {
    final result = _applyFormatters(
      phoneInputFormatters(),
      '+84 (912)-345-678abc',
    );

    expect(result.text, '+84 (912)-345-678');
    expect(validatePhoneNumber(result.text), isNull);
    expect(validatePhoneNumber('12345a'), 'Số điện thoại không hợp lệ');
  });

  test('integer formatter accepts digits only and enforces length', () {
    final result = _applyFormatters(
      integerInputFormatters(maxLength: 3),
      '12a34',
    );

    expect(result.text, '123');
  });

  test('new password formatter follows the supported character set', () {
    final result = _applyFormatters(
      newPasswordInputFormatters(),
      'Abc@123_ Tú',
    );

    expect(result.text, 'Abc@123T');
  });
}
