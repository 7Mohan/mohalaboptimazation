import '../entities/app_info.dart';
import '../repositories/app_info_repository.dart';

/// Use-case: fetch app metadata once.
class GetAppInfoUseCase {
  const GetAppInfoUseCase(this._repository);

  final AppInfoRepository _repository;

  Future<AppInfo> call() => _repository.getAppInfo();
}
