import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/budget_model.dart';
import '../models/transaction_model.dart';

class BudgetController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'budgets';
  String? get userId => FirebaseAuth.instance.currentUser?.uid;

  // Helpers to calculate progress and status
  Map<String, dynamic> _calculateBudgetStatus(double limit, double spent) {
    double remain = limit - spent;
    double progress = limit > 0 ? (spent / limit) : 0.0;
    
    String status = 'SAFE';
    if (progress > 1.0) {
      status = 'OVER_LIMIT';
    } else if (progress >= 0.9) {
      status = 'DANGER';
    } else if (progress >= 0.8) {
      status = 'WARNING';
    }

    return {
      'remainAmount': remain,
      'progressPercent': progress,
      'status': status,
    };
  }

  Future<bool> _isBudgetExists(String categoryId, DateTime start, DateTime end, {String? excludeBudgetId}) async {
    final uid = userId;
    if (uid == null) return false;
    
    final snapshot = await _firestore
        .collection(_collection)
        .where('userId', isEqualTo: uid)
        .where('categoryId', isEqualTo: categoryId)
        .get();
        
    for (var doc in snapshot.docs) {
      // Bỏ qua chính budget đang chỉnh sửa
      if (excludeBudgetId != null && doc.id == excludeBudgetId) continue;
      
      final b = BudgetModel.fromMap(doc.data(), doc.id);
      
      // Check for overlap: newStart <= oldEnd AND newEnd >= oldStart
      DateTime newStart = start;
      DateTime newEnd = end;
      DateTime oldStart = b.startDate;
      DateTime oldEnd = b.endDate;
      
      bool isOverlapping = (newStart.isBefore(oldEnd) || newStart.isAtSameMomentAs(oldEnd)) && 
                           (newEnd.isAfter(oldStart) || newEnd.isAtSameMomentAs(oldStart));
                           
      if (isOverlapping) return true;
    }
    return false;
  }

  // Helper to recalculate EVERYTHING for a budget
  Future<BudgetModel> _calculateBudgetFromScratch(BudgetModel budget) async {
    final uid = userId;
    if (uid == null) return budget;

    final walletsSnapshot = await _firestore
        .collection('users')
        .doc(uid)
        .collection('wallets')
        .get();

    double totalSpent = 0.0;

    for (var walletDoc in walletsSnapshot.docs) {
      final txSnapshot = await walletDoc.reference
          .collection('transactions')
          .where('type', isEqualTo: 'expense')
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(budget.startDate))
          .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(budget.endDate))
          .get();

      for (var txDoc in txSnapshot.docs) {
        final tx = TransactionModel.fromMap(txDoc.data(), txDoc.id);
        
        final catId = _getValidCategoryId(tx);
        if (catId == budget.categoryId) {
          totalSpent += tx.amount;
        }
      }
    }

    final calc = _calculateBudgetStatus(budget.limitAmount, totalSpent);
    
    return budget.copyWith(
      spentAmount: totalSpent,
      remainAmount: calc['remainAmount'],
      progressPercent: calc['progressPercent'],
      status: calc['status'],
      updatedAt: DateTime.now(),
    );
  }

  // Khai báo hàm public như user yêu cầu
  Future<void> recalculateBudgetModel(BudgetModel budget) async {
    final updatedBudget = await _calculateBudgetFromScratch(budget);
    if (updatedBudget.id.isNotEmpty) {
      await _firestore.collection(_collection).doc(updatedBudget.id).update(updatedBudget.toMap());
    }
  }

  // Create Budget
  Future<void> createBudget(BudgetModel budget) async {
    if (userId == null) return;
    
    bool exists = await _isBudgetExists(budget.categoryId, budget.startDate, budget.endDate);
    if (exists) {
      throw Exception('Ngân sách cho danh mục này đã tồn tại trong khoảng thời gian đã chọn!');
    }
    
    final docRef = _firestore.collection(_collection).doc();
    
    final newBudget = budget.copyWith(
      id: docRef.id,
      userId: userId!,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    
    // Tính lại từ đầu
    final finalBudget = await _calculateBudgetFromScratch(newBudget);
    
    await docRef.set(finalBudget.toMap());
  }

  // Update Budget
  Future<void> updateBudget(BudgetModel budget) async {
    if (userId == null) return;
    
    bool exists = await _isBudgetExists(budget.categoryId, budget.startDate, budget.endDate, excludeBudgetId: budget.id);
    if (exists) {
      throw Exception('Ngân sách cho danh mục này đã tồn tại trong khoảng thời gian đã chọn!');
    }
    
    // Tính lại từ đầu toàn bộ
    final finalBudget = await _calculateBudgetFromScratch(budget);
    
    await _firestore
        .collection(_collection)
        .doc(finalBudget.id)
        .update(finalBudget.toMap());
  }

  // Delete Budget
  Future<void> deleteBudget(String id) async {
    if (userId == null) return;
    await _firestore.collection(_collection).doc(id).delete();
  }

  // Get Budgets Stream
  Stream<List<BudgetModel>> getBudgets() {
    if (userId == null) return Stream.value([]);
    
    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
           final list = snapshot.docs
              .map((doc) => BudgetModel.fromMap(doc.data(), doc.id))
              .toList();
           list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
           return list;
        });
  }

  // Get Budget by ID
  Future<BudgetModel?> getBudgetById(String id) async {
    final doc = await _firestore.collection(_collection).doc(id).get();
    if (doc.exists && doc.data() != null) {
      return BudgetModel.fromMap(doc.data()!, doc.id);
    }
    return null;
  }
  
  // Find Active Budget for a given Category and Date
  Future<BudgetModel?> _findActiveBudgetForCategory(String categoryId, DateTime date) async {
    if (userId == null) return null;
    
    final snapshot = await _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .where('categoryId', isEqualTo: categoryId)
        .get();
        
    for (var doc in snapshot.docs) {
      final budget = BudgetModel.fromMap(doc.data(), doc.id);
      // Check if date falls within budget period
      if ((date.isAfter(budget.startDate) || date.isAtSameMomentAs(budget.startDate)) &&
          (date.isBefore(budget.endDate) || date.isAtSameMomentAs(budget.endDate))) {
        return budget;
      }
    }
    return null;
  }

  String? _getValidCategoryId(TransactionModel tx) {
    if (tx.categoryId != null && tx.categoryId!.isNotEmpty) {
      return tx.categoryId;
    }
    if (tx.category.isNotEmpty && !tx.category.contains(' ') && tx.category.length > 15) {
      return tx.category; // Legacy support
    }
    return null;
  }

  // Hook for Transaction Lifecycle: Recalculate (add expense)
  Future<String?> recalculateBudget(TransactionModel tx) async {
    if (tx.type != 'expense') return null;
    final catId = _getValidCategoryId(tx);
    if (catId == null) return null;
    
    final budget = await _findActiveBudgetForCategory(catId, tx.createdAt);
    if (budget != null) {
      final updatedBudget = await _calculateBudgetFromScratch(budget);
      await _firestore.collection(_collection).doc(updatedBudget.id).update(updatedBudget.toMap());
      return checkBudgetWarning(updatedBudget);
    }
    return null;
  }

  // Hook for Transaction Lifecycle: Rollback (remove expense)
  Future<void> rollbackBudget(TransactionModel tx) async {
    if (tx.type != 'expense') return;
    final catId = _getValidCategoryId(tx);
    if (catId == null) return;
    
    final budget = await _findActiveBudgetForCategory(catId, tx.createdAt);
    if (budget != null) {
      final updatedBudget = await _calculateBudgetFromScratch(budget);
      await _firestore.collection(_collection).doc(updatedBudget.id).update(updatedBudget.toMap());
    }
  }

  // Check budget warning and return warning message if needed
  String? checkBudgetWarning(BudgetModel budget) {
    if (budget.status == 'OVER_LIMIT') {
      return "Ngân sách ${budget.name} đã vượt mức giới hạn!";
    } else if (budget.status == 'DANGER') {
      return "Ngân sách ${budget.name} đã đạt trên 90%!";
    } else if (budget.status == 'WARNING') {
      return "Ngân sách ${budget.name} đã đạt trên 80%!";
    }
    return null;
  }
}
