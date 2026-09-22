import 'dart:typed_data';

import '../entities/game_entity.dart';

/// Contract for game discovery, persistence, and launching operations.
abstract class GameRepository {
  /// Scans the device for installed gaming applications.
  Future<List<GameEntity>> getInstalledGames({bool forceRefresh = false});

  /// Requests the operating system to launch a game by package name.
  Future<bool> launchGame(String packageName);

  /// Retrieves high-resolution icon bytes for a package if not pre-cached.
  Future<Uint8List?> getGameIcon(String packageName);
}
