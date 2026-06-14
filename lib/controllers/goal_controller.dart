import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/goal_contribution_model.dart';
import '../models/goal_model.dart';
import '../models/transaction_model.dart';
import 'budget_controller.dart';
import 'category_controller.dart';

class GoalController {
  GoalController({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  final BudgetController _budgetController = BudgetController();
  final CategoryController _categoryController = CategoryController();

  String get _uid {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Người dùng chưa đăng nhập');
    return user.uid;
  }

  CollectionReference<Map<String, dynamic>> get _goalsRef =>
      _firestore.collection('goals');

  CollectionReference<Map<String, dynamic>> get _contributionsRef =>
      _firestore.collection('goal_contributions');

  CollectionReference<Map<String, dynamic>> get _walletsRef =>
      _firestore.collection('users').doc(_uid).collection('wallets');

  Map<String, dynamic> _goalProgressUpdate(
    GoalModel goal,
    double currentAmount,
  ) {
    final safeCurrent = currentAmount < 0 ? 0.0 : currentAmount;
    final remain = (goal.targetAmount - safeCurrent).clamp(
      0.0,
      double.infinity,
    );
    final progress = goal.targetAmount > 0
        ? safeCurrent / goal.targetAmount
        : 0.0;
    final now = DateTime.now();
    final status = safeCurrent >= goal.targetAmount
        ? 'COMPLETED'
        : now.isAfter(goal.targetDate)
        ? 'FAILED'
        : progress >= 0.8
        ? 'NEAR_TARGET'
        : 'ON_GOING';
    return {
      'currentAmount': safeCurrent,
      'remainAmount': remain,
      'progressPercent': progress,
      'status': status,
      'updatedAt': Timestamp.fromDate(now),
    };
  }

  Future<GoalModel> _calculateGoalFromScratch(String goalId) async {
    final goalDoc = await _goalsRef.doc(goalId).get();
    if (!goalDoc.exists || goalDoc.data() == null) {
      throw Exception('Mục tiêu không tồn tại');
    }
    final goal = GoalModel.fromMap(goalDoc.data()!, goalDoc.id);
    final snapshot = await _contributionsRef
        .where('goalId', isEqualTo: goalId)
        .get();
    final total = snapshot.docs.fold<double>(
      0,
      (total, doc) =>
          total + GoalContributionModel.fromMap(doc.data(), doc.id).amount,
    );
    final update = _goalProgressUpdate(goal, total);
    return goal.copyWith(
      currentAmount: (update['currentAmount'] as num).toDouble(),
      remainAmount: (update['remainAmount'] as num).toDouble(),
      progressPercent: (update['progressPercent'] as num).toDouble(),
      status: update['status'] as String,
      updatedAt: (update['updatedAt'] as Timestamp).toDate(),
    );
  }

  Future<void> createGoal(GoalModel goal) async {
    final docRef = _goalsRef.doc();
    final now = DateTime.now();
    await docRef.set(
      goal
          .copyWith(
            id: docRef.id,
            userId: _uid,
            createdAt: now,
            updatedAt: now,
            status: 'ON_GOING',
            currentAmount: 0,
            remainAmount: goal.targetAmount,
            progressPercent: 0,
          )
          .toMap(),
    );
  }

  Future<void> updateGoal(GoalModel goal) async {
    if (goal.userId != _uid) throw Exception('Không có quyền sửa mục tiêu');
    final current = await _calculateGoalFromScratch(goal.id);
    final edited = current.copyWith(
      name: goal.name,
      targetAmount: goal.targetAmount,
      targetDate: goal.targetDate,
      note: goal.note,
      iconCode: goal.iconCode,
      colorHex: goal.colorHex,
    );
    await _goalsRef.doc(goal.id).update({
      ...edited.toMap(),
      ..._goalProgressUpdate(edited, current.currentAmount),
    });
  }

  Future<void> deleteGoal(String id) async {
    final goalDoc = await _goalsRef.doc(id).get();
    if (!goalDoc.exists || goalDoc.data() == null) return;
    final goal = GoalModel.fromMap(goalDoc.data()!, goalDoc.id);
    if (goal.userId != _uid) throw Exception('Không có quyền xóa mục tiêu');
    if (goal.currentAmount > 0.001) {
      throw Exception('Hãy rút toàn bộ tiền trước khi xóa mục tiêu');
    }

    final contributions = await _contributionsRef
        .where('goalId', isEqualTo: id)
        .get();
    final batch = _firestore.batch();
    for (final doc in contributions.docs) {
      final item = GoalContributionModel.fromMap(doc.data(), doc.id);
      if (item.walletId.isNotEmpty && item.transactionId.isNotEmpty) {
        batch.delete(
          _walletsRef
              .doc(item.walletId)
              .collection('transactions')
              .doc(item.transactionId),
        );
      }
      batch.delete(doc.reference);
    }
    batch.delete(goalDoc.reference);
    await batch.commit();
  }

  Future<void> addContribution({
    required String goalId,
    required String walletId,
    required double amount,
    required String note,
  }) async {
    await _moveGoalMoney(
      goalId: goalId,
      walletId: walletId,
      amount: amount,
      note: note,
      isWithdrawal: false,
    );
  }

  Future<void> withdrawContribution({
    required String goalId,
    required String walletId,
    required double amount,
    required String note,
  }) async {
    await _moveGoalMoney(
      goalId: goalId,
      walletId: walletId,
      amount: amount,
      note: note,
      isWithdrawal: true,
    );
  }

  Future<void> _moveGoalMoney({
    required String goalId,
    required String walletId,
    required double amount,
    required String note,
    required bool isWithdrawal,
  }) async {
    if (!amount.isFinite || amount <= 0) {
      throw Exception('Số tiền phải lớn hơn 0');
    }
    final goalRef = _goalsRef.doc(goalId);
    final walletRef = _walletsRef.doc(walletId);
    final transactionRef = walletRef.collection('transactions').doc();
    final contributionRef = _contributionsRef.doc();
    final savingCategory = await _categoryController
        .getOrCreateSavingCategory();
    late TransactionModel movementTransaction;

    await _firestore.runTransaction((transaction) async {
      final goalSnapshot = await transaction.get(goalRef);
      final walletSnapshot = await transaction.get(walletRef);
      if (!goalSnapshot.exists || goalSnapshot.data() == null) {
        throw Exception('Mục tiêu không tồn tại');
      }
      if (!walletSnapshot.exists || walletSnapshot.data() == null) {
        throw Exception('Ví không tồn tại');
      }

      final goal = GoalModel.fromMap(goalSnapshot.data()!, goalSnapshot.id);
      if (goal.userId != _uid) throw Exception('Không có quyền sửa mục tiêu');
      final walletBalance = (walletSnapshot.data()!['balance'] ?? 0).toDouble();

      if (isWithdrawal && amount > goal.currentAmount + 0.001) {
        throw Exception('Số tiền rút vượt quá số đã tích lũy');
      }
      if (!isWithdrawal && amount > goal.remainAmount + 0.001) {
        throw Exception('Số tiền nạp vượt quá phần còn thiếu của mục tiêu');
      }
      if (!isWithdrawal && walletBalance < amount) {
        throw Exception('Số dư ví không đủ');
      }

      final nextBalance = isWithdrawal
          ? walletBalance + amount
          : walletBalance - amount;
      final nextGoalAmount = isWithdrawal
          ? goal.currentAmount - amount
          : goal.currentAmount + amount;
      final now = DateTime.now();
      final signedAmount = isWithdrawal ? -amount : amount;
      final actionLabel = isWithdrawal ? 'Rút từ mục tiêu' : 'Nạp mục tiêu';

      transaction.update(walletRef, {'balance': nextBalance});
      transaction.update(goalRef, _goalProgressUpdate(goal, nextGoalAmount));
      movementTransaction = TransactionModel(
        id: transactionRef.id,
        amount: amount,
        type: 'goal',
        category: savingCategory.name,
        categoryId: savingCategory.id,
        note: note.isEmpty ? '$actionLabel: ${goal.name}' : note,
        createdAt: now,
        walletId: walletId,
        cashFlowDirection: isWithdrawal ? 'in' : 'out',
        referenceId: goalId,
      );
      transaction.set(transactionRef, movementTransaction.toMap());
      transaction.set(
        contributionRef,
        GoalContributionModel(
          id: contributionRef.id,
          goalId: goalId,
          walletId: walletId,
          transactionId: transactionRef.id,
          amount: signedAmount,
          note: note,
          createdAt: now,
          type: isWithdrawal ? 'withdrawal' : 'deposit',
        ).toMap(),
      );
    });

    await _budgetController.syncTransactionChange(current: movementTransaction);
  }

  Future<void> handleTransactionUpdated(TransactionModel transaction) async {
    final snapshot = await _contributionsRef
        .where('transactionId', isEqualTo: transaction.id)
        .limit(1)
        .get();
    if (snapshot.docs.isEmpty) return;
    final doc = snapshot.docs.first;
    final contribution = GoalContributionModel.fromMap(doc.data(), doc.id);
    final signedAmount = contribution.isWithdrawal
        ? -transaction.amount
        : transaction.amount;
    await doc.reference.update({
      'amount': signedAmount,
      'walletId': transaction.walletId,
    });
    final goal = await _calculateGoalFromScratch(contribution.goalId);
    await _goalsRef.doc(goal.id).update(goal.toMap());
  }

  Future<void> handleTransactionDeleted(TransactionModel transaction) async {
    final snapshot = await _contributionsRef
        .where('transactionId', isEqualTo: transaction.id)
        .limit(1)
        .get();
    if (snapshot.docs.isEmpty) return;
    final doc = snapshot.docs.first;
    final contribution = GoalContributionModel.fromMap(doc.data(), doc.id);
    await doc.reference.delete();
    final goalDoc = await _goalsRef.doc(contribution.goalId).get();
    if (!goalDoc.exists) return;
    final goal = await _calculateGoalFromScratch(contribution.goalId);
    await _goalsRef.doc(goal.id).update(goal.toMap());
  }

  Stream<List<GoalModel>> getGoals() {
    return _goalsRef.where('userId', isEqualTo: _uid).snapshots().map((
      snapshot,
    ) {
      final goals = snapshot.docs
          .map((doc) => GoalModel.fromMap(doc.data(), doc.id))
          .toList();
      goals.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return goals;
    });
  }

  Stream<List<GoalContributionModel>> getContributions(String goalId) {
    return _contributionsRef
        .where('goalId', isEqualTo: goalId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => GoalContributionModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }
}
