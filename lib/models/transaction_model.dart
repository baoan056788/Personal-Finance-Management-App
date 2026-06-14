import 'package:cloud_firestore/cloud_firestore.dart';

class TransactionModel {
  final String id;
  final double amount;
  final String type; // income, expense, transfer, goal, or debt
  final String category; // Name of category (legacy)
  final String? categoryId; // ID of category for better icon lookup
  final String note;
  final DateTime createdAt;
  final String? imageUrl;
  final bool isRecurring;
  final String walletId; // NEW: Track which wallet this belongs to
  final String? transferId;
  final String? transferDirection;
  final String? relatedWalletId;
  final String? relatedWalletName;
  final String? cashFlowDirection;
  final String? referenceId;

  TransactionModel({
    required this.id,
    required this.amount,
    required this.type,
    required this.category,
    this.categoryId,
    required this.note,
    required this.createdAt,
    this.imageUrl,
    this.isRecurring = false,
    this.walletId = '', // Default to empty for legacy
    this.transferId,
    this.transferDirection,
    this.relatedWalletId,
    this.relatedWalletName,
    this.cashFlowDirection,
    this.referenceId,
  });

  bool get isTransfer => type == 'transfer';

  bool get isGoalMovement => type == 'goal';

  bool get isDebtMovement => type == 'debt';

  bool get isInternalMovement => isTransfer || isGoalMovement || isDebtMovement;

  bool get isIncomingTransfer =>
      isTransfer &&
      (transferDirection == 'in' ||
          (transferDirection == null && category == 'Nhận tiền'));

  bool get isIncomingInternalMovement =>
      (isGoalMovement || isDebtMovement) && cashFlowDirection == 'in';

  bool get isCredit =>
      isIncome || isIncomingTransfer || isIncomingInternalMovement;

  bool get isIncome =>
      type == 'income' || (isGoalMovement && cashFlowDirection == 'in');

  bool get isExpense =>
      type == 'expense' || (isGoalMovement && cashFlowDirection != 'in');

  double get walletBalanceImpact {
    if (isIncome || isIncomingTransfer || isIncomingInternalMovement) {
      return amount;
    }
    if (isExpense || isTransfer || isGoalMovement || isDebtMovement) {
      return -amount;
    }
    return 0;
  }

  double get reportImpact {
    if (isIncome) return amount;
    if (isExpense) return -amount;
    return 0;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'type': type,
      'category': category,
      'categoryId': categoryId,
      'note': note,
      'createdAt': Timestamp.fromDate(createdAt),
      'isRecurring': isRecurring,
      'walletId': walletId,
      if (transferId != null) 'transferId': transferId,
      if (transferDirection != null) 'transferDirection': transferDirection,
      if (relatedWalletId != null) 'relatedWalletId': relatedWalletId,
      if (relatedWalletName != null) 'relatedWalletName': relatedWalletName,
      if (cashFlowDirection != null) 'cashFlowDirection': cashFlowDirection,
      if (referenceId != null) 'referenceId': referenceId,
      if (imageUrl != null) 'imageUrl': imageUrl,
    };
  }

  factory TransactionModel.fromMap(
    Map<String, dynamic> map,
    String documentId,
  ) {
    final category = map['category'] as String? ?? '';
    final note = map['note'] as String? ?? '';
    final storedType = map['type'] as String? ?? 'expense';
    final isLegacyGoalContribution =
        storedType == 'expense' && note.trim().startsWith('Góp mục tiêu:');
    return TransactionModel(
      id: documentId,
      amount: (map['amount'] ?? 0.0).toDouble(),
      type: isLegacyGoalContribution ? 'goal' : storedType,
      category: category,
      categoryId: map['categoryId'],
      note: note,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      imageUrl: map['imageUrl'],
      isRecurring: map['isRecurring'] ?? false,
      walletId: map['walletId'] ?? '',
      transferId: map['transferId'],
      transferDirection: map['transferDirection'],
      relatedWalletId: map['relatedWalletId'],
      relatedWalletName: map['relatedWalletName'],
      cashFlowDirection:
          map['cashFlowDirection'] ?? (isLegacyGoalContribution ? 'out' : null),
      referenceId: map['referenceId'],
    );
  }

  TransactionModel copyWith({
    String? id,
    double? amount,
    String? type,
    String? category,
    String? categoryId,
    String? note,
    DateTime? createdAt,
    String? imageUrl,
    bool? isRecurring,
    String? walletId,
    String? transferId,
    String? transferDirection,
    String? relatedWalletId,
    String? relatedWalletName,
    String? cashFlowDirection,
    String? referenceId,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      category: category ?? this.category,
      categoryId: categoryId ?? this.categoryId,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      imageUrl: imageUrl ?? this.imageUrl,
      isRecurring: isRecurring ?? this.isRecurring,
      walletId: walletId ?? this.walletId,
      transferId: transferId ?? this.transferId,
      transferDirection: transferDirection ?? this.transferDirection,
      relatedWalletId: relatedWalletId ?? this.relatedWalletId,
      relatedWalletName: relatedWalletName ?? this.relatedWalletName,
      cashFlowDirection: cashFlowDirection ?? this.cashFlowDirection,
      referenceId: referenceId ?? this.referenceId,
    );
  }
}
