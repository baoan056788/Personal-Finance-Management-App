import 'package:flutter_test/flutter_test.dart';
import 'package:personal_finance_management_app/utils/auth_validation.dart';

void main() {
  group('validateEmailAddress', () {
    test('accepts a valid email', () {
      expect(validateEmailAddress('baoan@example.com'), isNull);
    });

    test('rejects an incomplete email', () {
      expect(validateEmailAddress('baoan@'), 'Email không hợp lệ');
    });

    test('rejects an empty email', () {
      expect(validateEmailAddress('  '), 'Vui lòng nhập email');
    });

    test('rejects Vietnamese and other non-ASCII email characters', () {
      expect(validateEmailAddress('tú@example.com'), 'Email không hợp lệ');
    });
  });

  group('passwordResetErrorMessage', () {
    test('maps Firebase throttling errors', () {
      expect(
        passwordResetErrorMessage('too-many-requests'),
        contains('quá nhiều yêu cầu'),
      );
    });

    test('uses a safe fallback for unknown errors', () {
      expect(
        passwordResetErrorMessage('unknown'),
        'Không thể gửi email khôi phục mật khẩu. Vui lòng thử lại.',
      );
    });
  });
}
