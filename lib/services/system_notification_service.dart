import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/system_notification_model.dart';

class SystemNotificationService {
  SystemNotificationService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Stream<List<SystemNotificationModel>> watchActiveNotifications() {
    return _firestore
        .collection('system_notifications')
        .where('isPublished', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
          final items = snapshot.docs
              .map((doc) => SystemNotificationModel.fromMap(doc.data(), doc.id))
              .where((item) => item.isActive)
              .toList();
          items.sort((left, right) {
            final leftDate = left.updatedAt ?? left.createdAt ?? left.expiresAt;
            final rightDate =
                right.updatedAt ?? right.createdAt ?? right.expiresAt;
            return rightDate.compareTo(leftDate);
          });
          return items;
        });
  }

  Future<List<SystemNotificationModel>> getActiveNotifications() async {
    final snapshot = await _firestore
        .collection('system_notifications')
        .where('isPublished', isEqualTo: true)
        .get();
    final items = snapshot.docs
        .map((doc) => SystemNotificationModel.fromMap(doc.data(), doc.id))
        .where((item) => item.isActive)
        .toList();
    items.sort((left, right) {
      final leftDate = left.updatedAt ?? left.createdAt ?? left.expiresAt;
      final rightDate = right.updatedAt ?? right.createdAt ?? right.expiresAt;
      return rightDate.compareTo(leftDate);
    });
    return items;
  }
}
