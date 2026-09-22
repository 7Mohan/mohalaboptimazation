/// Minimal structured logger for Moha Lab Optimization.
///
/// In debug builds: prints formatted log lines to the console.
/// In release builds: all log calls are no-ops (tree-shaken away).
///
/// Replace with a proper logging package (e.g., `logger`) in future phases
/// without changing call sites.
library;

import 'package:flutter/foundation.dart';

enum _LogLevel { debug, info, warning, error }

abstract final class AppLogger {
  AppLogger._();

  static void debug(String message, {String? tag}) =>
      _log(_LogLevel.debug, message, tag: tag);

  static void info(String message, {String? tag}) =>
      _log(_LogLevel.info, message, tag: tag);

  static void warning(String message, {String? tag, Object? error}) =>
      _log(_LogLevel.warning, message, tag: tag, error: error);

  static void error(String message, {String? tag, Object? error, StackTrace? stackTrace}) =>
      _log(_LogLevel.error, message, tag: tag, error: error, stackTrace: stackTrace);

  static void _log(
    _LogLevel level,
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (!kDebugMode) return;

    final prefix = switch (level) {
      _LogLevel.debug   => '🔍 DEBUG',
      _LogLevel.info    => 'ℹ️  INFO ',
      _LogLevel.warning => '⚠️  WARN ',
      _LogLevel.error   => '🔴 ERROR',
    };
    final tagStr = tag != null ? '[$tag] ' : '';
    debugPrint('$prefix $tagStr$message');
    if (error != null) debugPrint('       ↳ $error');
    if (stackTrace != null) debugPrint('$stackTrace');
  }
}
