import 'package:cloud_firestore/cloud_firestore.dart';

/// Konu modeli (bir dersin içindeki alt konular)
class TopicModel {
  final String id;
  final String subjectId; // Hangi derse ait
  final String? parentId; // Üst konu ID'si (Subtopic için)
  final String name;
  final String? description;
  final int order; // Sıralama
  final bool isActive;
  final int? questionCount; // Bu konuda kaç soru var
  final DateTime createdAt;
  final DateTime updatedAt;

  TopicModel({
    required this.id,
    required this.subjectId,
    this.parentId,
    required this.name,
    this.description,
    required this.order,
    required this.isActive,
    this.questionCount,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Firestore'dan TopicModel oluştur
  factory TopicModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TopicModel(
      id: doc.id,
      subjectId: data['subjectId'] ?? '',
      parentId: data['parentId'],
      name: data['name'] ?? '',
      description: data['description'],
      order: data['order'] ?? 0,
      isActive: data['isActive'] ?? true,
      questionCount: data['questionCount'],
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  /// TopicModel'i Firestore formatına çevir
  Map<String, dynamic> toFirestore() {
    return {
      'subjectId': subjectId,
      'parentId': parentId,
      'name': name,
      'description': description,
      'order': order,
      'isActive': isActive,
      'questionCount': questionCount,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Copy with metodu
  TopicModel copyWith({
    String? id,
    String? subjectId,
    String? parentId,
    String? name,
    String? description,
    int? order,
    bool? isActive,
    int? questionCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TopicModel(
      id: id ?? this.id,
      subjectId: subjectId ?? this.subjectId,
      parentId: parentId ?? this.parentId,
      name: name ?? this.name,
      description: description ?? this.description,
      order: order ?? this.order,
      isActive: isActive ?? this.isActive,
      questionCount: questionCount ?? this.questionCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
