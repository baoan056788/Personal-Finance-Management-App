import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../models/transaction_model.dart';

class TransactionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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

  Future<void> createTransaction(String walletId, TransactionModel transaction, double currentWalletBalance) async {
    final batch = _firestore.batch();

    // 1. Add new transaction
    final transactionRef = _transactionsRef(walletId).doc(transaction.id);
    batch.set(transactionRef, transaction.toMap());

    // 2. Update wallet balance
    double newBalance = currentWalletBalance;
    if (transaction.type == 'income') {
      newBalance += transaction.amount;
    } else {
      newBalance -= transaction.amount;
    }

    batch.update(_walletRef(walletId), {'balance': newBalance});

    // Commit batch
    await batch.commit();
  }
}

