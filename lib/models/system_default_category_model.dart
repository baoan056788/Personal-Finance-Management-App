import 'package:cloud_firestore/cloud_firestore.dart';

class SystemDefaultCategoryModel {
  final String id;
  final String name;
  final String normalizedName;
  final String type;
  final String iconCode;
  final String colorHex;
  final int order;
  final bool isActive;

  const SystemDefaultCategoryModel({
    required this.id,
    required this.name,
    required this.normalizedName,
    required this.type,
    required this.iconCode,
    required this.colorHex,
    required this.order,
    required this.isActive,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'normalizedName': normalizedName,
      'type': type,
      'iconCode': iconCode,
      'colorHex': colorHex,
      'order': order,
      'isActive': isActive,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  factory SystemDefaultCategoryModel.fromMap(
    Map<String, dynamic> map,
    String documentId,
  ) {
    return SystemDefaultCategoryModel(
      id: documentId,
      name: map['name'] as String? ?? '',
      normalizedName: map['normalizedName'] as String? ?? '',
      type: map['type'] as String? ?? 'expense',
      iconCode: map['iconCode'] as String? ?? 'e5fc',
      colorHex: map['colorHex'] as String? ?? 'FF9E9E9E',
      order: (map['order'] as num?)?.toInt() ?? 0,
      isActive: map['isActive'] as bool? ?? true,
    );
  }

  SystemDefaultCategoryModel copyWith({
    String? id,
    String? name,
    String? normalizedName,
    String? type,
    String? iconCode,
    String? colorHex,
    int? order,
    bool? isActive,
  }) {
    return SystemDefaultCategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      normalizedName: normalizedName ?? this.normalizedName,
      type: type ?? this.type,
      iconCode: iconCode ?? this.iconCode,
      colorHex: colorHex ?? this.colorHex,
      order: order ?? this.order,
      isActive: isActive ?? this.isActive,
    );
  }
}
