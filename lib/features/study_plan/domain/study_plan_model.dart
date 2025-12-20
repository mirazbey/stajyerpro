import 'package:flutter/material.dart';

class StudyPlan {
  final String id;
  final String name;
  final DateTime startDate;
  final List<StudySession> sessions;

  StudyPlan({
    required this.id,
    required this.name,
    required this.startDate,
    required this.sessions,
  });

  factory StudyPlan.create({
    required String name,
    required DateTime startDate,
    required int durationDays,
  }) {
    final sessions = List.generate(durationDays, (index) {
      return StudySession(
        id: DateTime.now()
            .add(Duration(milliseconds: index))
            .millisecondsSinceEpoch
            .toString(),
        date: startDate.add(Duration(days: index)),
        subject: "Konu Belirlenmedi",
        progress: 0.0,
        duration: "2 saat",
        isNotificationOn: false,
        notificationTime: const TimeOfDay(
          hour: 19,
          minute: 0,
        ), // Default: 19:00
      );
    });

    return StudyPlan(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      startDate: startDate,
      sessions: sessions,
    );
  }
}

class StudySession {
  final String id;
  final DateTime date;
  String subject;
  double progress;
  String duration;
  bool isNotificationOn;
  TimeOfDay notificationTime;

  StudySession({
    required this.id,
    required this.date,
    required this.subject,
    required this.progress,
    required this.duration,
    required this.isNotificationOn,
    required this.notificationTime,
  });
}
