import 'package:cloud_firestore/cloud_firestore.dart';

class SystemNotificationModel {
  final String id;
  final String title;
  final String message;
  final DateTime expiresAt;
  final bool isPublished;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const SystemNotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.expiresAt,
    required this.isPublished,
    this.createdAt,
    this.updatedAt,
  });

  bool get isActive => isPublished && expiresAt.isAfter(DateTime.now());

  factory SystemNotificationModel.fromMap(Map<String, dynamic> map, String id) {
    return SystemNotificationModel(
      id: id,
      title: map['title'] as String? ?? '',
      message: map['message'] as String? ?? '',
      expiresAt:
          _parseDate(map['expiresAt']) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      isPublished: map['isPublished'] as bool? ?? false,
      createdAt: _parseDate(map['createdAt']),
      updatedAt: _parseDate(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title.trim(),
      'message': message.trim(),
      'expiresAt': Timestamp.fromDate(expiresAt),
      'isPublished': isPublished,
    };
  }

  static DateTime? _parseDate(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
