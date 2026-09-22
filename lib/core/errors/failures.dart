/// Base class for all domain-layer failures.
///
/// Failures represent expected error states (e.g., permission denied,
/// feature unavailable). They are distinct from Exceptions, which represent
/// unexpected errors.
sealed class Failure {
  const Failure({required this.message, this.code});

  final String message;
  final String? code;

  @override
  String toString() => 'Failure($code): $message';
}

/// The requested feature is not yet implemented.
final class FeatureUnavailableFailure extends Failure {
  const FeatureUnavailableFailure({required super.message})
      : super(code: 'feature_unavailable');
}

/// The device does not meet the minimum requirements.
final class DeviceNotSupportedFailure extends Failure {
  const DeviceNotSupportedFailure({required super.message})
      : super(code: 'device_not_supported');
}

/// A local storage read/write failure.
final class StorageFailure extends Failure {
  const StorageFailure({required super.message})
      : super(code: 'storage_error');
}

/// A permission was denied by the user or system.
final class PermissionFailure extends Failure {
  const PermissionFailure({required super.message})
      : super(code: 'permission_denied');
}

/// An unknown/unexpected failure occurred.
final class UnknownFailure extends Failure {
  const UnknownFailure({required super.message, this.cause})
      : super(code: 'unknown');

  final Object? cause;
}
