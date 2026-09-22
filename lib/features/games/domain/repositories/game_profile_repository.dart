import '../entities/game_profile_entity.dart';

/// Contract for managing local game profiles.
abstract class GameProfileRepository {
  /// Retrieves a profile for a given package name, or null if not yet configured.
  Future<GameProfile?> getProfile(String packageName);

  /// Retrieves all configured game profiles stored locally.
  Future<List<GameProfile>> getAllProfiles();

  /// Saves or updates a game profile after passing validation.
  Future<void> saveProfile(GameProfile profile);

  /// Deletes a configured profile, reverting the game to unconfigured state.
  Future<void> deleteProfile(String packageName);

  /// Resets a game's profile to default balanced parameters.
  Future<GameProfile> resetProfile(String packageName, String gameName);

  /// Duplicates an existing profile configuration to another package or slot.
  Future<GameProfile> duplicateProfile({
    required String sourcePackage,
    required String targetPackage,
    required String targetGameName,
  });

  /// Serializes a profile to a sanitized JSON string.
  String exportProfile(GameProfile profile);

  /// Validates and deserializes an imported JSON string into a [GameProfile].
  Future<GameProfile> importProfile(String jsonString);
}
