import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/exam_model.dart';
import '../../../shared/models/question_model.dart';

final examRepositoryProvider = Provider<ExamRepository>((ref) {
  return ExamRepository(
    firestore: FirebaseFirestore.instance,
    auth: FirebaseAuth.instance,
  );
});

class ExamRepository {
  final FirebaseFirestore firestore;
  final FirebaseAuth auth;

  ExamRepository({required this.firestore, required this.auth});

  String? get currentUserId => auth.currentUser?.uid;

  /// Aktif denemeleri getir (sıralı)
  Stream<List<ExamModel>> getExams() {
    return firestore
        .collection('exams')
        .where('isActive', isEqualTo: true)
        .orderBy('orderIndex')
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => ExamModel.fromFirestore(doc)).toList(),
        );
  }

  /// Belirli bir denemeyi getir
  Future<ExamModel?> getExamById(String examId) async {
    final doc = await firestore.collection('exams').doc(examId).get();
    if (!doc.exists) return null;
    return ExamModel.fromFirestore(doc);
  }

  /// Kullanıcının satın aldığı denemeleri getir
  Future<Set<String>> getUserPurchasedExams() async {
    final userId = currentUserId;
    if (userId == null) return {};

    final snapshot = await firestore
        .collection('user_exam_purchases')
        .where('userId', isEqualTo: userId)
        .where('isRefunded', isEqualTo: false)
        .get();

    return snapshot.docs.map((doc) => doc.data()['examId'] as String).toSet();
  }

  /// Kullanıcının denemeye erişimi var mı?
  Future<bool> hasAccessToExam(String examId) async {
    // Önce denemeyi kontrol et
    final exam = await getExamById(examId);
    if (exam == null) return false;

    // Ücretsiz ise erişim var
    if (exam.isFree) return true;

    // Satın alınmış mı kontrol et
    final userId = currentUserId;
    if (userId == null) return false;

    final purchase = await firestore
        .collection('user_exam_purchases')
        .where('userId', isEqualTo: userId)
        .where('examId', isEqualTo: examId)
        .where('isRefunded', isEqualTo: false)
        .limit(1)
        .get();

    return purchase.docs.isNotEmpty;
  }

  /// Deneme satın alımını kaydet
  Future<void> recordPurchase({
    required String examId,
    required String productId,
    required String transactionId,
    required double price,
    required String platform,
  }) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('User not logged in');

    await firestore.collection('user_exam_purchases').add({
      'userId': userId,
      'examId': examId,
      'productId': productId,
      'transactionId': transactionId,
      'price': price,
      'currency': 'TRY',
      'platform': platform,
      'purchaseDate': FieldValue.serverTimestamp(),
      'isRefunded': false,
    });
  }

  /// Deneme için sorular çek (120 soru)
  /// HMGS 2024 resmi dağılımına göre garantili soru seçimi
  /// [exam]: Deneme modeli - zorluk dağılımı bilgisini içerir
  Future<List<QuestionModel>> getExamQuestions(
    String examId, {
    String? difficulty,
    ExamModel? exam,
  }) async {
    print(
      '📝 [ExamRepo] getExamQuestions called - examId: $examId, difficulty: $difficulty',
    );

    // Exam bilgisi yoksa Firestore'dan çek
    ExamModel? examModel = exam;
    if (examModel == null) {
      examModel = await getExamById(examId);
    }

    // Zorluk dağılımını hesapla
    final int easyPercent = examModel?.easyPercent ?? 25;
    final int mediumPercent = examModel?.mediumPercent ?? 50;
    final int hardPercent = examModel?.hardPercent ?? 25;

    print(
      '📝 [ExamRepo] Zorluk dağılımı: $easyPercent% kolay, $mediumPercent% orta, $hardPercent% zor',
    );

    // HMGS dağılımı - Firestore'daki GERÇEK subject ID'leri
    // Toplam: 120 soru
    final distribution = {
      'medeni_hukuk': 15, // Medeni Hukuk
      'borclar_hukuku': 12, // Borçlar Hukuku
      'ticaret_hukuku': 12, // Ticaret Hukuku
      'ceza_hukuku': 12, // Ceza Hukuku (genel + özel birleşik)
      'ceza_muhakemesi': 9, // Ceza Muhakemesi Hukuku
      'anayasa_hukuku': 9, // Anayasa Hukuku
      'idare_hukuku': 9, // İdare Hukuku
      'idari_yargilama': 6, // İdari Yargılama Usulü (İYUK)
      'icra_iflas': 9, // İcra ve İflas Hukuku
      'is_hukuku': 9, // İş Hukuku ve Sosyal Güvenlik
      'milletlerarasi_hukuk': 3, // Milletlerarası Hukuk
      'avukatlik_hukuku': 6, // Avukatlık Hukuku
      'hukuk_felsefesi': 3, // Hukuk Felsefesi ve Sosyolojisi
      'vergi_hukuku': 3, // Vergi Hukuku
      'mohuk': 3, // Milletlerarası Özel Hukuk
    };

    final List<QuestionModel> examQuestions = [];
    final List<String> missingSubjects = [];

    // Her ders için belirtilen sayıda soru çek
    for (var entry in distribution.entries) {
      final subjectId = entry.key;
      final requiredCount = entry.value;

      // Bu ders için zorluk dağılımı
      final easyCount = (requiredCount * easyPercent / 100).round();
      final hardCount = (requiredCount * hardPercent / 100).round();
      final mediumCount = requiredCount - easyCount - hardCount;

      final List<QuestionModel> subjectQuestions = [];

      // Zorluk bazlı soru çek (eğer explicit difficulty verilmemişse)
      if (difficulty == null || difficulty == 'all') {
        // Kolay sorular
        if (easyCount > 0) {
          final easyQuery = await firestore
              .collection('questions')
              .where('subjectId', isEqualTo: subjectId)
              .where('difficulty', isEqualTo: 'easy')
              .get();
          final easyList =
              easyQuery.docs.map((d) => QuestionModel.fromFirestore(d)).toList()
                ..shuffle();
          subjectQuestions.addAll(easyList.take(easyCount));
        }

        // Orta sorular
        if (mediumCount > 0) {
          final mediumQuery = await firestore
              .collection('questions')
              .where('subjectId', isEqualTo: subjectId)
              .where('difficulty', isEqualTo: 'medium')
              .get();
          final mediumList =
              mediumQuery.docs
                  .map((d) => QuestionModel.fromFirestore(d))
                  .toList()
                ..shuffle();
          subjectQuestions.addAll(mediumList.take(mediumCount));
        }

        // Zor sorular
        if (hardCount > 0) {
          final hardQuery = await firestore
              .collection('questions')
              .where('subjectId', isEqualTo: subjectId)
              .where('difficulty', isEqualTo: 'hard')
              .get();
          final hardList =
              hardQuery.docs.map((d) => QuestionModel.fromFirestore(d)).toList()
                ..shuffle();
          subjectQuestions.addAll(hardList.take(hardCount));
        }

        // Eksik kalan varsa herhangi zorluktan tamamla
        if (subjectQuestions.length < requiredCount) {
          final remaining = requiredCount - subjectQuestions.length;
          final existingIds = subjectQuestions.map((q) => q.id).toSet();

          final fillQuery = await firestore
              .collection('questions')
              .where('subjectId', isEqualTo: subjectId)
              .get();
          final fillList =
              fillQuery.docs
                  .where((d) => !existingIds.contains(d.id))
                  .map((d) => QuestionModel.fromFirestore(d))
                  .toList()
                ..shuffle();
          subjectQuestions.addAll(fillList.take(remaining));
        }
      } else {
        // Tek bir zorluk seviyesi istenmiş
        final query = await firestore
            .collection('questions')
            .where('subjectId', isEqualTo: subjectId)
            .where('difficulty', isEqualTo: difficulty)
            .get();
        final list =
            query.docs.map((d) => QuestionModel.fromFirestore(d)).toList()
              ..shuffle();
        subjectQuestions.addAll(list.take(requiredCount));
      }

      // Yeterli soru var mı kontrol et
      if (subjectQuestions.length < requiredCount) {
        missingSubjects.add(
          '$subjectId: ${subjectQuestions.length}/$requiredCount soru',
        );
        print(
          '⚠️  Yetersiz soru: $subjectId (${subjectQuestions.length}/$requiredCount)',
        );
      }

      examQuestions.addAll(subjectQuestions);
    }

    // Eksik ders varsa uyarı (ancak devam et)
    if (missingSubjects.isNotEmpty) {
      print('⚠️  Eksik dersler: ${missingSubjects.join(", ")}');
      print(
        '⚠️  Deneme ${examQuestions.length} soru ile oluşturuldu (hedef: 120)',
      );
    }

    // Tüm soruları karıştır (ama dağılım korunmuş olur)
    examQuestions.shuffle();

    return examQuestions;
  }

  /// Deneme denemesini kaydet
  Future<String> saveExamAttempt(ExamAttemptModel attempt) async {
    final doc = await firestore
        .collection('exam_attempts')
        .add(attempt.toFirestore());
    return doc.id;
  }

  /// Deneme denemesini güncelle
  Future<void> updateExamAttempt(
    String attemptId,
    Map<String, dynamic> updates,
  ) async {
    await firestore.collection('exam_attempts').doc(attemptId).update(updates);
  }

  /// Kullanıcının deneme geçmişini getir
  Stream<List<ExamAttemptModel>> getUserExamAttempts({int limit = 10}) {
    final userId = auth.currentUser?.uid;
    if (userId == null) return Stream.value([]);

    return firestore
        .collection('exam_attempts')
        .where('userId', isEqualTo: userId)
        .orderBy('startedAt', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ExamAttemptModel.fromFirestore(doc))
              .toList(),
        );
  }

  /// Kullanıcının kalan deneme hakkını kontrol et
  Future<int> getUserExamCredits() async {
    final userId = auth.currentUser?.uid;
    if (userId == null) return 0;

    final doc = await firestore.collection('users').doc(userId).get();
    if (!doc.exists) return 0;

    final data = doc.data();
    final planType = data?['plan_type'] ?? 'free';

    if (planType == 'pro') {
      return 999; // Pro kullanıcılar için sınırsız
    }

    // Free kullanıcılar için aylık 1 deneme
    final examCredits = data?['exam_credits'] ?? 1;
    return examCredits;
  }

  /// Deneme hakkını stream olarak izle
  Stream<int> watchUserExamCredits() {
    final userId = auth.currentUser?.uid;
    if (userId == null) return Stream.value(0);

    return firestore.collection('users').doc(userId).snapshots().map((doc) {
      final data = doc.data();
      if (data == null) return 0;
      final planType = data['plan_type'] ?? 'free';
      if (planType == 'pro') return 999;
      return (data['exam_credits'] as num?)?.toInt() ?? 0;
    });
  }

  /// Deneme hakkını azalt
  Future<void> decrementExamCredit() async {
    final userId = auth.currentUser?.uid;
    if (userId == null) return;

    await firestore.collection('users').doc(userId).update({
      'exam_credits': FieldValue.increment(-1),
    });
  }

  /// Hızlı Test için 20 rastgele soru getir
  Future<List<QuestionModel>> getFastTestQuestions() async {
    print('⚡ [ExamRepo] getFastTestQuestions called');

    try {
      // Performans için: Sadece 50 soru çekip içinden 20 tane seçelim
      final snapshot = await firestore.collection('questions').limit(50).get();
      print(
        '⚡ [ExamRepo] Retrieved ${snapshot.docs.length} documents from questions collection',
      );

      if (snapshot.docs.isEmpty) {
        print('❌ [ExamRepo] NO QUESTIONS FOUND in Firestore!');
        // Debug: List all collections
        print('⚡ [ExamRepo] Checking if questions collection exists...');
        return [];
      }

      final allQuestions = snapshot.docs.map((doc) {
        final data = doc.data();
        print(
          '⚡ [ExamRepo] Doc ${doc.id}: subjectId=${data['subjectId']}, stem=${(data['stem'] as String?)?.substring(0, 50) ?? 'N/A'}...',
        );
        return QuestionModel.fromFirestore(doc);
      }).toList()..shuffle();

      final result = allQuestions.take(20).toList();
      print('✅ [ExamRepo] Returning ${result.length} fast test questions');
      return result;
    } catch (e, stack) {
      print('❌ [ExamRepo] Error in getFastTestQuestions: $e');
      print('❌ [ExamRepo] Stack: $stack');
      rethrow;
    }
  }

  /// Maraton modu için soru havuzu getir (örn: 50'şerli paketler)
  Future<List<QuestionModel>> getMarathonQuestions({
    QuestionModel? lastQuestion,
  }) async {
    Query query = firestore
        .collection('questions')
        .orderBy('createdAt')
        .limit(50);

    if (lastQuestion != null) {
      query = query.startAfter([Timestamp.fromDate(lastQuestion.createdAt)]);
    }

    final snapshot = await query.get();
    return snapshot.docs
        .map((doc) => QuestionModel.fromFirestore(doc))
        .toList();
  }

  /// Deneme hakkı ekle (Satın alma sonrası)
  Future<void> addExamCredits(int amount) async {
    final userId = auth.currentUser?.uid;
    if (userId == null) return;

    await firestore.collection('users').doc(userId).update({
      'exam_credits': FieldValue.increment(amount),
    });
  }

  /// Konu bazlı soruları getir (Pekiştirme Testi için) - Updated
  Future<List<QuestionModel>> getQuestionsByTopic(
    String topicId, {
    int limit = 10,
    String? difficulty,
  }) async {
    Query query = firestore
        .collection('questions')
        .where('topicIds', arrayContains: topicId);

    if (difficulty != null && difficulty != 'all') {
      query = query.where('difficulty', isEqualTo: difficulty);
    }

    query = query.limit(limit * 2); // Daha fazla çek, sonra shuffle

    final snapshot = await query.get();

    final questions = snapshot.docs
        .map((doc) => QuestionModel.fromFirestore(doc))
        .toList();

    questions.shuffle();
    return questions.take(limit).toList();
  }

  /// Ders bazlı soruları getir (Ders Quiz ve Mini Sınav için)
  Future<List<QuestionModel>> getQuestionsBySubject(
    String subjectId, {
    int limit = 20,
    String? difficulty,
  }) async {
    Query query = firestore
        .collection('questions')
        .where('subjectId', isEqualTo: subjectId);

    if (difficulty != null && difficulty != 'all') {
      query = query.where('difficulty', isEqualTo: difficulty);
    }

    query = query.limit(limit * 2);

    final snapshot = await query.get();

    final questions = snapshot.docs
        .map((doc) => QuestionModel.fromFirestore(doc))
        .toList();

    questions.shuffle();
    return questions.take(limit).toList();
  }

  /// Rastgele sorular getir (Hızlı Quiz için)
  Future<List<QuestionModel>> getRandomQuestions({
    int limit = 10,
    String? difficulty,
    List<String>? excludeSubjects,
  }) async {
    Query query = firestore.collection('questions');

    if (difficulty != null && difficulty != 'all') {
      query = query.where('difficulty', isEqualTo: difficulty);
    }

    // Daha fazla çek ve client-side shuffle yap
    query = query.limit(limit * 5);

    final snapshot = await query.get();

    var questions = snapshot.docs
        .map((doc) => QuestionModel.fromFirestore(doc))
        .toList();

    // Exclude subjects varsa filtrele
    if (excludeSubjects != null && excludeSubjects.isNotEmpty) {
      questions = questions
          .where((q) => !excludeSubjects.contains(q.subjectId))
          .toList();
    }

    questions.shuffle();
    return questions.take(limit).toList();
  }

  /// Mini sınav için ders bazlı dengeli soru getir
  /// Zorluk dağılımı: %30 kolay, %50 orta, %20 zor
  Future<List<QuestionModel>> getMiniExamQuestions(
    String subjectId, {
    int totalQuestions = 20,
  }) async {
    final List<QuestionModel> result = [];

    // Zorluk dağılımı hesapla
    final easyCount = (totalQuestions * 0.3).round();
    final mediumCount = (totalQuestions * 0.5).round();
    final hardCount = totalQuestions - easyCount - mediumCount;

    // Her zorluk seviyesinden soru çek
    final easyQuestions = await getQuestionsBySubject(
      subjectId,
      limit: easyCount + 5,
      difficulty: 'easy',
    );
    final mediumQuestions = await getQuestionsBySubject(
      subjectId,
      limit: mediumCount + 5,
      difficulty: 'medium',
    );
    final hardQuestions = await getQuestionsBySubject(
      subjectId,
      limit: hardCount + 5,
      difficulty: 'hard',
    );

    result.addAll(easyQuestions.take(easyCount));
    result.addAll(mediumQuestions.take(mediumCount));
    result.addAll(hardQuestions.take(hardCount));

    // Eğer yeterli soru yoksa, tamamla
    if (result.length < totalQuestions) {
      final allQuestions = await getQuestionsBySubject(
        subjectId,
        limit: totalQuestions * 2,
      );

      final existingIds = result.map((q) => q.id).toSet();
      final remaining = allQuestions
          .where((q) => !existingIds.contains(q.id))
          .take(totalQuestions - result.length);

      result.addAll(remaining);
    }

    result.shuffle();
    return result.take(totalQuestions).toList();
  }

  /// Quiz sonucunu kaydet
  Future<void> saveQuizResult({
    required String quizType, // 'quick', 'topic', 'subject', 'mini_exam'
    required int totalQuestions,
    required int correctAnswers,
    required int duration, // saniye
    String? subjectId,
    String? topicId,
    Map<String, dynamic>? details,
    List<UserAnswer>? answers,
  }) async {
    final userId = auth.currentUser?.uid;
    if (userId == null) return;

    await firestore.collection('quiz_results').add({
      'userId': userId,
      'quizType': quizType,
      'totalQuestions': totalQuestions,
      'correctAnswers': correctAnswers,
      'score': (correctAnswers / totalQuestions * 100).round(),
      'duration': duration,
      'subjectId': subjectId,
      'topicId': topicId,
      'details': details,
      if (answers != null)
        'answers': answers.map((a) => a.toMap()).toList(),
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Kullanıcı istatistiklerini güncelle
    await firestore.collection('users').doc(userId).update({
      'totalQuizzes': FieldValue.increment(1),
      'totalQuestions': FieldValue.increment(totalQuestions),
      'totalCorrect': FieldValue.increment(correctAnswers),
      'lastQuizAt': FieldValue.serverTimestamp(),
    });

    // Günlük istatistikleri güncelle (subject/topic detayları dahil)
    await _updateDailyStats(
      userId: userId,
      correctAnswers: correctAnswers,
      totalQuestions: totalQuestions,
      answers: answers,
    );
  }

  Future<void> _updateDailyStats({
    required String userId,
    required int correctAnswers,
    required int totalQuestions,
    List<UserAnswer>? answers,
  }) async {
    final today = DateTime.now();
    final dateStr =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    final docRef = firestore.collection('daily_stats').doc('${userId}_$dateStr');

    // Aggregate subject and topic stats
    final Map<String, Map<String, int>> subjectStats = {};
    final Map<String, Map<String, int>> topicStats = {};

    if (answers != null) {
      for (var answer in answers) {
        if (answer.subjectId != null) {
          subjectStats.putIfAbsent(
            answer.subjectId!,
            () => {'correct': 0, 'total': 0},
          );
          subjectStats[answer.subjectId!]!['total'] =
              (subjectStats[answer.subjectId!]!['total']! + 1);
          if (answer.isCorrect) {
            subjectStats[answer.subjectId!]!['correct'] =
                (subjectStats[answer.subjectId!]!['correct']! + 1);
          }
        }

        if (answer.topicId != null) {
          topicStats.putIfAbsent(
            answer.topicId!,
            () => {'correct': 0, 'total': 0},
          );
          topicStats[answer.topicId!]!['total'] =
              (topicStats[answer.topicId!]!['total']! + 1);
          if (answer.isCorrect) {
            topicStats[answer.topicId!]!['correct'] =
                (topicStats[answer.topicId!]!['correct']! + 1);
          }
        }
      }
    }

    await firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);

      if (!snapshot.exists) {
        transaction.set(docRef, {
          'userId': userId,
          'date': dateStr,
          'questions_solved': totalQuestions,
          'correct_count': correctAnswers,
          if (subjectStats.isNotEmpty) 'subject_stats': subjectStats,
          if (topicStats.isNotEmpty) 'topic_stats': topicStats,
          'createdAt': FieldValue.serverTimestamp(),
        });
      } else {
        final data = snapshot.data()!;
        final updateData = <String, dynamic>{
          'questions_solved': (data['questions_solved'] ?? 0) + totalQuestions,
          'correct_count': (data['correct_count'] ?? 0) + correctAnswers,
          'updatedAt': FieldValue.serverTimestamp(),
        };

        if (subjectStats.isNotEmpty) {
          final existingSubjectStats =
              data['subject_stats'] as Map<String, dynamic>? ?? {};

          for (var entry in subjectStats.entries) {
            final subjectId = entry.key;
            final stats = entry.value;

            if (existingSubjectStats.containsKey(subjectId)) {
              final existing =
                  existingSubjectStats[subjectId] as Map<String, dynamic>;
              updateData['subject_stats.$subjectId'] = {
                'correct': (existing['correct'] ?? 0) + stats['correct']!,
                'total': (existing['total'] ?? 0) + stats['total']!,
              };
            } else {
              updateData['subject_stats.$subjectId'] = stats;
            }
          }
        }

        if (topicStats.isNotEmpty) {
          final existingTopicStats =
              data['topic_stats'] as Map<String, dynamic>? ?? {};

          for (var entry in topicStats.entries) {
            final topicId = entry.key;
            final stats = entry.value;

            if (existingTopicStats.containsKey(topicId)) {
              final existing =
                  existingTopicStats[topicId] as Map<String, dynamic>;
              updateData['topic_stats.$topicId'] = {
                'correct': (existing['correct'] ?? 0) + stats['correct']!,
                'total': (existing['total'] ?? 0) + stats['total']!,
              };
            } else {
              updateData['topic_stats.$topicId'] = stats;
            }
          }
        }

        transaction.update(docRef, updateData);
      }
    });
  }
}

/// Deneme hakkını stream olarak izle
final examCreditsStreamProvider = StreamProvider<int>((ref) {
  final repository = ref.watch(examRepositoryProvider);
  return repository.watchUserExamCredits();
});
