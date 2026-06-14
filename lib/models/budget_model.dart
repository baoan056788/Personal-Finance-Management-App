import 'package:cloud_firestore/cloud_firestore.dart';

DateTime _startOfDay(DateTime value) {
  return DateTime(value.year, value.month, value.day);
}

DateTime _endOfDay(DateTime value) {
  return DateTime(
    value.year,
    value.month,
    value.day + 1,
  ).subtract(const Duration(microseconds: 1));
}

class BudgetModel {
  final String id;
  final String userId;
  final String categoryId;
  final String? walletId;
  final String name;
  final double limitAmount;
  final double spentAmount;
  final double remainAmount;
  final double progressPercent;
  final DateTime startDate;
  final DateTime endDate;
  final String periodType; // DAILY, WEEKLY, MONTHLY, YEARLY
  final String note;
  final String status; // SAFE, WARNING, DANGER, OVER_LIMIT
  final DateTime createdAt;
  final DateTime updatedAt;

  BudgetModel({
    required this.id,
    required this.userId,
    required this.categoryId,
    this.walletId,
    required this.name,
    required this.limitAmount,
    required this.spentAmount,
    required this.remainAmount,
    required this.progressPercent,
    required this.startDate,
    required this.endDate,
    required this.periodType,
    required this.note,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'categoryId': categoryId,
      'walletId': walletId,
      'name': name,
      'limitAmount': limitAmount,
      'spentAmount': spentAmount,
      'remainAmount': remainAmount,
      'progressPercent': progressPercent,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'periodType': periodType,
      'note': note,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory BudgetModel.fromMap(Map<String, dynamic> map, String documentId) {
    return BudgetModel(
      id: documentId,
      userId: map['userId'] ?? '',
      categoryId: map['categoryId'] ?? '',
      walletId: map['walletId'],
      name: map['name'] ?? '',
      limitAmount: (map['limitAmount'] ?? 0.0).toDouble(),
      spentAmount: (map['spentAmount'] ?? 0.0).toDouble(),
      remainAmount: (map['remainAmount'] ?? 0.0).toDouble(),
      progressPercent: (map['progressPercent'] ?? 0.0).toDouble(),
      startDate: _startOfDay(
        (map['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      ),
      endDate: _endOfDay(
        (map['endDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      ),
      periodType: map['periodType'] ?? 'MONTHLY',
      note: map['note'] ?? '',
      status: map['status'] ?? 'SAFE',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  BudgetModel copyWith({
    String? id,
    String? userId,
    String? categoryId,
    String? walletId,
    String? name,
    double? limitAmount,
    double? spentAmount,
    double? remainAmount,
    double? progressPercent,
    DateTime? startDate,
    DateTime? endDate,
    String? periodType,
    String? note,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BudgetModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      categoryId: categoryId ?? this.categoryId,
      walletId: walletId ?? this.walletId,
      name: name ?? this.name,
      limitAmount: limitAmount ?? this.limitAmount,
      spentAmount: spentAmount ?? this.spentAmount,
      remainAmount: remainAmount ?? this.remainAmount,
      progressPercent: progressPercent ?? this.progressPercent,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      periodType: periodType ?? this.periodType,
      note: note ?? this.note,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
