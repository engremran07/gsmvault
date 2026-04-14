import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ac_techs/core/models/models.dart';
import 'package:ac_techs/core/constants/app_constants.dart';

const _kRememberEmailKey = 'remember_email';
const _kRememberMeKey = 'remember_me';
const _kClearFirestoreCacheOnLaunchKey = 'clear_firestore_cache_on_launch';
const _kProfileSyncAtPrefix = 'profile_sync_at_';
const _kLastSyncedEmailPrefix = 'profile_sync_email_';
const _kProfileSyncCooldown = Duration(hours: 24);

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    auth: FirebaseAuth.instance,
    firestore: FirebaseFirestore.instance,
  );
});

class AuthRepository {
  AuthRepository({required this.auth, required this.firestore});

  static const Set<String> _supportedLanguages = {'en', 'ur', 'ar'};
  static const Set<String> _supportedThemeModes = {
    'auto',
    'dark',
    'light',
    'highContrast',
  };

  final FirebaseAuth auth;
  final FirebaseFirestore firestore;

  Stream<User?> get authStateChanges =>
      auth.userChanges().asyncMap((user) async {
        if (user != null && await _shouldSyncProfile(user.uid)) {
          await _syncProfileFromAuth(user);
        }
        return user;
      });

  User? get currentUser => auth.currentUser;

  DocumentReference<Map<String, dynamic>> _userDocRef(String uid) {
    return firestore.collection(AppConstants.usersCollection).doc(uid);
  }

  String _profileSyncKey(String uid) => '$_kProfileSyncAtPrefix$uid';

  String _normalizedEmail(String email) => email.trim().toLowerCase();

  Future<bool> _shouldSyncProfile(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    final lastSyncedAt = prefs.getInt(_profileSyncKey(uid));
    if (lastSyncedAt == null) return true;

    final elapsed = DateTime.now().millisecondsSinceEpoch - lastSyncedAt;
    return elapsed >= _kProfileSyncCooldown.inMilliseconds;
  }

