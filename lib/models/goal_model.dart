import 'package:cloud_firestore/cloud_firestore.dart';

class GoalModel {
  final String id;
  final String userId;
  final String name;
  final double targetAmount;
  final double currentAmount;
  final double remainAmount;
  final double progressPercent;
  final DateTime targetDate;
  final String note;
  final String colorHex;
  final String iconCode;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  GoalModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.targetAmount,
    this.currentAmount = 0.0,
    this.remainAmount = 0.0,
    this.progressPercent = 0.0,
    required this.targetDate,
    this.note = '',
    required this.colorHex,
    required this.iconCode,
    this.status = 'ON_GOING',
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'targetAmount': targetAmount,
      'currentAmount': currentAmount,
      'remainAmount': remainAmount,
      'progressPercent': progressPercent,
      'targetDate': Timestamp.fromDate(targetDate),
      'note': note,
      'colorHex': colorHex,
      'iconCode': iconCode,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory GoalModel.fromMap(Map<String, dynamic> map, String id) {
    return GoalModel(
      id: id,
      userId: map['userId'] ?? '',
      name: map['name'] ?? '',
      targetAmount: (map['targetAmount'] ?? 0).toDouble(),
      currentAmount: (map['currentAmount'] ?? 0).toDouble(),
      remainAmount: (map['remainAmount'] ?? 0).toDouble(),
      progressPercent: (map['progressPercent'] ?? 0).toDouble(),
      targetDate: (map['targetDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      note: map['note'] ?? '',
      colorHex: map['colorHex'] ?? 'FF2196F3',
      iconCode: map['iconCode'] ?? 'e838',
      status: map['status'] ?? 'ON_GOING',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  GoalModel copyWith({
    String? id,
    String? userId,
    String? name,
    double? targetAmount,
    double? currentAmount,
    double? remainAmount,
    double? progressPercent,
    DateTime? targetDate,
    String? note,
    String? colorHex,
    String? iconCode,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return GoalModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      targetAmount: targetAmount ?? this.targetAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      remainAmount: remainAmount ?? this.remainAmount,
      progressPercent: progressPercent ?? this.progressPercent,
      targetDate: targetDate ?? this.targetDate,
      note: note ?? this.note,
      colorHex: colorHex ?? this.colorHex,
      iconCode: iconCode ?? this.iconCode,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
