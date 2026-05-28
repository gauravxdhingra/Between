import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

const _prefKey = 'notifications_enabled';
const _weeklyId = 1001;
const _channelId = 'settle_default';
const _channelName = 'Settle';

final _plugin = FlutterLocalNotificationsPlugin();

Future<void> initNotifications() async {
  tz.initializeTimeZones();

  const android = AndroidInitializationSettings('@mipmap/ic_launcher');
  const ios = DarwinInitializationSettings(
    requestAlertPermission: false,
    requestBadgePermission: false,
    requestSoundPermission: false,
  );

  await _plugin.initialize(
    const InitializationSettings(android: android, iOS: ios),
  );
}

Future<bool> notificationsEnabled() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool(_prefKey) ?? true;
}

Future<void> setNotificationsEnabled(bool value) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(_prefKey, value);
  if (!value) {
    await _plugin.cancelAll();
  } else {
    await scheduleWeeklyDigest();
  }
}

Future<bool> requestPermission() async {
  final android = _plugin.resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin>();
  final ios = _plugin.resolvePlatformSpecificImplementation<
      IOSFlutterLocalNotificationsPlugin>();

  bool granted = false;
  if (android != null) {
    granted = await android.requestNotificationsPermission() ?? false;
  }
  if (ios != null) {
    granted = await ios.requestPermissions(alert: true, badge: true, sound: true) ?? false;
  }
  return granted;
}

// ── Notification types ────────────────────────────────────────────────────────

/// Called immediately when someone adds an expense the user is part of.
Future<void> showExpenseAdded({
  required String addedBy,
  required String title,
  required double yourShare,
  required String groupName,
}) async {
  if (!await notificationsEnabled()) return;

  const details = NotificationDetails(
    android: AndroidNotificationDetails(
      _channelId,
      _channelName,
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    ),
    iOS: DarwinNotificationDetails(),
  );

  await _plugin.show(
    DateTime.now().millisecondsSinceEpoch % 100000,
    '$addedBy added "$title"',
    'Your share is ₹${yourShare.toStringAsFixed(0)} in $groupName',
    details,
  );
}

/// Schedules (or re-schedules) the weekly Sunday 7 pm digest.
Future<void> scheduleWeeklyDigest({
  double totalOwed = 0,
  double totalOwe = 0,
  int groupCount = 0,
}) async {
  if (!await notificationsEnabled()) return;

  await _plugin.cancel(_weeklyId);

  final now = tz.TZDateTime.now(tz.local);
  // Find next Sunday at 19:00
  var next = tz.TZDateTime(
    tz.local,
    now.year,
    now.month,
    now.day,
    19,
  );
  final daysUntilSunday = (DateTime.sunday - now.weekday) % 7;
  next = next.add(Duration(days: daysUntilSunday == 0 ? 7 : daysUntilSunday));

  final body = totalOwed > 0
      ? 'You\'re owed ₹${totalOwed.toStringAsFixed(0)} across $groupCount group${groupCount == 1 ? '' : 's'}.'
      : totalOwe > 0
          ? 'You owe ₹${totalOwe.toStringAsFixed(0)} across $groupCount group${groupCount == 1 ? '' : 's'}.'
          : 'All settled up — nice work!';

  await _plugin.zonedSchedule(
    _weeklyId,
    'Weekly digest',
    body,
    next,
    const NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        importance: Importance.low,
        priority: Priority.low,
      ),
      iOS: DarwinNotificationDetails(),
    ),
    androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    uiLocalNotificationDateInterpretation:
        UILocalNotificationDateInterpretation.absoluteTime,
    matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
  );
}

/// Shows an idle-group nudge (called on app resume, not a scheduled alarm).
Future<void> showIdleGroupNudge({
  required String groupName,
  required double unsettledAmount,
}) async {
  if (!await notificationsEnabled()) return;

  const details = NotificationDetails(
    android: AndroidNotificationDetails(
      _channelId,
      _channelName,
      importance: Importance.low,
      priority: Priority.low,
    ),
    iOS: DarwinNotificationDetails(),
  );

  await _plugin.show(
    groupName.hashCode.abs() % 100000,
    'Still sorting out $groupName?',
    '₹${unsettledAmount.toStringAsFixed(0)} left to settle.',
    details,
  );
}
