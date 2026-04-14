import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ac_techs/core/models/approval_config.dart';

void main() {
  group('ApprovalConfig', () {
    test('parses lockedBefore timestamp and evaluates locked dates', () {
      final config = ApprovalConfig.fromMap({
        'lockedBefore': Timestamp.fromDate(DateTime(2026, 4, 1)),
      });

      expect(config.lockedBeforeDate, DateTime(2026, 4, 1));
      expect(config.locksDate(DateTime(2026, 3, 31, 23, 59)), isTrue);
      expect(config.locksDate(DateTime(2026, 4, 1)), isFalse);
    });

    test('copyWith can clear lockedBeforeDate', () {
      final original = ApprovalConfig.fromMap({
        'lockedBefore': Timestamp.fromDate(DateTime(2026, 4, 1)),
      });

      final updated = original.copyWith(clearLockedBeforeDate: true);
      expect(updated.lockedBeforeDate, isNull);
    });
  });
}
