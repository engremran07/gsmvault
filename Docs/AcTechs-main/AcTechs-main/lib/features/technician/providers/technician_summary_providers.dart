import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ac_techs/core/utils/technician_in_out_summary.dart';
import 'package:ac_techs/core/utils/technician_job_summary.dart';
import 'package:ac_techs/features/expenses/providers/expense_providers.dart';
import 'package:ac_techs/features/jobs/providers/job_providers.dart';

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

final monthlyTechnicianStatsProvider = Provider.autoDispose
    .family<
      AsyncValue<({TechnicianJobSummary jobs, TechnicianInOutSummary inOut})>,
      DateTime
    >((ref, month) {
      return _combineAsyncValues<
        TechnicianJobSummary,
        TechnicianInOutSummary,
        ({TechnicianJobSummary jobs, TechnicianInOutSummary inOut})
      >(
        ref.watch(monthlyTechnicianJobSummaryProvider(month)),
        ref.watch(monthlyTechnicianInOutSummaryProvider(month)),
        (jobs, inOut) => (jobs: jobs, inOut: inOut),
      );
    });
