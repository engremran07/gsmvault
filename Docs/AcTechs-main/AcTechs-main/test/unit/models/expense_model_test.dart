import 'package:flutter_test/flutter_test.dart';
import 'package:ac_techs/core/models/expense_model.dart';

void main() {
  group('ExpenseModel.fromJson()', () {
    Map<String, dynamic> baseExpense() => {
      'techId': 'tech-01',
      'techName': 'Hassan',
      'category': 'Food',
      'amount': 120.0,
    };

    test('parses required fields correctly', () {
      final model = ExpenseModel.fromJson(baseExpense());
      expect(model.techId, 'tech-01');
      expect(model.techName, 'Hassan');
      expect(model.category, 'Food');
      expect(model.amount, 120.0);
    });

    test('defaults id to empty string when absent', () {
      expect(ExpenseModel.fromJson(baseExpense()).id, '');
    });

    test('parses provided id', () {
      final json = {...baseExpense(), 'id': 'exp-999'};
      expect(ExpenseModel.fromJson(json).id, 'exp-999');
    });

    test('defaults note to empty string when absent', () {
      expect(ExpenseModel.fromJson(baseExpense()).note, '');
    });

    test('parses note', () {
      final json = {...baseExpense(), 'note': 'lunch'};
      expect(ExpenseModel.fromJson(json).note, 'lunch');
    });

    test('defaults expenseType to "work" when absent', () {
      expect(ExpenseModel.fromJson(baseExpense()).expenseType, 'work');
    });

    test('parses expenseType "home"', () {
      final json = {...baseExpense(), 'expenseType': 'home'};
      expect(ExpenseModel.fromJson(json).expenseType, 'home');
    });

    test('parses date from ISO string', () {
      final json = {...baseExpense(), 'date': '2024-08-01T00:00:00.000'};
      final model = ExpenseModel.fromJson(json);
      expect(model.date!.year, 2024);
      expect(model.date!.month, 8);
      expect(model.date!.day, 1);
    });

    test('date is null when absent', () {
      expect(ExpenseModel.fromJson(baseExpense()).date, isNull);
    });

    test('createdAt is null when absent', () {
      expect(ExpenseModel.fromJson(baseExpense()).createdAt, isNull);
    });

    test('parses integer amount as double', () {
      final json = {...baseExpense(), 'amount': 50};
      expect(ExpenseModel.fromJson(json).amount, 50.0);
      expect(ExpenseModel.fromJson(json).amount, isA<double>());
    });
  });

  group('ExpenseModel.toJson()', () {
    test('serialises all fields', () {
      const model = ExpenseModel(
        id: 'e-1',
        techId: 'tech-1',
        techName: 'Karim',
        category: 'Petrol',
        amount: 80.0,
        note: 'tank full',
        expenseType: 'work',
      );
      final json = model.toJson();

      expect(json['id'], 'e-1');
      expect(json['techId'], 'tech-1');
      expect(json['techName'], 'Karim');
      expect(json['category'], 'Petrol');
      expect(json['amount'], 80.0);
      expect(json['note'], 'tank full');
      expect(json['expenseType'], 'work');
      expect(json['date'], isNull);
      expect(json['createdAt'], isNull);
    });
  });

  group('ExpenseModel – equality', () {
    test('two models with same data are equal', () {
      const a = ExpenseModel(
        techId: 't',
        techName: 'N',
        category: 'Food',
        amount: 10.0,
      );
      const b = ExpenseModel(
        techId: 't',
        techName: 'N',
        category: 'Food',
        amount: 10.0,
      );
      expect(a, b);
    });

    test('different amounts make models unequal', () {
      const a = ExpenseModel(
        techId: 't',
        techName: 'N',
        category: 'Food',
        amount: 10.0,
      );
      const b = ExpenseModel(
        techId: 't',
        techName: 'N',
        category: 'Food',
        amount: 20.0,
      );
      expect(a, isNot(b));
    });
  });

  group('ExpenseModel – copyWith()', () {
    test('copyWith updates specified field only', () {
      const original = ExpenseModel(
        techId: 'tech-1',
        techName: 'Original Tech',
        category: 'Food',
        amount: 50.0,
      );
      final updated = original.copyWith(amount: 100.0);

      expect(updated.techId, 'tech-1');
      expect(updated.category, 'Food');
      expect(updated.amount, 100.0);
    });
  });

  group('ExpenseModelX – toFirestore()', () {
    test('excludes id key', () {
      const model = ExpenseModel(
        id: 'should-not-appear',
        techId: 't',
        techName: 'N',
        category: 'Gas',
        amount: 30.0,
      );
      expect(model.toFirestore().containsKey('id'), isFalse);
    });

    test('includes category and amount', () {
      const model = ExpenseModel(
        id: 'e-2',
        techId: 't',
        techName: 'N',
        category: 'Tools',
        amount: 200.0,
      );
      final fs = model.toFirestore();
      expect(fs['category'], 'Tools');
      expect(fs['amount'], 200.0);
    });
  });
}
