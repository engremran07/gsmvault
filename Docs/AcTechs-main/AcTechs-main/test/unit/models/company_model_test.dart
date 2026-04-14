import 'package:flutter_test/flutter_test.dart';
import 'package:ac_techs/core/models/company_model.dart';

void main() {
  group('CompanyModel.fromJson()', () {
    test('parses required name field', () {
      final model = CompanyModel.fromJson({'name': 'ArcticCool'});
      expect(model.name, 'ArcticCool');
    });

    test('defaults id to empty string when absent', () {
      expect(CompanyModel.fromJson({'name': 'C'}).id, '');
    });

    test('parses provided id', () {
      final json = {'id': 'comp-1', 'name': 'IceTech'};
      expect(CompanyModel.fromJson(json).id, 'comp-1');
    });

    test('defaults invoicePrefix to empty string when absent', () {
      expect(CompanyModel.fromJson({'name': 'C'}).invoicePrefix, '');
    });

    test('parses invoicePrefix', () {
      final json = {'name': 'AcmeCo', 'invoicePrefix': 'ACM'};
      expect(CompanyModel.fromJson(json).invoicePrefix, 'ACM');
    });

    test('defaults isActive to true when absent', () {
      expect(CompanyModel.fromJson({'name': 'C'}).isActive, isTrue);
    });

    test('parses isActive false', () {
      final json = {'name': 'OldCo', 'isActive': false};
      expect(CompanyModel.fromJson(json).isActive, isFalse);
    });

    test('createdAt is null when absent', () {
      expect(CompanyModel.fromJson({'name': 'C'}).createdAt, isNull);
    });

    test('parses createdAt from ISO string', () {
      final json = {'name': 'Dated Co', 'createdAt': '2023-01-01T00:00:00.000'};
      final model = CompanyModel.fromJson(json);
      expect(model.createdAt!.year, 2023);
      expect(model.createdAt!.month, 1);
      expect(model.createdAt!.day, 1);
    });
  });

  group('CompanyModel.toJson()', () {
    test('serialises all fields', () {
      const model = CompanyModel(
        id: 'comp-2',
        name: 'FrostBreeze',
        invoicePrefix: 'FB',
        isActive: true,
      );
      final json = model.toJson();

      expect(json['id'], 'comp-2');
      expect(json['name'], 'FrostBreeze');
      expect(json['invoicePrefix'], 'FB');
      expect(json['isActive'], isTrue);
      expect(json['createdAt'], isNull);
    });
  });

  group('CompanyModel – equality', () {
    test('two models with same data are equal', () {
      const a = CompanyModel(id: 'c1', name: 'Same Co', invoicePrefix: 'SC');
      const b = CompanyModel(id: 'c1', name: 'Same Co', invoicePrefix: 'SC');
      expect(a, b);
    });

    test('different names make models unequal', () {
      const a = CompanyModel(name: 'Alpha');
      const b = CompanyModel(name: 'Beta');
      expect(a, isNot(b));
    });

    test('different isActive values make models unequal', () {
      const a = CompanyModel(name: 'Co', isActive: true);
      const b = CompanyModel(name: 'Co', isActive: false);
      expect(a, isNot(b));
    });
  });

  group('CompanyModel – copyWith()', () {
    test('copyWith changes only specified field', () {
      const original = CompanyModel(
        id: 'c1',
        name: 'Original',
        invoicePrefix: 'OR',
        isActive: true,
      );
      final updated = original.copyWith(isActive: false);

      expect(updated.id, 'c1');
      expect(updated.name, 'Original');
      expect(updated.invoicePrefix, 'OR');
      expect(updated.isActive, isFalse);
    });

    test('copyWith can update name', () {
      const original = CompanyModel(name: 'OldName', invoicePrefix: 'ON');
      final updated = original.copyWith(name: 'NewName');
      expect(updated.name, 'NewName');
      expect(updated.invoicePrefix, 'ON');
    });
  });

  group('CompanyModelX – toFirestore()', () {
    test('excludes id key', () {
      const model = CompanyModel(
        id: 'should-not-appear',
        name: 'TestCo',
        invoicePrefix: 'TC',
      );
      expect(model.toFirestore().containsKey('id'), isFalse);
    });

    test('includes name and invoicePrefix', () {
      const model = CompanyModel(
        id: 'comp-x',
        name: 'StoredCo',
        invoicePrefix: 'STC',
        isActive: false,
      );
      final fs = model.toFirestore();
      expect(fs['name'], 'StoredCo');
      expect(fs['invoicePrefix'], 'STC');
      expect(fs['isActive'], isFalse);
    });
  });
}
