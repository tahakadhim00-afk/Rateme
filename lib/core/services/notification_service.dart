import 'package:flutter/material.dart' show TimeOfDay;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  static const _channelId = 'rateme_main';
  static const _channelName = 'RateMe';
  static const _channelDesc = 'RateMe reminders and updates';
  static const _reminderKey = 'daily_reminder_enabled';
  static const _reminderHourKey = 'daily_reminder_hour';
  static const _reminderMinuteKey = 'daily_reminder_minute';

  // ── Init ──────────────────────────────────────────────────────────────────

  static Future<void> init() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);
    await _plugin.initialize(settings);

    // Request permission on Android 13+
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  // ── Show a notification immediately ──────────────────────────────────────

  static Future<void> show({
    int id = 0,
    required String title,
    required String body,
  }) async {
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDesc,
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        playSound: true,
        enableVibration: true,
      ),
    );
    await _plugin.show(id, title, body, details);
  }

  // ── Reminder preference ───────────────────────────────────────────────────

  static Future<bool> isReminderEnabled() async {
    final val = await _storage.read(key: _reminderKey);
    return val == 'true';
  }

  static Future<TimeOfDay?> getReminderTime() async {
    final hour = await _storage.read(key: _reminderHourKey);
    final minute = await _storage.read(key: _reminderMinuteKey);
    if (hour == null || minute == null) return null;
    final h = int.tryParse(hour);
    final m = int.tryParse(minute);
    if (h == null || m == null) return null;
    return TimeOfDay(hour: h, minute: m);
  }

  static Future<void> setReminderTime(TimeOfDay time) async {
    await _storage.write(key: _reminderHourKey, value: time.hour.toString());
    await _storage.write(key: _reminderMinuteKey, value: time.minute.toString());
  }

  static Future<void> setReminderEnabled(bool enabled) async {
    await _storage.write(key: _reminderKey, value: enabled.toString());

    if (enabled) {
      const details = NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDesc,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          playSound: true,
          enableVibration: true,
        ),
      );
      await _plugin.periodicallyShow(
        1,
        '🎬 RateMe Daily Reminder',
        'Your watchlist is waiting — anything new to rate today?',
        RepeatInterval.daily,
        details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    } else {
      await _plugin.cancel(1);
    }
  }
}
