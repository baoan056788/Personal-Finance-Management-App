import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/recurring_transaction_model.dart';

class RecurringTransactionController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'recurring_transactions';

  String? get userId => FirebaseAuth.instance.currentUser?.uid;

  Stream<List<RecurringTransactionModel>> getRecurringTransactions() {
    if (userId == null) return Stream.value([]);
    
    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs
              .map((doc) => RecurringTransactionModel.fromMap(doc.data(), doc.id))
              .toList();
          list.sort((a, b) => a.nextDueDate.compareTo(b.nextDueDate));
          return list;
        });
  }

  Future<void> addRecurringTransaction(RecurringTransactionModel transaction) async {
    if (userId == null) return;
    
    final docRef = _firestore.collection(_collection).doc();
    final newTransaction = RecurringTransactionModel(
      id: docRef.id,
      userId: userId!,
      name: transaction.name,
      amount: transaction.amount,
      type: transaction.type,
      categoryId: transaction.categoryId,
      walletId: transaction.walletId,
      frequency: transaction.frequency,
      nextDueDate: transaction.nextDueDate,
      createdAt: DateTime.now(),
      endDate: transaction.endDate,
      imageUrl: transaction.imageUrl,
    );
    
    await docRef.set(newTransaction.toMap());
  }

  Future<void> deleteRecurringTransaction(String id) async {
    await _firestore.collection(_collection).doc(id).delete();
  }

  Future<void> updateRecurringTransaction(RecurringTransactionModel transaction) async {
    await _firestore
        .collection(_collection)
        .doc(transaction.id)
        .update(transaction.toMap());
  }

  Future<void> updateNextDueDate(String id, DateTime nextDate) async {
    await _firestore
        .collection(_collection)
        .doc(id)
        .update({'nextDueDate': Timestamp.fromDate(nextDate)});
  }
}
