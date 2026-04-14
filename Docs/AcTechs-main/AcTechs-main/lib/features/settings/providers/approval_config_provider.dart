import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ac_techs/core/models/models.dart';
import 'package:ac_techs/features/settings/data/approval_config_repository.dart';

final approvalConfigProvider = StreamProvider<ApprovalConfig>((ref) {
  return ref.watch(approvalConfigRepositoryProvider).watchConfig();
});
