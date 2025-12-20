import 'package:cloud_firestore/cloud_firestore.dart';

/// AI tarafından oluşturulan kişiselleştirilmiş çalışma planı
class PersonalizedStudyPlan {
  final String id;
  final String userId;
  final int durationDays;
  final DateTime startDate;
  final DateTime targetDate;
  final String planContent; // AI tarafından oluşturulan markdown içerik
  final List<DailyTask> dailyTasks;
  final String studyIntensity;
  final DateTime createdAt;
  final int completedDays;

  PersonalizedStudyPlan({
    required this.id,
    required this.userId,
    required this.durationDays,
    required this.startDate,
    required this.targetDate,
    required this.planContent,
    required this.dailyTasks,
    required this.studyIntensity,
    required this.createdAt,
    this.completedDays = 0,
  });

  double get progressPercentage =>
      durationDays > 0 ? (completedDays / durationDays * 100) : 0;

  int get daysRemaining {
    final now = DateTime.now();
    return targetDate.difference(now).inDays;
  }

  DailyTask? get todayTask {
    final now = DateTime.now();
    final dayIndex = now.difference(startDate).inDays;
    if (dayIndex >= 0 && dayIndex < dailyTasks.length) {
      return dailyTasks[dayIndex];
    }
    return null;
  }

  factory PersonalizedStudyPlan.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PersonalizedStudyPlan(
      id: doc.id,
      userId: data['userId'] ?? '',
      durationDays: data['durationDays'] ?? 30,
      startDate: (data['startDate'] as Timestamp).toDate(),
      targetDate: (data['targetDate'] as Timestamp).toDate(),
      planContent: data['planContent'] ?? '',
      dailyTasks: (data['dailyTasks'] as List<dynamic>?)
              ?.map((t) => DailyTask.fromMap(t as Map<String, dynamic>))
              .toList() ??
          [],
      studyIntensity: data['studyIntensity'] ?? 'medium',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      completedDays: data['completedDays'] ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'durationDays': durationDays,
      'startDate': Timestamp.fromDate(startDate),
      'targetDate': Timestamp.fromDate(targetDate),
      'planContent': planContent,
      'dailyTasks': dailyTasks.map((t) => t.toMap()).toList(),
      'studyIntensity': studyIntensity,
      'createdAt': Timestamp.fromDate(createdAt),
      'completedDays': completedDays,
    };
  }
}

/// Günlük görev
class DailyTask {
  final int dayNumber;
  final String title;
  final String description;
  final List<TaskItem> items;
  final bool isCompleted;
  final String focusSubject;

  DailyTask({
    required this.dayNumber,
    required this.title,
    required this.description,
    required this.items,
    this.isCompleted = false,
    required this.focusSubject,
  });

  int get completedItemsCount => items.where((i) => i.isCompleted).length;
  double get itemProgressPercentage =>
      items.isNotEmpty ? (completedItemsCount / items.length * 100) : 0;

  factory DailyTask.fromMap(Map<String, dynamic> map) {
    return DailyTask(
      dayNumber: map['dayNumber'] ?? 0,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      items: (map['items'] as List<dynamic>?)
              ?.map((i) => TaskItem.fromMap(i as Map<String, dynamic>))
              .toList() ??
          [],
      isCompleted: map['isCompleted'] ?? false,
      focusSubject: map['focusSubject'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'dayNumber': dayNumber,
      'title': title,
      'description': description,
      'items': items.map((i) => i.toMap()).toList(),
      'isCompleted': isCompleted,
      'focusSubject': focusSubject,
    };
  }
}

/// Görev öğesi
class TaskItem {
  final String id;
  final String title;
  final String type; // 'lesson', 'quiz', 'review', 'exam'
  final int estimatedMinutes;
  final bool isCompleted;
  final String? topicId;
  final String? subjectId;

  TaskItem({
    required this.id,
    required this.title,
    required this.type,
    required this.estimatedMinutes,
    this.isCompleted = false,
    this.topicId,
    this.subjectId,
  });

  factory TaskItem.fromMap(Map<String, dynamic> map) {
    return TaskItem(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      type: map['type'] ?? 'lesson',
      estimatedMinutes: map['estimatedMinutes'] ?? 30,
      isCompleted: map['isCompleted'] ?? false,
      topicId: map['topicId'],
      subjectId: map['subjectId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'type': type,
      'estimatedMinutes': estimatedMinutes,
      'isCompleted': isCompleted,
      'topicId': topicId,
      'subjectId': subjectId,
    };
  }
}
