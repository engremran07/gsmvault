import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AppConnectivityStatus { online, offline }

final connectivityStatusProvider =
    StreamProvider.autoDispose<AppConnectivityStatus>((ref) async* {
      final connectivity = Connectivity();

      yield _toConnectivityStatus(await connectivity.checkConnectivity());

      yield* connectivity.onConnectivityChanged
          .map(_toConnectivityStatus)
          .distinct();
    });

AppConnectivityStatus _toConnectivityStatus(Object result) {
  final values = result is Iterable ? result : [result];
  final hasConnection = values.any(
    (entry) => entry is ConnectivityResult && entry != ConnectivityResult.none,
  );
  return hasConnection
      ? AppConnectivityStatus.online
      : AppConnectivityStatus.offline;
}
