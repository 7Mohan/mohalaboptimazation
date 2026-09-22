import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/network_diagnostic_session.dart';

/// Local data source persisting network diagnostic runs using [SharedPreferences].
class NetworkHistoryLocalDataSource {
  const NetworkHistoryLocalDataSource(this._prefs);

  final SharedPreferences _prefs;

  static const String _indexKey = 'mohalab_network_history_index';
  static const String _sessionPrefix = 'mohalab_network_session_';

  String _keyForSession(String id) => '$_sessionPrefix$id';

  /// Saves a session and updates the historical index.
  Future<void> saveSession(NetworkDiagnosticSession session) async {
    final raw = jsonEncode(session.toMap());
    await _prefs.setString(_keyForSession(session.id), raw);

    final index = _prefs.getStringList(_indexKey) ?? <String>[];
    if (!index.contains(session.id)) {
      // Prepend newest session
      final updated = [session.id, ...index];
      // Cap history index to 50 items to conserve storage
      if (updated.length > 50) {
        final removed = updated.sublist(50);
        for (final id in removed) {
          await _prefs.remove(_keyForSession(id));
        }
        await _prefs.setStringList(_indexKey, updated.sublist(0, 50));
      } else {
        await _prefs.setStringList(_indexKey, updated);
      }
    }
  }

  /// Retrieves past sessions, ordered newest first.
  Future<List<NetworkDiagnosticSession>> getHistory({int limit = 20}) async {
    final index = _prefs.getStringList(_indexKey) ?? const [];
    final sessions = <NetworkDiagnosticSession>[];

    for (final id in index.take(limit)) {
      final raw = _prefs.getString(_keyForSession(id));
      if (raw != null && raw.isNotEmpty) {
        try {
          final map = jsonDecode(raw) as Map<String, dynamic>;
          sessions.add(NetworkDiagnosticSession.fromMap(map));
        } catch (_) {
          // Skip corrupt records
        }
      }
    }

    return sessions;
  }

  /// Deletes a specific session.
  Future<void> deleteSession(String id) async {
    await _prefs.remove(_keyForSession(id));
    final index = _prefs.getStringList(_indexKey) ?? <String>[];
    if (index.contains(id)) {
      index.remove(id);
      await _prefs.setStringList(_indexKey, index);
    }
  }

  /// Clears all historical records.
  Future<void> clearHistory() async {
    final index = _prefs.getStringList(_indexKey) ?? const [];
    for (final id in index) {
      await _prefs.remove(_keyForSession(id));
    }
    await _prefs.remove(_indexKey);
  }
}
