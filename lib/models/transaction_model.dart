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
  });

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
    );
  }
}
