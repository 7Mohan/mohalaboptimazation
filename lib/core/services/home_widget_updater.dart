import 'package:home_widget/home_widget.dart';

class MohaHomeWidgetUpdater {
  static Future<void> update({
    required String profileName,
    required String status,
    required String metrics,
  }) async {
    try {
      await HomeWidget.saveWidgetData<String>('widget_profile', profileName);
      await HomeWidget.saveWidgetData<String>('widget_status', status);
      await HomeWidget.saveWidgetData<String>('widget_metrics', metrics);
      await HomeWidget.updateWidget(
        name: 'MohaWidgetProvider',
        androidName: 'MohaWidgetProvider',
      );
    } catch (_) {
      // Graceful fallback
    }
  }
}
