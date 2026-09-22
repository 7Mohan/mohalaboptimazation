/// Data-layer exceptions.
///
/// Exceptions represent unexpected errors caught at the data layer.
/// They are typically caught and converted to [Failure] objects before
/// crossing into the domain layer.
sealed class AppException implements Exception {
  const AppException({required this.message, this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() => 'AppException: $message${cause != null ? ' (caused by: $cause)' : ''}';
}

/// A local storage operation failed.
final class LocalStorageException extends AppException {
  const LocalStorageException({required super.message, super.cause});
}

/// Platform channel / method channel error.
final class PlatformChannelException extends AppException {
  const PlatformChannelException({required super.message, super.cause});
}

/// Feature is not available on this device / API level.
final class FeatureNotAvailableException extends AppException {
  const FeatureNotAvailableException({required super.message, super.cause});
}

/// Validation failed for domain entities or import data.
final class ValidationException extends AppException {
  const ValidationException({required super.message, super.cause});
}
