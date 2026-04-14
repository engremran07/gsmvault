import 'package:flutter_test/flutter_test.dart';
import 'package:ac_techs/core/models/earning_model.dart';

void main() {
  group('EarningModel.fromJson()', () {
    Map<String, dynamic> baseEarning() => {
      'techId': 'tech-02',
      'techName': 'Bilal',
      'category': 'Sold Old AC',
      'amount': 500.0,
    };

    test('parses required fields correctly', () {
      final model = EarningModel.fromJson(baseEarning());
      expect(model.techId, 'tech-02');
      expect(model.techName, 'Bilal');
      expect(model.category, 'Sold Old AC');
      expect(model.amount, 500.0);
    });

    test('defaults id to empty string when absent', () {
      expect(EarningModel.fromJson(baseEarning()).id, '');
    });

    test('parses provided id', () {
      final json = {...baseEarning(), 'id': 'earn-100'};
      expect(EarningModel.fromJson(json).id, 'earn-100');
    });

    test('defaults note to empty string when absent', () {
      expect(EarningModel.fromJson(baseEarning()).note, '');
    });

    test('parses note', () {
      final json = {...baseEarning(), 'note': 'decent price'};
      expect(EarningModel.fromJson(json).note, 'decent price');
    });

    test('parses date from ISO string', () {
      final json = {...baseEarning(), 'date': '2024-09-10T12:00:00.000'};
      final model = EarningModel.fromJson(json);
      expect(model.date!.year, 2024);
      expect(model.date!.month, 9);
      expect(model.date!.day, 10);
    });

    test('date is null when absent', () {
      expect(EarningModel.fromJson(baseEarning()).date, isNull);
    });

    test('createdAt is null when absent', () {
      expect(EarningModel.fromJson(baseEarning()).createdAt, isNull);
    });

    test('parses integer amount as double', () {
      final json = {...baseEarning(), 'amount': 300};
      final model = EarningModel.fromJson(json);
      expect(model.amount, 300.0);
      expect(model.amount, isA<double>());
    });
  });

  group('EarningModel.toJson()', () {
    test('serialises all fields', () {
      const model = EarningModel(
        id: 'earn-1',
        techId: 'tech-2',
        techName: 'Faisal',
        category: 'Sold Scrap',
        amount: 150.0,
        note: 'copper pipes',
      );
      final json = model.toJson();

      expect(json['id'], 'earn-1');
      expect(json['techId'], 'tech-2');
      expect(json['techName'], 'Faisal');
      expect(json['category'], 'Sold Scrap');
      expect(json['amount'], 150.0);
      expect(json['note'], 'copper pipes');
      expect(json['date'], isNull);
      expect(json['createdAt'], isNull);
    });
  });

  group('EarningModel – equality', () {
    test('two models with same data are equal', () {
      const a = EarningModel(
        techId: 't',
        techName: 'N',
        category: 'Sold Scrap',
        amount: 200.0,
      );
      const b = EarningModel(
        techId: 't',
        techName: 'N',
        category: 'Sold Scrap',
        amount: 200.0,
      );
      expect(a, b);
    });

    test('different categories make models unequal', () {
      const a = EarningModel(
        techId: 't',
        techName: 'N',
        category: 'Sold Scrap',
        amount: 200.0,
      );
      const b = EarningModel(
        techId: 't',
        techName: 'N',
        category: 'Sold Old AC',
        amount: 200.0,
      );
      expect(a, isNot(b));
    });
  });

  group('EarningModel – copyWith()', () {
    test('copyWith updates specified field only', () {
      const original = EarningModel(
        techId: 'tech-1',
        techName: 'Original',
        category: 'Sold Scrap',
        amount: 100.0,
      );
      final updated = original.copyWith(amount: 250.0, note: 'updated note');

      expect(updated.techId, 'tech-1');
      expect(updated.category, 'Sold Scrap');
      expect(updated.amount, 250.0);
      expect(updated.note, 'updated note');
    });
  });

  group('EarningModelX – toFirestore()', () {
    test('excludes id key', () {
      const model = EarningModel(
        id: 'should-not-appear',
        techId: 't',
        techName: 'N',
        category: 'Old AC Removal',
        amount: 75.0,
      );
      expect(model.toFirestore().containsKey('id'), isFalse);
    });

    test('includes category and amount', () {
      const model = EarningModel(
        id: 'earn-3',
        techId: 't',
        techName: 'N',
        category: 'Installed Bracket',
        amount: 120.0,
      );
      final fs = model.toFirestore();
      expect(fs['category'], 'Installed Bracket');
      expect(fs['amount'], 120.0);
    });

    test('includes techName', () {
      const model = EarningModel(
        id: 'earn-4',
        techId: 'tech-x',
        techName: 'Stored Name',
        category: 'Other',
        amount: 50.0,
      );
      expect(model.toFirestore()['techName'], 'Stored Name');
    });
  });
}
