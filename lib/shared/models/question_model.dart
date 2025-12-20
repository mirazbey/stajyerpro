import 'package:cloud_firestore/cloud_firestore.dart';

/// Soru modeli (HMGS sorular)
class QuestionModel {
  final String id;
  final String stem; // Soru metni
  final List<String> options; // Şıklar (A, B, C, D, E)
  final int correctIndex; // Doğru cevabın index'i (0-4)
  final String?
  explanation; // AI açıklaması (opsiyonel) - DEPRECATED, use detailedExplanation
  final String? source; // Kaynak (örn: "2023 HMGS")
  final String subjectId; // Hangi derse ait
  final List<String> topicIds; // Hangi konulara ait
  final String difficulty; // 'easy', 'medium', 'hard'
  final List<String>? targetRoles; // Hedef roller (hakim, savcı, avukat)
  final DateTime createdAt;
  final DateTime updatedAt;

  // YENİ ALANLAR - Detaylı Açıklama Sistemi
  final String? lawArticle; // İlgili kanun maddesi (örn: "TMK m.186")
  final String? detailedExplanation; // Doğru cevabın detaylı açıklaması
  final Map<int, String>?
  wrongReasons; // Her yanlış şıkkın açıklaması {0: "A şıkkı yanlış çünkü..."}
  final List<String>?
  relatedCases; // İlgili emsal kararlar ["Yargıtay 2. HD 2023/456"]
  final int? year; // Sorunun yılı (2023, 2024 vs.)
  final List<String>? tags; // Etiketler ["9.yargı", "güncel", "emsal"]
  final String? aiTip; // AI tarafından üretilen kısa ipucu/pratik öneri

  QuestionModel({
    required this.id,
    required this.stem,
    required this.options,
    required this.correctIndex,
    this.explanation,
    this.source,
    required this.subjectId,
    required this.topicIds,
    required this.difficulty,
    this.targetRoles,
    required this.createdAt,
    required this.updatedAt,
    // Yeni alanlar
    this.lawArticle,
    this.detailedExplanation,
    this.wrongReasons,
    this.relatedCases,
    this.year,
    this.tags,
    this.aiTip,
  });

  /// Firestore'dan QuestionModel oluştur
  factory QuestionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return QuestionModel(
      id: doc.id,
      stem: data['stem'] ?? '',
      options: List<String>.from(data['options'] ?? []),
      correctIndex: data['correctIndex'] ?? 0,
      explanation: data['explanation'],
      source: data['source'],
      subjectId: data['subjectId'] ?? '',
      topicIds: List<String>.from(data['topicIds'] ?? []),
      difficulty: data['difficulty'] ?? 'medium',
      targetRoles: data['targetRoles'] != null
          ? List<String>.from(data['targetRoles'])
          : null,
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
      // Yeni alanlar
      lawArticle: data['lawArticle'] as String?,
      detailedExplanation: data['detailedExplanation'] as String?,
      wrongReasons: data['wrongReasons'] != null
          ? Map<int, String>.from(
              (data['wrongReasons'] as Map).map(
                (k, v) => MapEntry(int.parse(k.toString()), v.toString()),
              ),
            )
          : null,
      relatedCases: data['relatedCases'] != null
          ? List<String>.from(data['relatedCases'])
          : null,
      year: data['year'] as int?,
      tags: data['tags'] != null ? List<String>.from(data['tags']) : null,
      aiTip: data['aiTip'] as String?,
    );
  }

  /// QuestionModel'i Firestore formatına çevir
  Map<String, dynamic> toFirestore() {
    return {
      'stem': stem,
      'options': options,
      'correctIndex': correctIndex,
      'explanation': explanation,
      'source': source,
      'subjectId': subjectId,
      'topicIds': topicIds,
      'difficulty': difficulty,
      'targetRoles': targetRoles,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      // Yeni alanlar
      'lawArticle': lawArticle,
      'detailedExplanation': detailedExplanation,
      'wrongReasons': wrongReasons?.map((k, v) => MapEntry(k.toString(), v)),
      'relatedCases': relatedCases,
      'year': year,
      'tags': tags,
      'aiTip': aiTip,
    };
  }

  /// Copy with metodu
  QuestionModel copyWith({
    String? id,
    String? stem,
    List<String>? options,
    int? correctIndex,
    String? explanation,
    String? source,
    String? subjectId,
    List<String>? topicIds,
    String? difficulty,
    List<String>? targetRoles,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? lawArticle,
    String? detailedExplanation,
    Map<int, String>? wrongReasons,
    List<String>? relatedCases,
    int? year,
    List<String>? tags,
    String? aiTip,
  }) {
    return QuestionModel(
      id: id ?? this.id,
      stem: stem ?? this.stem,
      options: options ?? this.options,
      correctIndex: correctIndex ?? this.correctIndex,
      explanation: explanation ?? this.explanation,
      source: source ?? this.source,
      subjectId: subjectId ?? this.subjectId,
      topicIds: topicIds ?? this.topicIds,
      difficulty: difficulty ?? this.difficulty,
      targetRoles: targetRoles ?? this.targetRoles,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lawArticle: lawArticle ?? this.lawArticle,
      detailedExplanation: detailedExplanation ?? this.detailedExplanation,
      wrongReasons: wrongReasons ?? this.wrongReasons,
      relatedCases: relatedCases ?? this.relatedCases,
      year: year ?? this.year,
      tags: tags ?? this.tags,
      aiTip: aiTip ?? this.aiTip,
    );
  }
}

/// Kullanıcı cevap modeli (quiz sırasında)
class UserAnswer {
  final String questionId;
  final int selectedIndex;
  final bool isCorrect;
  final DateTime answeredAt;
  final String? subjectId; // For analytics
  final String? topicId; // For weak topic detection

  UserAnswer({
    required this.questionId,
    required this.selectedIndex,
    required this.isCorrect,
    required this.answeredAt,
    this.subjectId,
    this.topicId,
  });

  Map<String, dynamic> toMap() {
    return {
      'questionId': questionId,
      'selectedIndex': selectedIndex,
      'isCorrect': isCorrect,
      'answeredAt': Timestamp.fromDate(answeredAt),
      if (subjectId != null) 'subjectId': subjectId,
      if (topicId != null) 'topicId': topicId,
    };
  }
}
