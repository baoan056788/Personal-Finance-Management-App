import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:personal_finance_management_app/models/admin_dashboard_model.dart';
import 'package:personal_finance_management_app/models/admin_user_model.dart';
import 'package:personal_finance_management_app/models/app_config_model.dart';
import 'package:personal_finance_management_app/models/system_notification_model.dart';
import 'package:personal_finance_management_app/models/transaction_model.dart';
import 'package:personal_finance_management_app/utils/category_name_normalizer.dart';

void main() {
  group('AdminUserModel', () {
    test('uses safe defaults for legacy user documents', () {
      final user = AdminUserModel.fromMap({
        'uid': 'user-1',
        'email': 'user@example.com',
      });

      expect(user.role, 'user');
      expect(user.isAdmin, isFalse);
    });

    test('reads admin state', () {
      final user = AdminUserModel.fromMap({'uid': 'admin-1', 'role': 'admin'});

      expect(user.isAdmin, isTrue);
    });

    test('reads Firestore timestamps used by profile documents', () {
      final timestamp = Timestamp.fromDate(DateTime(2026, 6, 13, 10));
      final user = AdminUserModel.fromMap({
        'createdAt': timestamp,
        'lastLoginAt': timestamp,
      });

      expect(user.createdAt, timestamp.toDate());
      expect(user.lastSignInAt, timestamp.toDate());
    });
  });

  test('AdminDashboardModel parses registration data', () {
    final dashboard = AdminDashboardModel.fromMap({
      'totalUsers': 10,
      'activeUsers': 7,
      'newUsersThisMonth': 2,
      'registrations': [
        {'key': '2026-06', 'label': 'T6', 'count': 2},
      ],
    });

    expect(dashboard.totalUsers, 10);
    expect(dashboard.registrations.single.count, 2);
  });

  test('AppConfigModel uses safe Spark defaults', () {
    final config = AppConfigModel.fromMap(null);

    expect(config.appName, 'QLTC_N11');
    expect(config.registrationEnabled, isTrue);
    expect(config.maintenanceMode, isFalse);
    expect(config.maxTransactionAmount, greaterThan(0));
  });

  test('SystemNotificationModel detects active publication', () {
    final notification = SystemNotificationModel.fromMap({
      'title': 'Bảo trì',
      'message': 'Nội dung',
      'isPublished': true,
      'expiresAt': Timestamp.fromDate(
        DateTime.now().add(const Duration(days: 1)),
      ),
    }, 'notice-1');

    expect(notification.isActive, isTrue);
  });

  test('TransactionModel detects incoming wallet transfers as credit', () {
    final transfer = TransactionModel(
      id: 'transfer-in',
      amount: 100000,
      type: 'transfer',
      category: 'Nhận tiền',
      note: '',
      createdAt: DateTime(2026, 6, 13),
      transferDirection: 'in',
    );

    expect(transfer.isTransfer, isTrue);
    expect(transfer.isIncomingTransfer, isTrue);
    expect(transfer.isCredit, isTrue);
  });

  test('normalizes Vietnamese category names for duplicate detection', () {
    expect(normalizeCategoryName('  Ăn   Uống  '), 'an uong');
    expect(normalizeCategoryName('Lương'), 'luong');
  });
}
