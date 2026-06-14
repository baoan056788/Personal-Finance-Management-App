import 'dart:async';

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
  static final Map<String, _GlobalTransactionFeed> _globalTransactionFeeds = {};
  static StreamSubscription<User?>? _authStateSubscription;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final BudgetController _budgetController = BudgetController();
  final GoalController _goalController = GoalController();

  String get _uid {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Người dùng chưa đăng nhập');
    return user.uid;
  }

  CollectionReference<Map<String, dynamic>> _transactionsRef(String walletId) {
    return _firestore
        .collection('users')
        .doc(_uid)
        .collection('wallets')
        .doc(walletId)
        .collection('transactions');
  }

  DocumentReference<Map<String, dynamic>> _walletRef(String walletId) {
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
              .map((doc) => TransactionModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  Stream<List<TransactionModel>> watchAllTransactionsGlobal() {
    final userId = _uid;
    _ensureRealtimeFeedCleanup();
    return _globalTransactionFeeds
        .putIfAbsent(
          userId,
          () => _GlobalTransactionFeed(firestore: _firestore, userId: userId),
        )
        .stream;
  }

  static void _ensureRealtimeFeedCleanup() {
    _authStateSubscription ??= FirebaseAuth.instance.authStateChanges().listen((
      user,
    ) {
      final activeUserId = user?.uid;
      final staleUserIds = _globalTransactionFeeds.keys
          .where((userId) => userId != activeUserId)
          .toList();
      for (final userId in staleUserIds) {
        final feed = _globalTransactionFeeds.remove(userId);
        if (feed != null) unawaited(feed.dispose());
      }
    });
  }

  Stream<Map<String, double>> watchMonthlyTotal(int month, int year) {
    return watchAllTransactionsGlobal().map((transactions) {
      double income = 0;
      double expense = 0;
      for (final transaction in transactions) {
        if (transaction.createdAt.month != month ||
            transaction.createdAt.year != year) {
          continue;
        }
        if (transaction.isIncome) {
          income += transaction.amount;
        } else if (transaction.isExpense) {
          expense += transaction.amount;
        }
      }
      return {'income': income, 'expense': expense};
    });
  }

  double _applyTransaction(double balance, TransactionModel transaction) {
    return balance + transaction.walletBalanceImpact;
  }

  double _revertTransaction(double balance, TransactionModel transaction) {
    return balance - transaction.walletBalanceImpact;
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
    if (oldTx.isGoalMovement || oldTx.isDebtMovement) {
      throw Exception(
        'Hãy chỉnh sửa giao dịch này trong mục tiêu tiết kiệm hoặc sổ nợ',
      );
    }
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

    await _goalController.handleTransactionUpdated(txWithWallet);
    return await _budgetController.syncTransactionChange(
      previous: oldTx,
      current: txWithWallet,
    );
  }

  Future<void> deleteTransactionGlobal(TransactionModel tx) async {
    if (tx.isGoalMovement || tx.isDebtMovement) {
      throw Exception(
        'Hãy xử lý giao dịch này trong mục tiêu tiết kiệm hoặc sổ nợ',
      );
    }
    if (tx.isTransfer) {
      await _deleteTransfer(tx);
      return;
    }

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

  Future<void> _deleteTransfer(TransactionModel tx) async {
    if (tx.transferId == null || tx.relatedWalletId == null) {
      throw Exception('Giao dịch chuyển khoản thiếu thông tin liên kết');
    }

    final relatedTxSnapshot = await _firestore
        .collection('users')
        .doc(_uid)
        .collection('wallets')
        .doc(tx.relatedWalletId)
        .collection('transactions')
        .where('transferId', isEqualTo: tx.transferId)
        .limit(1)
        .get();

    TransactionModel? relatedTx;
    if (relatedTxSnapshot.docs.isNotEmpty) {
      relatedTx = TransactionModel.fromMap(
        relatedTxSnapshot.docs.first.data(),
        relatedTxSnapshot.docs.first.id,
      );
    }

    final String sourceWalletId = tx.transferDirection == 'out'
        ? tx.walletId
        : tx.relatedWalletId!;
    final String destWalletId = tx.transferDirection == 'out'
        ? tx.relatedWalletId!
        : tx.walletId;
    final double amount = tx.amount;

    final sourceWalletRef = _walletRef(sourceWalletId);
    final destWalletRef = _walletRef(destWalletId);
    final txRef = _transactionsRef(tx.walletId).doc(tx.id);
    final relatedTxRef = relatedTx != null
        ? _transactionsRef(tx.relatedWalletId!).doc(relatedTx.id)
        : null;

    await _firestore.runTransaction((firestoreTransaction) async {
      final sourceWalletDoc = await firestoreTransaction.get(sourceWalletRef);
      final destWalletDoc = await firestoreTransaction.get(destWalletRef);
      if (!sourceWalletDoc.exists || !destWalletDoc.exists) {
        throw Exception('Không tìm thấy một trong hai ví liên quan');
      }

      final sourceBalance =
          ((sourceWalletDoc.data() as Map<String, dynamic>)['balance'] ?? 0)
              .toDouble();
      final destBalance =
          ((destWalletDoc.data() as Map<String, dynamic>)['balance'] ?? 0)
              .toDouble();

      final newSourceBalance = sourceBalance + amount;
      final newDestBalance = destBalance - amount;

      _ensureNonNegative(newDestBalance);

      firestoreTransaction.delete(txRef);
      if (relatedTxRef != null) {
        firestoreTransaction.delete(relatedTxRef);
      }

      firestoreTransaction.update(sourceWalletRef, {
        'balance': newSourceBalance,
      });
      firestoreTransaction.update(destWalletRef, {'balance': newDestBalance});
    });

    await _budgetController.rollbackBudget(tx);
    if (relatedTx != null) {
      await _budgetController.rollbackBudget(relatedTx);
    }
    await _goalController.handleTransactionDeleted(tx);
    if (relatedTx != null) {
      await _goalController.handleTransactionDeleted(relatedTx);
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
    await _goalController.handleTransactionDeleted(tx);
  }

  Future<List<TransactionModel>> getRecentTransactionsGlobal() async {
    final walletsSnapshot = await _firestore
        .collection('users')
        .doc(_uid)
        .collection('wallets')
        .get();
    final transactionSnapshots = await Future.wait(
      walletsSnapshot.docs.map((doc) {
        return doc.reference
            .collection('transactions')
            .orderBy('createdAt', descending: true)
            .limit(5)
            .get();
      }),
    );
    final allTransactions = transactionSnapshots
        .expand((snapshot) => snapshot.docs)
        .map((doc) => TransactionModel.fromMap(doc.data(), doc.id))
        .toList();
    allTransactions.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return allTransactions.take(5).toList();
  }

  Future<List<TransactionModel>> getAllTransactionsGlobal() async {
    final walletsSnapshot = await _firestore
        .collection('users')
        .doc(_uid)
        .collection('wallets')
        .get();
    final transactionSnapshots = await Future.wait(
      walletsSnapshot.docs.map((doc) {
        return doc.reference
            .collection('transactions')
            .orderBy('createdAt', descending: true)
            .get();
      }),
    );
    final allTransactions = transactionSnapshots
        .expand((snapshot) => snapshot.docs)
        .map((doc) => TransactionModel.fromMap(doc.data(), doc.id))
        .toList();
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

class _TransactionFeedEvent {
  final int revision;
  final List<TransactionModel> transactions;

  const _TransactionFeedEvent(this.revision, this.transactions);
}

class _GlobalTransactionFeed {
  _GlobalTransactionFeed({
    required FirebaseFirestore firestore,
    required String userId,
  }) : _firestore = firestore,
       _userId = userId {
    _start();
  }

  final FirebaseFirestore _firestore;
  final String _userId;
  final Map<String, List<TransactionModel>> _walletTransactions = {};
  final Map<String, StreamSubscription<QuerySnapshot<Map<String, dynamic>>>>
  _transactionSubscriptions = {};
  final StreamController<_TransactionFeedEvent> _events =
      StreamController<_TransactionFeedEvent>.broadcast(sync: true);

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _walletSubscription;
  _TransactionFeedEvent? _latestEvent;
  int _revision = 0;
  bool _disposed = false;

  Stream<List<TransactionModel>> get stream {
    return Stream<List<TransactionModel>>.multi((controller) {
      var deliveredRevision = -1;

      void deliver(_TransactionFeedEvent event) {
        if (event.revision <= deliveredRevision) return;
        deliveredRevision = event.revision;
        controller.add(event.transactions);
      }

      final subscription = _events.stream.listen(
        deliver,
        onError: controller.addError,
        onDone: controller.close,
      );
      final latestEvent = _latestEvent;
      if (latestEvent != null) deliver(latestEvent);

      controller.onCancel = subscription.cancel;
    }, isBroadcast: true);
  }

  void _start() {
    _walletSubscription = _firestore
        .collection('users')
        .doc(_userId)
        .collection('wallets')
        .snapshots()
        .listen(_syncWalletSubscriptions, onError: _addError);
  }

  void _syncWalletSubscriptions(
    QuerySnapshot<Map<String, dynamic>> walletSnapshot,
  ) {
    if (_disposed) return;

    final walletIds = walletSnapshot.docs.map((doc) => doc.id).toSet();
    final removedWalletIds = _transactionSubscriptions.keys
        .where((walletId) => !walletIds.contains(walletId))
        .toList();

    for (final walletId in removedWalletIds) {
      final subscription = _transactionSubscriptions.remove(walletId);
      if (subscription != null) unawaited(subscription.cancel());
      _walletTransactions.remove(walletId);
    }

    for (final walletId in walletIds) {
      if (_transactionSubscriptions.containsKey(walletId)) continue;
      _walletTransactions[walletId] = const [];
      _transactionSubscriptions[walletId] = _firestore
          .collection('users')
          .doc(_userId)
          .collection('wallets')
          .doc(walletId)
          .collection('transactions')
          .orderBy('createdAt', descending: true)
          .snapshots()
          .listen(
            (snapshot) {
              _walletTransactions[walletId] = snapshot.docs.map((doc) {
                return TransactionModel.fromMap(doc.data(), doc.id);
              }).toList();
              _emitTransactions();
            },
            onError: (Object error, StackTrace stackTrace) {
              _addError(error, stackTrace);
              _emitTransactions();
            },
          );
    }

    _emitTransactions();
  }

  void _emitTransactions() {
    if (_disposed) return;

    final transactions =
        _walletTransactions.values.expand((items) => items).toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final event = _TransactionFeedEvent(
      ++_revision,
      List<TransactionModel>.unmodifiable(transactions),
    );
    _latestEvent = event;
    if (!_events.isClosed) _events.add(event);
  }

  void _addError(Object error, [StackTrace? stackTrace]) {
    if (_disposed || _events.isClosed) return;
    _events.addError(error, stackTrace);
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    await _walletSubscription?.cancel();
    await Future.wait(
      _transactionSubscriptions.values.map((subscription) {
        return subscription.cancel();
      }),
    );
    _transactionSubscriptions.clear();
    _walletTransactions.clear();
    await _events.close();
  }
}
