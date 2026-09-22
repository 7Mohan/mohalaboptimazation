import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/repositories/app_info_repository_impl.dart';
import '../../../../domain/entities/app_info.dart';
import '../../../../domain/usecases/get_app_info_usecase.dart';

final _appInfoRepositoryProvider = Provider(
  (_) => const AppInfoRepositoryImpl(),
  name: '_appInfoRepositoryProvider',
);

final _getAppInfoUseCaseProvider = Provider(
  (ref) => GetAppInfoUseCase(ref.watch(_appInfoRepositoryProvider)),
  name: '_getAppInfoUseCaseProvider',
);

/// Async provider that fetches real [AppInfo] once.
final appInfoProvider = FutureProvider<AppInfo>(
  (ref) => ref.watch(_getAppInfoUseCaseProvider).call(),
  name: 'appInfoProvider',
);
