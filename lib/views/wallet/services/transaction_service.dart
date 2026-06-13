import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../models/transaction_model.dart';
import '../../../controllers/budget_controller.dart';
import '../../../controllers/goal_controller.dart';

class InsufficientWalletBalanceException implements Exception {
  const InsufficientWalletBalanceException();

  @override
  String toString() => 'Số dư ví không đủ để thực hiện giao dịch';
}

class TransactionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final BudgetController _budgetController = BudgetController();
  final GoalController _goalController = GoalController();

  String get _uid {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Người dùng chưa đăng nhập');
    return user.uid;
  }

  CollectionReference _transactionsRef(String walletId) {
    return _firestore
        .collection('users')
        .doc(_uid)
        .collection('wallets')
        .doc(walletId)
        .collection('transactions');
  }

  DocumentReference _walletRef(String walletId) {
    return _firestore
        .collection('users')
        .doc(_uid)
        .collection('wallets')
        .doc(walletId);
  }

  Stream<List<TransactionModel>> getWalletTransactions(String walletId) {
    return _transactionsRef(walletId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => TransactionModel.fromMap(
                  doc.data() as Map<String, dynamic>,
                  doc.id,
                ),
              )
              .toList(),
        );
  }

  double _applyTransaction(double balance, TransactionModel transaction) {
    return transaction.type == 'income'
        ? balance + transaction.amount
        : balance - transaction.amount;
  }

  double _revertTransaction(double balance, TransactionModel transaction) {
    return transaction.type == 'income'
        ? balance - transaction.amount
        : balance + transaction.amount;
  }

  void _ensureNonNegative(double balance) {
    if (balance < 0) throw const InsufficientWalletBalanceException();
  }

  Future<String?> createTransaction(
    String walletId,
    TransactionModel transaction,
  ) async {
    final txWithWallet = transaction.copyWith(walletId: walletId);
    final transactionRef = _transactionsRef(walletId).doc(txWithWallet.id);
    final walletRef = _walletRef(walletId);

    await _firestore.runTransaction((firestoreTransaction) async {
      final walletDoc = await firestoreTransaction.get(walletRef);
      if (!walletDoc.exists) throw Exception('Không tìm thấy ví');

      final walletData = walletDoc.data() as Map<String, dynamic>;
      final currentBalance = (walletData['balance'] ?? 0).toDouble();
      final newBalance = _applyTransaction(currentBalance, txWithWallet);
      _ensureNonNegative(newBalance);

      firestoreTransaction.set(transactionRef, txWithWallet.toMap());
      firestoreTransaction.update(walletRef, {'balance': newBalance});
    });

    return await _budgetController.recalculateBudget(txWithWallet);
  }

  Future<String?> createTransactionAutoBalance(
    String walletId,
    TransactionModel transaction,
  ) async {
    return await createTransaction(walletId, transaction);
  }

  Future<String?> updateTransaction(
    String walletId,
    TransactionModel oldTx,
    TransactionModel newTx,
  ) async {
    final txWithWallet = newTx.copyWith(walletId: walletId);

    if (oldTx.walletId != walletId && oldTx.walletId.isNotEmpty) {
      final oldWalletRef = _walletRef(oldTx.walletId);
      final newWalletRef = _walletRef(walletId);
      final oldTransactionRef = _transactionsRef(oldTx.walletId).doc(oldTx.id);
      final newTransactionRef = _transactionsRef(walletId).doc(txWithWallet.id);

      await _firestore.runTransaction((firestoreTransaction) async {
        final oldWalletDoc = await firestoreTransaction.get(oldWalletRef);
        final newWalletDoc = await firestoreTransaction.get(newWalletRef);
        if (!oldWalletDoc.exists || !newWalletDoc.exists) {
          throw Exception('Không tìm thấy ví');
        }

        final oldBalance =
            ((oldWalletDoc.data() as Map<String, dynamic>)['balance'] ?? 0)
                .toDouble();
        final newBalance =
            ((newWalletDoc.data() as Map<String, dynamic>)['balance'] ?? 0)
                .toDouble();
        final oldWalletBalance = _revertTransaction(oldBalance, oldTx);
        final newWalletBalance = _applyTransaction(newBalance, txWithWallet);
        _ensureNonNegative(oldWalletBalance);
        _ensureNonNegative(newWalletBalance);

        firestoreTransaction.delete(oldTransactionRef);
        firestoreTransaction.set(newTransactionRef, txWithWallet.toMap());
        firestoreTransaction.update(oldWalletRef, {
          'balance': oldWalletBalance,
        });
        firestoreTransaction.update(newWalletRef, {
          'balance': newWalletBalance,
        });
      });
    } else {
      final walletRef = _walletRef(walletId);
      final transactionRef = _transactionsRef(walletId).doc(txWithWallet.id);

      await _firestore.runTransaction((firestoreTransaction) async {
        final walletDoc = await firestoreTransaction.get(walletRef);
        if (!walletDoc.exists) throw Exception('Không tìm thấy ví');

        final currentBalance =
            ((walletDoc.data() as Map<String, dynamic>)['balance'] ?? 0)
                .toDouble();
        final revertedBalance = _revertTransaction(currentBalance, oldTx);
        final newBalance = _applyTransaction(revertedBalance, txWithWallet);
        _ensureNonNegative(newBalance);

        firestoreTransaction.set(transactionRef, txWithWallet.toMap());
        firestoreTransaction.update(walletRef, {'balance': newBalance});
      });
    }

    await _budgetController.rollbackBudget(oldTx);
    await _goalController.handleTransactionUpdated(txWithWallet);
    return await _budgetController.recalculateBudget(txWithWallet);
  }

  Future<void> deleteTransactionGlobal(TransactionModel tx) async {
    if (tx.walletId.isEmpty) {
      // Legacy: try to find which wallet it belongs to
      final wallets = await _firestore
          .collection('users')
          .doc(_uid)
          .collection('wallets')
          .get();
      for (var w in wallets.docs) {
        final doc = await w.reference
            .collection('transactions')
            .doc(tx.id)
            .get();
        if (doc.exists) {
          await _deleteFromWallet(w.id, tx);
          return;
        }
      }
      throw Exception('Không tìm thấy giao dịch để xóa');
    } else {
      await _deleteFromWallet(tx.walletId, tx);
    }
  }

  Future<void> _deleteFromWallet(String walletId, TransactionModel tx) async {
    final walletRef = _walletRef(walletId);
    final transactionRef = _transactionsRef(walletId).doc(tx.id);

    await _firestore.runTransaction((firestoreTransaction) async {
      final walletDoc = await firestoreTransaction.get(walletRef);
      if (!walletDoc.exists) throw Exception('Không tìm thấy ví');

      final currentBalance =
          ((walletDoc.data() as Map<String, dynamic>)['balance'] ?? 0)
              .toDouble();
      final newBalance = _revertTransaction(currentBalance, tx);
      _ensureNonNegative(newBalance);

      firestoreTransaction.delete(transactionRef);
      firestoreTransaction.update(walletRef, {'balance': newBalance});
    });

    await _budgetController.rollbackBudget(tx);
    await _goalController.handleTransactionDeleted(tx.id);
  }

  Future<List<TransactionModel>> getRecentTransactionsGlobal() async {
    final walletsSnapshot = await _firestore
        .collection('users')
        .doc(_uid)
        .collection('wallets')
        .get();
    List<TransactionModel> allTransactions = [];
    for (var doc in walletsSnapshot.docs) {
      final txSnapshot = await doc.reference
          .collection('transactions')
          .orderBy('createdAt', descending: true)
          .limit(5)
          .get();
      for (var txDoc in txSnapshot.docs) {
        allTransactions.add(TransactionModel.fromMap(txDoc.data(), txDoc.id));
      }
    }
    allTransactions.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return allTransactions.take(5).toList();
  }

  Future<List<TransactionModel>> getAllTransactionsGlobal() async {
    final walletsSnapshot = await _firestore
        .collection('users')
        .doc(_uid)
        .collection('wallets')
        .get();
    List<TransactionModel> allTransactions = [];
    for (var doc in walletsSnapshot.docs) {
      final txSnapshot = await doc.reference
          .collection('transactions')
          .orderBy('createdAt', descending: true)
          .get();
      for (var txDoc in txSnapshot.docs) {
        allTransactions.add(TransactionModel.fromMap(txDoc.data(), txDoc.id));
      }
    }
    allTransactions.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return allTransactions;
  }

  Future<Map<String, double>> getMonthlyTotal(int month, int year) async {
    final txs = await getAllTransactionsGlobal();
    double income = 0;
    double expense = 0;
    for (var tx in txs) {
      if (tx.createdAt.month == month && tx.createdAt.year == year) {
        if (tx.type == 'income') {
          income += tx.amount;
        } else if (tx.type == 'expense') {
          expense += tx.amount;
        }
      }
    }
    return {'income': income, 'expense': expense};
  }
}
