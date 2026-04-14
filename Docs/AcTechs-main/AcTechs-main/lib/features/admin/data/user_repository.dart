import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ac_techs/core/models/models.dart';
import 'package:ac_techs/core/constants/app_constants.dart';
import 'package:ac_techs/core/utils/invoice_utils.dart';

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository(firestore: FirebaseFirestore.instance);
});

enum FlushOperationPhase {
  idle,
  verifyingPassword,
  checkingConnection,
  scanningAffectedData,
  deletingOperationalData,
  deletingDerivedData,
  deletingCompanies,
  archivingUsers,
  rebuildingDerivedData,
  clearingLocalCache,
  refreshingAppData,
  completed,
}

typedef FlushProgressCallback = void Function(FlushOperationPhase phase);

class InvoicePrefixNormalizationResult {
  const InvoicePrefixNormalizationResult({
    required this.scannedJobs,
    required this.updatedJobs,
    required this.conflictedInvoices,
    required this.rebuiltInvoiceClaims,
    required this.rebuiltSharedAggregates,
  });

  final int scannedJobs;
  final int updatedJobs;
  final int conflictedInvoices;
  final int rebuiltInvoiceClaims;
  final int rebuiltSharedAggregates;
}

class _InvoiceMigrationJobState {
  _InvoiceMigrationJobState({
    required this.reference,
    required this.invoiceNumber,
    required this.companyId,
    required this.companyName,
    required this.techId,
    required this.status,
    required this.isSharedInstall,
    required this.sharedInstallGroupKey,
    required this.data,
    this.submittedAt,
  });

  final DocumentReference<Map<String, dynamic>> reference;
  final String invoiceNumber;
  final String companyId;
  final String companyName;
  final String techId;
  final String status;
  final bool isSharedInstall;
  final String sharedInstallGroupKey;
  final Map<String, dynamic> data;
  final DateTime? submittedAt;

  bool get isRejected => status.trim().toLowerCase() == JobStatus.rejected.name;
}

class UserRepository {
  UserRepository({
    required this.firestore,
    Future<void> Function()? flushPreflight,
  }) : _flushPreflight = flushPreflight;

  static const Set<String> _historyCollections = {
    AppConstants.jobsCollection,
    AppConstants.expensesCollection,
    AppConstants.earningsCollection,
    AppConstants.acInstallsCollection,
  };

  final FirebaseFirestore firestore;
  final Future<void> Function()? _flushPreflight;

  CollectionReference<Map<String, dynamic>> get _usersRef =>
      firestore.collection(AppConstants.usersCollection);

  CollectionReference<Map<String, dynamic>> get _jobsRef =>
      firestore.collection(AppConstants.jobsCollection);

  CollectionReference<Map<String, dynamic>> get _companiesRef =>
      firestore.collection(AppConstants.companiesCollection);

  Query<Map<String, dynamic>> get _activeTechniciansQuery => _usersRef
      .where('role', isEqualTo: AppConstants.roleTechnician)
      .where('isActive', isEqualTo: true);

  Query<Map<String, dynamic>> get _allUsersQuery => _usersRef.orderBy('name');

  String _normalizedEmail(String email) => email.trim().toLowerCase();

  Stream<List<UserModel>> allTechnicians() {
    return _activeTechniciansQuery.snapshots().map(
      (snap) => _sortedUsers(snap.docs),
    );
  }

  Stream<List<UserModel>> allUsers() {
    return _allUsersQuery.snapshots().map((snap) => _sortedUsers(snap.docs));
  }

  Future<List<UserModel>> usersForImport() async {
    try {
      final snap = await _activeTechniciansQuery.get();
      return _sortedUsers(snap.docs);
    } on FirebaseException catch (e) {
      debugPrint('usersForImport error code: ${e.code}');
      throw AdminException.noPermission();
    }
  }

  List<UserModel> _sortedUsers(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final users = docs.map(UserModel.fromFirestore).toList()
      ..sort((a, b) {
        final nameCompare = a.name.toLowerCase().compareTo(
          b.name.toLowerCase(),
        );
        if (nameCompare != 0) {
          return nameCompare;
        }
        return a.uid.compareTo(b.uid);
      });
    return users;
  }

  Future<UserModel?> _findUserByEmail(String email) async {
    final normalized = _normalizedEmail(email);
    if (normalized.isEmpty) return null;

    final lowerSnap = await _usersRef
        .where('emailLower', isEqualTo: normalized)
        .limit(1)
        .get();
    if (lowerSnap.docs.isNotEmpty) {
      return UserModel.fromFirestore(lowerSnap.docs.first);
    }

    final exactSnap = await _usersRef
        .where('email', isEqualTo: email.trim())
        .limit(1)
        .get();
    if (exactSnap.docs.isNotEmpty) {
      return UserModel.fromFirestore(exactSnap.docs.first);
    }

    final snap = await _usersRef.get();
    for (final doc in snap.docs) {
      final candidate = (doc.data()['email'] as String? ?? '')
          .trim()
          .toLowerCase();
      if (candidate == normalized) {
        return UserModel.fromFirestore(doc);
      }
    }

    return null;
  }

