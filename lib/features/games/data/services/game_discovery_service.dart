import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../../../core/utils/logger.dart';
import '../../domain/classifier/game_classifier.dart';

/// Platform channel service communicating with native Android [MainActivity].
class GameDiscoveryService {
  static const _channel =
      MethodChannel('com.mohalab.optimization/game_discovery');

  static bool get _isTesting =>
      WidgetsBinding.instance is! WidgetsFlutterBinding;

  /// Fetches raw metadata for all installed applications on the device.
  static Future<List<RawAppMetadata>> fetchInstalledApps({
    bool includeIcons = true,
  }) async {
    if (_isTesting) return const [];

    try {
      final List<dynamic>? rawList = await _channel.invokeListMethod(
        'getInstalledApps',
        {'includeIcons': includeIcons},
      ).timeout(const Duration(seconds: 5));

      if (rawList == null) return const [];

      final results = <RawAppMetadata>[];
      for (final item in rawList) {
        if (item is Map) {
          try {
            results.add(RawAppMetadata.fromMap(Map<String, dynamic>.from(item)));
          } catch (_) {
            // Ignore malformed package entry
          }
        }
      }
      return results;
    } on PlatformException catch (e) {
      AppLogger.warning('PlatformException: ${e.message}', tag: 'GameDiscoveryService');
      return const [];
    } on MissingPluginException {
      // Non-Android platform or web preview
      return const [];
    } catch (e) {
      AppLogger.error('Unexpected error: $e', tag: 'GameDiscoveryService');
      return const [];
    }
  }

  /// Launches an application via its package name.
  static Future<bool> launchApp(String packageName) async {
    if (_isTesting) return true;

    try {
      final bool? success = await _channel.invokeMethod<bool>(
        'launchApp',
        {'packageName': packageName},
      ).timeout(const Duration(seconds: 2));

      return success ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Fetches the PNG icon bytes for a specific package name.
  static Future<Uint8List?> fetchAppIcon(String packageName) async {
    if (_isTesting) return null;

    try {
      final Uint8List? bytes = await _channel.invokeMethod<Uint8List>(
        'getAppIcon',
        {'packageName': packageName},
      ).timeout(const Duration(seconds: 2));

      return bytes;
    } catch (_) {
      return null;
    }
  }
}
