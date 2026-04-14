import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ac_techs/core/models/models.dart';
import 'package:ac_techs/features/admin/data/company_repository.dart';
import 'package:ac_techs/features/auth/providers/auth_providers.dart';

final allCompaniesProvider = StreamProvider.autoDispose<List<CompanyModel>>((
  ref,
) {
  final user = ref.watch(currentUserProvider).value;
  if (user == null || !user.isAdmin) return Stream.value([]);
  return ref.watch(companyRepositoryProvider).allCompanies();
});

final activeCompaniesProvider = StreamProvider.autoDispose<List<CompanyModel>>((
  ref,
) {
  final user = ref.watch(currentUserProvider).value;
  if (user == null) return Stream.value([]);
  return ref.watch(companyRepositoryProvider).activeCompanies();
});
