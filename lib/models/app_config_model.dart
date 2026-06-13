import 'package:cloud_firestore/cloud_firestore.dart';

class AppConfigModel {
  final String appName;
  final String supportEmail;
  final String supportPhone;
  final double maxTransactionAmount;
  final bool maintenanceMode;
  final bool registrationEnabled;
  final DateTime? updatedAt;

  const AppConfigModel({
    this.appName = 'QLTC_N11',
    this.supportEmail = 'support@finance.app',
    this.supportPhone = '1800-xxxx',
    this.maxTransactionAmount = 1000000000,
    this.maintenanceMode = false,
    this.registrationEnabled = true,
    this.updatedAt,
  });

  factory AppConfigModel.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const AppConfigModel();
    return AppConfigModel(
      appName: (map['appName'] as String?)?.trim().isNotEmpty == true
          ? (map['appName'] as String).trim()
          : 'QLTC_N11',
      supportEmail:
          (map['supportEmail'] as String?)?.trim() ?? 'support@finance.app',
      supportPhone: (map['supportPhone'] as String?)?.trim() ?? '1800-xxxx',
      maxTransactionAmount:
          (map['maxTransactionAmount'] as num?)?.toDouble() ?? 1000000000,
      maintenanceMode: map['maintenanceMode'] as bool? ?? false,
      registrationEnabled: map['registrationEnabled'] as bool? ?? true,
      updatedAt: _parseDate(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'appName': appName.trim(),
      'supportEmail': supportEmail.trim(),
      'supportPhone': supportPhone.trim(),
      'maxTransactionAmount': maxTransactionAmount,
      'maintenanceMode': maintenanceMode,
      'registrationEnabled': registrationEnabled,
    };
  }

  static DateTime? _parseDate(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
