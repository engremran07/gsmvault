import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ac_techs/core/models/models.dart';
import 'package:ac_techs/core/utils/technician_in_out_summary.dart';
import 'package:ac_techs/features/expenses/data/expense_repository.dart';
import 'package:ac_techs/features/expenses/data/earning_repository.dart';
import 'package:ac_techs/features/auth/providers/auth_providers.dart';

AsyncValue<T> _combineAsyncValues<A, B, T>(
  AsyncValue<A> first,
  AsyncValue<B> second,
  T Function(A first, B second) combine,
) {
  final firstError = first.asError;
  if (firstError != null) {
    return AsyncError(firstError.error, firstError.stackTrace);
  }

  final secondError = second.asError;
  if (secondError != null) {
    return AsyncError(secondError.error, secondError.stackTrace);
  }

  if (!first.hasValue || !second.hasValue) {
    return const AsyncLoading();
  }

  return AsyncData(combine(first.value as A, second.value as B));
}

/// All expenses for the logged-in tech (newest first).
final techExpensesProvider = StreamProvider.autoDispose<List<ExpenseModel>>((
  ref,
) {
  final user = ref.watch(currentUserProvider).value;
  if (user == null) return Stream.value([]);
  return ref.watch(expenseRepositoryProvider).techExpenses(user.uid);
});

/// Today's expenses for the logged-in tech.
/// Derived from monthlyExpensesProvider — no extra Firestore listener (per in-out-model.md rules).
final todaysExpensesProvider =
    Provider.autoDispose<AsyncValue<List<ExpenseModel>>>((ref) {
      final today = DateTime.now();
      final month = DateTime(today.year, today.month);
      return ref
          .watch(monthlyExpensesProvider(month))
          .whenData(
            (list) => list
                .where(
                  (e) =>
                      e.date?.year == today.year &&
                      e.date?.month == today.month &&
                      e.date?.day == today.day,
                )
                .toList(),
          );
    });

/// Monthly expenses for the logged-in tech.
/// DateTime key is normalised to the first of the month to prevent duplicate listeners.
final monthlyExpensesProvider = StreamProvider.autoDispose
    .family<List<ExpenseModel>, DateTime>((ref, month) {
      final normalized = DateTime(month.year, month.month);
      final user = ref.watch(currentUserProvider).value;
      if (user == null) return Stream.value([]);
      return ref
          .watch(expenseRepositoryProvider)
          .monthlyExpenses(user.uid, normalized);
    });

/// All earnings for the logged-in tech (newest first).
final techEarningsProvider = StreamProvider.autoDispose<List<EarningModel>>((
  ref,
) {
  final user = ref.watch(currentUserProvider).value;
  if (user == null) return Stream.value([]);
  return ref.watch(earningRepositoryProvider).techEarnings(user.uid);
});

final technicianInOutSummaryProvider =
    Provider.autoDispose<AsyncValue<TechnicianInOutSummary>>((ref) {
      return _combineAsyncValues<
        List<EarningModel>,
        List<ExpenseModel>,
        TechnicianInOutSummary
      >(
        ref.watch(techEarningsProvider),
        ref.watch(techExpensesProvider),
        (earnings, expenses) => TechnicianInOutSummary.fromEntries(
          earnings: earnings,
          expenses: expenses,
        ),
      );
    });

/// Today's earnings for the logged-in tech.
/// Derived from monthlyEarningsProvider — no extra Firestore listener (per in-out-model.md rules).
final todaysEarningsProvider =
    Provider.autoDispose<AsyncValue<List<EarningModel>>>((ref) {
      final today = DateTime.now();
      final month = DateTime(today.year, today.month);
      return ref
          .watch(monthlyEarningsProvider(month))
          .whenData(
            (list) => list
                .where(
                  (e) =>
                      e.date?.year == today.year &&
                      e.date?.month == today.month &&
                      e.date?.day == today.day,
                )
                .toList(),
          );
    });

/// Single day's earnings — derived from monthlyEarningsProvider (no extra Firestore listener).
final dailyEarningsProvider = Provider.autoDispose
    .family<AsyncValue<List<EarningModel>>, DateTime>((ref, date) {
      final month = DateTime(date.year, date.month);
      return ref
          .watch(monthlyEarningsProvider(month))
          .whenData(
            (list) => list
                .where(
                  (e) =>
                      e.date?.year == date.year &&
                      e.date?.month == date.month &&
                      e.date?.day == date.day,
                )
                .toList(),
          );
    });

/// Single day's expenses — derived from monthlyExpensesProvider (no extra Firestore listener).
final dailyExpensesProvider = Provider.autoDispose
    .family<AsyncValue<List<ExpenseModel>>, DateTime>((ref, date) {
      final month = DateTime(date.year, date.month);
      return ref
          .watch(monthlyExpensesProvider(month))
          .whenData(
            (list) => list
                .where(
                  (e) =>
                      e.date?.year == date.year &&
                      e.date?.month == date.month &&
                      e.date?.day == date.day,
                )
                .toList(),
          );
    });

/// Monthly earnings for the logged-in tech.
final monthlyEarningsProvider = StreamProvider.autoDispose
    .family<List<EarningModel>, DateTime>((ref, month) {
      final normalized = DateTime(month.year, month.month);
      final user = ref.watch(currentUserProvider).value;
      if (user == null) return Stream.value([]);
      return ref
          .watch(earningRepositoryProvider)
          .monthlyEarnings(user.uid, normalized);
    });

final monthlyTechnicianInOutSummaryProvider = Provider.autoDispose
    .family<AsyncValue<TechnicianInOutSummary>, DateTime>((ref, month) {
      return _combineAsyncValues<
        List<EarningModel>,
        List<ExpenseModel>,
        TechnicianInOutSummary
      >(
        ref.watch(monthlyEarningsProvider(month)),
        ref.watch(monthlyExpensesProvider(month)),
        (earnings, expenses) => TechnicianInOutSummary.fromEntries(
          earnings: earnings,
          expenses: expenses,
        ),
      );
    });

final pendingExpensesProvider = StreamProvider.autoDispose<List<ExpenseModel>>((
  ref,
) {
  final user = ref.watch(currentUserProvider).value;
  if (user == null || !user.isAdmin) return Stream.value([]);
  return ref.watch(expenseRepositoryProvider).pendingExpenses();
});

final pendingEarningsProvider = StreamProvider.autoDispose<List<EarningModel>>((
  ref,
) {
  final user = ref.watch(currentUserProvider).value;
  if (user == null || !user.isAdmin) return Stream.value([]);
  return ref.watch(earningRepositoryProvider).pendingEarnings();
});
