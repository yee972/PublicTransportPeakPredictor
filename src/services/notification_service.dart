import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static const int peakAlertId = 1001;
  static const int departureReminderId = 1002;

  static const AndroidNotificationDetails _androidDetails =
      AndroidNotificationDetails(
    'peak_predictor_alerts',
    'Peak alerts',
    channelDescription: 'Daily rail demand forecasts and departure reminders',
    importance: Importance.defaultImportance,
    priority: Priority.defaultPriority,
  );

  static const NotificationDetails _details = NotificationDetails(
    android: _androidDetails,
    iOS: DarwinNotificationDetails(),
  );

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _ready = false;

  Future<void> initialize() async {
    if (_ready) return;
    try {
      tz_data.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation('Asia/Kuala_Lumpur'));

      await _plugin.initialize(
        const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          ),
        ),
      );
      _ready = true;
    } catch (_) {
      _ready = false;
    }
  }

  Future<bool> requestPermission() async {
    await initialize();
    if (!_ready) return false;
    try {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (android != null) {
        return await android.requestNotificationsPermission() ?? false;
      }
      final ios = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      if (ios != null) {
        return await ios.requestPermissions(alert: true, badge: true, sound: true) ??
            false;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<void> showNow({required String title, required String body}) async {
    await initialize();
    if (!_ready) return;
    try {
      await _plugin.show(peakAlertId, title, body, _details);
    } catch (_) {
      return;
    }
  }

  Future<void> scheduleDailyPeakAlert({
    required int hour,
    required int minute,
    required String title,
    required String body,
  }) async {
    await initialize();
    if (!_ready) return;
    try {
      await _plugin.zonedSchedule(
        peakAlertId,
        title,
        body,
        _nextInstanceOf(hour, minute),
        _details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (_) {
      return;
    }
  }

  Future<void> scheduleDepartureReminder({
    required DateTime departAt,
    required String title,
    required String body,
  }) async {
    await initialize();
    if (!_ready) return;
    if (departAt.isBefore(DateTime.now())) return;
    try {
      await _plugin.zonedSchedule(
        departureReminderId,
        title,
        body,
        tz.TZDateTime.from(departAt, tz.local),
        _details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    } catch (_) {
      return;
    }
  }

  Future<void> cancelPeakAlert() async {
    if (!_ready) return;
    try {
      await _plugin.cancel(peakAlertId);
    } catch (_) {
      return;
    }
  }

  tz.TZDateTime _nextInstanceOf(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }
}
