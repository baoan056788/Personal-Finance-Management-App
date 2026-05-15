import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/category_model.dart';

class CategoryController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'categories';
  final String? userId = FirebaseAuth.instance.currentUser?.uid;

  // Setup default categories for a new user
  Future<void> setupDefaultCategoriesIfNeeded() async {
    if (userId == null) return;
    
    final snapshot = await _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) {
      final defaultCategories = [
        // Expense
        CategoryModel(id: '', userId: userId!, name: 'Ăn uống', type: 'expense', iconCode: 'e532', colorHex: 'FFF44336', isDefault: true),
        CategoryModel(id: '', userId: userId!, name: 'Di chuyển', type: 'expense', iconCode: 'e531', colorHex: 'FF2196F3', isDefault: true),
        CategoryModel(id: '', userId: userId!, name: 'Mua sắm', type: 'expense', iconCode: 'e8cc', colorHex: 'FFFF9800', isDefault: true),
        CategoryModel(id: '', userId: userId!, name: 'Hóa đơn', type: 'expense', iconCode: 'e8b0', colorHex: 'FF9C27B0', isDefault: true),
        // Income
        CategoryModel(id: '', userId: userId!, name: 'Lương', type: 'income', iconCode: 'e53d', colorHex: 'FF4CAF50', isDefault: true),
        CategoryModel(id: '', userId: userId!, name: 'Thưởng', type: 'income', iconCode: 'e838', colorHex: 'FFFFEB3B', isDefault: true),
      ];

      for (var cat in defaultCategories) {
        await addCategory(cat);
      }
    }
  }

  // Get categories stream
  Stream<List<CategoryModel>> getCategories(String type) {
    if (userId == null) return Stream.value([]);
    
    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .where('type', isEqualTo: type)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CategoryModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Get ALL categories (both income + expense) as a Future (for icon lookup)
  Future<List<CategoryModel>> getAllCategories() async {
    if (userId == null) return [];
    final snapshot = await _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .get();
    return snapshot.docs
        .map((doc) => CategoryModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  // Add category
  Future<void> addCategory(CategoryModel category) async {
    if (userId == null) return;
    
    final docRef = _firestore.collection(_collection).doc();
    final newCategory = CategoryModel(
      id: docRef.id,
      userId: userId!,
      name: category.name,
      type: category.type,
      iconCode: category.iconCode,
      colorHex: category.colorHex,
      isDefault: category.isDefault,
    );
    
    await docRef.set(newCategory.toMap());
  }

  // Update category
  Future<void> updateCategory(CategoryModel category) async {
    if (userId == null) return;
    
    await _firestore
        .collection(_collection)
        .doc(category.id)
        .update(category.toMap());
  }

  // Delete category
  Future<void> deleteCategory(String id) async {
    if (userId == null) return;
    
    await _firestore.collection(_collection).doc(id).delete();
  }
}
