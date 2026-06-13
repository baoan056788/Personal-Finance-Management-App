import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/app_config_model.dart';
import '../models/admin_dashboard_model.dart';
import '../models/admin_user_model.dart';
import '../models/system_default_category_model.dart';
import '../models/system_notification_model.dart';

class AdminService {
  AdminService({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  String? get currentUid => _auth.currentUser?.uid;

  Future<List<AdminUserModel>> listUsers({String query = ''}) async {
    final snapshot = await _firestore.collection('users').get();
    final normalizedQuery = query.trim().toLowerCase();
    final users = snapshot.docs
        .map((doc) => AdminUserModel.fromMap({...doc.data(), 'uid': doc.id}))
        .where((user) {
          if (normalizedQuery.isEmpty) return true;
          return user.fullName.toLowerCase().contains(normalizedQuery) ||
              user.email.toLowerCase().contains(normalizedQuery);
        })
        .toList();

    users.sort((left, right) {
      final leftDate = left.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final rightDate =
          right.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return rightDate.compareTo(leftDate);
    });
    return users;
  }

  Future<AdminDashboardModel> getDashboard() async {
    final snapshot = await _firestore.collection('users').get();
    final users = snapshot.docs
        .map((doc) => AdminUserModel.fromMap({...doc.data(), 'uid': doc.id}))
        .toList();
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month);
    final activeThreshold = now.subtract(const Duration(days: 30));

    return AdminDashboardModel(
      totalUsers: users.length,
      activeUsers: users
          .where(
            (user) =>
                user.lastSignInAt != null &&
                !user.lastSignInAt!.isBefore(activeThreshold),
          )
          .length,
      newUsersThisMonth: users
          .where(
            (user) =>
                user.createdAt != null && !user.createdAt!.isBefore(monthStart),
          )
          .length,
      registrations: _buildRegistrationSeries(users, now),
    );
  }

  List<MonthlyRegistrationModel> _buildRegistrationSeries(
    List<AdminUserModel> users,
    DateTime now,
  ) {
    final months = <DateTime>[
      for (var offset = 5; offset >= 0; offset--)
        DateTime(now.year, now.month - offset),
    ];

    return months.map((month) {
      final count = users.where((user) {
        final createdAt = user.createdAt;
        return createdAt != null &&
            createdAt.year == month.year &&
            createdAt.month == month.month;
      }).length;
      return MonthlyRegistrationModel(
        key: '${month.year}-${month.month.toString().padLeft(2, '0')}',
        label: 'T${month.month}',
        count: count,
      );
    }).toList();
  }

  Stream<List<SystemDefaultCategoryModel>> watchDefaultCategories() {
    return _firestore
        .collection('default_categories')
        .orderBy('order')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => SystemDefaultCategoryModel.fromMap(doc.data(), doc.id),
              )
              .toList(),
        );
  }

  Future<void> saveDefaultCategory(SystemDefaultCategoryModel category) async {
    final snapshot = await _firestore.collection('default_categories').get();
    final duplicate = snapshot.docs.any((doc) {
      if (doc.id == category.id) return false;
      final data = doc.data();
      return data['normalizedName'] == category.normalizedName &&
          data['type'] == category.type;
    });
    if (duplicate) {
      throw Exception('Danh mục cùng tên và cùng loại đã tồn tại.');
    }

    final collection = _firestore.collection('default_categories');
    final ref = category.id.isEmpty
        ? collection.doc()
        : collection.doc(category.id);
    final batch = _firestore.batch();
    batch.set(ref, {
      ...category.toMap(),
      if (category.id.isEmpty) 'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': currentUid,
    }, SetOptions(merge: true));
    _addAuditLog(
      batch,
      action: category.id.isEmpty
          ? 'create_default_category'
          : 'update_default_category',
      targetType: 'default_category',
      targetId: ref.id,
      summary: category.name,
    );
    await batch.commit();
  }

  Future<void> setDefaultCategoryActive(
    SystemDefaultCategoryModel category,
    bool isActive,
  ) async {
    final ref = _firestore.collection('default_categories').doc(category.id);
    final batch = _firestore.batch();
    batch.update(ref, {
      'isActive': isActive,
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': currentUid,
    });
    _addAuditLog(
      batch,
      action: isActive
          ? 'activate_default_category'
          : 'deactivate_default_category',
      targetType: 'default_category',
      targetId: category.id,
      summary: category.name,
    );
    await batch.commit();
  }

  Stream<List<SystemNotificationModel>> watchSystemNotifications() {
    return _firestore
        .collection('system_notifications')
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => SystemNotificationModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  Future<void> saveSystemNotification(
    SystemNotificationModel notification,
  ) async {
    final collection = _firestore.collection('system_notifications');
    final ref = notification.id.isEmpty
        ? collection.doc()
        : collection.doc(notification.id);
    final batch = _firestore.batch();
    batch.set(ref, {
      ...notification.toMap(),
      if (notification.id.isEmpty) 'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': currentUid,
    }, SetOptions(merge: true));
    _addAuditLog(
      batch,
      action: notification.id.isEmpty
          ? 'create_system_notification'
          : 'update_system_notification',
      targetType: 'system_notification',
      targetId: ref.id,
      summary: notification.title,
    );
    await batch.commit();
  }

  Future<void> setSystemNotificationPublished(
    SystemNotificationModel notification,
    bool isPublished,
  ) async {
    final ref = _firestore
        .collection('system_notifications')
        .doc(notification.id);
    final batch = _firestore.batch();
    batch.update(ref, {
      'isPublished': isPublished,
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': currentUid,
    });
    _addAuditLog(
      batch,
      action: isPublished
          ? 'publish_system_notification'
          : 'unpublish_system_notification',
      targetType: 'system_notification',
      targetId: notification.id,
      summary: notification.title,
    );
    await batch.commit();
  }

  Future<void> deleteSystemNotification(
    SystemNotificationModel notification,
  ) async {
    final ref = _firestore
        .collection('system_notifications')
        .doc(notification.id);
    final batch = _firestore.batch();
    batch.delete(ref);
    _addAuditLog(
      batch,
      action: 'delete_system_notification',
      targetType: 'system_notification',
      targetId: notification.id,
      summary: notification.title,
    );
    await batch.commit();
  }

  Stream<AppConfigModel> watchAppConfig() {
    return _firestore
        .collection('app_config')
        .doc('general')
        .snapshots()
        .map((snapshot) => AppConfigModel.fromMap(snapshot.data()));
  }

  Future<void> saveAppConfig(AppConfigModel config) async {
    final configRef = _firestore.collection('app_config').doc('general');
    final batch = _firestore.batch();
    batch.set(configRef, {
      ...config.toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': currentUid,
    }, SetOptions(merge: true));
    _addAuditLog(
      batch,
      action: 'update_app_config',
      targetType: 'app_config',
      targetId: 'general',
      summary: config.appName,
    );
    await batch.commit();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchAuditLogs() {
    return _firestore
        .collection('admin_audit_logs')
        .orderBy('createdAt', descending: true)
        .limit(100)
        .snapshots();
  }

  void _addAuditLog(
    WriteBatch batch, {
    required String action,
    required String targetType,
    required String targetId,
    required String summary,
  }) {
    final ref = _firestore.collection('admin_audit_logs').doc();
    batch.set(ref, {
      'action': action,
      'targetType': targetType,
      'targetId': targetId,
      'summary': summary,
      'actorUid': currentUid,
      'actorEmail': _auth.currentUser?.email,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
