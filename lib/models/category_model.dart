import 'package:cloud_firestore/cloud_firestore.dart';

class CategoryModel {
  final String id;
  final String userId;
  final String name;
  final String type; // 'income' or 'expense'
  final String iconCode;
  final String colorHex;
  final bool isDefault;

  CategoryModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.type,
    required this.iconCode,
    required this.colorHex,
    this.isDefault = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'type': type,
      'iconCode': iconCode,
      'colorHex': colorHex,
      'isDefault': isDefault,
    };
  }

  factory CategoryModel.fromMap(Map<String, dynamic> map, String documentId) {
    return CategoryModel(
      id: documentId,
      userId: map['userId'] ?? '',
      name: map['name'] ?? '',
      type: map['type'] ?? 'expense',
      iconCode: map['iconCode'] ?? 'e5fc', // default icon
      colorHex: map['colorHex'] ?? 'FF9E9E9E', // default gray
      isDefault: map['isDefault'] ?? false,
    );
  }
}
