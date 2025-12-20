import 'package:cloud_firestore/cloud_firestore.dart';

/// HMGS Net Hesaplama Helper
class HMGSNetCalculator {
  /// HMGS Net Hesaplama: Net = Doğru - (Yanlış / 4)
  /// Boş bırakılan sorular nete etki etmez
  static double calculateNet({
    required int correct,
    required int wrong,
    required int empty,
  }) {
    return correct - (wrong / 4);
  }

  /// Net'i 100 üzerinden puana çevir
  /// HMGS: 120 soru = 120 max net
  /// Puan = (Net / 120) * 100
  static double netToScore(double net, {int totalQuestions = 120}) {
    if (net < 0) return 0;
    return (net / totalQuestions) * 100;
  }

  /// 70 Baraj kontrolü
  /// HMGS'de geçme puanı 70
  static bool passedBaraj(double score) {
    return score >= 70;
  }

  /// Baraj için gereken minimum net
  /// 70 puan için: (net / 120) * 100 = 70 => net = 84
  static double minimumNetForBaraj({int totalQuestions = 120}) {
    return totalQuestions * 0.7; // 84 net for 120 questions
  }
}

/// Deneme sınavı modeli
class ExamModel {
  final String id;
  final String name;
  final String? description;
  final int totalQuestions; // Toplam soru sayısı (genelde 120)
  final int durationMinutes; // Süre (dakika)
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Yeni alanlar - Satın alma sistemi için
  final bool isFree; // Ücretsiz mi?
  final double price; // Fiyat (TL)
  final String? productId; // RevenueCat product ID
  final String difficultyDistribution; // 'easy', 'medium', 'hard', 'mixed', 'hmgs_real'
  final int? easyPercent; // Kolay soru yüzdesi
  final int? mediumPercent; // Orta soru yüzdesi
  final int? hardPercent; // Zor soru yüzdesi
  final String? badge; // 'YENİ', 'POPÜLER', 'ÖNERİLEN' vb.
  final int orderIndex; // Sıralama için

  ExamModel({
    required this.id,
    required this.name,
    this.description,
    required this.totalQuestions,
    required this.durationMinutes,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.isFree = false,
    this.price = 0,
    this.productId,
    this.difficultyDistribution = 'hmgs_real',
    this.easyPercent,
    this.mediumPercent,
    this.hardPercent,
    this.badge,
    this.orderIndex = 0,
  });

  factory ExamModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ExamModel(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'],
      totalQuestions: data['totalQuestions'] ?? 120,
      durationMinutes: data['durationMinutes'] ?? 180,
      isActive: data['isActive'] ?? true,
      createdAt: data['createdAt'] != null 
          ? (data['createdAt'] as Timestamp).toDate() 
          : DateTime.now(),
      updatedAt: data['updatedAt'] != null 
          ? (data['updatedAt'] as Timestamp).toDate() 
          : DateTime.now(),
      isFree: data['isFree'] ?? false,
      price: (data['price'] as num?)?.toDouble() ?? 0,
      productId: data['productId'],
      difficultyDistribution: data['difficultyDistribution'] ?? 'hmgs_real',
      easyPercent: data['easyPercent'],
      mediumPercent: data['mediumPercent'],
      hardPercent: data['hardPercent'],
      badge: data['badge'],
      orderIndex: data['orderIndex'] ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'totalQuestions': totalQuestions,
      'durationMinutes': durationMinutes,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isFree': isFree,
      'price': price,
      'productId': productId,
      'difficultyDistribution': difficultyDistribution,
      'easyPercent': easyPercent,
      'mediumPercent': mediumPercent,
      'hardPercent': hardPercent,
      'badge': badge,
      'orderIndex': orderIndex,
    };
  }
  
  /// Zorluk açıklaması
  String get difficultyLabel {
    switch (difficultyDistribution) {
      case 'easy':
        return 'Kolay Seviye';
      case 'medium':
        return 'Orta Seviye';
      case 'hard':
        return 'Zor Seviye';
      case 'mixed':
        return 'Karma Seviye';
      case 'hmgs_real':
      default:
        return 'HMGS Gerçek Dağılım';
    }
  }
}

/// Deneme denemesi (attempt) modeli
class ExamAttemptModel {
  final String id;
  final String userId;
  final String examId;
  final Map<int, int> answers; // questionIndex -> selectedOptionIndex
  final Set<int> markedQuestions; // İşaretli sorular (sonra bak)
  final int totalQuestions;
  final int correctAnswers;
  final int wrongAnswers;
  final int emptyAnswers;
  final double net; // HMGS Net = Doğru - (Yanlış/4)
  final int score; // 100 üzerinden puan
  final Duration duration;
  final bool isCompleted;
  final DateTime startedAt;
  final DateTime? completedAt;
  final Map<int, int>? perQuestionDuration; // questionIndex -> saniye
  final Map<String, SubjectResult>? subjectResults; // Ders bazlı sonuçlar

  ExamAttemptModel({
    required this.id,
    required this.userId,
    required this.examId,
    required this.answers,
    this.markedQuestions = const {},
    required this.totalQuestions,
    required this.correctAnswers,
    this.wrongAnswers = 0,
    this.emptyAnswers = 0,
    this.net = 0,
    required this.score,
    required this.duration,
    required this.isCompleted,
    required this.startedAt,
    this.completedAt,
    this.perQuestionDuration,
    this.subjectResults,
  });

