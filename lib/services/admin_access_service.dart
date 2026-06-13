import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminAccessService {
  AdminAccessService({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  Future<bool> isCurrentUserAdmin({bool forceRefresh = false}) async {
    final user = _auth.currentUser;
    if (user == null) return false;
    final token = await user.getIdTokenResult(forceRefresh);
    return token.claims?['admin'] == true;
  }

  Future<void> ensureCurrentUserProfile() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final ref = _firestore.collection('users').doc(user.uid);
    final snapshot = await ref.get();
    if (snapshot.exists) {
      await ref.set({
        'lastLoginAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      return;
    }

    await ref.set({
      'email': user.email?.trim().toLowerCase() ?? '',
      'fullName': (user.displayName ?? '').trim().isEmpty
          ? 'Người dùng'
          : user.displayName!.trim(),
      'avatarUrl': user.photoURL,
      'lastLoginAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'role': 'user',
      'status': 'active',
      'createdAt': FieldValue.serverTimestamp(),
      'onboardingCompleted': false,
      'loginProvider':
          user.providerData.any(
            (provider) => provider.providerId == 'google.com',
          )
          ? 'google'
          : 'email',
    }, SetOptions(merge: true));
  }
}
