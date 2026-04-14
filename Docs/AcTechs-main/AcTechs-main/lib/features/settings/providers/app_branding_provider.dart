import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ac_techs/core/models/models.dart';
import 'package:ac_techs/features/settings/data/app_branding_repository.dart';

final appBrandingProvider = StreamProvider<AppBrandingConfig>((ref) {
  return ref.watch(appBrandingRepositoryProvider).watchConfig();
});
