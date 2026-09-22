import '../../domain/entities/network_diagnostic_session.dart';
import '../../domain/repositories/network_history_repository.dart';
import '../datasources/network_history_local_datasource.dart';

/// Implementation of [NetworkHistoryRepository] backed by [NetworkHistoryLocalDataSource].
class NetworkHistoryRepositoryImpl implements NetworkHistoryRepository {
  const NetworkHistoryRepositoryImpl(this._dataSource);

  final NetworkHistoryLocalDataSource _dataSource;

  @override
  Future<void> saveSession(NetworkDiagnosticSession session) =>
      _dataSource.saveSession(session);

  @override
  Future<List<NetworkDiagnosticSession>> getHistory({int limit = 20}) =>
      _dataSource.getHistory(limit: limit);

  @override
  Future<void> deleteSession(String id) => _dataSource.deleteSession(id);

  @override
  Future<void> clearHistory() => _dataSource.clearHistory();
}
