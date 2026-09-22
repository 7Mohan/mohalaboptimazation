/// Immutable entity representing published app information.
class AppInfo {
  const AppInfo({
    required this.appName,
    required this.packageName,
    required this.version,
    required this.buildNumber,
  });

  final String appName;
  final String packageName;
  final String version;
  final String buildNumber;

  String get versionDisplay => 'v$version ($buildNumber)';

  @override
  String toString() =>
      'AppInfo(name: $appName, package: $packageName, version: $version, build: $buildNumber)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppInfo &&
          runtimeType == other.runtimeType &&
          appName == other.appName &&
          packageName == other.packageName &&
          version == other.version &&
          buildNumber == other.buildNumber;

  @override
  int get hashCode =>
      Object.hash(appName, packageName, version, buildNumber);
}
