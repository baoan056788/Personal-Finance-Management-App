import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/goal_model.dart';
import '../models/goal_contribution_model.dart';
import '../models/transaction_model.dart';
import 'category_controller.dart';

class GoalController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CategoryController _categoryController = CategoryController();
  
  String get _uid {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Người dùng chưa đăng nhập');
    return user.uid;
  }

  // Collection References
  CollectionReference get _goalsRef => _firestore.collection('goals');
  CollectionReference get _contributionsRef => _firestore.collection('goal_contributions');

  // Helper: Get users/{uid}/wallets
  CollectionReference _walletsRef() => _firestore.collection('users').doc(_uid).collection('wallets');

  // RECALCULATE FROM SCRATCH
  Future<GoalModel> _calculateGoalFromScratch(String goalId, {Transaction? transaction}) async {
    final goalDoc = transaction != null 
        ? await transaction.get(_goalsRef.doc(goalId))
        : await _goalsRef.doc(goalId).get();

    if (!goalDoc.exists) throw Exception('Goal không tồn tại');
    final goal = GoalModel.fromMap(goalDoc.data() as Map<String, dynamic>, goalDoc.id);

    // Query all contributions
    final snapshot = await _contributionsRef
        .where('goalId', isEqualTo: goalId)
        .get();

    double totalAmount = 0;
    for (var doc in snapshot.docs) {
      final contribution = GoalContributionModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      totalAmount += contribution.amount;
    }

    double remain = goal.targetAmount - totalAmount;
    if (remain < 0) remain = 0;

    double progress = goal.targetAmount > 0 ? (totalAmount / goal.targetAmount) : 0;

    // Status logic
    // < 80% -> ON_GOING
    // >= 80% and < 100% -> NEAR_TARGET
    // >= 100% -> COMPLETED
    // expired -> FAILED
    String status = 'ON_GOING';
    if (totalAmount >= goal.targetAmount) {
      status = 'COMPLETED';
    } else if (DateTime.now().isAfter(goal.targetDate)) {
      status = 'FAILED';
    } else if (progress >= 0.8) {
      status = 'NEAR_TARGET';
    }

    return goal.copyWith(
      currentAmount: totalAmount,
      remainAmount: remain,
      progressPercent: progress,
      status: status,
      updatedAt: DateTime.now(),
    );
  }

  // Create Goal
  Future<void> createGoal(GoalModel goal) async {
    final docRef = _goalsRef.doc();
    final newGoal = goal.copyWith(
      id: docRef.id,
      userId: _uid,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      status: 'ON_GOING',
      currentAmount: 0,
      remainAmount: goal.targetAmount,
      progressPercent: 0,
    );
    await docRef.set(newGoal.toMap());
  }

  // Update Goal Details (Not Amount)
  Future<void> updateGoal(GoalModel goal) async {
    if (goal.userId != _uid) return;
    
    // Recalculate in case targetAmount changed
    final updatedGoal = await _calculateGoalFromScratch(goal.id);
    final finalGoal = updatedGoal.copyWith(
      name: goal.name,
      targetAmount: goal.targetAmount,
      targetDate: goal.targetDate,
      note: goal.note,
      iconCode: goal.iconCode,
      colorHex: goal.colorHex,
    );
    
    // Recalculate again with the new targetAmount
    double remain = finalGoal.targetAmount - finalGoal.currentAmount;
    if (remain < 0) remain = 0;
    double progress = finalGoal.targetAmount > 0 ? (finalGoal.currentAmount / finalGoal.targetAmount) : 0;
    String status = 'ON_GOING';
    if (finalGoal.currentAmount >= finalGoal.targetAmount) {
      status = 'COMPLETED';
    } else if (DateTime.now().isAfter(finalGoal.targetDate)) {
      status = 'FAILED';
    } else if (progress >= 0.8) {
      status = 'NEAR_TARGET';
    }

    final savedGoal = finalGoal.copyWith(
      remainAmount: remain,
      progressPercent: progress,
      status: status,
    );

    await _goalsRef.doc(savedGoal.id).update(savedGoal.toMap());
  }

  // Delete Goal
  Future<void> deleteGoal(String id) async {
    // 1. Get all contributions
    final snapshot = await _contributionsRef.where('goalId', isEqualTo: id).get();
    
    // 2. We should ideally refund the wallets and delete transactions, 
    // but the user only mentioned deleting the goal and its contributions. 
    // Let's delete contributions and the goal. The transactions remain as valid expense history unless we want to rollback.
    // If they want to rollback, they should delete contributions. For now we just batch delete.
    final batch = _firestore.batch();
    for (var doc in snapshot.docs) {
      batch.delete(doc.reference);
      // Wait, we should probably let the user manually delete contributions to get refunds,
      // or we just delete them. We will just delete the contributions here.
    }
    batch.delete(_goalsRef.doc(id));
    await batch.commit();
  }

  // Add Contribution (Atomic Flow)
  Future<void> addContribution({
    required String goalId,
    required String walletId,
    required double amount,
    required String note,
  }) async {
    if (amount <= 0) throw Exception('Số tiền phải lớn hơn 0');

    final savingCategory = await _categoryController.getOrCreateSavingCategory();

    await _firestore.runTransaction((transaction) async {
      final walletDocRef = _walletsRef().doc(walletId);
      final walletSnap = await transaction.get(walletDocRef);
      if (!walletSnap.exists) throw Exception('Ví không tồn tại');

      final walletData = walletSnap.data() as Map<String, dynamic>;
      final currentBalance = (walletData['balance'] ?? 0.0).toDouble();

      if (currentBalance < amount) {
        throw Exception('Số dư ví không đủ');
      }

      // 1. Update wallet balance
      transaction.update(walletDocRef, {
        'balance': currentBalance - amount,
      });

      // 2. Create expense transaction
      final txDocRef = walletDocRef.collection('transactions').doc();
      final txData = {
        'id': txDocRef.id,
        'amount': amount,
        'categoryId': savingCategory.id,
        'category': savingCategory.name,
        'type': 'expense',
        'note': 'Góp mục tiêu: $note',
        'createdAt': FieldValue.serverTimestamp(),
        'walletId': walletId,
      };
      transaction.set(txDocRef, txData);

      // 3. Create goal contribution
      final contributionRef = _contributionsRef.doc();
      final contribution = GoalContributionModel(
        id: contributionRef.id,
        goalId: goalId,
        walletId: walletId,
        transactionId: txDocRef.id,
        amount: amount,
        note: note,
        createdAt: DateTime.now(),
      );
      transaction.set(contributionRef, contribution.toMap());

      // 4. Recalculate goal (we must do this AFTER transaction commits, 
      // but to do it atomically we'd need to query inside transaction. 
      // Firestore transactions can't query collections easily if they conflict. 
      // However, we can just do the recalculation normally because we added it.)
    });

    // We do Recalculate From Scratch after the atomic commit to ensure accurate read.
    // This avoids transaction read limits.
    final updatedGoal = await _calculateGoalFromScratch(goalId);
    await _goalsRef.doc(goalId).update(updatedGoal.toMap());
  }

  // Hook: When a transaction is updated from the general transaction flow
  Future<void> handleTransactionUpdated(TransactionModel tx) async {
    // Find if this transaction is a contribution
    final snapshot = await _contributionsRef
        .where('transactionId', isEqualTo: tx.id)
        .limit(1)
        .get();
        
    if (snapshot.docs.isNotEmpty) {
      final doc = snapshot.docs.first;
      final contribution = GoalContributionModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      
      // Update contribution amount
      await doc.reference.update({
        'amount': tx.amount,
      });
      
      // Recalculate Goal
      final updatedGoal = await _calculateGoalFromScratch(contribution.goalId);
      await _goalsRef.doc(contribution.goalId).update(updatedGoal.toMap());
    }
  }

  // Hook: When a transaction is deleted from the general transaction flow
  Future<void> handleTransactionDeleted(String txId) async {
    final snapshot = await _contributionsRef
        .where('transactionId', isEqualTo: txId)
        .limit(1)
        .get();
        
    if (snapshot.docs.isNotEmpty) {
      final doc = snapshot.docs.first;
      final contribution = GoalContributionModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      
      // Delete contribution
      await doc.reference.delete();
      
      // Recalculate Goal
      final updatedGoal = await _calculateGoalFromScratch(contribution.goalId);
      await _goalsRef.doc(contribution.goalId).update(updatedGoal.toMap());
    }
  }

  // Stream Goals
  Stream<List<GoalModel>> getGoals() {
    return _goalsRef
        .where('userId', isEqualTo: _uid)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) => GoalModel.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList();
        });
  }

  // Stream Contributions for a goal
  Stream<List<GoalContributionModel>> getContributions(String goalId) {
    return _contributionsRef
        .where('goalId', isEqualTo: goalId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) => GoalContributionModel.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList();
        });
  }
}
