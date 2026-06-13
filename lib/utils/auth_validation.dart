final RegExp _emailPattern = RegExp(
  r"^[A-Za-z0-9.!#$%&'*+/=?^_`{|}~-]+@[A-Za-z0-9-]+(?:\.[A-Za-z0-9-]+)+$",
);

String? validateEmailAddress(String? value) {
  final email = value?.trim() ?? '';
  if (email.isEmpty) return 'Vui lòng nhập email';
  if (email.length > 100 || !_emailPattern.hasMatch(email)) {
    return 'Email không hợp lệ';
  }
  return null;
}

String passwordResetErrorMessage(String code) {
  switch (code) {
    case 'invalid-email':
      return 'Email không hợp lệ.';
    case 'network-request-failed':
      return 'Không thể kết nối mạng. Vui lòng kiểm tra kết nối và thử lại.';
    case 'too-many-requests':
      return 'Bạn đã gửi quá nhiều yêu cầu. Vui lòng thử lại sau.';
    case 'user-disabled':
      return 'Tài khoản đã bị vô hiệu hóa. Vui lòng liên hệ hỗ trợ.';
    default:
      return 'Không thể gửi email khôi phục mật khẩu. Vui lòng thử lại.';
  }
}
