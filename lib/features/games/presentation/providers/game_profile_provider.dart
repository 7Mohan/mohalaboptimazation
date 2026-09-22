import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/game_profile_local_datasource.dart';
import '../../data/repositories/game_profile_repository_impl.dart';
import '../../domain/entities/game_profile_entity.dart';
import '../../domain/repositories/game_profile_repository.dart';
import '../../../settings/presentation/providers/theme_provider.dart';

/// Provides the active [GameProfileRepository].
final gameProfileRepositoryProvider = Provider<GameProfileRepository>((ref) {
  try {
    final prefs = ref.watch(sharedPreferencesProvider);
    return GameProfileRepositoryImpl(GameProfileLocalDataSource(prefs));
  } catch (_) {
    return InMemoryGameProfileRepository();
  }
});

/// Argument holder for watching a game's profile.
class GameProfileArg {
  const GameProfileArg({
    required this.packageName,
    required this.gameName,
  });

  final String packageName;
  final String gameName;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GameProfileArg &&
          runtimeType == other.runtimeType &&
          packageName == other.packageName;

  @override
  int get hashCode => packageName.hashCode;
}

/// Provides the current [GameProfile] for a specific game, defaulting to balanced if not saved.
final gameProfileFamily =
    FutureProvider.family<GameProfile, GameProfileArg>((ref, arg) async {
  final repo = ref.watch(gameProfileRepositoryProvider);
  final profile = await repo.getProfile(arg.packageName);
  return profile ?? GameProfile.defaultForGame(arg.packageName, arg.gameName);
});

/// Provides all configured game profiles.
final allGameProfilesProvider = FutureProvider<List<GameProfile>>((ref) async {
  final repo = ref.watch(gameProfileRepositoryProvider);
  return repo.getAllProfiles();
});

/// Action controller managing Game Profile modifications.
class GameProfileController {
  GameProfileController(this._ref);

  final Ref _ref;

  GameProfileRepository get _repo => _ref.read(gameProfileRepositoryProvider);

  /// Saves or updates a game profile.
  Future<void> saveProfile(GameProfile profile) async {
    await _repo.saveProfile(profile);
    _invalidate(profile.gamePackage, profile.gameName);
  }

  /// Resets a profile back to default balanced settings.
  Future<GameProfile> resetProfile(String packageName, String gameName) async {
    final reset = await _repo.resetProfile(packageName, gameName);
    _invalidate(packageName, gameName);
    return reset;
  }

  /// Deletes a profile from persistence.
  Future<void> deleteProfile(String packageName, String gameName) async {
    await _repo.deleteProfile(packageName);
    _invalidate(packageName, gameName);
  }

  /// Duplicates a profile from one package configuration to another.
  Future<GameProfile> duplicateProfile({
    required String sourcePackage,
    required String targetPackage,
    required String targetGameName,
  }) async {
    final copy = await _repo.duplicateProfile(
      sourcePackage: sourcePackage,
      targetPackage: targetPackage,
      targetGameName: targetGameName,
    );
    _invalidate(targetPackage, targetGameName);
    return copy;
  }

  /// Exports profile configuration to JSON string.
  String exportProfile(GameProfile profile) {
    return _repo.exportProfile(profile);
  }

  /// Imports profile from JSON string.
  Future<GameProfile> importProfile(String jsonString) async {
    final imported = await _repo.importProfile(jsonString);
    _invalidate(imported.gamePackage, imported.gameName);
    return imported;
  }

  void _invalidate(String packageName, String gameName) {
    _ref.invalidate(allGameProfilesProvider);
    _ref.invalidate(
      gameProfileFamily(GameProfileArg(
        packageName: packageName,
        gameName: gameName,
      )),
    );
  }
}

/// Provider for [GameProfileController].
final gameProfileControllerProvider = Provider<GameProfileController>((ref) {
  return GameProfileController(ref);
});
