import 'dart:typed_data';

import '../../../../shared/widgets/indicators/moha_status_badge.dart';

/// Confidence level indicating how strongly the classifier identified the app as a game.
enum GameConfidence {
  high('High Confidence'),
  medium('Medium Confidence'),
  low('Low Confidence');

  const GameConfidence(this.label);
  final String label;
}

/// Sorting options for the game library list.
enum GameSortOrder {
  nameAsc('Name (A-Z)'),
  nameDesc('Name (Z-A)'),
  installDate('Recently Installed'),
  confidence('Detection Confidence');

  const GameSortOrder(this.label);
  final String label;
}

/// Domain entity representing an installed game on the Android device.
class GameEntity {
  const GameEntity({
    required this.packageName,
    required this.appName,
    this.versionName,
    this.versionCode,
    this.iconBytes,
    this.isSystemApp = false,
    this.category,
    this.installedAt,
    this.lastUpdatedAt,
    this.confidence = GameConfidence.high,
    this.confidenceScore = 1.0,
    this.classificationReasons = const [],
    this.isInstalled = true,
    this.statusLabel = 'Optimized',
    this.statusType = MohaStatusType.safe,
  });

  final String packageName;
  final String appName;
  final String? versionName;
  final int? versionCode;
  final Uint8List? iconBytes;
  final bool isSystemApp;
  final int? category;
  final DateTime? installedAt;
  final DateTime? lastUpdatedAt;
  final GameConfidence confidence;
  final double confidenceScore;
  final List<String> classificationReasons;
  final bool isInstalled;
  final String statusLabel;
  final MohaStatusType statusType;

  /// User-friendly version display string.
  String get versionDisplay {
    if (versionName != null && versionName!.trim().isNotEmpty) {
      return 'v$versionName';
    }
    if (versionCode != null) {
      return 'Build $versionCode';
    }
    return 'Version Unavailable';
  }

  /// Formatted date string for install time.
  String get installedDisplay {
    if (installedAt == null) return 'Install date unavailable';
    final d = installedAt!;
    final year = d.year.toString().padLeft(4, '0');
    final month = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  GameEntity copyWith({
    String? packageName,
    String? appName,
    String? versionName,
    int? versionCode,
    Uint8List? iconBytes,
    bool? isSystemApp,
    int? category,
    DateTime? installedAt,
    DateTime? lastUpdatedAt,
    GameConfidence? confidence,
    double? confidenceScore,
    List<String>? classificationReasons,
    bool? isInstalled,
    String? statusLabel,
    MohaStatusType? statusType,
  }) {
    return GameEntity(
      packageName: packageName ?? this.packageName,
      appName: appName ?? this.appName,
      versionName: versionName ?? this.versionName,
      versionCode: versionCode ?? this.versionCode,
      iconBytes: iconBytes ?? this.iconBytes,
      isSystemApp: isSystemApp ?? this.isSystemApp,
      category: category ?? this.category,
      installedAt: installedAt ?? this.installedAt,
      lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
      confidence: confidence ?? this.confidence,
      confidenceScore: confidenceScore ?? this.confidenceScore,
      classificationReasons:
          classificationReasons ?? this.classificationReasons,
      isInstalled: isInstalled ?? this.isInstalled,
      statusLabel: statusLabel ?? this.statusLabel,
      statusType: statusType ?? this.statusType,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GameEntity &&
          runtimeType == other.runtimeType &&
          packageName == other.packageName &&
          versionCode == other.versionCode;

  @override
  int get hashCode => packageName.hashCode ^ versionCode.hashCode;
}
