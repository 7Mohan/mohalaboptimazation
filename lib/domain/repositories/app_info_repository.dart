import '../entities/app_info.dart';

/// Abstract contract for retrieving app metadata.
abstract interface class AppInfoRepository {
  /// Returns [AppInfo] for the running application.
  Future<AppInfo> getAppInfo();
}
