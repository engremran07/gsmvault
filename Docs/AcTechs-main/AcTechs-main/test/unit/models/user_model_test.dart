import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ac_techs/core/models/user_model.dart';

void main() {
  group('UserModel.fromJson()', () {
    test('parses required fields correctly', () {
      final json = {
        'uid': 'user-001',
        'name': 'Ahmed',
        'email': 'ahmed@example.com',
      };
      final model = UserModel.fromJson(json);

      expect(model.uid, 'user-001');
      expect(model.name, 'Ahmed');
      expect(model.email, 'ahmed@example.com');
    });

    test('applies default role "technician" when absent', () {
      final json = {'uid': 'u1', 'name': 'Ali', 'email': 'ali@example.com'};
      expect(UserModel.fromJson(json).role, 'technician');
    });

    test('parses explicit role "admin"', () {
      final json = {
        'uid': 'u2',
        'name': 'Boss',
        'email': 'boss@example.com',
        'role': 'admin',
      };
      expect(UserModel.fromJson(json).role, 'admin');
    });

    test('applies default isActive true when absent', () {
      final json = {'uid': 'u3', 'name': 'Tech', 'email': 'tech@example.com'};
      expect(UserModel.fromJson(json).isActive, isTrue);
    });

    test('parses isActive false', () {
      final json = {
        'uid': 'u4',
        'name': 'Inactive',
        'email': 'inactive@example.com',
        'isActive': false,
      };
      expect(UserModel.fromJson(json).isActive, isFalse);
    });

    test('applies default language "en" when absent', () {
      final json = {
        'uid': 'u5',
        'name': 'Default',
        'email': 'default@example.com',
      };
      expect(UserModel.fromJson(json).language, 'en');
    });

    test('parses explicit language "ur"', () {
      final json = {
        'uid': 'u6',
        'name': 'Urdu User',
        'email': 'urdu@example.com',
        'language': 'ur',
      };
      expect(UserModel.fromJson(json).language, 'ur');
    });

    test('applies default themeMode "dark" when absent', () {
      final json = {
        'uid': 'u6-theme',
        'name': 'Default Theme',
        'email': 'theme@example.com',
      };
      expect(UserModel.fromJson(json).themeMode, 'dark');
    });

    test('parses explicit themeMode "light"', () {
      final json = {
        'uid': 'u6-theme-light',
        'name': 'Light Theme',
        'email': 'light@example.com',
        'themeMode': 'light',
      };
      expect(UserModel.fromJson(json).themeMode, 'light');
    });

    test('parses createdAt from ISO string', () {
      final json = {
        'uid': 'u7',
        'name': 'Dated',
        'email': 'dated@example.com',
        'createdAt': '2024-06-15T10:30:00.000',
      };
      final model = UserModel.fromJson(json);
      expect(model.createdAt, isNotNull);
      expect(model.createdAt!.year, 2024);
      expect(model.createdAt!.month, 6);
      expect(model.createdAt!.day, 15);
    });

    test('createdAt is null when absent', () {
      final json = {
        'uid': 'u8',
        'name': 'No Date',
        'email': 'nodate@example.com',
      };
      expect(UserModel.fromJson(json).createdAt, isNull);
    });
  });

  group('UserModel.toJson()', () {
    test('serialises all fields', () {
      const model = UserModel(
        uid: 'u-serial',
        name: 'Serialised',
        email: 'serial@example.com',
        role: 'admin',
        isActive: false,
        language: 'ar',
        themeMode: 'light',
      );
      final json = model.toJson();

      expect(json['uid'], 'u-serial');
      expect(json['name'], 'Serialised');
      expect(json['email'], 'serial@example.com');
      expect(json['role'], 'admin');
      expect(json['isActive'], isFalse);
      expect(json['language'], 'ar');
      expect(json['themeMode'], 'light');
      expect(json['createdAt'], isNull);
    });
  });

  group('UserModel.fromFirestore()', () {
    test('normalizes legacy admin role casing', () async {
      final firestore = FakeFirebaseFirestore();
      await firestore.collection('users').doc('legacy-admin').set({
        'name': 'Legacy Admin',
        'email': 'legacy@example.com',
        'role': 'Administrator',
      });

      final doc = await firestore.collection('users').doc('legacy-admin').get();
      final model = UserModel.fromFirestore(doc);

      expect(model.role, 'admin');
      expect(model.isAdmin, isTrue);
    });

    test('applies default themeMode for legacy Firestore docs', () async {
      final firestore = FakeFirebaseFirestore();
      await firestore.collection('users').doc('legacy-theme').set({
        'name': 'Legacy Theme',
        'email': 'legacy-theme@example.com',
        'role': 'technician',
      });

      final doc = await firestore.collection('users').doc('legacy-theme').get();
      final model = UserModel.fromFirestore(doc);

      expect(model.themeMode, 'dark');
    });
  });

  group('UserModel – equality', () {
    test('two models with same data are equal', () {
      const a = UserModel(uid: 'same', name: 'Name', email: 'e@e.com');
      const b = UserModel(uid: 'same', name: 'Name', email: 'e@e.com');
      expect(a, b);
    });

    test('two models with different uids are not equal', () {
      const a = UserModel(uid: 'a', name: 'N', email: 'e@e.com');
      const b = UserModel(uid: 'b', name: 'N', email: 'e@e.com');
      expect(a, isNot(b));
    });
  });

  group('UserModel – copyWith()', () {
    test('copyWith changes only specified field', () {
      const original = UserModel(
        uid: 'uid-1',
        name: 'Original',
        email: 'orig@example.com',
      );
      final updated = original.copyWith(name: 'Updated');

      expect(updated.uid, 'uid-1');
      expect(updated.name, 'Updated');
      expect(updated.email, 'orig@example.com');
    });
  });

  group('UserModelX extensions', () {
    test('isAdmin returns true for role "admin"', () {
      const admin = UserModel(
        uid: 'a',
        name: 'A',
        email: 'a@a.com',
        role: 'admin',
      );
      expect(admin.isAdmin, isTrue);
    });

    test('isAdmin returns false for role "technician"', () {
      const tech = UserModel(
        uid: 't',
        name: 'T',
        email: 't@t.com',
        role: 'technician',
      );
      expect(tech.isAdmin, isFalse);
    });

    test('isTechnician returns true for role "technician"', () {
      const tech = UserModel(uid: 't', name: 'T', email: 't@t.com');
      expect(tech.isTechnician, isTrue);
    });

    test('isTechnician returns false for role "admin"', () {
      const admin = UserModel(
        uid: 'a',
        name: 'A',
        email: 'a@a.com',
        role: 'admin',
      );
      expect(admin.isTechnician, isFalse);
    });

    test(
      'isAdmin and isTechnician are mutually exclusive for standard roles',
      () {
        const admin = UserModel(
          uid: 'a',
          name: 'A',
          email: 'a@a.com',
          role: 'admin',
        );
        const tech = UserModel(
          uid: 't',
          name: 'T',
          email: 't@t.com',
          role: 'technician',
        );
        expect(admin.isAdmin && admin.isTechnician, isFalse);
        expect(tech.isAdmin && tech.isTechnician, isFalse);
      },
    );

    test('toFirestore() excludes uid key', () {
      const model = UserModel(
        uid: 'should-not-appear',
        name: 'Firestore User',
        email: 'fs@example.com',
      );
      final firestoreMap = model.toFirestore();
      expect(firestoreMap.containsKey('uid'), isFalse);
    });

    test('toFirestore() includes name and email', () {
      const model = UserModel(
        uid: 'fs-uid',
        name: 'Stored Name',
        email: 'stored@example.com',
        role: 'admin',
        themeMode: 'highContrast',
      );
      final firestoreMap = model.toFirestore();
      expect(firestoreMap['name'], 'Stored Name');
      expect(firestoreMap['email'], 'stored@example.com');
      expect(firestoreMap['role'], 'admin');
      expect(firestoreMap['themeMode'], 'highContrast');
    });
  });
}
