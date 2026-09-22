import 'package:flutter/services.dart';

import '../../../../core/utils/logger.dart';
import '../../domain/entities/shizuku_status.dart';
import '../../domain/services/shizuku_service.dart';

/// Production implementation of [ShizukuService] using a Flutter MethodChannel.
///
/// Channel: com.mohalab.optimization/shizuku
///
/// This class is the only place in the Flutter codebase that knows about
/// the MethodChannel name or the raw string codes returned by the Android layer.
/// All callers above this class depend only on [ShizukuService] and [ShizukuStatus].
final class ShizukuServiceImpl implements ShizukuService {
  ShizukuServiceImpl() : _channel = const MethodChannel(_channelName);

  static const String _channelName = 'com.mohalab.optimization/shizuku';

  final MethodChannel _channel;

  @override
  Future<ShizukuStatus> getStatus() async {
    try {
      final code = await _channel.invokeMethod<String>('getStatus');
      return ShizukuStatusExtension.fromCode(code ?? '');
    } on PlatformException catch (e) {
      // Channel errors mean we cannot communicate with the native layer —
      // treat as notInstalled rather than crashing.
      AppLogger.warning('getStatus PlatformException: ${e.message}', tag: 'ShizukuService');
      return ShizukuStatus.notInstalled;
    } on MissingPluginException {
      // Running on a non-Android platform (web, desktop) — Shizuku is unavailable.
      return ShizukuStatus.notInstalled;
    }
  }

  @override
  Future<bool> checkPermission() async {
    try {
      return await _channel.invokeMethod<bool>('checkPermission') ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  @override
  Future<bool> isReady() async {
    try {
      return await _channel.invokeMethod<bool>('isReady') ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  @override
  Future<bool> requestPermission() async {
    try {
      return await _channel.invokeMethod<bool>('requestPermission') ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  @override
  Future<Map<String, dynamic>> execShellCommand(String command) async {
    try {
      final res = await _channel.invokeMapMethod<String, dynamic>(
        'execShellCommand',
        {'command': command},
      );
      return res ?? {'success': false, 'exitCode': -1, 'stdout': '', 'stderr': 'Null response'};
    } on PlatformException catch (e) {
      return {'success': false, 'exitCode': -1, 'stdout': '', 'stderr': e.message ?? 'Platform error'};
    } catch (e) {
      return {'success': false, 'exitCode': -1, 'stdout': '', 'stderr': e.toString()};
    }
  }
}
