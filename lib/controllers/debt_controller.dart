import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/debt_model.dart';
import '../models/debt_payment_model.dart';
import '../models/transaction_model.dart';

class DebtController {
  DebtController({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  String get _uid {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Người dùng chưa đăng nhập');
    return user.uid;
  }

  CollectionReference<Map<String, dynamic>> get _debtsRef =>
      _firestore.collection('debts');

  CollectionReference<Map<String, dynamic>> get _paymentsRef =>
      _firestore.collection('debt_payments');

  CollectionReference<Map<String, dynamic>> get _walletsRef =>
      _firestore.collection('users').doc(_uid).collection('wallets');

  Stream<List<DebtModel>> getDebts() {
    return _debtsRef.where('userId', isEqualTo: _uid).snapshots().map((
      snapshot,
    ) {
      final debts = snapshot.docs
          .map((doc) => _withLiveStatus(DebtModel.fromMap(doc.data(), doc.id)))
          .toList();
      debts.sort((a, b) {
        if (a.isPaid != b.isPaid) return a.isPaid ? 1 : -1;
        return a.dueDate.compareTo(b.dueDate);
      });
      return debts;
    });
  }

  Stream<List<DebtPaymentModel>> getPayments(String debtId) {
    return _paymentsRef
        .where('userId', isEqualTo: _uid)
        .where('debtId', isEqualTo: debtId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => DebtPaymentModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  Future<List<DebtModel>> getDueReminders({int daysAhead = 3}) async {
    final snapshot = await _debtsRef.where('userId', isEqualTo: _uid).get();
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
          return !due.isAfter(reminderEnd);
        })
        .toList();
    debts.sort((a, b) => a.dueDate.compareTo(b.dueDate));
    return debts;
  }

  Future<void> createDebt(
    DebtModel debt, {
    String? walletId,
    bool updateWalletBalance = false,
  }) async {
    if (debt.amount <= 0) throw Exception('Số tiền phải lớn hơn 0');
    final debtRef = _debtsRef.doc();
    final now = DateTime.now();

    if (!updateWalletBalance) {
      final created = _withLiveStatus(
        debt.copyWith(
          id: debtRef.id,
          userId: _uid,
          paidAmount: 0,
          affectsWallet: false,
          createdAt: now,
          updatedAt: now,
        ),
      );
      await debtRef.set(created.toMap());
      return;
    }

    if (walletId == null || walletId.isEmpty) {
      throw Exception('Vui lòng chọn ví nhận hoặc chi tiền');
    }
    final walletRef = _walletsRef.doc(walletId);
    final transactionRef = walletRef.collection('transactions').doc();
    await _firestore.runTransaction((transaction) async {
      final walletSnapshot = await transaction.get(walletRef);
      if (!walletSnapshot.exists || walletSnapshot.data() == null) {
        throw Exception('Ví không tồn tại');
      }
      final balance = (walletSnapshot.data()!['balance'] ?? 0).toDouble();
      final isBorrowed = debt.type == 'borrowed';
      final nextBalance = isBorrowed
          ? balance + debt.amount
          : balance - debt.amount;
      if (nextBalance < 0) throw Exception('Số dư ví không đủ để cho vay');

      final created = _withLiveStatus(
        debt.copyWith(
          id: debtRef.id,
          userId: _uid,
          paidAmount: 0,
          affectsWallet: true,
          initialWalletId: walletId,
          initialTransactionId: transactionRef.id,
          createdAt: now,
          updatedAt: now,
        ),
      );
      transaction.update(walletRef, {'balance': nextBalance});
      transaction.set(debtRef, created.toMap());
      transaction.set(
        transactionRef,
        TransactionModel(
          id: transactionRef.id,
          amount: debt.amount,
          type: 'debt',
          category: isBorrowed ? 'Tiền đi vay' : 'Tiền cho vay',
          note: debt.note.isEmpty
              ? '${isBorrowed ? 'Vay từ' : 'Cho vay'} ${debt.personName}'
              : debt.note,
          createdAt: now,
          walletId: walletId,
          cashFlowDirection: isBorrowed ? 'in' : 'out',
          referenceId: debtRef.id,
        ).toMap(),
      );
    });
  }

  Future<void> updateDebt(DebtModel debt) async {
    final snapshot = await _debtsRef.doc(debt.id).get();
    if (!snapshot.exists || snapshot.data() == null) {
      throw Exception('Khoản công nợ không tồn tại');
    }
    final existing = DebtModel.fromMap(snapshot.data()!, snapshot.id);
    if (existing.userId != _uid) throw Exception('Không có quyền chỉnh sửa');
    final hasFinancialHistory =
        existing.affectsWallet || existing.paidAmount > 0;
    final updated = _withLiveStatus(
      debt.copyWith(
        userId: _uid,
        type: hasFinancialHistory ? existing.type : debt.type,
        amount: hasFinancialHistory ? existing.amount : debt.amount,
        paidAmount: existing.paidAmount,
        affectsWallet: existing.affectsWallet,
        initialWalletId: existing.initialWalletId,
        initialTransactionId: existing.initialTransactionId,
        createdAt: existing.createdAt,
        updatedAt: DateTime.now(),
      ),
    );
    await snapshot.reference.update(updated.toMap());
  }

  Future<void> recordPayment({
    required String debtId,
    required String walletId,
    required double amount,
    required String note,
  }) async {
    if (!amount.isFinite || amount <= 0) {
      throw Exception('Số tiền thanh toán phải lớn hơn 0');
    }
    final debtRef = _debtsRef.doc(debtId);
    final walletRef = _walletsRef.doc(walletId);
    final paymentRef = _paymentsRef.doc();
    final transactionRef = walletRef.collection('transactions').doc();

    await _firestore.runTransaction((transaction) async {
      final debtSnapshot = await transaction.get(debtRef);
      final walletSnapshot = await transaction.get(walletRef);
      if (!debtSnapshot.exists || debtSnapshot.data() == null) {
        throw Exception('Khoản công nợ không tồn tại');
      }
      if (!walletSnapshot.exists || walletSnapshot.data() == null) {
        throw Exception('Ví không tồn tại');
      }
      final debt = DebtModel.fromMap(debtSnapshot.data()!, debtSnapshot.id);
      if (debt.userId != _uid) throw Exception('Không có quyền thanh toán');
      if (debt.isPaid) throw Exception('Khoản công nợ đã tất toán');
      if (amount > debt.remainAmount + 0.001) {
        throw Exception('Số tiền vượt quá dư nợ còn lại');
      }

      final balance = (walletSnapshot.data()!['balance'] ?? 0).toDouble();
      final isBorrowed = debt.isBorrowed;
      final nextBalance = isBorrowed ? balance - amount : balance + amount;
      if (nextBalance < 0) throw Exception('Số dư ví không đủ để trả nợ');
      final paidAmount = debt.paidAmount + amount;
      final completed = paidAmount >= debt.amount - 0.001;
      final now = DateTime.now();

      transaction.update(walletRef, {'balance': nextBalance});
      transaction.update(debtRef, {
        'paidAmount': completed ? debt.amount : paidAmount,
        'status': completed ? 'PAID' : _withLiveStatus(debt).status,
        'updatedAt': Timestamp.fromDate(now),
      });
      transaction.set(
        transactionRef,
        TransactionModel(
          id: transactionRef.id,
          amount: amount,
          type: 'debt',
          category: isBorrowed ? 'Trả nợ' : 'Thu hồi khoản cho vay',
          note: note.isEmpty
              ? '${isBorrowed ? 'Trả cho' : 'Thu từ'} ${debt.personName}'
              : note,
          createdAt: now,
          walletId: walletId,
          cashFlowDirection: isBorrowed ? 'out' : 'in',
          referenceId: debtId,
        ).toMap(),
      );
      transaction.set(
        paymentRef,
        DebtPaymentModel(
          id: paymentRef.id,
          userId: _uid,
          debtId: debtId,
          walletId: walletId,
          transactionId: transactionRef.id,
          amount: amount,
          note: note,
          createdAt: now,
        ).toMap(),
      );
    });
  }

  Future<void> deleteDebt(String id) async {
    final debtDoc = await _debtsRef.doc(id).get();
    if (!debtDoc.exists || debtDoc.data() == null) return;
    final debt = DebtModel.fromMap(debtDoc.data()!, debtDoc.id);
    if (debt.userId != _uid) throw Exception('Không có quyền xóa');
    final payments = await _paymentsRef
        .where('userId', isEqualTo: _uid)
        .where('debtId', isEqualTo: id)
        .limit(1)
        .get();
    if (debt.affectsWallet || debt.paidAmount > 0 || payments.docs.isNotEmpty) {
      throw Exception(
        'Không thể xóa khoản đã phát sinh dòng tiền; hãy giữ lại để đối soát',
      );
    }
    await debtDoc.reference.delete();
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
