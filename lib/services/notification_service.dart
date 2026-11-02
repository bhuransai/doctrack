import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../models/document.dart';
import '../utils/date_utils.dart';
import '../utils/text_utils.dart';

/// Schedules real OS-level local notifications for document expiry reminders.
/// Each document reserves a block of 10 notification ids (id*10 .. id*10+9)
/// so reminders can be cancelled and re-scheduled per-document without
/// touching anyone else's.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;
  // False when the plugin has no implementation on this platform (tests,
  // desktop, web): cancel/schedule calls then become no-ops.
  bool _available = false;
  bool _permissionGranted = false;

  bool get permissionGranted => _permissionGranted;

  Future<void> init() async {
    if (_ready) return;
    tz_data.initializeTimeZones();
    try {
      final name = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(name));
    } catch (_) {
      // Fall back to UTC if the platform timezone can't be resolved.
    }

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    try {
      await _plugin.initialize(
        const InitializationSettings(android: androidInit, iOS: iosInit, macOS: iosInit),
      );
      _available = true;
    } catch (e) {
      debugPrint('DocTrack: notification plugin unavailable on this platform: $e');
    }
    _ready = true;
  }

  Future<bool> requestPermission() async {
    await init();
    try {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (android != null) {
        final granted = await android.requestNotificationsPermission();
        _permissionGranted = granted ?? true;
        return _permissionGranted;
      }
      final ios = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      if (ios != null) {
        final granted = await ios.requestPermissions(alert: true, badge: true, sound: true);
        _permissionGranted = granted ?? true;
        return _permissionGranted;
      }
    } catch (e) {
      debugPrint('DocTrack: could not request notification permission: $e');
    }
    // Desktop/web targets, or platforms without a registered implementation
    // (e.g. tests): nothing to request, treat as unavailable but not blocking.
    _permissionGranted = false;
    return false;
  }

  Future<void> cancelForDocument(int docId) async {
    if (!_available) return;
    try {
      for (var i = 0; i < 10; i++) {
        await _plugin.cancel(docId * 10 + i);
      }
    } catch (e) {
      debugPrint('DocTrack: could not cancel reminders for doc $docId: $e');
    }
  }

  Future<void> cancelAll() async {
    if (!_available) return;
    try {
      await _plugin.cancelAll();
    } catch (e) {
      debugPrint('DocTrack: could not cancel all reminders: $e');
    }
  }

  /// Cancels any existing schedule for [doc] and re-schedules one
  /// notification per entry in [DocRecord.reminderDays], at 9:00 AM local
  /// time on the reminder date, plus an on-expiry-day alert. Past times are
  /// skipped automatically. When [userName] is given, notifications open
  /// with a personal greeting ("Hi Aarav — ...").
  ///
  /// Uses inexact scheduling: a morning reminder doesn't need to-the-minute
  /// delivery, and exact alarms require a permission Google Play restricts
  /// to alarm and calendar apps.
  Future<void> scheduleForDocument(DocRecord doc, {String userName = ''}) async {
    await init();
    await cancelForDocument(doc.id);
    if (!_available || !doc.remindersEnabled || !_permissionGranted) return;

    final firstName = firstNameOf(userName);
    final greeting = firstName.isEmpty ? '' : 'Hi $firstName — ';
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'doctrack_reminders',
        'Document reminders',
        channelDescription: 'Expiry reminders for tracked documents',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
      macOS: DarwinNotificationDetails(),
    );

    var slot = 0;
    for (final n in doc.reminderDays) {
      if (slot >= 9) break;
      final fireDate = shiftDays(doc.expiry, n);
      final when = tz.TZDateTime(tz.local, fireDate.year, fireDate.month, fireDate.day, 9);
      if (when.isBefore(tz.TZDateTime.now(tz.local))) continue;
      try {
        await _plugin.zonedSchedule(
          doc.id * 10 + slot,
          '$greeting${doc.name} expires in $n day${n == 1 ? '' : 's'}',
          '${doc.type.label} · expires ${fmtDate(doc.expiry)}',
          when,
          details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
      } catch (e) {
        debugPrint('DocTrack: failed to schedule reminder for ${doc.name}: $e');
      }
      slot++;
    }

    final expiryWhen =
        tz.TZDateTime(tz.local, doc.expiry.year, doc.expiry.month, doc.expiry.day, 9);
    if (expiryWhen.isAfter(tz.TZDateTime.now(tz.local)) && slot < 9) {
      try {
        await _plugin.zonedSchedule(
          doc.id * 10 + slot,
          '$greeting${doc.name} expires today',
          '${doc.type.label} · renew now',
          expiryWhen,
          details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
      } catch (e) {
        debugPrint('DocTrack: failed to schedule expiry alert for ${doc.name}: $e');
      }
    }
  }

  Future<void> rescheduleAll(Iterable<DocRecord> docs, {String userName = ''}) async {
    await init();
    for (final doc in docs) {
      await scheduleForDocument(doc, userName: userName);
    }
  }
}
