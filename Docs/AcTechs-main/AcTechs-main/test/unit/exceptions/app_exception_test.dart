import 'package:flutter_test/flutter_test.dart';
import 'package:ac_techs/core/models/app_exception.dart';

void main() {
  group('AppException', () {
    group('message()', () {
      test('returns English message for "en" locale', () {
        final ex = AuthException.wrongCredentials();
        expect(
          ex.message('en'),
          'Wrong username or password. Please check and try again.',
        );
      });

      test('returns Urdu message for "ur" locale', () {
        final ex = AuthException.wrongCredentials();
        expect(
          ex.message('ur'),
          'غلط نام یا پاس ورڈ۔ براہ کرم دوبارہ چیک کریں۔',
        );
      });

      test('returns Arabic message for "ar" locale', () {
        final ex = AuthException.wrongCredentials();
        expect(
          ex.message('ar'),
          'اسم مستخدم أو كلمة مرور خاطئة. يرجى المحاولة مرة أخرى.',
        );
      });

      test('falls back to English for unknown locale', () {
        final ex = AuthException.wrongCredentials();
        expect(
          ex.message('fr'),
          'Wrong username or password. Please check and try again.',
        );
      });
    });

    group('toString()', () {
      test('includes runtimeType, code and English message', () {
        final ex = AuthException.wrongCredentials();
        final str = ex.toString();
        expect(str, contains('AuthException'));
        expect(str, contains('auth_wrong_credentials'));
        expect(str, contains('Wrong username or password'));
      });
    });
  });

  // ────────────────────────────────────────────────────────────
  group('AuthException', () {
    test('wrongCredentials has correct code', () {
      expect(AuthException.wrongCredentials().code, 'auth_wrong_credentials');
    });

    test('accountDisabled has correct code', () {
      expect(AuthException.accountDisabled().code, 'auth_account_disabled');
    });

    test('tooManyAttempts has correct code', () {
      expect(AuthException.tooManyAttempts().code, 'auth_too_many_attempts');
    });

    test('sessionExpired has correct code', () {
      expect(AuthException.sessionExpired().code, 'auth_session_expired');
    });

    group('fromFirebase()', () {
      test('maps wrong-password to wrongCredentials', () {
        final ex = AuthException.fromFirebase('wrong-password');
        expect(ex.code, 'auth_wrong_credentials');
      });

      test('maps user-not-found to wrongCredentials', () {
        final ex = AuthException.fromFirebase('user-not-found');
        expect(ex.code, 'auth_wrong_credentials');
      });

      test('maps invalid-credential to wrongCredentials', () {
        final ex = AuthException.fromFirebase('invalid-credential');
        expect(ex.code, 'auth_wrong_credentials');
      });

      test('maps user-disabled to accountDisabled', () {
        final ex = AuthException.fromFirebase('user-disabled');
        expect(ex.code, 'auth_account_disabled');
      });

      test('maps too-many-requests to tooManyAttempts', () {
        final ex = AuthException.fromFirebase('too-many-requests');
        expect(ex.code, 'auth_too_many_attempts');
      });

      test('maps unknown code to auth_unknown', () {
        final ex = AuthException.fromFirebase('some-other-error');
        expect(ex.code, 'auth_unknown');
      });

      test('auth_unknown has English message', () {
        final ex = AuthException.fromFirebase('unknown');
        expect(ex.message('en'), 'Something went wrong. Please try again.');
      });
    });

    test('accountDisabled Urdu message is non-empty', () {
      expect(AuthException.accountDisabled().message('ur'), isNotEmpty);
    });

    test('tooManyAttempts Arabic message is non-empty', () {
      expect(AuthException.tooManyAttempts().message('ar'), isNotEmpty);
    });

    test('sessionExpired is an AppException', () {
      expect(AuthException.sessionExpired(), isA<AppException>());
    });
  });

  // ────────────────────────────────────────────────────────────
  group('NetworkException', () {
    test('offline has correct code', () {
      expect(NetworkException.offline().code, 'network_offline');
    });

    test('syncFailed has correct code', () {
      expect(NetworkException.syncFailed().code, 'network_sync_failed');
    });

    test('offline English message mentions offline', () {
      expect(NetworkException.offline().message('en'), contains('offline'));
    });

    test('offline Urdu message is non-empty', () {
      expect(NetworkException.offline().message('ur'), isNotEmpty);
    });

    test('syncFailed Arabic message is non-empty', () {
      expect(NetworkException.syncFailed().message('ar'), isNotEmpty);
    });

    test('is an AppException', () {
      expect(NetworkException.offline(), isA<AppException>());
    });
  });

  // ────────────────────────────────────────────────────────────
  group('JobException', () {
    test('noInvoice has correct code', () {
      expect(JobException.noInvoice().code, 'job_no_invoice');
    });

    test('noUnits has correct code', () {
      expect(JobException.noUnits().code, 'job_no_units');
    });

    test('saveFailed has correct code', () {
      expect(JobException.saveFailed().code, 'job_save_failed');
    });

    test('duplicateInvoice has correct code', () {
      expect(JobException.duplicateInvoice().code, 'job_duplicate_invoice');
    });

    test('noInvoice English message asks to enter invoice number', () {
      expect(
        JobException.noInvoice().message('en'),
        contains('invoice number'),
      );
    });

    test('noUnits Urdu message is non-empty', () {
      expect(JobException.noUnits().message('ur'), isNotEmpty);
    });

    test('duplicateInvoice Arabic message is non-empty', () {
      expect(JobException.duplicateInvoice().message('ar'), isNotEmpty);
    });

    test('is an AppException', () {
      expect(JobException.saveFailed(), isA<AppException>());
    });
  });

  // ────────────────────────────────────────────────────────────
  group('AdminException', () {
    test('rejectNoReason has correct code', () {
      expect(AdminException.rejectNoReason().code, 'admin_reject_no_reason');
    });

    test('noPermission has correct code', () {
      expect(AdminException.noPermission().code, 'admin_no_permission');
    });

    test('rejectNoReason English message mentions reason', () {
      expect(AdminException.rejectNoReason().message('en'), contains('reason'));
    });

    test('noPermission Urdu message is non-empty', () {
      expect(AdminException.noPermission().message('ur'), isNotEmpty);
    });

    test('noPermission Arabic message is non-empty', () {
      expect(AdminException.noPermission().message('ar'), isNotEmpty);
    });

    test('is an AppException', () {
      expect(AdminException.noPermission(), isA<AppException>());
    });

    test('flushFailed has correct code', () {
      expect(AdminException.flushFailed().code, 'admin_flush_failed');
    });

    test('flushFailed English message mentions flush', () {
      expect(AdminException.flushFailed().message('en'), contains('flush'));
    });

    test('flushFailed Urdu message is non-empty', () {
      expect(AdminException.flushFailed().message('ur'), isNotEmpty);
    });

    test('flushFailed Arabic message is non-empty', () {
      expect(AdminException.flushFailed().message('ar'), isNotEmpty);
    });

    test('flushFailed is an AppException', () {
      expect(AdminException.flushFailed(), isA<AppException>());
    });

    test('wrongPassword has correct code', () {
      expect(AdminException.wrongPassword().code, 'admin_wrong_password');
    });

    test('wrongPassword English message mentions password', () {
      expect(
        AdminException.wrongPassword().message('en'),
        contains('password'),
      );
    });

    test('wrongPassword Urdu message is non-empty', () {
      expect(AdminException.wrongPassword().message('ur'), isNotEmpty);
    });

    test('wrongPassword Arabic message is non-empty', () {
      expect(AdminException.wrongPassword().message('ar'), isNotEmpty);
    });

    test('wrongPassword is an AppException', () {
      expect(AdminException.wrongPassword(), isA<AppException>());
    });
  });

  // ────────────────────────────────────────────────────────────
  group('ExpenseException', () {
    test('saveFailed has correct code', () {
      expect(ExpenseException.saveFailed().code, 'expense_save_failed');
    });

    test('deleteFailed has correct code', () {
      expect(ExpenseException.deleteFailed().code, 'expense_delete_failed');
    });

    test('userSaveFailed has correct code', () {
      expect(ExpenseException.userSaveFailed().code, 'user_save_failed');
    });

    test('saveFailed English message mentions connection', () {
      expect(
        ExpenseException.saveFailed().message('en'),
        contains('connection'),
      );
    });

    test('deleteFailed Urdu message is non-empty', () {
      expect(ExpenseException.deleteFailed().message('ur'), isNotEmpty);
    });

    test('userSaveFailed Arabic message is non-empty', () {
      expect(ExpenseException.userSaveFailed().message('ar'), isNotEmpty);
    });

    test('is an AppException', () {
      expect(ExpenseException.saveFailed(), isA<AppException>());
    });
  });
}
