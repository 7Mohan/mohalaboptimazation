import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MohaNotificationService {
  MohaNotificationService._();
  static final MohaNotificationService instance = MohaNotificationService._();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  static const String channelId = 'moha_lab_optimization_channel';
  static const String channelName = 'Optimization Reminders';
  static const String channelDescription =
      'Notifications for scheduled optimizations and system tuning reminders.';

  Future<void> initialize() async {
    if (_isInitialized) return;

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    try {
      await _notificationsPlugin.initialize(initSettings);
      _isInitialized = true;
    } catch (_) {
      // Graceful fallback on unsupported platforms / emulator
    }
  }

  Future<void> showOptimizationReminder({
    required String title,
    required String body,
  }) async {
    await initialize();

    const androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDescription,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const notificationDetails = NotificationDetails(android: androidDetails);

    try {
      await _notificationsPlugin.show(
        1001,
        title,
        body,
        notificationDetails,
      );
    } catch (_) {}
  }

  Future<void> showInstantOptimizationSuccess({
    required int toolsCount,
    required String profileName,
  }) async {
    await showOptimizationReminder(
      title: 'Moha Lab Optimization Completed',
      body: 'Successfully tuned $toolsCount system parameters in $profileName profile.',
    );
  }
}

final notificationServiceProvider = Provider<MohaNotificationService>((ref) {
  return MohaNotificationService.instance;
});
