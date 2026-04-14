import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ac_techs/core/constants/app_constants.dart';
import 'package:ac_techs/core/models/models.dart';

final appBrandingRepositoryProvider = Provider<AppBrandingRepository>((ref) {
  return AppBrandingRepository(firestore: FirebaseFirestore.instance);
});

class AppBrandingRepository {
  AppBrandingRepository({required this.firestore});

  final FirebaseFirestore firestore;

  DocumentReference<Map<String, dynamic>> get _doc => firestore
      .collection(AppConstants.appSettingsCollection)
      .doc(AppConstants.companyBrandingDocId);

  Stream<AppBrandingConfig> watchConfig() {
    return _doc.snapshots().map((doc) {
      if (!doc.exists) return AppBrandingConfig.defaults();
      return AppBrandingConfig.fromMap(doc.data());
    });
  }

  Future<void> saveConfig(AppBrandingConfig config) async {
    try {
      await _doc.set({
        ...config.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } on FirebaseException catch (error) {
      debugPrint('save app branding error: ${error.code} — ${error.message}');
      throw AdminException.userSaveFailed();
    }
  }
}