  Future<void> toggleUserActive(String uid, bool isActive) async {
    try {
      await _usersRef.doc(uid).update({
        'isActive': isActive,
        'archivedAt': isActive
            ? FieldValue.delete()
            : FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      debugPrint('toggleUserActive error code: ${e.code}');
      if (e.code == 'permission-denied') {
        throw AdminException.noPermission();
      }
      throw AdminException.userSaveFailed();
    }
  }

  /// Create a new user (technician or admin) via a secondary Firebase App.
  /// Admin session is preserved since createUserWithEmailAndPassword on a
  /// secondary app doesn't sign out the primary auth context.
  Future<void> createUser({
    required String name,
    required String email,
    required String password,
    required String role,
  }) async {
    FirebaseApp? secondaryApp;
    User? secondaryUser;
    final appName = 'userCreation_${DateTime.now().millisecondsSinceEpoch}';
    try {
      // Use a secondary Firebase App to avoid signing out the admin
      secondaryApp = await Firebase.initializeApp(
        name: appName,
        options: Firebase.app().options,
      );
      final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);

      final credential = await secondaryAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      secondaryUser = credential.user;
      final uid = credential.user!.uid;
      final normalizedRole = role.trim().toLowerCase() == AppConstants.roleAdmin
          ? AppConstants.roleAdmin
          : AppConstants.roleTechnician;
      final normalizedEmail = _normalizedEmail(email);

      // Create the Firestore user document with the specified role
      await _usersRef.doc(uid).set({
        'name': name,
        'email': email,
        'emailLower': normalizedEmail,
        'role': normalizedRole,
        'isActive': true,
        'language': 'en',
        'themeMode': 'dark',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Clean up: sign out from secondary and delete the temp app
      await secondaryAuth.signOut();
      await secondaryApp.delete();
      secondaryApp = null;
    } catch (e) {
      // Always clean up the secondary app
      if (secondaryApp != null) {
        if (secondaryUser != null) {
          try {
            await secondaryUser.delete();
          } catch (_) {}
        }
        try {
          await secondaryApp.delete();
        } catch (_) {}
      }

      if (e is FirebaseAuthException) {
        if (e.code == 'email-already-in-use') {
          final existingUser = await _findUserByEmail(email);
          if (existingUser != null && !existingUser.isActive) {
            throw const AdminException(
              'user_inactive_reactivation_required',
              'This email belongs to an inactive account. Edit that user, then reactivate it and send a password reset instead of creating a new account.',
              'یہ ای میل ایک غیر فعال اکاؤنٹ سے منسلک ہے۔ نیا اکاؤنٹ بنانے کے بجائے اسی صارف کو ایڈٹ کریں، دوبارہ فعال کریں، اور پاس ورڈ ری سیٹ بھیجیں۔',
              'هذا البريد مرتبط بحساب غير نشط. عدّل ذلك المستخدم ثم أعد تفعيله وأرسل إعادة تعيين كلمة المرور بدلاً من إنشاء حساب جديد.',
            );
          }
          throw const AdminException(
            'user_exists',
            'A user with this email already exists.',
            'اس ای میل سے پہلے سے ایک صارف موجود ہے۔',
            'يوجد مستخدم بهذا البريد الإلكتروني بالفعل.',
          );
        }
        if (e.code == 'weak-password') {
          throw const AdminException(
            'weak_password',
            'Password must be at least 6 characters.',
            'پاس ورڈ کم از کم ۶ حروف کا ہونا چاہیے۔',
            'يجب أن تتكون كلمة المرور من 6 أحرف على الأقل.',
          );
        }
      }
      throw AdminException.userSaveFailed();
    }
  }

  /// Update user name in Firestore (email display only — auth email unchanged).
  Future<void> updateUser({
    required String uid,
    required String name,
    String? role,
  }) async {
    try {
      final updates = <String, dynamic>{'name': name};
      if (role != null) {
        updates['role'] = role.trim().toLowerCase() == AppConstants.roleAdmin
            ? AppConstants.roleAdmin
            : AppConstants.roleTechnician;
      }
      await _usersRef.doc(uid).update(updates);
    } on FirebaseException catch (e) {
      debugPrint('updateUser error code: ${e.code}');
      if (e.code == 'permission-denied') {
        throw const AdminException(
          'admin_permission',
          'Permission denied. Are you still logged in as admin?',
          'اجازت نہیں ہے۔ کیا آپ ابھی ایڈمن کے طور پر لاگ ان ہیں؟',
          'لا يوجد إذن. هل أنت لا تزال مسجل دخولاً كمسؤول؟',
        );
      }
      throw AdminException.userSaveFailed();
    }
  }

  /// Backward-compatibility: technicianonly wrapper for createUser.
  Future<void> createTechnician({
    required String name,
    required String email,
    required String password,
  }) async => createUser(
    name: name,
    email: email,
    password: password,
    role: AppConstants.roleTechnician,
  );

  /// Bulk toggle active status for a list of user IDs.
  Future<void> bulkToggleActive(List<String> uids, bool isActive) async {
    try {
      final batch = firestore.batch();
      for (final uid in uids) {
        batch.update(_usersRef.doc(uid), {
          'isActive': isActive,
          'archivedAt': isActive
              ? FieldValue.delete()
              : FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();
    } on FirebaseException catch (e) {
      debugPrint('bulkToggleActive error code: ${e.code}');
      if (e.code == 'permission-denied') {
        throw AdminException.noPermission();
      }
      throw AdminException.userSaveFailed();
    }
  }

  /// Send a password reset email — uses Firebase Auth (free, no cloud fn needed).
  ///
  /// [ActionCodeSettings] configure the deep-link so Android can offer to
  /// reopen the app after the user resets their password in the browser, and
  /// the continue URL gives users a clear landing page post-reset.
  Future<void> sendPasswordReset(String email) async {
    try {
      final settings = ActionCodeSettings(
        url: 'https://actechs-d415e.web.app',
        handleCodeInApp: false,
        androidPackageName: 'com.actechs.pk',
        androidInstallApp: false,
        // Match app minimum supported Android API level.
        androidMinimumVersion: '29',
      );
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: email,
        actionCodeSettings: settings,
      );
    } on FirebaseAuthException catch (e) {
      debugPrint('sendPasswordReset error code: ${e.code}');
      if (e.code == 'network-request-failed') {
        throw AuthException.resetNetworkError();
      }
      if (e.code == 'too-many-requests') {
        throw AuthException.resetRateLimit();
      }
      throw AuthException.resetFailed();
    }
  }

  /// Archive a user instead of deleting the profile so historical records
  /// remain attributable to the original technician.
  Future<void> deleteUser(String uid) async {
    try {
      await _usersRef.doc(uid).update({
        'isActive': false,
        'archivedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      debugPrint('deleteUser error code: ${e.code}');
      if (e.code == 'permission-denied') {
        throw const AdminException(
          'admin_permission',
          'Permission denied. Are you still logged in as admin?',
          'اجازت نہیں ہے۔ کیا آپ ابھی ایڈمن کے طور پر لاگ ان ہیں؟',
          'لا يوجد إذن. هل أنت لا تزال مسجل دخولاً كمسؤول؟',
        );
      }
      throw AdminException.userSaveFailed();
    }
  }

  /// Verify admin password by re-authenticating with Firebase Auth.
  /// Throws [AdminException.wrongPassword] on bad password.
  Future<void> verifyAdminPassword(String password) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null || user.email == null) {
        throw AdminException.noPermission();
      }
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );
      await user.reauthenticateWithCredential(credential);
    } on AdminException {
      rethrow;
    } on FirebaseAuthException catch (e) {
      debugPrint('verifyAdminPassword error code: ${e.code}');
      if (e.code == 'network-request-failed') {
        throw AdminException.flushRequiresInternet();
      }
      throw AdminException.wrongPassword();
    } catch (_) {
      throw AdminException.wrongPassword();
    }
  }

  /// Flush the database: deletes all jobs, expenses, earnings, and companies.
  ///
  /// When [deleteNonAdminUsers] is true, it archives all non-admin user
  /// documents instead of permanently deleting them. Admin documents are
  /// always preserved.
  Future<void> flushDatabase({
    bool deleteNonAdminUsers = false,
    FlushProgressCallback? onProgress,
  }) async {
    try {
      onProgress?.call(FlushOperationPhase.checkingConnection);
      await _assertFlushServerReachable();
      await _assertNoActiveSettlementBatches();

      onProgress?.call(FlushOperationPhase.deletingOperationalData);
      await Future.wait([
        _deleteCollectionInChunks(AppConstants.jobsCollection),
        _deleteCollectionInChunks(AppConstants.expensesCollection),
        _deleteCollectionInChunks(AppConstants.earningsCollection),
        _deleteCollectionInChunks(AppConstants.acInstallsCollection),
      ]);

      onProgress?.call(FlushOperationPhase.deletingDerivedData);
      await Future.wait([
        _deleteCollectionInChunks(
          AppConstants.sharedInstallAggregatesCollection,
        ),
        _deleteCollectionInChunks(AppConstants.invoiceClaimsCollection),
      ]);

      onProgress?.call(FlushOperationPhase.deletingCompanies);
      await _deleteCollectionInChunks(AppConstants.companiesCollection);

      if (deleteNonAdminUsers) {
        onProgress?.call(FlushOperationPhase.archivingUsers);
        await _archiveNonAdminUsersInChunks();
      }

      onProgress?.call(FlushOperationPhase.clearingLocalCache);
      await _scheduleCacheClearOnNextLaunch();
    } on FirebaseException catch (e) {
      debugPrint('flushDatabase error code: ${e.code}');
      if (e.code == 'permission-denied') {
        throw const AdminException(
          'admin_flush_permission_denied',
          'Database flush is blocked by security rules. Contact admin support.',
          'ڈیٹا بیس فلش سیکیورٹی رولز کی وجہ سے بلاک ہے۔ ایڈمن سپورٹ سے رابطہ کریں۔',
          'تم حظر مسح قاعدة البيانات بواسطة قواعد الأمان. تواصل مع دعم المسؤول.',
        );
      }
      if (e.code == 'unavailable' || e.code == 'deadline-exceeded') {
        throw AdminException.flushRequiresInternet();
      }
      throw AdminException.flushFailed();
    }
  }

  Future<void> flushTechnicianData(
    String techId, {
    FlushProgressCallback? onProgress,
  }) async {
    try {
      if (techId.trim().isEmpty) return;

      onProgress?.call(FlushOperationPhase.checkingConnection);
      await _assertFlushServerReachable();
      await _assertNoActiveSettlementBatches(techId: techId);

      onProgress?.call(FlushOperationPhase.scanningAffectedData);

      final jobsToDelete = await _jobsRef
          .where('techId', isEqualTo: techId)
          .get();
      final affectedInvoices = <String>{};
      final affectedGroupKeys = <String>{};

      for (final doc in jobsToDelete.docs) {
        final job = JobModel.fromFirestore(doc);
        if (job.isRejected) continue;

        final normalizedInvoice = InvoiceUtils.normalize(job.invoiceNumber);
        if (normalizedInvoice.isNotEmpty) {
          affectedInvoices.add(normalizedInvoice);
        }
        if (job.isSharedInstall &&
            job.sharedInstallGroupKey.trim().isNotEmpty) {
          affectedGroupKeys.add(job.sharedInstallGroupKey.trim());
        }
      }

      onProgress?.call(FlushOperationPhase.deletingOperationalData);
      await Future.wait([
        _deleteCollectionByFieldInChunks(
          AppConstants.jobsCollection,
          'techId',
          techId,
        ),
        _deleteCollectionByFieldInChunks(
          AppConstants.expensesCollection,
          'techId',
          techId,
        ),
        _deleteCollectionByFieldInChunks(
          AppConstants.earningsCollection,
          'techId',
          techId,
        ),
        _deleteCollectionByFieldInChunks(
          AppConstants.acInstallsCollection,
          'techId',
          techId,
        ),
      ]);

      onProgress?.call(FlushOperationPhase.rebuildingDerivedData);
      await Future.wait([
        _rebuildInvoiceClaimsForInvoices(affectedInvoices),
        _rebuildSharedAggregatesForGroups(affectedGroupKeys),
      ]);

      onProgress?.call(FlushOperationPhase.clearingLocalCache);
      await _scheduleCacheClearOnNextLaunch();
    } on FirebaseException catch (e) {
      debugPrint('flushTechnicianData error code: ${e.code}');
      if (e.code == 'permission-denied') {
        throw const AdminException(
          'admin_flush_permission_denied',
          'Database flush is blocked by security rules. Contact admin support.',
          'ڈیٹا بیس فلش سیکیورٹی رولز کی وجہ سے بلاک ہے۔ ایڈمن سپورٹ سے رابطہ کریں۔',
          'تم حظر مسح قاعدة البيانات بواسطة قواعد الأمان. تواصل مع دعم المسؤول.',
        );
      }
      if (e.code == 'unavailable' || e.code == 'deadline-exceeded') {
        throw AdminException.flushRequiresInternet();
      }
      throw AdminException.flushFailed();
    }
  }

  Future<void> _assertFlushServerReachable() async {
    final preflight = _flushPreflight;
    if (preflight != null) {
      await preflight();
      return;
    }

    try {
      await firestore
          .collection(AppConstants.appSettingsCollection)
          .doc(AppConstants.approvalConfigDocId)
          .get(const GetOptions(source: Source.server));
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        throw AdminException.noPermission();
      }
      if (e.code == 'unavailable' ||
          e.code == 'deadline-exceeded' ||
          e.code == 'cancelled') {
        throw AdminException.flushRequiresInternet();
      }
      rethrow;
    }
  }

  Future<void> _assertNoActiveSettlementBatches({String? techId}) async {
    Query<Map<String, dynamic>> query = _jobsRef.where(
      'settlementStatus',
      whereIn: [
        JobSettlementStatus.awaitingTechnician.firestoreValue,
        JobSettlementStatus.correctionRequired.firestoreValue,
        JobSettlementStatus.disputedFinal.firestoreValue,
      ],
    );

    final normalizedTechId = techId?.trim() ?? '';
    if (normalizedTechId.isNotEmpty) {
      query = query.where('techId', isEqualTo: normalizedTechId);
    }

    final snap = await query
        .limit(1)
        .get(const GetOptions(source: Source.server));
    if (snap.docs.isNotEmpty) {
      throw AdminException.activeSettlementBatchesPreventFlush();
    }
  }

  Future<void> _archiveNonAdminUsersInChunks() async {
    const chunkSize = 400;
    while (true) {
      final usersSnap = await _usersRef.limit(chunkSize).get();
      if (usersSnap.docs.isEmpty) break;

      final batch = firestore.batch();
      var updatedAny = false;
      for (final doc in usersSnap.docs) {
        final role =
            doc.data()['role'] as String? ?? AppConstants.roleTechnician;
        if (role != AppConstants.roleAdmin) {
          batch.update(doc.reference, {
            'isActive': false,
            'archivedAt': FieldValue.serverTimestamp(),
          });
          updatedAny = true;
        }
      }

      if (!updatedAny) {
        break;
      }

      await batch.commit();
      if (usersSnap.docs.length < chunkSize) {
        break;
      }
    }
  }

  Future<void> _scheduleCacheClearOnNextLaunch() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('clear_firestore_cache_on_launch', true);
    } catch (_) {
      // Non-critical: cache flag may fail in test environments without
      // binding initialization. Flush itself already succeeded.
    }
  }