  factory ExamAttemptModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    // Parse subject results
    Map<String, SubjectResult>? subjectResults;
    if (data['subjectResults'] != null) {
      subjectResults = (data['subjectResults'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(key, SubjectResult.fromMap(value as Map<String, dynamic>)),
      );
    }
    
    return ExamAttemptModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      examId: data['examId'] ?? '',
      answers: Map<int, int>.from(
        (data['answers'] as Map?)?.map((k, v) => MapEntry(int.parse(k.toString()), v as int)) ?? {},
      ),
      markedQuestions: Set<int>.from(
        (data['markedQuestions'] as List?)?.map((e) => e as int) ?? [],
      ),
      totalQuestions: data['totalQuestions'] ?? 0,
      correctAnswers: data['correctAnswers'] ?? 0,
      wrongAnswers: data['wrongAnswers'] ?? 0,
      emptyAnswers: data['emptyAnswers'] ?? 0,
      net: (data['net'] as num?)?.toDouble() ?? 0,
      score: data['score'] ?? 0,
      duration: Duration(seconds: data['durationSeconds'] ?? 0),
      isCompleted: data['isCompleted'] ?? false,
      startedAt: data['startedAt'] != null 
          ? (data['startedAt'] as Timestamp).toDate() 
          : DateTime.now(),
      completedAt: data['completedAt'] != null
          ? (data['completedAt'] as Timestamp).toDate()
          : null,
      perQuestionDuration: data['perQuestionDuration'] != null
          ? Map<int, int>.from(
              (data['perQuestionDuration'] as Map).map(
                (k, v) => MapEntry(int.parse(k.toString()), v as int),
              ),
            )
          : null,
      subjectResults: subjectResults,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'examId': examId,
      'answers': answers.map((k, v) => MapEntry(k.toString(), v)),
      'markedQuestions': markedQuestions.toList(),
      'totalQuestions': totalQuestions,
      'correctAnswers': correctAnswers,
      'wrongAnswers': wrongAnswers,
      'emptyAnswers': emptyAnswers,
      'net': net,
      'score': score,
      'durationSeconds': duration.inSeconds,
      'isCompleted': isCompleted,
      'startedAt': Timestamp.fromDate(startedAt),
      'completedAt':
          completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'perQuestionDuration': perQuestionDuration?.map((k, v) => MapEntry(k.toString(), v)),
      'subjectResults': subjectResults?.map((k, v) => MapEntry(k, v.toMap())),
    };
  }

  /// 70 Baraj geçti mi?
  bool get passedBaraj => HMGSNetCalculator.passedBaraj(score.toDouble());

  /// Baraj için eksik puan
  double get pointsToBaraj {
    if (passedBaraj) return 0.0;
    return (70 - score).toDouble();
  }

  /// Zaman yönetimi analizi
  Map<String, dynamic> getTimeManagementAnalysis() {
    if (perQuestionDuration == null || perQuestionDuration!.isEmpty) {
      return {};
    }

    final durations = perQuestionDuration!.values.toList();
    final total = durations.fold<int>(0, (sum, d) => sum + d);
    final avg = total / durations.length;
    final sorted = List<int>.from(durations)..sort();
    final median = sorted[sorted.length ~/ 2];
    final fastest = sorted.first;
    final slowest = sorted.last;

    // En yavaş 5 soru
    final slowestQuestions = perQuestionDuration!.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return {
      'totalSeconds': total,
      'averageSeconds': avg.round(),
      'medianSeconds': median,
      'fastestSeconds': fastest,
      'slowestSeconds': slowest,
      'slowestQuestions': slowestQuestions.take(5).map((e) => {
        'questionIndex': e.key,
        'seconds': e.value,
      }).toList(),
    };
  }
}

/// Ders bazlı sonuç modeli
class SubjectResult {
  final String subjectId;
  final String subjectName;
  final int totalQuestions;
  final int correctAnswers;
  final int wrongAnswers;
  final int emptyAnswers;
  final double net;

  SubjectResult({
    required this.subjectId,
    required this.subjectName,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.wrongAnswers,
    required this.emptyAnswers,
    required this.net,
  });

  factory SubjectResult.fromMap(Map<String, dynamic> map) {
    return SubjectResult(
      subjectId: map['subjectId'] ?? '',
      subjectName: map['subjectName'] ?? '',
      totalQuestions: map['totalQuestions'] ?? 0,
      correctAnswers: map['correctAnswers'] ?? 0,
      wrongAnswers: map['wrongAnswers'] ?? 0,
      emptyAnswers: map['emptyAnswers'] ?? 0,
      net: (map['net'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'subjectId': subjectId,
      'subjectName': subjectName,
      'totalQuestions': totalQuestions,
      'correctAnswers': correctAnswers,
      'wrongAnswers': wrongAnswers,
      'emptyAnswers': emptyAnswers,
      'net': net,
    };
  }

  /// Başarı yüzdesi
  double get successRate => totalQuestions > 0 ? (correctAnswers / totalQuestions) * 100 : 0;
}
