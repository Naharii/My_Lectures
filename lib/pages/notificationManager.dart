import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:flutter_timezone/flutter_timezone.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  static bool _isInitialized = false;

  static Future<void> init() async {
    if (_isInitialized) return;

    try {
      // 1. Initialize Timezones
      tz_data.initializeTimeZones();
      String timezoneId = 'Asia/Riyadh';
      try {
        final dynamic result = await FlutterTimezone.getLocalTimezone();
        String raw = result.toString();
        
        // Robust parsing: extract the name from "TimezoneInfo(name: Asia/Riyadh, ...)"
        if (raw.contains('name:')) {
          timezoneId = raw.split('name:')[1].split(',')[0].split(')')[0].trim();
        } else {
          timezoneId = raw.trim();
        }
        
        tz.setLocalLocation(tz.getLocation(timezoneId));
      } catch (e) {
        debugPrint("Timezone Error: $e. Falling back to Riyadh.");
        tz.setLocalLocation(tz.getLocation('Asia/Riyadh'));
      }

      // 2. Initialize Plugin with the correct resource path for the icon
      const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

      await _notificationsPlugin.initialize(
        settings: const InitializationSettings(android: androidSettings, iOS: DarwinInitializationSettings()),
      );

      _isInitialized = true;

      // 3. Request permissions
      final androidImplementation = _notificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (androidImplementation != null) {
        await androidImplementation.requestNotificationsPermission();
        await androidImplementation.requestExactAlarmsPermission();
      }
    } catch (e) {
      debugPrint("Notification Init Error: $e");
    }
  }

  static String _cleanArabicNumbers(String input) {
    var arabic = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    var english = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    for (int i = 0; i < 10; i++) {
      input = input.replaceAll(arabic[i], english[i]);
    }
    return input;
  }

  static Future<void> scheduleWeeklyNotification({
    required int id,
    required String name,
    required String room,
    required String day,
    required String timeStr,
    int offsetMinutes = 0,
  }) async {
    if (!_isInitialized) await init();
    try {
      String cleanTime = _cleanArabicNumbers(timeStr).toUpperCase();
      
      final RegExp timeRegExp = RegExp(r'(\d+):(\d+)');
      final match = timeRegExp.firstMatch(cleanTime);
      if (match == null) return;

      int hour = int.parse(match.group(1)!);
      int minute = int.parse(match.group(2)!);

      // Handle 12-hour logic
      bool isPM = cleanTime.contains("PM") || cleanTime.contains("م");
      bool isAM = cleanTime.contains("AM") || cleanTime.contains("ص");

      if (isPM && hour != 12) hour += 12;
      if (isAM && hour == 12) hour = 0;

      final dayMap = {"Sun": 7, "Mon": 1, "Tue": 2, "Wed": 3, "Thur": 4, "Fri": 5, "Sat": 6};
      int targetDay = dayMap[day] ?? 1;

      final now = tz.TZDateTime.now(tz.local);
      tz.TZDateTime scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
      
      while (scheduledDate.weekday != targetDay) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }
      
      tz.TZDateTime triggerTime = scheduledDate.subtract(Duration(minutes: offsetMinutes));
      // Added 1-minute grace period: if the lecture is set for right now, 
      // fire it today instead of pushing it to next week.
      if (triggerTime.isBefore(now.subtract(const Duration(minutes: 1)))) {
        triggerTime = triggerTime.add(const Duration(days: 7));
      }

      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'lecture_channel_v25', 
        'Lectures',
        channelDescription: 'Weekly Lecture Notifications',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
      );
      
      await _notificationsPlugin.zonedSchedule(
        id: id,
        title: "Lecture Starting: $name",
        body: "Room: $room",
        scheduledDate: triggerTime,
        notificationDetails: const NotificationDetails(android: androidDetails),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime, 
      );
      debugPrint("Scheduled $name for $triggerTime");
    } catch (e) {
      debugPrint("Schedule Error: $e");
    }
  }

  static Future<void> scheduleReminderNotification(String id, String type, String course, DateTime dueDate, int hoursBefore) async {
    if (!_isInitialized) await init();
    try {
      final now = tz.TZDateTime.now(tz.local);
      final scheduledDate = tz.TZDateTime.from(dueDate, tz.local);
      tz.TZDateTime triggerTime = scheduledDate.subtract(Duration(hours: hoursBefore));

      if (triggerTime.isBefore(now)) {
        debugPrint("Reminder time is in the past, skipping: $triggerTime");
        return;
      }

      // Convert String ID to unique int for notifications
      int intId = id.hashCode.abs();

      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'reminder_channel_v1',
        'Reminders',
        channelDescription: 'Homework and Quiz Alerts',
        importance: Importance.max,
        priority: Priority.high,
        category: AndroidNotificationCategory.reminder,
        playSound: true,
        enableVibration: true,
      );

      await _notificationsPlugin.zonedSchedule(
        id: intId,
        title: "$type Due: $course",
        body: "Your $type is due in $hoursBefore hours!",
        scheduledDate: triggerTime,
        notificationDetails: const NotificationDetails(android: androidDetails),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
      debugPrint("Scheduled Reminder for $course at $triggerTime");
    } catch (e) {
      debugPrint("Reminder Schedule Error: $e");
    }
  }

  static Future<void> cancelNotification(String id) async {
    if (_isInitialized) await _notificationsPlugin.cancel(id: id.hashCode.abs());
  }

  static Future<void> cancelAll() async {
    if (_isInitialized) await _notificationsPlugin.cancelAll();
  }

  static Future<void> showInstantNotification(String title, String body) async {
    if (!_isInitialized) {
      // Small delay or recursive call risk if not careful, but init() checks _isInitialized
      await init(); 
    }
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'test_channel_v3', 'Tests', importance: Importance.max, priority: Priority.high);
    await _notificationsPlugin.show(id: 888, title: title, body: body, notificationDetails: const NotificationDetails(android: androidDetails));
  }
}
