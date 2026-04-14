import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

final appPackageInfoProvider = FutureProvider<PackageInfo>((ref) async {
  return PackageInfo.fromPlatform();
});

final appBuildNumberProvider = FutureProvider<int>((ref) async {
  final info = await ref.watch(appPackageInfoProvider.future);
  final parsed = int.tryParse(info.buildNumber);
  return parsed == null || parsed < 1 ? 1 : parsed;
});

final appVersionLabelProvider = FutureProvider<String>((ref) async {
  final info = await ref.watch(appPackageInfoProvider.future);
  return '${info.version}+${info.buildNumber}';
});
