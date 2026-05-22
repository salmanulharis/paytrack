import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../constants/app_constants.dart';
import '../../data/repositories/expense_repository.dart';
import 'analytics_service.dart';

class NotificationService {
  NotificationService({
    required this.expenseRepository,
    required this.analyticsService,
    required this.prefs,
  });

  final ExpenseRepository expenseRepository;
  final AnalyticsService analyticsService;
  final SharedPreferences prefs;

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    tz.initializeTimeZones();

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );
    _initialized = true;
    await scheduleRecurringNotifications();
  }

  bool get notificationsEnabled =>
      prefs.getBool(AppConstants.prefNotificationsEnabled) ?? true;

  Future<void> scheduleRecurringNotifications() async {
    if (!notificationsEnabled) return;

    if (prefs.getBool(AppConstants.prefDailySummary) ?? true) {
      await _scheduleDaily(20, 0, 1, 'Daily Summary', 'See how much you spent today');
    }
    if (prefs.getBool(AppConstants.prefWeeklyReport) ?? true) {
      await _scheduleWeekly(DateTime.monday, 9, 0, 2, 'Weekly Report', 'Your weekly spending recap is ready');
    }
  }

  Future<void> _scheduleDaily(
    int hour,
    int minute,
    int id,
    String title,
    String body,
  ) async {
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      _nextInstanceOfTime(hour, minute),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_summary',
          'Daily Summary',
          channelDescription: 'Daily expense summaries',
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> _scheduleWeekly(
    int weekday,
    int hour,
    int minute,
    int id,
    String title,
    String body,
  ) async {
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      _nextInstanceOfWeekday(weekday, hour, minute),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'weekly_report',
          'Weekly Report',
          channelDescription: 'Weekly spending reports',
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
    );
  }

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  tz.TZDateTime _nextInstanceOfWeekday(int weekday, int hour, int minute) {
    var scheduled = _nextInstanceOfTime(hour, minute);
    while (scheduled.weekday != weekday) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  Future<void> showPendingReminder() async {
    await _plugin.show(
      99,
      'Pending Payment',
      'Confirm if your UPI payment was successful',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'pending_payment',
          'Pending Payments',
          channelDescription: 'Reminders for unconfirmed payments',
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  Future<void> showBudgetAlert(String message) async {
    if (!(prefs.getBool(AppConstants.prefBudgetAlerts) ?? true)) return;
    await _plugin.show(
      100,
      'Budget Alert',
      message,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'budget_alerts',
          'Budget Alerts',
          channelDescription: 'Budget threshold alerts',
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }
}
