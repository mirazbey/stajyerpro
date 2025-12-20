import 'package:cloud_firestore/cloud_firestore.dart';

/// Bildirim tipi
enum NotificationType {
  examReminder,    // Sınav hatırlatması
  studyPlan,       // Çalışma planı
  newContent,      // Yeni içerik
  achievement,     // Başarı/rozet
  lawUpdate,       // Mevzuat güncellemesi
  system,          // Sistem bildirimi
}

/// Bildirim modeli
class NotificationModel {
  final String id;
  final String userId;
  final NotificationType type;
  final String title;
  final String content;
  final bool isRead;
  final DateTime createdAt;
  final String? actionRoute; // Tıklanınca gidilecek rota

  NotificationModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.content,
    required this.isRead,
    required this.createdAt,
    this.actionRoute,
  });

  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return NotificationModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      type: NotificationType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => NotificationType.system,
      ),
      title: data['title'] ?? '',
      content: data['content'] ?? '',
      isRead: data['isRead'] ?? false,
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      actionRoute: data['actionRoute'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'type': type.name,
      'title': title,
      'content': content,
      'isRead': isRead,
      'createdAt': Timestamp.fromDate(createdAt),
      'actionRoute': actionRoute,
    };
  }

  NotificationModel copyWith({
    String? id,
    String? userId,
    NotificationType? type,
    String? title,
    String? content,
    bool? isRead,
    DateTime? createdAt,
    String? actionRoute,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      title: title ?? this.title,
      content: content ?? this.content,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      actionRoute: actionRoute ?? this.actionRoute,
    );
  }

  /// Bildirim tipine göre ikon
  String get iconName {
    switch (type) {
      case NotificationType.examReminder:
        return 'calendar_today';
      case NotificationType.studyPlan:
        return 'schedule';
      case NotificationType.newContent:
        return 'new_releases';
      case NotificationType.achievement:
        return 'emoji_events';
      case NotificationType.lawUpdate:
        return 'gavel';
      case NotificationType.system:
        return 'notifications';
    }
  }
}
