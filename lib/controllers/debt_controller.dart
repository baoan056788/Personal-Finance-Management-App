import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/debt_model.dart';

class DebtController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'debts';

  String? get userId => FirebaseAuth.instance.currentUser?.uid;

  Stream<List<DebtModel>> getDebts() {
    final uid = userId;
    if (uid == null) return Stream.value([]);

    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: uid)
        .snapshots()
        .map((snapshot) {
          final debts = snapshot.docs
              .map(
                (doc) => _withLiveStatus(DebtModel.fromMap(doc.data(), doc.id)),
              )
              .toList();
          debts.sort((a, b) {
            if (a.isPaid != b.isPaid) return a.isPaid ? 1 : -1;
            return a.dueDate.compareTo(b.dueDate);
          });
          return debts;
        });
  }

  Future<List<DebtModel>> getDueReminders({int daysAhead = 3}) async {
    final uid = userId;
    if (uid == null) return [];

    final snapshot = await _firestore
        .collection(_collection)
        .where('userId', isEqualTo: uid)
        .get();

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final reminderEnd = today.add(Duration(days: daysAhead));

    final debts = snapshot.docs
        .map((doc) => _withLiveStatus(DebtModel.fromMap(doc.data(), doc.id)))
        .where((debt) {
          if (debt.isPaid) return false;
          final due = DateTime(
            debt.dueDate.year,
            debt.dueDate.month,
            debt.dueDate.day,
          );
          return due.isBefore(reminderEnd) || due.isAtSameMomentAs(reminderEnd);
        })
        .toList();
    debts.sort((a, b) => a.dueDate.compareTo(b.dueDate));
    return debts;
  }

  Future<void> createDebt(DebtModel debt) async {
    final uid = userId;
    if (uid == null) return;

    final docRef = _firestore.collection(_collection).doc();
    final now = DateTime.now();
    final newDebt = _withLiveStatus(
      debt.copyWith(id: docRef.id, userId: uid, createdAt: now, updatedAt: now),
    );
    await docRef.set(newDebt.toMap());
  }

  Future<void> updateDebt(DebtModel debt) async {
    final uid = userId;
    if (uid == null || debt.userId != uid) return;

    final updatedDebt = _withLiveStatus(
      debt.copyWith(updatedAt: DateTime.now()),
    );
    await _firestore
        .collection(_collection)
        .doc(debt.id)
        .update(updatedDebt.toMap());
  }

  Future<void> markAsPaid(DebtModel debt) async {
    final uid = userId;
    if (uid == null || debt.userId != uid) return;

    await _firestore.collection(_collection).doc(debt.id).update({
      'paidAmount': debt.amount,
      'status': 'PAID',
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  Future<void> deleteDebt(String id) async {
    final uid = userId;
    if (uid == null) return;
    await _firestore.collection(_collection).doc(id).delete();
  }

  DebtModel _withLiveStatus(DebtModel debt) {
    if (debt.remainAmount <= 0 || debt.status == 'PAID') {
      return debt.copyWith(status: 'PAID', paidAmount: debt.amount);
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(
      debt.dueDate.year,
      debt.dueDate.month,
      debt.dueDate.day,
    );
    final daysLeft = due.difference(today).inDays;

    if (daysLeft < 0) return debt.copyWith(status: 'OVERDUE');
    if (daysLeft <= 3) return debt.copyWith(status: 'DUE_SOON');
    return debt.copyWith(status: 'OPEN');
  }
}
