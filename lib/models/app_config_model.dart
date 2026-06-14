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
    this.supportEmail = 'nhom11ltdd@gmail.com',
    this.supportPhone = '0972328274',
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
      supportEmail: _parseSupportEmail(map['supportEmail']),
      supportPhone: _parseSupportPhone(map['supportPhone']),
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

  static String _parseSupportEmail(Object? value) {
    final email = value is String ? value.trim() : '';
    if (email.isEmpty || email == 'support@finance.app') {
      return 'nhom11ltdd@gmail.com';
    }
    return email;
  }

  static String _parseSupportPhone(Object? value) {
    final phone = value is String ? value.trim() : '';
    if (phone.isEmpty || phone == '18001234' || phone == '1800-xxxx') {
      return '0972328274';
    }
    return phone;
  }
}
