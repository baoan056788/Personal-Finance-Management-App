import 'package:cloud_firestore/cloud_firestore.dart';

String financeErrorMessage(Object error) {
  if (error is FirebaseException) {
    switch (error.code) {
      case 'permission-denied':
        return 'Không thể cập nhật dữ liệu lúc này. Vui lòng đăng nhập lại hoặc thử lại sau khi hệ thống hoàn tất đồng bộ quyền truy cập.';
      case 'unavailable':
        return 'Không thể kết nối đến máy chủ. Vui lòng kiểm tra Internet và thử lại.';
      case 'aborted':
      case 'failed-precondition':
        return 'Dữ liệu vừa thay đổi ở nơi khác. Vui lòng đóng cửa sổ và thực hiện lại.';
      case 'not-found':
        return 'Dữ liệu cần xử lý không còn tồn tại.';
      default:
        return 'Không thể hoàn tất thao tác. Vui lòng thử lại sau.';
    }
  }

  final message = error.toString().replaceFirst('Exception: ', '').trim();
  return message.isEmpty ? 'Không thể hoàn tất thao tác.' : message;
}
