import 'package:cloud_firestore/cloud_firestore.dart';

class TransactionModel {
  final String id;
  final double amount;
  final String type; // 'income' or 'expense'
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
  });

  bool get isTransfer => type == 'transfer';

  bool get isIncomingTransfer =>
      isTransfer &&
      (transferDirection == 'in' ||
          (transferDirection == null && category == 'Nhận tiền'));

  bool get isCredit => type == 'income' || isIncomingTransfer;

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
      if (imageUrl != null) 'imageUrl': imageUrl,
    };
  }

  factory TransactionModel.fromMap(Map<String, dynamic> map, String documentId) {
    return TransactionModel(
      id: documentId,
      amount: (map['amount'] ?? 0.0).toDouble(),
      type: map['type'] ?? 'expense',
      category: map['category'] ?? '',
      categoryId: map['categoryId'],
      note: map['note'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      imageUrl: map['imageUrl'],
      isRecurring: map['isRecurring'] ?? false,
      walletId: map['walletId'] ?? '',
      transferId: map['transferId'],
      transferDirection: map['transferDirection'],
      relatedWalletId: map['relatedWalletId'],
      relatedWalletName: map['relatedWalletName'],
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
    );
  }
}
