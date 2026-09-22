import '../../domain/entities/shizuku_status.dart';
import '../../domain/services/shizuku_service.dart';

/// In-memory stub implementation of [ShizukuService] for use in tests.
///
/// Allows simulation of any of the 7 Shizuku states without a real
/// Android device or MethodChannel. Calls to [requestPermission] advance
/// the state deterministically when [permissionGrantOnRequest] is true.
final class ShizukuMockService implements ShizukuService {
  ShizukuMockService({
    ShizukuStatus initialStatus = ShizukuStatus.notInstalled,
    this.permissionGrantOnRequest = true,
  }) : _status = initialStatus;

  ShizukuStatus _status;

  /// If true, calling [requestPermission] advances the state to [ready].
  /// If false, it remains [permissionDenied].
  final bool permissionGrantOnRequest;

  /// Allows tests to set the simulated state directly.
  void simulateStatus(ShizukuStatus status) => _status = status;

  @override
  Future<ShizukuStatus> getStatus() async => _status;

  @override
  Future<bool> checkPermission() async =>
      _status == ShizukuStatus.permissionGranted ||
      _status == ShizukuStatus.ready;

  @override
  Future<bool> isReady() async => _status == ShizukuStatus.ready;

  @override
  Future<bool> requestPermission() async {
    if (_status == ShizukuStatus.notInstalled ||
        _status == ShizukuStatus.notRunning) {
      return false;
    }
    if (permissionGrantOnRequest) {
      _status = ShizukuStatus.ready;
      return true;
    } else {
      _status = ShizukuStatus.permissionDenied;
      return false;
    }
  }

  @override
  Future<Map<String, dynamic>> execShellCommand(String command) async {
    return {'success': _status == ShizukuStatus.ready, 'exitCode': 0, 'stdout': 'Mock execution: $command', 'stderr': ''};
  }
}