  Future<InvoicePrefixNormalizationResult>
  normalizeStoredInvoicePrefixes() async {
    try {
      final companyPrefixes = await _loadCompanyPrefixes();
      final jobsSnap = await _jobsRef.get();
      final jobUpdates =
          <DocumentReference<Map<String, dynamic>>, Map<String, dynamic>>{};
      final migratedJobs = <_InvoiceMigrationJobState>[];

      for (final doc in jobsSnap.docs) {
        final data = Map<String, dynamic>.from(doc.data());
        final companyId = (data['companyId'] as String? ?? '').trim();
        final companyName = (data['companyName'] as String? ?? '').trim();
        final techId = (data['techId'] as String? ?? '').trim();
        final rawInvoice = (data['invoiceNumber'] as String? ?? '').trim();
        final normalizedInvoice = InvoiceUtils.normalizeWithCompanyPrefix(
          rawInvoice,
          companyPrefix: companyPrefixes[companyId],
        );
        final isSharedInstall = data['isSharedInstall'] == true;
        final nextGroupKey = isSharedInstall
            ? InvoiceUtils.sharedInstallGroupKey(
                companyId: companyId,
                invoiceNumber: normalizedInvoice,
              )
            : '';
        final currentGroupKey = (data['sharedInstallGroupKey'] as String? ?? '')
            .trim();
        final nextData = <String, dynamic>{};

        if (normalizedInvoice != rawInvoice) {
          nextData['invoiceNumber'] = normalizedInvoice;
          data['invoiceNumber'] = normalizedInvoice;
        }

        if (isSharedInstall && nextGroupKey != currentGroupKey) {
          nextData['sharedInstallGroupKey'] = nextGroupKey;
          data['sharedInstallGroupKey'] = nextGroupKey;
        }

        if (nextData.isNotEmpty) {
          jobUpdates[doc.reference] = nextData;
        }

        migratedJobs.add(
          _InvoiceMigrationJobState(
            reference: doc.reference,
            invoiceNumber: (data['invoiceNumber'] as String? ?? '').trim(),
            companyId: companyId,
            companyName: companyName,
            techId: techId,
            status: (data['status'] as String? ?? '').trim(),
            isSharedInstall: isSharedInstall,
            sharedInstallGroupKey:
                (data['sharedInstallGroupKey'] as String? ?? '').trim(),
            data: data,
            submittedAt: _timestampToDate(data['submittedAt'] ?? data['date']),
          ),
        );
      }

      final activeJobs = migratedJobs
          .where((job) => !job.isRejected && job.invoiceNumber.isNotEmpty)
          .toList(growable: false);
      final invoiceBuckets = <String, List<_InvoiceMigrationJobState>>{};
      for (final job in activeJobs) {
        (invoiceBuckets[job.invoiceNumber] ??= <_InvoiceMigrationJobState>[])
            .add(job);
      }

      var conflictedInvoices = 0;
      for (final entry in invoiceBuckets.entries) {
        final jobs = entry.value;
        final companyNames =
            jobs
                .map((job) => job.companyName.trim())
                .where((name) => name.isNotEmpty)
                .toSet()
                .toList(growable: false)
              ..sort();
        final companyIds = jobs
            .map((job) => job.companyId.trim())
            .where((id) => id.isNotEmpty)
            .toSet();
        final hasConflict = companyIds.length > 1;
        if (hasConflict) {
          conflictedInvoices++;
        }

        for (final job in jobs) {
          final currentImportMeta = _copyStringKeyMap(job.data['importMeta']);
          final nextImportMeta = Map<String, dynamic>.from(currentImportMeta);
          if (hasConflict) {
            nextImportMeta['invoiceConflict'] = true;
            nextImportMeta['invoiceConflictCompanies'] = companyNames;
          } else {
            nextImportMeta.remove('invoiceConflict');
            nextImportMeta.remove('invoiceConflictCompanies');
          }

          if (!_mapEquals(currentImportMeta, nextImportMeta)) {
            final pendingUpdate =
                jobUpdates[job.reference] ?? <String, dynamic>{};
            pendingUpdate['importMeta'] = nextImportMeta;
            jobUpdates[job.reference] = pendingUpdate;
          }
        }
      }

      await _applyUpdatesInChunks(jobUpdates);

      final rebuiltClaims = _buildInvoiceClaimDocs(invoiceBuckets);
      final rebuiltAggregates = _buildSharedAggregateDocs(activeJobs);

      await _deleteCollectionInChunks(AppConstants.invoiceClaimsCollection);
      await _deleteCollectionInChunks(
        AppConstants.sharedInstallAggregatesCollection,
      );
      await _setDocumentsInChunks(
        AppConstants.invoiceClaimsCollection,
        rebuiltClaims,
      );
      await _setDocumentsInChunks(
        AppConstants.sharedInstallAggregatesCollection,
        rebuiltAggregates,
      );

      return InvoicePrefixNormalizationResult(
        scannedJobs: jobsSnap.docs.length,
        updatedJobs: jobUpdates.length,
        conflictedInvoices: conflictedInvoices,
        rebuiltInvoiceClaims: rebuiltClaims.length,
        rebuiltSharedAggregates: rebuiltAggregates.length,
      );
    } on FirebaseException catch (e) {
      debugPrint('normalizeStoredInvoicePrefixes error code: ${e.code}');
      if (e.code == 'permission-denied') {
        throw AdminException.noPermission();
      }
      throw const AdminException(
        'admin_invoice_prefix_migration_failed',
        'Could not normalize stored invoice numbers. Please try again.',
        'محفوظ شدہ انوائس نمبرز نارملائز نہیں ہو سکے۔ دوبارہ کوشش کریں۔',
        'تعذر توحيد أرقام الفواتير المخزنة. حاول مرة أخرى.',
      );
    }
  }

