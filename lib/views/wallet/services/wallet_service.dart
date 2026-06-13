import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../models/wallet_model.dart';

class WalletService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String get _uid {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Người dùng chưa đăng nhập');
    return user.uid;
  }

  CollectionReference get _walletsRef =>
      _firestore.collection('users').doc(_uid).collection('wallets');

  Stream<List<WalletModel>> getWallets() {
    return _walletsRef.snapshots().map(
      (snapshot) => snapshot.docs
          .map(
            (doc) =>
                WalletModel.fromMap(doc.data() as Map<String, dynamic>, doc.id),
          )
          .toList(),
    );
  }

  String generateWalletId() {
    return _walletsRef.doc().id;
  }

  Future<void> createWallet(WalletModel wallet) async {
    await _walletsRef.doc(wallet.id).set(wallet.toMap());
  }

  Future<void> updateWalletBalance(String walletId, double newBalance) async {
    if (newBalance < 0) {
      throw Exception('Số dư ví không được âm');
    }
    await _walletsRef.doc(walletId).update({'balance': newBalance});
  }

  Future<void> updateWalletName(String walletId, String newName) async {
    await _walletsRef.doc(walletId).update({'name': newName});
  }

  Future<void> deleteWallet(String walletId) async {
    final transactions = await _walletsRef
        .doc(walletId)
        .collection('transactions')
        .get();

    final batch = _firestore.batch();
    for (var doc in transactions.docs) {
      batch.delete(doc.reference);
    }

    batch.delete(_walletsRef.doc(walletId));

    await batch.commit();
  }

  Future<void> transferMoney({
    required String sourceWalletId,
    required String destWalletId,
    required double amount,
    required String note,
  }) async {
    if (sourceWalletId == destWalletId) {
      throw Exception('Không thể chuyển tiền cho cùng một ví');
    }
    if (amount <= 0) {
      throw Exception('Số tiền chuyển phải lớn hơn 0');
    }

    final sourceRef = _walletsRef.doc(sourceWalletId);
    final destRef = _walletsRef.doc(destWalletId);
    final sourceTransactionRef = sourceRef.collection('transactions').doc();
    final destTransactionRef = destRef.collection('transactions').doc();
    final transferId = _firestore.collection('_transfer_ids').doc().id;

    await _firestore.runTransaction((transaction) async {
      final sourceSnap = await transaction.get(sourceRef);
      final destSnap = await transaction.get(destRef);
      if (!sourceSnap.exists || !destSnap.exists) {
        throw Exception('Ví không tồn tại');
      }

      final sourceData = sourceSnap.data() as Map<String, dynamic>;
      final destData = destSnap.data() as Map<String, dynamic>;
      final sourceBalance = (sourceData['balance'] ?? 0.0).toDouble();
      final destBalance = (destData['balance'] ?? 0.0).toDouble();
      if (sourceBalance < amount) {
        throw Exception('Số dư không đủ để chuyển');
      }

      transaction.update(sourceRef, {'balance': sourceBalance - amount});
      transaction.update(destRef, {'balance': destBalance + amount});
      transaction.set(sourceTransactionRef, {
        'id': sourceTransactionRef.id,
        'amount': amount,
        'type': 'transfer',
        'category': 'Chuyển tiền',
        'note': 'Đến: ${destData['name']}${note.isEmpty ? '' : ' - $note'}',
        'createdAt': FieldValue.serverTimestamp(),
        'walletId': sourceWalletId,
        'transferId': transferId,
        'transferDirection': 'out',
        'relatedWalletId': destWalletId,
        'relatedWalletName': destData['name'],
      });
      transaction.set(destTransactionRef, {
        'id': destTransactionRef.id,
        'amount': amount,
        'type': 'transfer',
        'category': 'Nhận tiền',
        'note': 'Từ: ${sourceData['name']}${note.isEmpty ? '' : ' - $note'}',
        'createdAt': FieldValue.serverTimestamp(),
        'walletId': destWalletId,
        'transferId': transferId,
        'transferDirection': 'in',
        'relatedWalletId': sourceWalletId,
        'relatedWalletName': sourceData['name'],
      });
    });
  }
}
