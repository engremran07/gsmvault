import 'package:ac_techs/core/constants/app_constants.dart';
import 'package:ac_techs/core/models/earning_model.dart';
import 'package:ac_techs/core/models/expense_model.dart';
import 'package:ac_techs/core/utils/app_formatters.dart';

class TechnicianDayInOutSummary {
  const TechnicianDayInOutSummary({
    required this.date,
    required this.earned,
    required this.workExpenses,
    required this.homeExpenses,
    required this.earningDetails,
    required this.workDetails,
    required this.homeDetails,
  });

  final DateTime date;
  final double earned;
  final double workExpenses;
  final double homeExpenses;
  final List<String> earningDetails;
  final List<String> workDetails;
  final List<String> homeDetails;

  double get totalExpenses => workExpenses + homeExpenses;
  double get net => earned - totalExpenses;

  static List<TechnicianDayInOutSummary> summarize({
    required Iterable<EarningModel> earnings,
    required Iterable<ExpenseModel> expenses,
    DateTime? start,
    DateTime? end,
  }) {
    final byDay = <DateTime, _DayAccumulator>{};
    final normalizedStart = start == null
        ? null
        : DateTime(start.year, start.month, start.day);
    final normalizedEnd = end == null
        ? null
        : DateTime(end.year, end.month, end.day, 23, 59, 59);

    bool inRange(DateTime? date) {
      if (date == null) return false;
      if (normalizedStart != null && date.isBefore(normalizedStart)) {
        return false;
      }
      if (normalizedEnd != null && date.isAfter(normalizedEnd)) {
        return false;
      }
      return true;
    }

    for (final earning in earnings) {
      if (!inRange(earning.date)) continue;
      final date = earning.date!;
      final day = DateTime(date.year, date.month, date.day);
      final item = byDay.putIfAbsent(day, () => _DayAccumulator(day));
      item.earned += earning.amount;
      item.earningDetails.add(
        '${earning.category} (${AppFormatters.currency(earning.amount)})',
      );
    }

    for (final expense in expenses) {
      if (!inRange(expense.date)) continue;
      final date = expense.date!;
      final day = DateTime(date.year, date.month, date.day);
      final item = byDay.putIfAbsent(day, () => _DayAccumulator(day));
      final detail =
          '${expense.category} (${AppFormatters.currency(expense.amount)})';
      if (expense.expenseType == AppConstants.expenseTypeHome) {
        item.homeExpenses += expense.amount;
        item.homeDetails.add(detail);
      } else {
        item.workExpenses += expense.amount;
        item.workDetails.add(detail);
      }
    }

    return byDay.values.map((item) => item.toSummary()).toList(growable: false);
  }
}

class _DayAccumulator {
  _DayAccumulator(this.date);

  final DateTime date;
  double earned = 0;
  double workExpenses = 0;
  double homeExpenses = 0;
  final List<String> earningDetails = <String>[];
  final List<String> workDetails = <String>[];
  final List<String> homeDetails = <String>[];

  TechnicianDayInOutSummary toSummary() {
    return TechnicianDayInOutSummary(
      date: date,
      earned: earned,
      workExpenses: workExpenses,
      homeExpenses: homeExpenses,
      earningDetails: List<String>.unmodifiable(earningDetails),
      workDetails: List<String>.unmodifiable(workDetails),
      homeDetails: List<String>.unmodifiable(homeDetails),
    );
  }
}
