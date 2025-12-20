import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart'
    as fln;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

class NotificationService {
  final fln.FlutterLocalNotificationsPlugin _notificationsPlugin =
      fln.FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    tz.initializeTimeZones();

    const fln.AndroidInitializationSettings initializationSettingsAndroid =
        fln.AndroidInitializationSettings('@mipmap/ic_launcher');

    const fln.DarwinInitializationSettings initializationSettingsIOS =
        fln.DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const fln.InitializationSettings initializationSettings =
        fln.InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsIOS,
        );

    await _notificationsPlugin.initialize(initializationSettings);
    _initialized = true;
  }

  Future<void> requestPermissions() async {
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          fln.IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          fln.AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
  }

  Future<void> showInstantNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    const androidDetails = fln.AndroidNotificationDetails(
      'default_channel',
      'General',
      importance: fln.Importance.max,
      priority: fln.Priority.high,
    );

    const iosDetails = fln.DarwinNotificationDetails();
    const details = fln.NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notificationsPlugin.show(id, title, body, details);
  }

  Future<void> scheduleDailyReminder({
    required int id,
    required String title,
    required String body,
    required TimeOfDay time,
  }) async {
    await init();

    final location = tz.local;
    tz.TZDateTime scheduled = tz.TZDateTime(
      location,
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
      time.hour,
      time.minute,
    );

    if (scheduled.isBefore(tz.TZDateTime.now(location))) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    const androidDetails = fln.AndroidNotificationDetails(
      'daily_reminder_channel',
      'Daily Reminders',
      channelDescription: 'Gunluk calisma hatirlatmalari',
      importance: fln.Importance.high,
      priority: fln.Priority.high,
    );

    const iosDetails = fln.DarwinNotificationDetails();
    const details = fln.NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      scheduled,
      details,
      androidScheduleMode: fln.AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: fln.DateTimeComponents.time,
    );
  }

  Future<void> cancelAll() async {
    await _notificationsPlugin.cancelAll();
  }

  /// Sınava geri sayım bildirimi - belirli günler kala
  Future<void> scheduleExamCountdown({
    required int daysLeft,
    required DateTime examDate,
  }) async {
    await init();

    final location = tz.local;

    // Clear old countdown notifications (IDs 1000-1100)
    for (int i = 1000; i <= 1100; i++) {
      await _notificationsPlugin.cancel(i);
    }

    // Schedule notifications for specific milestones
    final milestones = [90, 60, 30, 14, 7, 3, 1];

    for (final milestone in milestones) {
      if (daysLeft > milestone) {
        final notificationDate = examDate.subtract(Duration(days: milestone));
        final scheduledTime = tz.TZDateTime(
          location,
          notificationDate.year,
          notificationDate.month,
          notificationDate.day,
          9,
          0,
        );

        if (scheduledTime.isAfter(tz.TZDateTime.now(location))) {
          String title;
          String body;

          if (milestone == 1) {
            title = '⏰ Yarın sınav!';
            body = 'Son hazırlıklarını yap ve dinlenmeyi unutma. Başarılar!';
          } else if (milestone <= 7) {
            title = '🔥 Sınava $milestone gün kaldı!';
            body =
                'Son sprint! Zayıf konularına odaklan ve pratik yapmaya devam et.';
          } else if (milestone <= 30) {
            title = '📚 Sınava $milestone gün kaldı';
            body = 'Düzenli çalışmaya devam et. Her gün biraz ilerleme önemli!';
          } else {
            title = '📅 Sınava $milestone gün kaldı';
            body =
                'Henüz zaman var ama erken başlamak avantaj sağlar. Çalışmaya devam!';
          }

          const androidDetails = fln.AndroidNotificationDetails(
            'exam_countdown_channel',
            'Sınav Geri Sayımı',
            channelDescription: 'Sınava kalan gün bildirimleri',
            importance: fln.Importance.high,
            priority: fln.Priority.high,
          );

          const iosDetails = fln.DarwinNotificationDetails();
          const details = fln.NotificationDetails(
            android: androidDetails,
            iOS: iosDetails,
          );

          await _notificationsPlugin.zonedSchedule(
            1000 + milestone,
            title,
            body,
            scheduledTime,
            details,
            androidScheduleMode: fln.AndroidScheduleMode.exactAllowWhileIdle,
          );
        }
      }
    }
  }

  /// Seri koruma bildirimi - akşam saat 20:00'de
  Future<void> scheduleStreakReminder() async {
    await init();

    final location = tz.local;
    tz.TZDateTime scheduled = tz.TZDateTime(
      location,
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
      20,
      0,
    );

    if (scheduled.isBefore(tz.TZDateTime.now(location))) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    const androidDetails = fln.AndroidNotificationDetails(
      'streak_reminder_channel',
      'Seri Hatırlatma',
      channelDescription: 'Günlük çalışma serisi hatırlatmaları',
      importance: fln.Importance.high,
      priority: fln.Priority.high,
    );

    const iosDetails = fln.DarwinNotificationDetails();
    const details = fln.NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notificationsPlugin.zonedSchedule(
      500,
      '🔥 Serini kaybetme!',
      'Bugün henüz soru çözmedin. Birkaç soru çözerek serini koru!',
      scheduled,
      details,
      androidScheduleMode: fln.AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: fln.DateTimeComponents.time,
    );
  }

  /// Motivasyon bildirimleri - rastgele zamanlarda
  Future<void> scheduleMotivationalNotification() async {
    await init();

    final motivationalMessages = [
      ('💪 Harika gidiyorsun!', 'Her gün bir adım daha hedefe yaklaşıyorsun.'),
      ('🎯 Odaklan!', 'Bugün 10 soru çözmek seni hedefe yaklaştırır.'),
      ('📚 Çalışma vakti!', 'Zayıf konularını pekiştirmek için harika bir gün.'),
      ('🚀 Sen yapabilirsin!', 'Düzenli çalışma başarının anahtarı.'),
      ('⭐ Süper!', 'Bu hafta harika ilerleme kaydediyorsun!'),
    ];

    final random = DateTime.now().millisecondsSinceEpoch % motivationalMessages.length;
    final (title, body) = motivationalMessages[random];

    final location = tz.local;
    tz.TZDateTime scheduled = tz.TZDateTime(
      location,
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
      14,
      0,
    );

    if (scheduled.isBefore(tz.TZDateTime.now(location))) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    const androidDetails = fln.AndroidNotificationDetails(
      'motivation_channel',
      'Motivasyon',
      channelDescription: 'Motivasyon bildirimleri',
      importance: fln.Importance.defaultImportance,
      priority: fln.Priority.defaultPriority,
    );

    const iosDetails = fln.DarwinNotificationDetails();
    const details = fln.NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notificationsPlugin.zonedSchedule(
      600,
      title,
      body,
      scheduled,
      details,
      androidScheduleMode: fln.AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: fln.DateTimeComponents.time,
    );
  }

  /// Belirli bir bildirimi iptal et
  Future<void> cancel(int id) async {
    await _notificationsPlugin.cancel(id);
  }
}
