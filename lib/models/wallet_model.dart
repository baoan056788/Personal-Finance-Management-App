import 'package:cloud_firestore/cloud_firestore.dart';

class WalletModel {
  final String id;
  final String name;
  final String type;
  final double balance;
  final DateTime createdAt;

  WalletModel({
    required this.id,
    required this.name,
    required this.type,
    required this.balance,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'balance': balance,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory WalletModel.fromMap(Map<String, dynamic> map, String documentId) {
    return WalletModel(
      id: documentId,
      name: map['name'] ?? '',
      type: map['type'] ?? 'Cash',
      balance: (map['balance'] ?? 0.0).toDouble(),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
