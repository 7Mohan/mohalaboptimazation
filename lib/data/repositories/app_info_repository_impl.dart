import 'package:package_info_plus/package_info_plus.dart';

import '../../../domain/entities/app_info.dart';
import '../../../domain/repositories/app_info_repository.dart';

/// Data-layer implementation of [AppInfoRepository].
/// Retrieves real package metadata via [PackageInfo].
class AppInfoRepositoryImpl implements AppInfoRepository {
  const AppInfoRepositoryImpl();

  @override
  Future<AppInfo> getAppInfo() async {
    final info = await PackageInfo.fromPlatform();
    return AppInfo(
      appName: info.appName,
      packageName: info.packageName,
      version: info.version,
      buildNumber: info.buildNumber,
    );
  }
}
