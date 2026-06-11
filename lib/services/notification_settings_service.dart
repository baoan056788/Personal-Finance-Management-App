import 'package:shared_preferences/shared_preferences.dart';

class NotificationSettings {
  final bool enabled;
  final bool debtReminders;
  final bool recurringReminders;
  final int advanceDays;

  const NotificationSettings({
    this.enabled = true,
    this.debtReminders = true,
    this.recurringReminders = true,
    this.advanceDays = 3,
  });

  NotificationSettings copyWith({
    bool? enabled,
    bool? debtReminders,
    bool? recurringReminders,
    int? advanceDays,
  }) {
    return NotificationSettings(
      enabled: enabled ?? this.enabled,
      debtReminders: debtReminders ?? this.debtReminders,
      recurringReminders: recurringReminders ?? this.recurringReminders,
      advanceDays: advanceDays ?? this.advanceDays,
    );
  }
}

class NotificationSettingsService {
  static const _enabledKey = 'notifications_enabled';
  static const _debtKey = 'notifications_debt_reminders';
  static const _recurringKey = 'notifications_recurring_reminders';
  static const _advanceDaysKey = 'notifications_advance_days';

  Future<NotificationSettings> load() async {
    final preferences = await SharedPreferences.getInstance();
    return NotificationSettings(
      enabled: preferences.getBool(_enabledKey) ?? true,
      debtReminders: preferences.getBool(_debtKey) ?? true,
      recurringReminders: preferences.getBool(_recurringKey) ?? true,
      advanceDays: preferences.getInt(_advanceDaysKey) ?? 3,
    );
  }

  Future<void> save(NotificationSettings settings) async {
    final preferences = await SharedPreferences.getInstance();
    await Future.wait([
      preferences.setBool(_enabledKey, settings.enabled),
      preferences.setBool(_debtKey, settings.debtReminders),
      preferences.setBool(_recurringKey, settings.recurringReminders),
      preferences.setInt(_advanceDaysKey, settings.advanceDays),
    ]);
  }
}