  Future<void> _markProfileSynced(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
      _profileSyncKey(uid),
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  Future<void> _prepareForSignOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kRememberMeKey);
    await prefs.remove(_kRememberEmailKey);
    await prefs.setBool(_kClearFirestoreCacheOnLaunchKey, true);
  }

  Future<void> _forceSessionSignOut() async {
    await _prepareForSignOut();
    await auth.signOut();
  }

  Map<String, dynamic> _authProfileMirrorUpdates({
    required Map<String, dynamic> currentData,
    required User user,
  }) {
    final authEmail = (user.email ?? '').trim();
    if (authEmail.isEmpty) {
      return const <String, dynamic>{};
    }

    final normalizedEmail = _normalizedEmail(authEmail);
    final updates = <String, dynamic>{};
    if (currentData['email'] != authEmail) {
      updates['email'] = authEmail;
    }
    if (currentData['emailLower'] != normalizedEmail) {
      updates['emailLower'] = normalizedEmail;
    }
    return updates;
  }

  Future<void> _syncProfileFromAuth(User user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final authEmail = (user.email ?? '').trim();
      final cachedEmail =
          prefs.getString('$_kLastSyncedEmailPrefix${user.uid}') ?? '';
      final userDocRef = _userDocRef(user.uid);
      final userDoc = await userDocRef.get();
      if (!userDoc.exists) return;

      final data = userDoc.data() ?? {};
      final updates = _authProfileMirrorUpdates(currentData: data, user: user);

      if (cachedEmail == authEmail && updates.isEmpty) {
        await _markProfileSynced(user.uid);
        return;
      }

      if (updates.isNotEmpty) {
        await userDocRef.update(updates);
      }

      await prefs.setString('$_kLastSyncedEmailPrefix${user.uid}', authEmail);

      await _markProfileSynced(user.uid);
    } on FirebaseException catch (e) {
      debugPrint('profile sync Firestore error: ${e.code} — ${e.message}');
    } catch (e) {
      debugPrint('profile sync unknown error: $e');
    }
  }

  Future<UserModel> signIn(String email, String password) async {
    try {
      final credential = await auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final uid = credential.user!.uid;
      final userDocRef = _userDocRef(uid);
      var userDoc = await userDocRef.get();

      if (!userDoc.exists) {
        await _forceSessionSignOut();
        throw AuthException.accountNotProvisioned();
      } else {
        final data = userDoc.data() ?? {};
        final updates = _authProfileMirrorUpdates(
          currentData: data,
          user: credential.user!,
        );
        if (updates.isNotEmpty) {
          try {
            await userDocRef.update(updates);
            userDoc = await userDocRef.get();
          } on FirebaseException catch (e) {
            debugPrint('signIn profile sync error: ${e.code} — ${e.message}');
          }
        }
      }

      final user = UserModel.fromFirestore(userDoc);

      if (!user.isActive) {
        await _forceSessionSignOut();
        throw AuthException.accountDisabled();
      }

      return user;
    } on FirebaseAuthException catch (e) {
      throw AuthException.fromFirebase(e.code);
    } on FirebaseException catch (e) {
      // If user profile document cannot be read (for example permission denied
      // or doc path mismatch), force sign-out to avoid auth/profile drift.
      await _forceSessionSignOut();
      debugPrint('signIn Firestore error: ${e.code} — ${e.message}');
      if (e.code == 'permission-denied') {
        throw AuthException.accountNotProvisioned();
      }
      if (e.code == 'unavailable') {
        throw NetworkException.offline();
      }
      throw AuthException.wrongCredentials();
    } on AuthException {
      rethrow;
    } catch (_) {
      throw AuthException.wrongCredentials();
    }
  }

  /// Update the current user's display name in both Firebase Auth and Firestore.
  Future<void> updateDisplayName(String name) async {
    try {
      final user = auth.currentUser;
      if (user == null) throw AuthException.sessionExpired();
      final trimmedName = name.trim();
      if (trimmedName.isEmpty) throw AuthException.updateFailed();
      // Update Firebase Auth displayName
      await user.updateDisplayName(trimmedName);
      // Update Firestore
      await _userDocRef(user.uid).update({'name': trimmedName});
    } on AuthException {
      rethrow;
    } on FirebaseException catch (e) {
      debugPrint('updateDisplayName error: ${e.code} — ${e.message}');
      throw AuthException.updateFailed();
    }
  }

  Future<void> updateLanguage(String language) async {
    try {
      final user = auth.currentUser;
      if (user == null) throw AuthException.sessionExpired();
      final normalizedLanguage = language.trim().toLowerCase();
      if (!_supportedLanguages.contains(normalizedLanguage)) {
        throw AuthException.updateFailed();
      }
      await _userDocRef(user.uid).update({'language': normalizedLanguage});
    } on AuthException {
      rethrow;
    } on FirebaseException catch (e) {
      debugPrint('updateLanguage error: ${e.code} — ${e.message}');
      throw AuthException.updateFailed();
    }
  }

  Future<void> updateThemeMode(String themeMode) async {
    try {
      final user = auth.currentUser;
      if (user == null) throw AuthException.sessionExpired();
      final normalizedThemeMode = themeMode.trim();
      if (!_supportedThemeModes.contains(normalizedThemeMode)) {
        throw AuthException.updateFailed();
      }
      await _userDocRef(user.uid).update({'themeMode': normalizedThemeMode});
    } on AuthException {
      rethrow;
    } on FirebaseException catch (e) {
      debugPrint('updateThemeMode error: ${e.code} — ${e.message}');
      throw AuthException.updateFailed();
    }
  }

  Future<void> _reauthenticateWithPassword(String currentPassword) async {
    final user = auth.currentUser;
    if (user == null || user.email == null) {
      throw AuthException.sessionExpired();
    }
    try {
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        throw AuthException.wrongCredentials();
      }
      if (e.code == 'too-many-requests') {
        throw AuthException.tooManyAttempts();
      }
      throw AuthException.updateFailed();
    }
  }

  Future<void> updateEmail({
    required String newEmail,
    required String currentPassword,
  }) async {
    try {
      await _reauthenticateWithPassword(currentPassword);
      final user = auth.currentUser;
      if (user == null) throw AuthException.sessionExpired();

      await user.verifyBeforeUpdateEmail(newEmail);
    } on AuthException {
      rethrow;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'invalid-email') throw AuthException.invalidEmail();
      if (e.code == 'email-already-in-use') {
        throw AuthException.emailAlreadyInUse();
      }
      if (e.code == 'requires-recent-login') {
        throw AuthException.recentLoginRequired();
      }
      if (e.code == 'network-request-failed') {
        throw NetworkException.offline();
      }
      throw AuthException.updateFailed();
    } on FirebaseException {
      throw AuthException.updateFailed();
    }
  }

  Future<void> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      await _reauthenticateWithPassword(currentPassword);
      final user = auth.currentUser;
      if (user == null) throw AuthException.sessionExpired();

      await user.updatePassword(newPassword);
    } on AuthException {
      rethrow;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') throw AuthException.weakPassword();
      if (e.code == 'requires-recent-login') {
        throw AuthException.recentLoginRequired();
      }
      if (e.code == 'network-request-failed') {
        throw NetworkException.offline();
      }
      throw AuthException.updateFailed();
    }
  }

  Future<void> sendPasswordReset(String email) async {
    try {
      final settings = ActionCodeSettings(
        url: 'https://actechs-d415e.web.app',
        handleCodeInApp: false,
        androidPackageName: 'com.actechs.pk',
        androidInstallApp: false,
        androidMinimumVersion: '29',
      );
      await auth.sendPasswordResetEmail(
        email: email,
        actionCodeSettings: settings,
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'network-request-failed') {
        throw AuthException.resetNetworkError();
      }
      if (e.code == 'too-many-requests') {
        throw AuthException.resetRateLimit();
      }
      throw AuthException.resetFailed();
    }
  }

  Future<void> signOut() async {
    await _prepareForSignOut();
    await auth.signOut();
    // NOTE: We do NOT call firestore.terminate() / clearPersistence() here.
    // Doing so kills the singleton Firestore instance, breaking all
    // subsequent Firestore operations after re-login. Instead, provider
    // invalidation in SignInNotifier ensures data isolation between sessions.
    // A safe cache wipe is scheduled for the next cold start.
  }

  Future<UserModel?> getCurrentUserModel() async {
    final user = auth.currentUser;
    if (user == null) return null;

    final doc = await _userDocRef(user.uid).get();

    if (!doc.exists) return null;
    return UserModel.fromFirestore(doc);
  }

  Stream<UserModel?> userStream(String uid) {
    final controller = StreamController<UserModel?>();
    final sub = firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .snapshots()
        .listen(
          (doc) {
            if (!doc.exists) {
              unawaited(_forceSessionSignOut());
              controller.add(null);
              return;
            }

            final userModel = UserModel.fromFirestore(doc);
            controller.add(userModel);

            if (!userModel.isActive) {
              unawaited(_forceSessionSignOut());
            }
          },
          onError: (error, stackTrace) {
            if (error is FirebaseException &&
                error.code == 'permission-denied') {
              debugPrint('userStream permission denied for uid=$uid');
              unawaited(_forceSessionSignOut());
              controller.add(null);
              return;
            }
            controller.addError(error, stackTrace);
          },
        );

    controller.onCancel = () async {
      await sub.cancel();
    };

    return controller.stream;
  }
}
