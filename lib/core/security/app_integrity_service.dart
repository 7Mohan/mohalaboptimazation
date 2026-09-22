import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../utils/logger.dart';

/// Holds the results of native environment and integrity verification.
class AppIntegrityReport {
  const AppIntegrityReport({
    required this.isDebuggable,
    required this.installerPackage,
    required this.certificateSha256,
    required this.packageName,
    required this.isTamperSuspected,
    required this.warnings,
  });

  /// True if the APK was compiled or modified with android:debuggable="true".
  final bool isDebuggable;

  /// Installer package name (e.g. "com.android.vending" for Google Play Store).
  final String? installerPackage;

  /// SHA-256 fingerprint of the APK signing certificate.
  final String? certificateSha256;

  /// Actual Android package name declared in the running process.
  final String packageName;

  /// True if high-confidence indicators of tampering or debug repackaging are detected.
  final bool isTamperSuspected;

  /// Human-readable security telemetry warnings.
  final List<String> warnings;

  /// Safe fallback report when running on non-Android test environments.
  factory AppIntegrityReport.clean() {
    return const AppIntegrityReport(
      isDebuggable: kDebugMode,
      installerPackage: 'com.android.vending',
      certificateSha256: null,
      packageName: 'com.mohalab.optimization',
      isTamperSuspected: false,
      warnings: [],
    );
  }
}

/// Service that performs defensive anti-tamper and environment checks.
///
/// NOTE: Client-side defenses increase the difficulty of casual repackaging
/// and modified APK redistribution, but cannot make reverse engineering
/// mathematically impossible on rooted or instrumented devices.
class AppIntegrityService {
  AppIntegrityService({MethodChannel? channel})
      : _channel = channel ?? const MethodChannel('com.mohalab.optimization/device_info');

  final MethodChannel _channel;

  /// Known package names of legitimate app stores.
  static const Set<String> trustedInstallers = {
    'com.android.vending', // Google Play Store
    'com.google.android.feedback',
    'com.amazon.venezia', // Amazon Appstore
    'com.sec.android.app.samsungapps', // Samsung Galaxy Store
    'com.huawei.appmarket', // Huawei AppGallery
  };

  /// Expected application package name.
  static const String expectedPackageName = 'com.mohalab.optimization';

  /// Performs a complete integrity assessment.
  Future<AppIntegrityReport> evaluateIntegrity() async {
    try {
      final raw = await _channel.invokeMapMethod<String, dynamic>('checkAppIntegrity');
      if (raw == null) {
        return AppIntegrityReport.clean();
      }

      final isDebuggable = raw['isDebuggable'] as bool? ?? false;
      final installer = raw['installerPackage'] as String?;
      final certSha256 = raw['certificateSha256'] as String?;
      final pkgName = raw['packageName'] as String? ?? expectedPackageName;

      final warnings = <String>[];
      bool tamperSuspected = false;

      // 1. Package Name Mismatch (Repackaging check)
      if (pkgName != expectedPackageName) {
        tamperSuspected = true;
        warnings.add('Package identity mismatch: expected $expectedPackageName, found $pkgName');
      }

      // 2. Production build running with debuggable flag
      if (!kDebugMode && isDebuggable) {
        tamperSuspected = true;
        warnings.add('Application is marked debuggable in a release runtime environment.');
      }

      // 3. Sideload / Unknown source check (informational)
      if (installer == null || !trustedInstallers.contains(installer)) {
        warnings.add('Application was sideloaded or installed from an unrecognized installer: ${installer ?? 'direct APK install'}');
      }

      if (tamperSuspected) {
        AppLogger.warning(
          'Integrity warnings detected: ${warnings.join('; ')}',
          tag: 'AppIntegrityService',
        );
      }

      return AppIntegrityReport(
        isDebuggable: isDebuggable,
        installerPackage: installer,
        certificateSha256: certSha256,
        packageName: pkgName,
        isTamperSuspected: tamperSuspected,
        warnings: warnings,
      );
    } on PlatformException catch (e) {
      AppLogger.warning('Could not evaluate integrity: ${e.message}', tag: 'AppIntegrityService');
      return AppIntegrityReport.clean();
    } on MissingPluginException {
      // Non-Android platform (e.g. desktop/unit test)
      return AppIntegrityReport.clean();
    } catch (e) {
      AppLogger.error('Unexpected error checking integrity: $e', tag: 'AppIntegrityService');
      return AppIntegrityReport.clean();
    }
  }

  /// Validates the signing certificate SHA-256 against an expected hash.
  /// Returns null if certificate is unavailable (e.g. in test environments).
  bool? verifyCertificateHash(String? actualHash, String expectedHash) {
    if (actualHash == null) return null;
    return actualHash.replaceAll(':', '').toUpperCase() ==
        expectedHash.replaceAll(':', '').toUpperCase();
  }
}

/// Provider for [AppIntegrityService].
final appIntegrityServiceProvider = Provider<AppIntegrityService>((ref) {
  return AppIntegrityService();
});
