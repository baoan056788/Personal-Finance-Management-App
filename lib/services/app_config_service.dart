import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/app_config_model.dart';

class AppConfigService {
  AppConfigService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> get _configRef =>
      _firestore.collection('app_config').doc('general');

  Stream<AppConfigModel> watchConfig() {
    return _configRef.snapshots().map(
      (snapshot) => AppConfigModel.fromMap(snapshot.data()),
    );
  }

  Future<AppConfigModel> getConfig() async {
    final snapshot = await _configRef.get();
    return AppConfigModel.fromMap(snapshot.data());
  }
}
