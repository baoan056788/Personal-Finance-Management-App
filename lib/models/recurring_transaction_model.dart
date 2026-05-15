import 'package:cloud_firestore/cloud_firestore.dart';

class RecurringTransactionModel {
  final String id;
  final String userId;
  final String name;
  final double amount;
  final String type;
  final String categoryId;
  final String walletId;
  final String frequency; // 'weekly', 'monthly', 'yearly'
  final DateTime nextDueDate;
  final DateTime createdAt;
  final String? imageUrl;
  final DateTime? endDate;

  RecurringTransactionModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.amount,
    required this.type,
    required this.categoryId,
    required this.walletId,
    required this.frequency,
    required this.nextDueDate,
    required this.createdAt,
    this.imageUrl,
    this.endDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'amount': amount,
      'type': type,
      'categoryId': categoryId,
      'walletId': walletId,
      'frequency': frequency,
      'nextDueDate': Timestamp.fromDate(nextDueDate),
      'createdAt': Timestamp.fromDate(createdAt),
      if (imageUrl != null) 'imageUrl': imageUrl,
      if (endDate != null) 'endDate': Timestamp.fromDate(endDate!),
    };
  }

  factory RecurringTransactionModel.fromMap(Map<String, dynamic> map, String documentId) {
    return RecurringTransactionModel(
      id: documentId,
      userId: map['userId'] ?? '',
      name: map['name'] ?? '',
      amount: (map['amount'] ?? 0.0).toDouble(),
      type: map['type'] ?? 'expense',
      categoryId: map['categoryId'] ?? '',
      walletId: map['walletId'] ?? '',
      frequency: map['frequency'] ?? 'monthly',
      nextDueDate: (map['nextDueDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      imageUrl: map['imageUrl'],
      endDate: (map['endDate'] as Timestamp?)?.toDate(),
    );
  }
}
