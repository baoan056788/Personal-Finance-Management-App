import 'package:cloud_firestore/cloud_firestore.dart';

class DebtModel {
  final String id;
  final String userId;
  final String type; // borrowed or lent
  final String personName;
  final double amount;
  final double paidAmount;
  final DateTime dueDate;
  final String note;
  final String status; // OPEN, DUE_SOON, OVERDUE, PAID
  final DateTime createdAt;
  final DateTime updatedAt;

  DebtModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.personName,
    required this.amount,
    this.paidAmount = 0,
    required this.dueDate,
    this.note = '',
    this.status = 'OPEN',
    required this.createdAt,
    required this.updatedAt,
  });

  double get remainAmount {
    final remain = amount - paidAmount;
    return remain < 0 ? 0 : remain;
  }

  bool get isBorrowed => type == 'borrowed';
  bool get isPaid => status == 'PAID' || remainAmount <= 0;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'type': type,
      'personName': personName,
      'amount': amount,
      'paidAmount': paidAmount,
      'dueDate': Timestamp.fromDate(dueDate),
      'note': note,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory DebtModel.fromMap(Map<String, dynamic> map, String id) {
    return DebtModel(
      id: id,
      userId: map['userId'] ?? '',
      type: map['type'] ?? 'borrowed',
      personName: map['personName'] ?? '',
      amount: (map['amount'] ?? 0).toDouble(),
      paidAmount: (map['paidAmount'] ?? 0).toDouble(),
      dueDate: (map['dueDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      note: map['note'] ?? '',
      status: map['status'] ?? 'OPEN',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  DebtModel copyWith({
    String? id,
    String? userId,
    String? type,
    String? personName,
    double? amount,
    double? paidAmount,
    DateTime? dueDate,
    String? note,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DebtModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      personName: personName ?? this.personName,
      amount: amount ?? this.amount,
      paidAmount: paidAmount ?? this.paidAmount,
      dueDate: dueDate ?? this.dueDate,
      note: note ?? this.note,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
