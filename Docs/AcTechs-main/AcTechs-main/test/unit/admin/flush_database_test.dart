import 'package:flutter_test/flutter_test.dart';
import 'package:ac_techs/core/models/app_exception.dart';

// NOTE: Full integration tests for flushDatabase() and verifyAdminPassword()
// require a live Firestore/Auth instance and are covered by E2E tests.
// These unit tests cover the pure exception logic for the flush feature.

void main() {
  // ── AdminException.flushFailed ──────────────────────────────────────────
  group('AdminException.flushFailed()', () {
    test('has code admin_flush_failed', () {
      expect(AdminException.flushFailed().code, 'admin_flush_failed');
    });

    test('English message mentions flush or connection', () {
      final msg = AdminException.flushFailed().message('en');
      expect(
        msg.toLowerCase(),
        anyOf(contains('flush'), contains('connection')),
      );
    });

    test('Urdu message is non-empty', () {
      expect(AdminException.flushFailed().message('ur'), isNotEmpty);
    });

    test('Arabic message is non-empty', () {
      expect(AdminException.flushFailed().message('ar'), isNotEmpty);
    });

    test('unknown locale falls back to English', () {
      expect(
        AdminException.flushFailed().message('xx'),
        AdminException.flushFailed().message('en'),
      );
    });

    test('is a subtype of AppException', () {
      expect(AdminException.flushFailed(), isA<AppException>());
    });

    test('toString includes type and code', () {
      final str = AdminException.flushFailed().toString();
      expect(str, contains('AdminException'));
      expect(str, contains('admin_flush_failed'));
    });
  });

  // ── AdminException.wrongPassword ────────────────────────────────────────
  group('AdminException.wrongPassword()', () {
    test('has code admin_wrong_password', () {
      expect(AdminException.wrongPassword().code, 'admin_wrong_password');
    });

    test('English message mentions password', () {
      expect(
        AdminException.wrongPassword().message('en').toLowerCase(),
        contains('password'),
      );
    });

    test('Urdu message is non-empty', () {
      expect(AdminException.wrongPassword().message('ur'), isNotEmpty);
    });

    test('Arabic message is non-empty', () {
      expect(AdminException.wrongPassword().message('ar'), isNotEmpty);
    });

    test('unknown locale falls back to English', () {
      expect(
        AdminException.wrongPassword().message('fr'),
        AdminException.wrongPassword().message('en'),
      );
    });

    test('is a subtype of AppException', () {
      expect(AdminException.wrongPassword(), isA<AppException>());
    });

    test('toString includes type and code', () {
      final str = AdminException.wrongPassword().toString();
      expect(str, contains('AdminException'));
      expect(str, contains('admin_wrong_password'));
    });
  });

  // ── Flush exception distinctness ────────────────────────────────────────
  group('Flush exceptions are distinct', () {
    test('flushFailed and wrongPassword have different codes', () {
      expect(
        AdminException.flushFailed().code,
        isNot(AdminException.wrongPassword().code),
      );
    });

    test('flushFailed and noPermission have different codes', () {
      expect(
        AdminException.flushFailed().code,
        isNot(AdminException.noPermission().code),
      );
    });

    test('wrongPassword and noPermission have different codes', () {
      expect(
        AdminException.wrongPassword().code,
        isNot(AdminException.noPermission().code),
      );
    });
  });
}
