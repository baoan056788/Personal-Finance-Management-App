import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class CurrencyInputFormatter extends TextInputFormatter {
  CurrencyInputFormatter({this.maxDigits = 15})
    : _formatter = NumberFormat.decimalPattern('vi_VN');

  final NumberFormat _formatter;
  final int maxDigits;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) {
      return const TextEditingValue();
    }
    if (digits.length > maxDigits) return oldValue;

    final normalized = digits.replaceFirst(RegExp(r'^0+(?=\d)'), '');
    final amount = int.tryParse(normalized);
    if (amount == null) return oldValue;

    final formatted = _formatter.format(amount);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

String formatCurrencyInput(num value) {
  return NumberFormat.decimalPattern('vi_VN').format(value);
}

double? parseCurrencyInput(String value) {
  final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
  return digits.isEmpty ? null : double.tryParse(digits);
}
