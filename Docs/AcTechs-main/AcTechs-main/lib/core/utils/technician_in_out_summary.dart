import 'package:ac_techs/core/constants/app_constants.dart';
import 'package:ac_techs/core/models/earning_model.dart';
import 'package:ac_techs/core/models/expense_model.dart';

class TechnicianInOutSummary {
  const TechnicianInOutSummary({
    required this.totalEarned,
    required this.workExpenses,
    required this.homeExpenses,
  });

  final double totalEarned;
  final double workExpenses;
  final double homeExpenses;

  double get totalExpenses => workExpenses + homeExpenses;
  double get net => totalEarned - totalExpenses;

  factory TechnicianInOutSummary.empty() {
    return const TechnicianInOutSummary(
      totalEarned: 0,
      workExpenses: 0,
      homeExpenses: 0,
    );
  }

  factory TechnicianInOutSummary.fromEntries({
    required Iterable<EarningModel> earnings,
    required Iterable<ExpenseModel> expenses,
  }) {
    var totalEarned = 0.0;
    var workExpenses = 0.0;
    var homeExpenses = 0.0;

    for (final earning in earnings) {
      totalEarned += earning.amount;
    }

    for (final expense in expenses) {
      if (expense.expenseType == AppConstants.expenseTypeHome) {
        homeExpenses += expense.amount;
      } else {
        workExpenses += expense.amount;
      }
    }

    return TechnicianInOutSummary(
      totalEarned: totalEarned,
      workExpenses: workExpenses,
      homeExpenses: homeExpenses,
    );
  }
}
