import 'package:flutter/services.dart';

List<TextInputFormatter> emailInputFormatters({int maxLength = 100}) => [
  FilteringTextInputFormatter.allow(
    RegExp(r"[A-Za-z0-9.!#$%&'*+/=?^_`{|}~@-]"),
  ),
  LengthLimitingTextInputFormatter(maxLength),
];

List<TextInputFormatter> phoneInputFormatters({int maxLength = 20}) => [
  FilteringTextInputFormatter.allow(RegExp(r'[0-9+()\- ]')),
  LengthLimitingTextInputFormatter(maxLength),
];

List<TextInputFormatter> integerInputFormatters({int? maxLength}) => [
  FilteringTextInputFormatter.digitsOnly,
  if (maxLength != null) LengthLimitingTextInputFormatter(maxLength),
];

List<TextInputFormatter> newPasswordInputFormatters() => [
  FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9@]')),
  LengthLimitingTextInputFormatter(32),
];

String? validatePhoneNumber(String? value) {
  final phone = value?.trim() ?? '';
  if (!RegExp(r'^\+?[0-9()\- ]+$').hasMatch(phone)) {
    return 'Số điện thoại không hợp lệ';
  }
  final digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
  if (digits.length < 5 || digits.length > 15) {
    return 'Số điện thoại không hợp lệ';
  }
  return null;
}
