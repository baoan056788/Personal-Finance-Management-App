import 'package:cloud_firestore/cloud_firestore.dart';

class GoalContributionModel {
  final String id;
  final String goalId;
  final String walletId;
  final String transactionId;
  final double amount;
  final String note;
  final DateTime createdAt;

  GoalContributionModel({
    required this.id,
    required this.goalId,
    required this.walletId,
    required this.transactionId,
    required this.amount,
    this.note = '',
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'goalId': goalId,
      'walletId': walletId,
      'transactionId': transactionId,
      'amount': amount,
      'note': note,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory GoalContributionModel.fromMap(Map<String, dynamic> map, String id) {
    return GoalContributionModel(
      id: id,
      goalId: map['goalId'] ?? '',
      walletId: map['walletId'] ?? '',
      transactionId: map['transactionId'] ?? '',
      amount: (map['amount'] ?? 0).toDouble(),
      note: map['note'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
