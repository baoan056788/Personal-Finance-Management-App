import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../models/transaction_model.dart';
import '../../../controllers/budget_controller.dart';

class TransactionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final BudgetController _budgetController = BudgetController();

  String get _uid {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Người dùng chưa đăng nhập');
    return user.uid;
  }

  CollectionReference _transactionsRef(String walletId) {
    return _firestore.collection('users').doc(_uid).collection('wallets').doc(walletId).collection('transactions');
  }

  DocumentReference _walletRef(String walletId) {
    return _firestore.collection('users').doc(_uid).collection('wallets').doc(walletId);
  }

  Stream<List<TransactionModel>> getWalletTransactions(String walletId) {
    return _transactionsRef(walletId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TransactionModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  Future<String?> createTransaction(String walletId, TransactionModel transaction, double currentWalletBalance) async {
    final batch = _firestore.batch();

    // 1. Add new transaction (ensure walletId is set)
    final txWithWallet = transaction.walletId.isEmpty 
        ? transaction.copyWith(walletId: walletId) 
        : transaction;
        
    final transactionRef = _transactionsRef(walletId).doc(txWithWallet.id);
    batch.set(transactionRef, txWithWallet.toMap());

    // 2. Update wallet balance
    double newBalance = currentWalletBalance;
    if (txWithWallet.type == 'income') {
      newBalance += txWithWallet.amount;
    } else {
      newBalance -= txWithWallet.amount;
    }

    batch.update(_walletRef(walletId), {'balance': newBalance});

    // Commit batch
    await batch.commit();

    // Hook budget recalculation
    return await _budgetController.recalculateBudget(txWithWallet);
  }

  Future<String?> createTransactionAutoBalance(String walletId, TransactionModel transaction) async {
    final docSnapshot = await _walletRef(walletId).get();
    double currentBalance = 0;
    if (docSnapshot.exists && docSnapshot.data() != null) {
      currentBalance = ((docSnapshot.data() as Map<String, dynamic>)['balance'] ?? 0).toDouble();
    }
    return await createTransaction(walletId, transaction, currentBalance);
  }

  Future<String?> updateTransaction(String walletId, TransactionModel oldTx, TransactionModel newTx) async {
    final batch = _firestore.batch();
    
    // 1. If wallet changed, we need to delete from old and add to new
    if (oldTx.walletId != walletId && oldTx.walletId.isNotEmpty) {
       await deleteTransactionGlobal(oldTx);
       return await createTransactionAutoBalance(walletId, newTx);
    }

    // 2. Update transaction doc
    final transactionRef = _transactionsRef(walletId).doc(newTx.id);
    batch.update(transactionRef, newTx.toMap());

    // 3. Adjust balance if amount or type changed
    if (oldTx.amount != newTx.amount || oldTx.type != newTx.type) {
      final walletDoc = await _walletRef(walletId).get();
      if (walletDoc.exists) {
        double currentBalance = ((walletDoc.data() as Map<String, dynamic>)['balance'] ?? 0).toDouble();
        
        // Revert old
        double adjustedBalance = currentBalance;
        if (oldTx.type == 'income') {
          adjustedBalance -= oldTx.amount;
        } else {
          adjustedBalance += oldTx.amount;
        }
        
        // Apply new
        if (newTx.type == 'income') {
          adjustedBalance += newTx.amount;
        } else {
          adjustedBalance -= newTx.amount;
        }
        
        batch.update(_walletRef(walletId), {'balance': adjustedBalance});
      }
    }
    
    await batch.commit();

    // Hook budget recalculation
    await _budgetController.rollbackBudget(oldTx);
    return await _budgetController.recalculateBudget(newTx);
  }

  Future<void> deleteTransactionGlobal(TransactionModel tx) async {
    if (tx.walletId.isEmpty) {
      // Legacy: try to find which wallet it belongs to
      final wallets = await _firestore.collection('users').doc(_uid).collection('wallets').get();
      for (var w in wallets.docs) {
        final doc = await w.reference.collection('transactions').doc(tx.id).get();
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
    final batch = _firestore.batch();
    
    // 1. Delete transaction
    batch.delete(_transactionsRef(walletId).doc(tx.id));
    
    // 2. Revert balance
    final walletDoc = await _walletRef(walletId).get();
    if (walletDoc.exists) {
      double currentBalance = ((walletDoc.data() as Map<String, dynamic>)['balance'] ?? 0).toDouble();
      double newBalance = currentBalance;
      if (tx.type == 'income') {
        newBalance -= tx.amount;
      } else {
        newBalance += tx.amount;
      }
      batch.update(_walletRef(walletId), {'balance': newBalance});
    }
    
    await batch.commit();

    // Hook budget rollback
    await _budgetController.rollbackBudget(tx);
  }

  Future<List<TransactionModel>> getRecentTransactionsGlobal() async {
    final walletsSnapshot = await _firestore.collection('users').doc(_uid).collection('wallets').get();
    List<TransactionModel> allTransactions = [];
    for (var doc in walletsSnapshot.docs) {
      final txSnapshot = await doc.reference.collection('transactions').orderBy('createdAt', descending: true).limit(5).get();
      for (var txDoc in txSnapshot.docs) {
        allTransactions.add(TransactionModel.fromMap(txDoc.data(), txDoc.id));
      }
    }
    allTransactions.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return allTransactions.take(5).toList();
  }

  Future<List<TransactionModel>> getAllTransactionsGlobal() async {
    final walletsSnapshot = await _firestore.collection('users').doc(_uid).collection('wallets').get();
    List<TransactionModel> allTransactions = [];
    for (var doc in walletsSnapshot.docs) {
      final txSnapshot = await doc.reference.collection('transactions').orderBy('createdAt', descending: true).get();
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
