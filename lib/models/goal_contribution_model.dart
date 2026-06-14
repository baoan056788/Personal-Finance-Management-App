import 'package:cloud_firestore/cloud_firestore.dart';

class GoalContributionModel {
  final String id;
  final String goalId;
  final String walletId;
  final String transactionId;
  final double amount;
  final String note;
  final DateTime createdAt;
  final String type;

  GoalContributionModel({
    required this.id,
    required this.goalId,
    required this.walletId,
    required this.transactionId,
    required this.amount,
    this.note = '',
    required this.createdAt,
    this.type = 'deposit',
  });

  Map<String, dynamic> toMap() {
    return {
      'goalId': goalId,
      'walletId': walletId,
      'transactionId': transactionId,
      'amount': amount,
      'note': note,
      'createdAt': Timestamp.fromDate(createdAt),
      'type': type,
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
      type:
          map['type'] ?? ((map['amount'] ?? 0) < 0 ? 'withdrawal' : 'deposit'),
    );
  }

  bool get isWithdrawal => type == 'withdrawal' || amount < 0;
}
