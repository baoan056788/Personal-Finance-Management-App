import 'package:cloud_firestore/cloud_firestore.dart';

class AdminUserModel {
  final String uid;
  final String email;
  final String fullName;
  final String? avatarUrl;
  final String role;
  final String loginProvider;
  final DateTime? createdAt;
  final DateTime? lastSignInAt;

  const AdminUserModel({
    required this.uid,
    required this.email,
    required this.fullName,
    required this.role,
    required this.loginProvider,
    this.avatarUrl,
    this.createdAt,
    this.lastSignInAt,
  });

  bool get isAdmin => role == 'admin';

  factory AdminUserModel.fromMap(Map<String, dynamic> map) {
    return AdminUserModel(
      uid: map['uid'] as String? ?? '',
      email: map['email'] as String? ?? '',
      fullName: map['fullName'] as String? ?? 'Người dùng',
      avatarUrl: map['avatarUrl'] as String?,
      role: map['role'] as String? ?? 'user',
      loginProvider: map['loginProvider'] as String? ?? 'unknown',
      createdAt: _parseDate(map['createdAt']),
      lastSignInAt: _parseDate(map['lastLoginAt'] ?? map['lastSignInAt']),
    );
  }

  static DateTime? _parseDate(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    return null;
  }
}
