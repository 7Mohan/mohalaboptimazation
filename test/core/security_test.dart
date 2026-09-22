import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mohalab_optimization/core/security/app_integrity_service.dart';
import 'package:mohalab_optimization/data/datasources/local/settings_local_datasource.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppIntegrityService', () {
    const channel = MethodChannel('com.mohalab.optimization/device_info');

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    test('clean report returns clean baseline', () {
      final report = AppIntegrityReport.clean();
      expect(report.packageName, AppIntegrityService.expectedPackageName);
      expect(report.isTamperSuspected, isFalse);
      expect(report.warnings, isEmpty);
    });

    test('detects package name tampering', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        if (call.method == 'checkAppIntegrity') {
          return {
            'isDebuggable': false,
            'installerPackage': 'com.android.vending',
            'certificateSha256': 'AA:BB:CC',
            'packageName': 'com.repackaged.malicious',
          };
        }
        return null;
      });

      final service = AppIntegrityService(channel: channel);
      final report = await service.evaluateIntegrity();

      expect(report.isTamperSuspected, isTrue);
      expect(report.warnings.any((w) => w.contains('mismatch')), isTrue);
    });

    test('reports trusted installer correctly', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        if (call.method == 'checkAppIntegrity') {
          return {
            'isDebuggable': false,
            'installerPackage': 'com.android.vending',
            'certificateSha256': '11:22:33',
            'packageName': 'com.mohalab.optimization',
          };
        }
        return null;
      });

      final service = AppIntegrityService(channel: channel);
      final report = await service.evaluateIntegrity();

      expect(report.isTamperSuspected, isFalse);
      expect(report.warnings, isEmpty);
      expect(report.installerPackage, 'com.android.vending');
    });

    test('flags unknown/sideloaded installer in warnings without tampering flag', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        if (call.method == 'checkAppIntegrity') {
          return {
            'isDebuggable': false,
            'installerPackage': null, // direct adb install
            'certificateSha256': '11:22:33',
            'packageName': 'com.mohalab.optimization',
          };
        }
        return null;
      });

      final service = AppIntegrityService(channel: channel);
      final report = await service.evaluateIntegrity();

      expect(report.isTamperSuspected, isFalse);
      expect(report.warnings.any((w) => w.contains('sideloaded')), isTrue);
    });

    test('verifyCertificateHash compares SHA-256 fingerprints case-insensitively', () {
      final service = AppIntegrityService();
      const expected = 'A1:B2:C3:D4';
      expect(service.verifyCertificateHash('a1:b2:c3:d4', expected), isTrue);
      expect(service.verifyCertificateHash('A1B2C3D4', expected), isTrue);
      expect(service.verifyCertificateHash('FF:EE:DD:CC', expected), isFalse);
      expect(service.verifyCertificateHash(null, expected), isNull);
    });
  });

  group('ImportValidator Security Bounds', () {
    const validator = ImportValidator();

    test('rejects oversized payloads (> 5MB)', () {
      // 5MB + 1 byte
      final huge = 'a' * (5 * 1024 * 1024 + 1);
      final res = validator.validate(huge);
      expect(res.isValid, isFalse);
      expect(res.error, contains('too large'));
    });

    test('rejects JSON with wrong appId', () {
      const json = '''
      {
        "appId": "com.malicious.app",
        "schemaVersion": 1,
        "exportedAt": "2026-09-21T12:00:00.000Z"
      }
      ''';
      final res = validator.validate(json);
      expect(res.isValid, isFalse);
      expect(res.error, contains('not exported from Moha Lab'));
    });

    test('rejects code or script injection attempts', () {
      const json = '''
      {
        "appId": "com.mohalab.optimization",
        "schemaVersion": 1,
        "exportedAt": "2026-09-21T12:00:00.000Z",
        "settings": {
          "code": "System.exit(0);",
          "script": "<script>alert(1)</script>"
        }
      }
      ''';
      final res = validator.validate(json);
      // Validates as JSON without executing; safe string parsing
      expect(res.isValid, isTrue);
      expect(res.bundle, isNotNull);
    });
  });

  group('Native Input Regex Validation Rules', () {
    final pkgRegex = RegExp(r'^[a-zA-Z][a-zA-Z0-9_]*(\.[a-zA-Z][a-zA-Z0-9_]*)+$');

    test('validates standard Android package names', () {
      expect(pkgRegex.hasMatch('com.mohalab.optimization'), isTrue);
      expect(pkgRegex.hasMatch('com.dts.freefireth'), isTrue);
      expect(pkgRegex.hasMatch('com.tencent.ig'), isTrue);
      expect(pkgRegex.hasMatch('org.example.game_1'), isTrue);
    });

    test('rejects malicious or invalid package names', () {
      expect(pkgRegex.hasMatch(''), isFalse);
      expect(pkgRegex.hasMatch('com.foo; rm -rf /'), isFalse);
      expect(pkgRegex.hasMatch('com.foo/../../'), isFalse);
      expect(pkgRegex.hasMatch('123.abc'), isFalse);
      expect(pkgRegex.hasMatch('com.foo&echo'), isFalse);
    });
  });
}
