import 'dart:convert';
import '../entities/game_profile_entity.dart';

/// Validation result detailing pass/fail status and specific error reasons.
class ProfileValidationResult {
  const ProfileValidationResult._({
    required this.isValid,
    this.errors = const [],
  });

  factory ProfileValidationResult.success() =>
      const ProfileValidationResult._(isValid: true);

  factory ProfileValidationResult.failure(List<String> errors) =>
      ProfileValidationResult._(isValid: false, errors: errors);

  final bool isValid;
  final List<String> errors;

  @override
  String toString() => isValid ? 'Valid' : 'Invalid: ${errors.join(', ')}';
}

/// Strict security and integrity validator for Game Profiles.
///
/// Prevents:
/// - Command injection via malicious package names or metadata (e.g. `; rm -rf`, `$(...)`, `&`)
/// - Arbitrary setting injection or script execution payloads
/// - Malformed, corrupt, or unsupported schema versions
abstract final class ProfileValidator {
  static final RegExp _packageNameRegex =
      RegExp(r'^[a-zA-Z][a-zA-Z0-9_]*(\.[a-zA-Z][a-zA-Z0-9_]*)+$');

  /// Validates a [GameProfile] instance before saving or applying.
  static ProfileValidationResult validate(GameProfile profile) {
    final errors = <String>[];

    // 1. Package name validation
    final pkg = profile.gamePackage.trim();
    if (pkg.isEmpty) {
      errors.add('Game package name cannot be empty');
    } else if (pkg.length > 150) {
      errors.add('Game package name exceeds maximum length (150)');
    } else if (!_packageNameRegex.hasMatch(pkg)) {
      errors.add('Invalid package name format: "$pkg"');
    } else if (_containsCommandInjectionChars(pkg)) {
      errors.add('Package name contains forbidden shell characters');
    }

    // 2. Game name validation
    final name = profile.gameName.trim();
    if (name.isEmpty) {
      errors.add('Game name cannot be empty');
    } else if (name.length > 100) {
      errors.add('Game name exceeds maximum length (100)');
    } else if (_containsControlCharacters(name)) {
      errors.add('Game name contains illegal control characters');
    }

    // 3. Version check
    if (profile.profileVersion < 1 ||
        profile.profileVersion > GameProfile.currentVersion) {
      errors.add(
        'Unsupported profile version (${profile.profileVersion}). Current supported version is ${GameProfile.currentVersion}.',
      );
    }

    // 4. User settings whitelist & type safety
    for (final entry in profile.userSettings.entries) {
      if (!SafeUserSettingsKeys.allKeys.contains(entry.key)) {
        errors.add('Disallowed custom setting key "${entry.key}"');
      }
      if (entry.value is! bool) {
        errors.add('Setting "${entry.key}" must be a boolean value');
      }
    }

    if (errors.isEmpty) {
      return ProfileValidationResult.success();
    }
    return ProfileValidationResult.failure(errors);
  }

  /// Parses and strictly validates a raw JSON string during profile import.
  static ProfileValidationResult validateRawJson(String rawJson) {
    final errors = <String>[];

    Map<String, dynamic> map;
    try {
      final decoded = jsonDecode(rawJson);
      if (decoded is! Map<String, dynamic>) {
        return ProfileValidationResult.failure([
          'Imported profile must be a JSON object',
        ]);
      }
      map = decoded;
    } catch (e) {
      return ProfileValidationResult.failure([
        'Malformed JSON: ${e.toString()}',
      ]);
    }

    // Check mandatory fields
    if (!map.containsKey('gamePackage') || map['gamePackage'] is! String) {
      errors.add('Missing or invalid "gamePackage" field');
    }
    if (!map.containsKey('gameName') || map['gameName'] is! String) {
      errors.add('Missing or invalid "gameName" field');
    }

    // Validate enum fields if present
    if (map.containsKey('performance') &&
        !PerformancePreference.values.any((e) => e.name == map['performance'])) {
      errors.add('Invalid performance preference: "${map['performance']}"');
    }
    if (map.containsKey('battery') &&
        !BatteryPreference.values.any((e) => e.name == map['battery'])) {
      errors.add('Invalid battery preference: "${map['battery']}"');
    }
    if (map.containsKey('network') &&
        !NetworkPreference.values.any((e) => e.name == map['network'])) {
      errors.add('Invalid network preference: "${map['network']}"');
    }
    if (map.containsKey('touch') &&
        !TouchPreference.values.any((e) => e.name == map['touch'])) {
      errors.add('Invalid touch preference: "${map['touch']}"');
    }
    if (map.containsKey('display') &&
        !DisplayPreference.values.any((e) => e.name == map['display'])) {
      errors.add('Invalid display preference: "${map['display']}"');
    }

    // Validate categories list
    if (map.containsKey('enabledCategories')) {
      if (map['enabledCategories'] is! List) {
        errors.add('"enabledCategories" must be a list of strings');
      } else {
        final catList = map['enabledCategories'] as List;
        for (final item in catList) {
          if (!OptimizationCategory.values.any((c) => c.name == item.toString())) {
            errors.add('Invalid optimization category: "$item"');
          }
        }
      }
    }

    // Validate userSettings dictionary
    if (map.containsKey('userSettings')) {
      if (map['userSettings'] is! Map) {
        errors.add('"userSettings" must be a JSON map');
      } else {
        final settingsMap = map['userSettings'] as Map;
        for (final entry in settingsMap.entries) {
          final key = entry.key.toString();
          if (!SafeUserSettingsKeys.allKeys.contains(key)) {
            errors.add('Disallowed custom setting key "$key"');
          }
          if (entry.value is! bool) {
            errors.add('Setting "$key" must be a boolean');
          }
        }
      }
    }

    if (errors.isNotEmpty) {
      return ProfileValidationResult.failure(errors);
    }

    // Run standard profile entity validation on parsed object
    try {
      final profile = GameProfile.fromMap(map);
      return validate(profile);
    } catch (e) {
      return ProfileValidationResult.failure([
        'Failed to instantiate profile from JSON: $e',
      ]);
    }
  }

  static bool _containsCommandInjectionChars(String value) {
    const forbidden = [
      ';', '&', '|', '`', '\$', '(', ')', '<', '>', '\n', '\r', '"', '\'', '\\', ' ',
    ];
    return forbidden.any((char) => value.contains(char));
  }

  static bool _containsControlCharacters(String value) {
    return value.codeUnits.any((code) => (code < 32 && code != 9) || code == 127);
  }
}
