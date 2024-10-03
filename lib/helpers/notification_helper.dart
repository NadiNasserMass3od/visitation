import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../helpers/database_helper.dart';
import '../models/visitor.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';

class NotificationHelper {
  static FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static onTap(NotificationResponse notificationResponse) {
  }

  static Future<void> initNotifications() async {
    InitializationSettings settings = const InitializationSettings(
      android: AndroidInitializationSettings('app_icon'),
    );
    flutterLocalNotificationsPlugin.initialize(
      settings,
      onDidReceiveBackgroundNotificationResponse: onTap,
      onDidReceiveNotificationResponse: onTap,
    );
  }

  Future<void> showNotification(String title, String body) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'your_channel_id',
      'your_channel_name',
      importance: Importance.max,
      priority: Priority.high,
    );
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.show(
        0, title, body, platformChannelSpecifics);
  }

  Future<void> scheduleDailyNotifications() async {
    List<Visitor> inactiveVisitors =
        await DatabaseHelper().getInactiveVisitors();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int? hour = prefs.getInt('notification_hour');
    int? minute = prefs.getInt('notification_minute');

    AndroidNotificationDetails android = const AndroidNotificationDetails(
      'your_channel_id',
      'your_channel_name',
      importance: Importance.max,
      priority: Priority.high,
    );
    NotificationDetails details = NotificationDetails(android: android);
    tz.initializeTimeZones();
    final String currentTimeZone = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(currentTimeZone));

    if (hour != null && minute != null) {
      tz.TZDateTime scheduledTime = tz.TZDateTime.now(tz.local).add(
        Duration(
          hours: hour - tz.TZDateTime.now(tz.local).hour,
          minutes: minute - tz.TZDateTime.now(tz.local).minute,
        ),
      );

      if (scheduledTime.isBefore(tz.TZDateTime.now(tz.local))) {
        scheduledTime = scheduledTime.add(const Duration(days: 1));
      }
      if (inactiveVisitors.isNotEmpty) {
        String body = 'لديك ${inactiveVisitors.length} مخدوم بحاجة إلى افتقاد';
        await flutterLocalNotificationsPlugin.zonedSchedule(
          0,
          'تذكير',
          body,
          scheduledTime,
          details,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.time,
        );
      }
    }
  }
}