  /// Deletes all documents in [collectionName] in chunks of 400.
  Future<void> _deleteCollectionInChunks(String collectionName) async {
    const chunkSize = 400;
    final hasHistory = _historyCollections.contains(collectionName);
    while (true) {
      final snap = await firestore
          .collection(collectionName)
          .limit(chunkSize)
          .get();
      if (snap.docs.isEmpty) break;
      if (hasHistory) {
        for (final doc in snap.docs) {
          await _deleteHistorySubcollectionInChunks(doc.reference);
        }
      }
      final batch = firestore.batch();
      for (final doc in snap.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }
  }

  Future<void> _deleteCollectionByFieldInChunks(
    String collectionName,
    String field,
    String value,
  ) async {
    const chunkSize = 400;
    final hasHistory = _historyCollections.contains(collectionName);
    while (true) {
      final snap = await firestore
          .collection(collectionName)
          .where(field, isEqualTo: value)
          .limit(chunkSize)
          .get();
      if (snap.docs.isEmpty) break;
      if (hasHistory) {
        for (final doc in snap.docs) {
          await _deleteHistorySubcollectionInChunks(doc.reference);
        }
      }
      final batch = firestore.batch();
      for (final doc in snap.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }
  }

  Future<void> _deleteHistorySubcollectionInChunks(
    DocumentReference<Map<String, dynamic>> parentRef,
  ) async {
    const chunkSize = 400;
    while (true) {
      final snap = await parentRef
          .collection(AppConstants.historySubCollection)
          .limit(chunkSize)
          .get();
      if (snap.docs.isEmpty) break;

      final batch = firestore.batch();
      for (final doc in snap.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }
  }

  _InvoiceMigrationJobState _jobStateFromSnapshot(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = Map<String, dynamic>.from(doc.data());
    return _InvoiceMigrationJobState(
      reference: doc.reference,
      invoiceNumber: (data['invoiceNumber'] as String? ?? '').trim(),
      companyId: (data['companyId'] as String? ?? '').trim(),
      companyName: (data['companyName'] as String? ?? '').trim(),
      techId: (data['techId'] as String? ?? '').trim(),
      status: (data['status'] as String? ?? '').trim(),
      isSharedInstall: data['isSharedInstall'] == true,
      sharedInstallGroupKey: (data['sharedInstallGroupKey'] as String? ?? '')
          .trim(),
      data: data,
      submittedAt: _timestampToDate(data['submittedAt'] ?? data['date']),
    );
  }

  Future<void> _rebuildInvoiceClaimsForInvoices(
    Set<String> invoiceNumbers,
  ) async {
    if (invoiceNumbers.isEmpty) return;

    final activeJobs = <_InvoiceMigrationJobState>[];
    final invoices = invoiceNumbers.toList(growable: false);
    for (var start = 0; start < invoices.length; start += 10) {
      final end = (start + 10 > invoices.length) ? invoices.length : start + 10;
      final snap = await _jobsRef
          .where('invoiceNumber', whereIn: invoices.sublist(start, end))
          .get();
      activeJobs.addAll(
        snap.docs
            .map(_jobStateFromSnapshot)
            .where((job) => !job.isRejected && job.invoiceNumber.isNotEmpty),
      );
    }

    final invoiceBuckets = <String, List<_InvoiceMigrationJobState>>{};
    for (final job in activeJobs) {
      (invoiceBuckets[job.invoiceNumber] ??= <_InvoiceMigrationJobState>[]).add(
        job,
      );
    }

    final rebuiltClaims = _buildInvoiceClaimDocs(invoiceBuckets);
    final expectedClaimDocIds = invoiceNumbers
        .map(InvoiceUtils.invoiceClaimDocumentId)
        .toSet();

    await _replaceDocumentSet(
      collectionName: AppConstants.invoiceClaimsCollection,
      expectedDocumentIds: expectedClaimDocIds,
      documents: rebuiltClaims,
    );
  }

  Future<void> _rebuildSharedAggregatesForGroups(Set<String> groupKeys) async {
    if (groupKeys.isEmpty) return;

    final activeJobs = <_InvoiceMigrationJobState>[];
    final keys = groupKeys.toList(growable: false);
    for (var start = 0; start < keys.length; start += 10) {
      final end = (start + 10 > keys.length) ? keys.length : start + 10;
      final snap = await _jobsRef
          .where('sharedInstallGroupKey', whereIn: keys.sublist(start, end))
          .get();
      activeJobs.addAll(
        snap.docs
            .map(_jobStateFromSnapshot)
            .where(
              (job) =>
                  !job.isRejected &&
                  job.isSharedInstall &&
                  job.sharedInstallGroupKey.isNotEmpty,
            ),
      );
    }

    final rebuiltAggregates = _buildSharedAggregateDocs(activeJobs);
    final expectedAggregateDocIds = groupKeys
        .map(_sharedAggregateDocId)
        .toSet();

    await _replaceDocumentSet(
      collectionName: AppConstants.sharedInstallAggregatesCollection,
      expectedDocumentIds: expectedAggregateDocIds,
      documents: rebuiltAggregates,
    );
  }

  Future<void> _replaceDocumentSet({
    required String collectionName,
    required Set<String> expectedDocumentIds,
    required Map<String, Map<String, dynamic>> documents,
  }) async {
    if (expectedDocumentIds.isEmpty) return;

    const chunkSize = 200;
    final ids = expectedDocumentIds.toList(growable: false);
    for (var start = 0; start < ids.length; start += chunkSize) {
      final end = (start + chunkSize > ids.length)
          ? ids.length
          : start + chunkSize;
      final batch = firestore.batch();

      for (final id in ids.sublist(start, end)) {
        final ref = firestore.collection(collectionName).doc(id);
        final data = documents[id];
        if (data == null) {
          batch.delete(ref);
        } else {
          batch.set(ref, data);
        }
      }

      await batch.commit();
    }
  }

  Future<Map<String, String>> _loadCompanyPrefixes() async {
    final snap = await _companiesRef.get();
    final prefixes = <String, String>{};
    for (final doc in snap.docs) {
      prefixes[doc.id] = (doc.data()['invoicePrefix'] as String? ?? '').trim();
    }
    return prefixes;
  }

  Future<void> _applyUpdatesInChunks(
    Map<DocumentReference<Map<String, dynamic>>, Map<String, dynamic>> updates,
  ) async {
    if (updates.isEmpty) return;

    const chunkSize = 350;
    final entries = updates.entries.toList(growable: false);
    for (var i = 0; i < entries.length; i += chunkSize) {
      final end = (i + chunkSize > entries.length)
          ? entries.length
          : i + chunkSize;
      final batch = firestore.batch();
      for (final entry in entries.sublist(i, end)) {
        batch.update(entry.key, entry.value);
      }
      await batch.commit();
    }
  }

  Map<String, Map<String, dynamic>> _buildInvoiceClaimDocs(
    Map<String, List<_InvoiceMigrationJobState>> invoiceBuckets,
  ) {
    final runAt = Timestamp.fromDate(DateTime.now());
    final docs = <String, Map<String, dynamic>>{};

    for (final entry in invoiceBuckets.entries) {
      final jobs = entry.value;
      if (jobs.isEmpty) continue;
      final companyIds = jobs
          .map((job) => job.companyId.trim())
          .where((id) => id.isNotEmpty)
          .toSet();
      if (companyIds.length > 1) {
        continue;
      }

      final first = jobs.first;
      docs[InvoiceUtils.invoiceClaimDocumentId(entry.key)] = {
        'invoiceNumber': entry.key,
        'companyId': first.companyId,
        'companyName': first.companyName,
        'reuseMode': jobs.every((job) => job.isSharedInstall)
            ? 'shared'
            : 'solo',
        'activeJobCount': jobs.length,
        'createdBy': first.techId,
        'createdAt': _earliestTimestamp(jobs) ?? runAt,
        'updatedAt': runAt,
      };
    }

    return docs;
  }

  Map<String, Map<String, dynamic>> _buildSharedAggregateDocs(
    List<_InvoiceMigrationJobState> activeJobs,
  ) {
    final runAt = Timestamp.fromDate(DateTime.now());
    final sharedBuckets = <String, List<_InvoiceMigrationJobState>>{};
    for (final job in activeJobs) {
      if (!job.isSharedInstall || job.sharedInstallGroupKey.isEmpty) continue;
      (sharedBuckets[job.sharedInstallGroupKey] ??=
              <_InvoiceMigrationJobState>[])
          .add(job);
    }

    final docs = <String, Map<String, dynamic>>{};
    for (final entry in sharedBuckets.entries) {
      final jobs = entry.value;
      if (jobs.isEmpty) continue;

      final first = jobs.first;
      var consumedSplitUnits = 0;
      var consumedWindowUnits = 0;
      var consumedFreestandingUnits = 0;
      var consumedUninstallSplitUnits = 0;
      var consumedUninstallWindowUnits = 0;
      var consumedUninstallFreestandingUnits = 0;
      var consumedBracketCount = 0;
      var consumedDeliveryAmount = 0.0;

      for (final job in jobs) {
        consumedSplitUnits += _unitsForType(
          job.data,
          AppConstants.unitTypeSplitAc,
        );
        consumedWindowUnits += _unitsForType(
          job.data,
          AppConstants.unitTypeWindowAc,
        );
        consumedFreestandingUnits += _unitsForType(
          job.data,
          AppConstants.unitTypeFreestandingAc,
        );
        consumedUninstallSplitUnits += _unitsForType(
          job.data,
          AppConstants.unitTypeUninstallSplit,
        );
        consumedUninstallWindowUnits += _unitsForType(
          job.data,
          AppConstants.unitTypeUninstallWindow,
        );
        consumedUninstallFreestandingUnits += _unitsForType(
          job.data,
          AppConstants.unitTypeUninstallFreestanding,
        );
        consumedBracketCount += _bracketCount(job.data);
        consumedDeliveryAmount += _deliveryAmount(job.data);
      }

      docs[_sharedAggregateDocId(entry.key)] = {
        'groupKey': entry.key,
        'sharedInvoiceSplitUnits': _readInt(
          first.data,
          'sharedInvoiceSplitUnits',
        ),
        'sharedInvoiceWindowUnits': _readInt(
          first.data,
          'sharedInvoiceWindowUnits',
        ),
        'sharedInvoiceFreestandingUnits': _readInt(
          first.data,
          'sharedInvoiceFreestandingUnits',
        ),
        'sharedInvoiceUninstallSplitUnits': _readInt(
          first.data,
          'sharedInvoiceUninstallSplitUnits',
        ),
        'sharedInvoiceUninstallWindowUnits': _readInt(
          first.data,
          'sharedInvoiceUninstallWindowUnits',
        ),
        'sharedInvoiceUninstallFreestandingUnits': _readInt(
          first.data,
          'sharedInvoiceUninstallFreestandingUnits',
        ),
        'sharedInvoiceBracketCount': _readInt(
          first.data,
          'sharedInvoiceBracketCount',
        ),
        'sharedDeliveryTeamCount': _readInt(
          first.data,
          'sharedDeliveryTeamCount',
        ),
        'sharedInvoiceDeliveryAmount': _readDouble(
          first.data,
          'sharedInvoiceDeliveryAmount',
        ),
        'consumedSplitUnits': consumedSplitUnits,
        'consumedWindowUnits': consumedWindowUnits,
        'consumedFreestandingUnits': consumedFreestandingUnits,
        'consumedUninstallSplitUnits': consumedUninstallSplitUnits,
        'consumedUninstallWindowUnits': consumedUninstallWindowUnits,
        'consumedUninstallFreestandingUnits':
            consumedUninstallFreestandingUnits,
        'consumedBracketCount': consumedBracketCount,
        'consumedDeliveryAmount': consumedDeliveryAmount,
        'createdBy': first.techId,
        'createdAt': _earliestTimestamp(jobs) ?? runAt,
        'updatedAt': runAt,
      };
    }

    return docs;
  }

  Future<void> _setDocumentsInChunks(
    String collectionName,
    Map<String, Map<String, dynamic>> docs,
  ) async {
    if (docs.isEmpty) return;

    const chunkSize = 350;
    final entries = docs.entries.toList(growable: false);
    for (var i = 0; i < entries.length; i += chunkSize) {
      final end = (i + chunkSize > entries.length)
          ? entries.length
          : i + chunkSize;
      final batch = firestore.batch();
      for (final entry in entries.sublist(i, end)) {
        batch.set(
          firestore.collection(collectionName).doc(entry.key),
          entry.value,
        );
      }
      await batch.commit();
    }
  }

  Map<String, dynamic> _copyStringKeyMap(Object? value) {
    if (value is! Map) return <String, dynamic>{};
    return value.map((key, mapValue) => MapEntry(key.toString(), mapValue));
  }

  bool _mapEquals(Map<String, dynamic> left, Map<String, dynamic> right) {
    if (left.length != right.length) return false;
    for (final entry in left.entries) {
      if (!_deepEquals(entry.value, right[entry.key])) {
        return false;
      }
    }
    return true;
  }

  bool _deepEquals(Object? left, Object? right) {
    if (left is List && right is List) {
      if (left.length != right.length) return false;
      for (var i = 0; i < left.length; i++) {
        if (!_deepEquals(left[i], right[i])) return false;
      }
      return true;
    }
    if (left is Map && right is Map) {
      return _mapEquals(_copyStringKeyMap(left), _copyStringKeyMap(right));
    }
    return left == right;
  }

  Timestamp? _earliestTimestamp(List<_InvoiceMigrationJobState> jobs) {
    DateTime? earliest;
    for (final job in jobs) {
      final submittedAt = job.submittedAt;
      if (submittedAt == null) continue;
      if (earliest == null || submittedAt.isBefore(earliest)) {
        earliest = submittedAt;
      }
    }
    return earliest == null ? null : Timestamp.fromDate(earliest);
  }

  DateTime? _timestampToDate(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }

  int _unitsForType(Map<String, dynamic> data, String type) {
    final units = data['acUnits'];
    if (units is! List) return 0;
    var total = 0;
    for (final unit in units) {
      if (unit is! Map) continue;
      final unitType = (unit['type'] as String? ?? '').trim();
      if (unitType != type) continue;
      total += (unit['quantity'] as num?)?.toInt() ?? 0;
    }
    return total;
  }

  int _bracketCount(Map<String, dynamic> data) {
    final charges = data['charges'];
    if (charges is! Map) return 0;
    final explicitCount = (charges['bracketCount'] as num?)?.toInt() ?? 0;
    if (explicitCount > 0) return explicitCount;
    final acBracket = charges['acBracket'] == true;
    final bracketAmount = (charges['bracketAmount'] as num?)?.toDouble() ?? 0;
    return (acBracket || bracketAmount > 0) ? 1 : 0;
  }

  double _deliveryAmount(Map<String, dynamic> data) {
    final charges = data['charges'];
    if (charges is! Map) return 0;
    return (charges['deliveryAmount'] as num?)?.toDouble() ?? 0;
  }

  int _readInt(Map<String, dynamic> data, String key) {
    return (data[key] as num?)?.toInt() ?? 0;
  }

  double _readDouble(Map<String, dynamic> data, String key) {
    return (data[key] as num?)?.toDouble() ?? 0;
  }

  String _sharedAggregateDocId(String groupKey) {
    final safe = groupKey.trim().toLowerCase().replaceAll(
      RegExp(r'[^a-z0-9_-]'),
      '_',
    );
    final scoped = 'shared_${safe.isEmpty ? 'unknown_group' : safe}';
    return scoped.length > 140 ? scoped.substring(0, 140) : scoped;
  }
}
