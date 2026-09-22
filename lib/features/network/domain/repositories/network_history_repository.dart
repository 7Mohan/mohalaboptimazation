import '../entities/network_diagnostic_session.dart';

/// Contract for persisting and retrieving gaming network diagnostic sessions.
abstract class NetworkHistoryRepository {
  /// Saves a completed diagnostic session to local storage.
  Future<void> saveSession(NetworkDiagnosticSession session);

  /// Retrieves recent diagnostic sessions, newest first.
  Future<List<NetworkDiagnosticSession>> getHistory({int limit = 20});

  /// Deletes a specific session by its ID.
  Future<void> deleteSession(String id);

  /// Clears all historical diagnostic sessions.
  Future<void> clearHistory();
}
