import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/about_config.dart';

/// Result status of a link launch request.
enum UrlLaunchStatus {
  success,
  copiedToClipboard,
  missingOrInvalid,
}

class UrlLaunchResult {
  const UrlLaunchResult({
    required this.status,
    required this.message,
    this.url,
  });

  final UrlLaunchStatus status;
  final String message;
  final String? url;

  bool get isSuccessful =>
      status == UrlLaunchStatus.success ||
      status == UrlLaunchStatus.copiedToClipboard;
}

/// Service handling link launches, validations, and graceful fallbacks.
///
/// Ensures missing or malformed configuration URLs never crash the application.
class UrlLauncherService {
  const UrlLauncherService({
    this.enablePlatformChannel = true,
  });

  final bool enablePlatformChannel;

  static const MethodChannel _platformChannel =
      MethodChannel('com.mohalab.optimization/device_info');

  /// Attempts to open [url].
  ///
  /// If the URL is empty or malformed, returns [UrlLaunchStatus.missingOrInvalid]
  /// and shows a friendly notification.
  /// If platform opening is unavailable (such as in headless or desktop/test environments),
  /// it automatically copies the URL to the user's clipboard and provides clear feedback.
  Future<UrlLaunchResult> launchOrCopy(
    BuildContext context,
    String? rawUrl, {
    String? title,
  }) async {
    final trimmed = rawUrl?.trim();
    if (trimmed == null || trimmed.isEmpty || !AboutConfig.isValidUrl(trimmed)) {
      final msg = title != null
          ? '$title is not currently configured.'
          : 'Link is not currently configured.';
      _showFeedback(context, msg, isError: true);
      return UrlLaunchResult(
        status: UrlLaunchStatus.missingOrInvalid,
        message: msg,
        url: rawUrl,
      );
    }

    try {
      // Attempt platform channel intent if on Android
      bool launchedOnPlatform = false;
      if (enablePlatformChannel) {
        try {
          final result = await _platformChannel.invokeMethod<bool>(
            'openUrl',
            {'url': trimmed},
          );
          launchedOnPlatform = result ?? false;
        } catch (_) {
          // Platform method not implemented or running in non-Android/test environment
          launchedOnPlatform = false;
        }
      }

      if (launchedOnPlatform) {
        return UrlLaunchResult(
          status: UrlLaunchStatus.success,
          message: 'Opened $trimmed',
          url: trimmed,
        );
      }

      // Safe, universal fallback: copy to clipboard
      await Clipboard.setData(ClipboardData(text: trimmed));
      if (context.mounted) {
        _showFeedback(
          context,
          'Link copied to clipboard:\n$trimmed',
          actionLabel: 'OK',
        );
      }

      return UrlLaunchResult(
        status: UrlLaunchStatus.copiedToClipboard,
        message: 'Link copied to clipboard',
        url: trimmed,
      );
    } catch (e) {
      if (context.mounted) {
        _showFeedback(context, 'Unable to open link: $e', isError: true);
      }
      return UrlLaunchResult(
        status: UrlLaunchStatus.missingOrInvalid,
        message: 'Error: $e',
        url: rawUrl,
      );
    }
  }

  void _showFeedback(
    BuildContext context,
    String message, {
    bool isError = false,
    String? actionLabel,
  }) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;

    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        backgroundColor: isError ? Colors.redAccent.shade700 : null,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        action: actionLabel != null
            ? SnackBarAction(
                label: actionLabel,
                onPressed: () => messenger.hideCurrentSnackBar(),
              )
            : null,
      ),
    );
  }
}

/// Provider for [UrlLauncherService].
final urlLauncherServiceProvider = Provider<UrlLauncherService>((ref) {
  return const UrlLauncherService();
});
