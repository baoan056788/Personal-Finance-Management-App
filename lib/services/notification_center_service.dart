import '../controllers/debt_controller.dart';
import '../controllers/recurring_transaction_controller.dart';
import '../models/debt_model.dart';
import '../models/recurring_transaction_model.dart';
import '../models/system_notification_model.dart';
import 'notification_settings_service.dart';
import 'system_notification_service.dart';

class NotificationCenterData {
  final NotificationSettings settings;
  final List<SystemNotificationModel> systemNotifications;
  final List<DebtModel> debts;
  final List<RecurringTransactionModel> recurring;

  const NotificationCenterData({
    required this.settings,
    required this.systemNotifications,
    required this.debts,
    required this.recurring,
  });

  int get reminderCount =>
      systemNotifications.length + debts.length + recurring.length;
}

class NotificationCenterService {
  final NotificationSettingsService _settingsService =
      NotificationSettingsService();
  final SystemNotificationService _systemNotificationService =
      SystemNotificationService();
  final DebtController _debtController = DebtController();
  final RecurringTransactionController _recurringController =
      RecurringTransactionController();

  Future<NotificationCenterData> load() async {
    final results = await Future.wait([
      _systemNotificationService.getActiveNotifications(),
      _settingsService.load(),
    ]);
    final systemNotifications = results[0] as List<SystemNotificationModel>;
    final settings = results[1] as NotificationSettings;

    var debts = <DebtModel>[];
    var recurring = <RecurringTransactionModel>[];
    if (settings.enabled) {
      final reminderResults = await Future.wait([
        settings.debtReminders
            ? _debtController.getDueReminders(daysAhead: settings.advanceDays)
            : Future.value(<DebtModel>[]),
        settings.recurringReminders
            ? _recurringController.getRecurringTransactions().first
            : Future.value(<RecurringTransactionModel>[]),
      ]);
      debts = reminderResults[0] as List<DebtModel>;
      recurring = _filterUpcomingRecurring(
        reminderResults[1] as List<RecurringTransactionModel>,
        settings.advanceDays,
      );
    }

    return NotificationCenterData(
      settings: settings,
      systemNotifications: systemNotifications,
      debts: debts,
      recurring: recurring,
    );
  }

  List<RecurringTransactionModel> _filterUpcomingRecurring(
    List<RecurringTransactionModel> transactions,
    int daysAhead,
  ) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final limit = today.add(Duration(days: daysAhead));
    final upcoming = transactions.where((transaction) {
      final due = DateTime(
        transaction.nextDueDate.year,
        transaction.nextDueDate.month,
        transaction.nextDueDate.day,
      );
      final endDate = transaction.endDate;
      if (endDate != null && due.isAfter(endDate)) return false;
      return due.isBefore(limit) || due.isAtSameMomentAs(limit);
    }).toList();
    upcoming.sort((a, b) => a.nextDueDate.compareTo(b.nextDueDate));
    return upcoming;
  }
}
