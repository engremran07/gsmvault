import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ac_techs/core/models/models.dart';
import 'package:ac_techs/features/expenses/data/ac_install_repository.dart';

final pendingAcInstallsProvider =
    StreamProvider.autoDispose<List<AcInstallModel>>((ref) {
      return ref.watch(acInstallRepositoryProvider).watchPendingInstalls();
    });
