import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ac_techs/core/constants/app_constants.dart';
import 'package:ac_techs/core/models/models.dart';

final companyRepositoryProvider = Provider<CompanyRepository>((ref) {
  return CompanyRepository(firestore: FirebaseFirestore.instance);
});

class CompanyRepository {
  CompanyRepository({required this.firestore});

  final FirebaseFirestore firestore;

  CollectionReference<Map<String, dynamic>> get _ref =>
      firestore.collection(AppConstants.companiesCollection);

  Stream<List<CompanyModel>> allCompanies() {
    return _ref
        .orderBy('name')
        .snapshots()
        .map((snap) => snap.docs.map(CompanyModel.fromFirestore).toList());
  }

  Stream<List<CompanyModel>> activeCompanies() {
    return _ref.where('isActive', isEqualTo: true).snapshots().map((snap) {
      final list = snap.docs.map(CompanyModel.fromFirestore).toList();
      list.sort((a, b) => a.name.compareTo(b.name)); // sort client-side
      return list;
    });
  }

  Future<void> createCompany({
    required String name,
    required String invoicePrefix,
    String logoBase64 = '',
  }) async {
    try {
      await _ref.add({
        'name': name,
        'invoicePrefix': invoicePrefix,
        'isActive': true,
        'logoBase64': logoBase64,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      debugPrint('createCompany error: ${e.code} — ${e.message}');
      throw AdminException.userSaveFailed();
    }
  }

  Future<void> updateCompany({
    required String id,
    required String name,
    required String invoicePrefix,
    String logoBase64 = '',
  }) async {
    try {
      await _ref.doc(id).update({
        'name': name,
        'invoicePrefix': invoicePrefix,
        'logoBase64': logoBase64,
      });
    } on FirebaseException catch (e) {
      debugPrint('updateCompany error: ${e.code} — ${e.message}');
      throw AdminException.userSaveFailed();
    }
  }

  Future<void> toggleCompanyActive(String id, bool isActive) async {
    try {
      await _ref.doc(id).update({'isActive': isActive});
    } on FirebaseException catch (e) {
      debugPrint('toggleCompanyActive error: ${e.code} — ${e.message}');
      throw AdminException.userSaveFailed();
    }
  }
}
