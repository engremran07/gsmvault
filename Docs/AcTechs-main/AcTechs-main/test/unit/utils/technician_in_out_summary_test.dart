import 'package:flutter_test/flutter_test.dart';
import 'package:ac_techs/core/models/earning_model.dart';
import 'package:ac_techs/core/models/expense_model.dart';
import 'package:ac_techs/core/utils/technician_day_in_out_summary.dart';
import 'package:ac_techs/core/utils/technician_in_out_summary.dart';

void main() {
  EarningModel buildEarning({
    required double amount,
    required String category,
    required DateTime date,
  }) {
    return EarningModel(
      techId: 'tech-1',
      techName: 'Ahsan',
      category: category,
      amount: amount,
      date: date,
    );
  }

  ExpenseModel buildExpense({
    required double amount,
    required String category,
    required String expenseType,
    required DateTime date,
  }) {
    return ExpenseModel(
      techId: 'tech-1',
      techName: 'Ahsan',
      category: category,
      amount: amount,
      expenseType: expenseType,
      date: date,
    );
  }

  group('TechnicianInOutSummary', () {
    test('separates earnings, work expenses, and home expenses', () {
      final summary = TechnicianInOutSummary.fromEntries(
        earnings: [
          buildEarning(
            amount: 200,
            category: 'Scrap',
            date: DateTime(2025, 2, 1),
          ),
          buildEarning(
            amount: 150,
            category: 'Bracket',
            date: DateTime(2025, 2, 2),
          ),
        ],
        expenses: [
          buildExpense(
            amount: 60,
            category: 'Fuel',
            expenseType: 'work',
            date: DateTime(2025, 2, 1),
          ),
          buildExpense(
            amount: 40,
            category: 'Groceries',
            expenseType: 'home',
            date: DateTime(2025, 2, 2),
          ),
        ],
      );

      expect(summary.totalEarned, 350);
      expect(summary.workExpenses, 60);
      expect(summary.homeExpenses, 40);
      expect(summary.totalExpenses, 100);
      expect(summary.net, 250);
    });
  });

  group('TechnicianDayInOutSummary', () {
    test('groups entries by day and respects date range', () {
      final summaries = TechnicianDayInOutSummary.summarize(
        earnings: [
          buildEarning(
            amount: 120,
            category: 'Bracket',
            date: DateTime(2025, 3, 10),
          ),
          buildEarning(
            amount: 90,
            category: 'Scrap',
            date: DateTime(2025, 3, 11),
          ),
        ],
        expenses: [
          buildExpense(
            amount: 35,
            category: 'Fuel',
            expenseType: 'work',
            date: DateTime(2025, 3, 10),
          ),
          buildExpense(
            amount: 20,
            category: 'Food',
            expenseType: 'home',
            date: DateTime(2025, 3, 12),
          ),
        ],
        start: DateTime(2025, 3, 10),
        end: DateTime(2025, 3, 11),
      );

      expect(summaries.length, 2);

      final firstDay = summaries.firstWhere(
        (summary) => summary.date == DateTime(2025, 3, 10),
      );
      expect(firstDay.earned, 120);
      expect(firstDay.workExpenses, 35);
      expect(firstDay.homeExpenses, 0);

      final secondDay = summaries.firstWhere(
        (summary) => summary.date == DateTime(2025, 3, 11),
      );
      expect(secondDay.earned, 90);
      expect(secondDay.totalExpenses, 0);
    });
  });
}
