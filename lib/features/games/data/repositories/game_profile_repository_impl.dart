import 'dart:convert';

import '../../../../core/errors/exceptions.dart';
import '../../domain/entities/game_profile_entity.dart';
import '../../domain/repositories/game_profile_repository.dart';
import '../../domain/validators/profile_validator.dart';
import '../datasources/game_profile_local_datasource.dart';

/// Implementation of [GameProfileRepository] managing persistence and validation.
class GameProfileRepositoryImpl implements GameProfileRepository {
  const GameProfileRepositoryImpl(this._localDataSource);

  final GameProfileLocalDataSource _localDataSource;

  @override
  Future<GameProfile?> getProfile(String packageName) async {
    return _localDataSource.getProfile(packageName);
  }

  @override
  Future<List<GameProfile>> getAllProfiles() async {
    return _localDataSource.getAllProfiles();
  }

  @override
  Future<void> saveProfile(GameProfile profile) async {
    final validation = ProfileValidator.validate(profile);
    if (!validation.isValid) {
      throw ValidationException(message: validation.errors.join('; '));
    }
    final updated = profile.copyWith(
      lastUsed: DateTime.now(),
      isCustomized: true,
    );
    await _localDataSource.saveProfile(updated);
  }

  @override
  Future<void> deleteProfile(String packageName) async {
    await _localDataSource.deleteProfile(packageName);
  }

  @override
  Future<GameProfile> resetProfile(String packageName, String gameName) async {
    final defaultProfile = GameProfile.defaultForGame(packageName, gameName);
    final validation = ProfileValidator.validate(defaultProfile);
    if (!validation.isValid) {
      throw ValidationException(message: validation.errors.join('; '));
    }
    await _localDataSource.saveProfile(defaultProfile);
    return defaultProfile;
  }

  @override
  Future<GameProfile> duplicateProfile({
    required String sourcePackage,
    required String targetPackage,
    required String targetGameName,
  }) async {
    final source = await _localDataSource.getProfile(sourcePackage) ??
        GameProfile.defaultForGame(sourcePackage, targetGameName);

    final copy = source.copyWith(
      gamePackage: targetPackage,
      gameName: targetGameName,
      lastUsed: DateTime.now(),
      isCustomized: true,
    );

    final validation = ProfileValidator.validate(copy);
    if (!validation.isValid) {
      throw ValidationException(message: validation.errors.join('; '));
    }

    await _localDataSource.saveProfile(copy);
    return copy;
  }

  @override
  String exportProfile(GameProfile profile) {
    final validation = ProfileValidator.validate(profile);
    if (!validation.isValid) {
      throw ValidationException(message: validation.errors.join('; '));
    }
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(profile.toMap());
  }

  @override
  Future<GameProfile> importProfile(String jsonString) async {
    final validation = ProfileValidator.validateRawJson(jsonString);
    if (!validation.isValid) {
      throw ValidationException(message: validation.errors.join('; '));
    }

    final decoded = jsonDecode(jsonString) as Map<String, dynamic>;
    final profile = GameProfile.fromMap(decoded).copyWith(
      lastUsed: DateTime.now(),
      isCustomized: true,
    );

    await _localDataSource.saveProfile(profile);
    return profile;
  }
}

/// Fallback in-memory implementation of [GameProfileRepository] for testing.
class InMemoryGameProfileRepository implements GameProfileRepository {
  InMemoryGameProfileRepository([Map<String, GameProfile>? initial])
      : _store = initial != null ? Map.from(initial) : {};

  final Map<String, GameProfile> _store;

  @override
  Future<GameProfile?> getProfile(String packageName) async {
    return _store[packageName];
  }

  @override
  Future<List<GameProfile>> getAllProfiles() async {
    return _store.values.toList();
  }

  @override
  Future<void> saveProfile(GameProfile profile) async {
    final validation = ProfileValidator.validate(profile);
    if (!validation.isValid) {
      throw ValidationException(message: validation.errors.join('; '));
    }
    _store[profile.gamePackage] = profile.copyWith(
      lastUsed: DateTime.now(),
      isCustomized: true,
    );
  }

  @override
  Future<void> deleteProfile(String packageName) async {
    _store.remove(packageName);
  }

  @override
  Future<GameProfile> resetProfile(String packageName, String gameName) async {
    final defaultProfile = GameProfile.defaultForGame(packageName, gameName);
    final validation = ProfileValidator.validate(defaultProfile);
    if (!validation.isValid) {
      throw ValidationException(message: validation.errors.join('; '));
    }
    _store[packageName] = defaultProfile;
    return defaultProfile;
  }

  @override
  Future<GameProfile> duplicateProfile({
    required String sourcePackage,
    required String targetPackage,
    required String targetGameName,
  }) async {
    final source = _store[sourcePackage] ??
        GameProfile.defaultForGame(sourcePackage, targetGameName);

    final copy = source.copyWith(
      gamePackage: targetPackage,
      gameName: targetGameName,
      lastUsed: DateTime.now(),
      isCustomized: true,
    );

    final validation = ProfileValidator.validate(copy);
    if (!validation.isValid) {
      throw ValidationException(message: validation.errors.join('; '));
    }

    _store[targetPackage] = copy;
    return copy;
  }

  @override
  String exportProfile(GameProfile profile) {
    final validation = ProfileValidator.validate(profile);
    if (!validation.isValid) {
      throw ValidationException(message: validation.errors.join('; '));
    }
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(profile.toMap());
  }

  @override
  Future<GameProfile> importProfile(String jsonString) async {
    final validation = ProfileValidator.validateRawJson(jsonString);
    if (!validation.isValid) {
      throw ValidationException(message: validation.errors.join('; '));
    }

    final decoded = jsonDecode(jsonString) as Map<String, dynamic>;
    final profile = GameProfile.fromMap(decoded).copyWith(
      lastUsed: DateTime.now(),
      isCustomized: true,
    );

    _store[profile.gamePackage] = profile;
    return profile;
  }
}
