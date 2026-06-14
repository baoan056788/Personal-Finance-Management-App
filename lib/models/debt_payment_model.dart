import 'package:cloud_firestore/cloud_firestore.dart';

class DebtPaymentModel {
  final String id;
  final String userId;
  final String debtId;
  final String walletId;
  final String transactionId;
  final double amount;
  final String note;
  final DateTime createdAt;

  const DebtPaymentModel({
    required this.id,
    required this.userId,
    required this.debtId,
    required this.walletId,
    required this.transactionId,
    required this.amount,
    required this.note,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    'userId': userId,
    'debtId': debtId,
    'walletId': walletId,
    'transactionId': transactionId,
    'amount': amount,
    'note': note,
    'createdAt': Timestamp.fromDate(createdAt),
  };

  factory DebtPaymentModel.fromMap(Map<String, dynamic> map, String id) {
    return DebtPaymentModel(
      id: id,
      userId: map['userId'] ?? '',
      debtId: map['debtId'] ?? '',
      walletId: map['walletId'] ?? '',
      transactionId: map['transactionId'] ?? '',
      amount: (map['amount'] ?? 0).toDouble(),
      note: map['note'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
