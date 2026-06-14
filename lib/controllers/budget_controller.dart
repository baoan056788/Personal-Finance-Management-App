import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/budget_model.dart';
import '../models/transaction_model.dart';
import '../utils/budget_calculator.dart';

class BudgetController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'budgets';
  String? get userId => FirebaseAuth.instance.currentUser?.uid;

  Future<bool> _isBudgetExists(
    String categoryId,
    DateTime start,
    DateTime end, {
    String? walletId,
    String? excludeBudgetId,
  }) async {
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
      if (b.walletId != walletId) continue;

      // Check for overlap: newStart <= oldEnd AND newEnd >= oldStart
      DateTime newStart = start;
      DateTime newEnd = end;
      DateTime oldStart = b.startDate;
      DateTime oldEnd = b.endDate;

      bool isOverlapping =
          (newStart.isBefore(oldEnd) || newStart.isAtSameMomentAs(oldEnd)) &&
          (newEnd.isAfter(oldStart) || newEnd.isAtSameMomentAs(oldStart));

      if (isOverlapping) return true;
    }
    return false;
  }

  // Helper to recalculate EVERYTHING for a budget
  Future<BudgetModel> _calculateBudgetFromScratch(BudgetModel budget) async {
    final uid = userId;
    if (uid == null) return budget;

    final walletsCollection = _firestore
        .collection('users')
        .doc(uid)
        .collection('wallets');
    final walletDocuments = budget.walletId == null
        ? (await walletsCollection.get()).docs
        : [
            await walletsCollection.doc(budget.walletId).get(),
          ].where((document) => document.exists).toList();

    final transactionSnapshots = await Future.wait(
      walletDocuments.map((walletDoc) {
        return walletDoc.reference
            .collection('transactions')
            .where(
              'createdAt',
              isGreaterThanOrEqualTo: Timestamp.fromDate(budget.startDate),
            )
            .where(
              'createdAt',
              isLessThanOrEqualTo: Timestamp.fromDate(budget.endDate),
            )
            .get();
      }),
    );

    double totalSpent = 0.0;
    for (final txSnapshot in transactionSnapshots) {
      for (var txDoc in txSnapshot.docs) {
        final tx = TransactionModel.fromMap(txDoc.data(), txDoc.id);
        if (tx.isExpense &&
            budgetCategoryIdForTransaction(tx) == budget.categoryId) {
          totalSpent += tx.amount.abs();
        }
      }
    }

    final calculation = calculateBudget(budget.limitAmount, totalSpent);

    return budget.copyWith(
      spentAmount: calculation.spentAmount,
      remainAmount: calculation.remainAmount,
      progressPercent: calculation.progressPercent,
      status: calculation.status,
      updatedAt: DateTime.now(),
    );
  }

  // Khai báo hàm public như user yêu cầu
  Future<void> recalculateBudgetModel(BudgetModel budget) async {
    final updatedBudget = await _calculateBudgetFromScratch(budget);
    if (updatedBudget.id.isNotEmpty) {
      await _firestore
          .collection(_collection)
          .doc(updatedBudget.id)
          .update(updatedBudget.toMap());
    }
  }

  // Create Budget
  Future<void> createBudget(BudgetModel budget) async {
    if (userId == null) return;

    bool exists = await _isBudgetExists(
      budget.categoryId,
      budget.startDate,
      budget.endDate,
      walletId: budget.walletId,
    );
    if (exists) {
      throw Exception(
        'Ngân sách cho danh mục này đã tồn tại trong khoảng thời gian đã chọn!',
      );
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

    bool exists = await _isBudgetExists(
      budget.categoryId,
      budget.startDate,
      budget.endDate,
      walletId: budget.walletId,
      excludeBudgetId: budget.id,
    );
    if (exists) {
      throw Exception(
        'Ngân sách cho danh mục này đã tồn tại trong khoảng thời gian đã chọn!',
      );
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
    final uid = userId;
    if (uid == null) return null;
    final doc = await _firestore.collection(_collection).doc(id).get();
    if (doc.exists && doc.data() != null) {
      final budget = BudgetModel.fromMap(doc.data()!, doc.id);
      return budget.userId == uid ? budget : null;
    }
    return null;
  }

  Stream<BudgetModel?> watchBudgetById(String id) {
    final uid = userId;
    if (uid == null) return Stream.value(null);

    return _firestore.collection(_collection).doc(id).snapshots().map((doc) {
      final data = doc.data();
      if (!doc.exists || data == null) return null;
      final budget = BudgetModel.fromMap(data, doc.id);
      return budget.userId == uid ? budget : null;
    });
  }

  Future<List<BudgetModel>> _findActiveBudgetsForTransaction(
    TransactionModel transaction,
  ) async {
    if (userId == null) return [];
    final categoryId = budgetCategoryIdForTransaction(transaction);
    if (categoryId == null) return [];

    final snapshot = await _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .where('categoryId', isEqualTo: categoryId)
        .get();

    final budgets = <BudgetModel>[];
    for (var doc in snapshot.docs) {
      final budget = BudgetModel.fromMap(doc.data(), doc.id);
      if (transactionCountsTowardBudget(budget, transaction)) {
        budgets.add(budget);
      }
    }
    return budgets;
  }

  // Hook for Transaction Lifecycle: Recalculate (add expense)
  Future<String?> recalculateBudget(TransactionModel tx) async {
    return syncTransactionChange(current: tx);
  }

  // Hook for Transaction Lifecycle: Rollback (remove expense)
  Future<void> rollbackBudget(TransactionModel tx) async {
    await syncTransactionChange(previous: tx);
  }

  Future<String?> syncTransactionChange({
    TransactionModel? previous,
    TransactionModel? current,
  }) async {
    final transactions = [previous, current]
        .whereType<TransactionModel>()
        .where((transaction) => transaction.isExpense)
        .toList();
    if (transactions.isEmpty) return null;

    final matchingBudgetGroups = await Future.wait(
      transactions.map(_findActiveBudgetsForTransaction),
    );

    final uniqueBudgets = <String, BudgetModel>{};
    for (final budgets in matchingBudgetGroups) {
      for (final budget in budgets) {
        uniqueBudgets[budget.id] = budget;
      }
    }
    if (uniqueBudgets.isEmpty) return null;

    final updatedBudgets = await Future.wait(
      uniqueBudgets.values.map(_calculateBudgetFromScratch),
    );
    final batch = _firestore.batch();
    for (final budget in updatedBudgets) {
      batch.update(
        _firestore.collection(_collection).doc(budget.id),
        budget.toMap(),
      );
    }
    await batch.commit();

    if (current == null || !current.isExpense) return null;
    final currentCategoryId = budgetCategoryIdForTransaction(current);
    for (final budget in updatedBudgets) {
      if (budget.categoryId == currentCategoryId &&
          (budget.walletId == null || budget.walletId == current.walletId) &&
          isWithinBudgetPeriod(
            current.createdAt,
            budget.startDate,
            budget.endDate,
          )) {
        return checkBudgetWarning(budget);
      }
    }
    return null;
  }

  // Check budget warning and return warning message if needed
  String? checkBudgetWarning(BudgetModel budget) {
    if (budget.status == 'OVER_LIMIT') {
      return "Ngân sách ${budget.name} đã vượt mức giới hạn!";
    } else if (budget.status == 'DANGER') {
      return "Ngân sách ${budget.name} đã đạt từ 90%!";
    } else if (budget.status == 'WARNING') {
      return "Ngân sách ${budget.name} đã đạt từ 80%!";
    }
    return null;
  }
}
