import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/question_model.dart';

/// QuizRepository Provider
final quizRepositoryProvider = Provider<QuizRepository>((ref) {
  return QuizRepository(
    firestore: FirebaseFirestore.instance,
    auth: FirebaseAuth.instance,
  );
});

/// Quiz ve soru verilerini yöneten repository
class QuizRepository {
  final FirebaseFirestore firestore;
  final FirebaseAuth auth;

  QuizRepository({required this.firestore, required this.auth});

  /// Tüm konulardan rastgele sorular çek
  Future<List<QuestionModel>> getRandomQuestions({
    required int limit,
    String? difficulty,
  }) async {
    print('📚 [QuizRepo] getRandomQuestions called - limit: $limit, difficulty: $difficulty');
    
    Query query = firestore.collection('questions');

    if (difficulty != null && difficulty != 'all') {
      query = query.where('difficulty', isEqualTo: difficulty);
      print('📚 [QuizRepo] Filtering by difficulty: $difficulty');
    }

    // Firestore'da random query zor olduğu için
    // limitin 3 katı kadar çekip client-side shuffle yapıyoruz
    query = query.limit(limit * 3);
    print('📚 [QuizRepo] Querying ${limit * 3} questions from Firestore...');

    try {
      final snapshot = await query.get();
      print('📚 [QuizRepo] Retrieved ${snapshot.docs.length} documents from Firestore');
      
      if (snapshot.docs.isEmpty) {
        print('❌ [QuizRepo] NO QUESTIONS FOUND in Firestore!');
        return [];
      }
      
      final questions = snapshot.docs
          .map((doc) {
            print('📚 [QuizRepo] Processing doc: ${doc.id}');
            return QuestionModel.fromFirestore(doc);
          })
          .toList();

      questions.shuffle();
      final result = questions.take(limit).toList();
      print('✅ [QuizRepo] Returning ${result.length} random questions');
      return result;
    } catch (e, stack) {
      print('❌ [QuizRepo] Error fetching random questions: $e');
      print('❌ [QuizRepo] Stack: $stack');
      rethrow;
    }
  }

  /// Belirli konulardan rastgele sorular çek
  /// NOT: Konu seçilmişse ve o konuda soru yoksa boş liste döner (fallback yok)
  Future<List<QuestionModel>> getQuestionsByTopics({
    required List<String> topicIds,
    required int limit,
    String? difficulty,
  }) async {
    print('📚 [QuizRepo] getQuestionsByTopics called');
    print('📚 [QuizRepo] topicIds: $topicIds');
    print('📚 [QuizRepo] limit: $limit, difficulty: $difficulty');
    
    // Firestore arrayContainsAny boş listeyi kabul etmez
    if (topicIds.isEmpty) {
      print('📚 [QuizRepo] topicIds empty - returning empty list');
      return [];
    }

    try {
      Query query = firestore
          .collection('questions')
          .where('topicIds', arrayContainsAny: topicIds)
          .limit(limit * 3);
      print('📚 [QuizRepo] Query: topicIds arrayContainsAny $topicIds');

      if (difficulty != null && difficulty != 'all') {
        query = query.where('difficulty', isEqualTo: difficulty);
        print('📚 [QuizRepo] Adding difficulty filter: $difficulty');
      }

      final snapshot = await query.get();
      print('📚 [QuizRepo] Retrieved ${snapshot.docs.length} documents');
      
      if (snapshot.docs.isEmpty) {
        print('❌ [QuizRepo] NO QUESTIONS FOUND for topics: $topicIds');
        // Fallback YOK - seçilen konuda soru yoksa boş döner
        return [];
      }
      
      final questions = snapshot.docs
          .map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            print('📚 [QuizRepo] Doc ${doc.id}: subjectId=${data['subjectId']}, topicIds=${data['topicIds']}');
            return QuestionModel.fromFirestore(doc);
          })
          .toList();

      questions.shuffle();
      final result = questions.take(limit).toList();
      print('✅ [QuizRepo] Returning ${result.length} questions by topics');
      return result;
    } catch (e, stack) {
      print('❌ [QuizRepo] Error fetching questions by topics: $e');
      print('❌ [QuizRepo] Stack: $stack');
      rethrow;
    }
  }

  /// Belirli bir dersten rastgele sorular çek
  Future<List<QuestionModel>> getQuestionsBySubject({
    required String subjectId,
    required int limit,
    String? difficulty,
  }) async {
    print('📚 [QuizRepo] getQuestionsBySubject called');
    print('📚 [QuizRepo] subjectId: $subjectId, limit: $limit, difficulty: $difficulty');
    
    try {
      Query query = firestore
          .collection('questions')
          .where('subjectId', isEqualTo: subjectId)
          .limit(limit * 2);

      if (difficulty != null && difficulty != 'all') {
        query = query.where('difficulty', isEqualTo: difficulty);
        print('📚 [QuizRepo] Adding difficulty filter: $difficulty');
      }

      final snapshot = await query.get();
      print('📚 [QuizRepo] Retrieved ${snapshot.docs.length} documents for subject: $subjectId');
      
      if (snapshot.docs.isEmpty) {
        print('❌ [QuizRepo] NO QUESTIONS FOUND for subject: $subjectId');
      }
      
      final questions = snapshot.docs
          .map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            print('📚 [QuizRepo] Doc ${doc.id}: subjectId=${data['subjectId']}');
            return QuestionModel.fromFirestore(doc);
          })
          .toList();

      questions.shuffle();
      final result = questions.take(limit).toList();
      print('✅ [QuizRepo] Returning ${result.length} questions for subject: $subjectId');
      return result;
    } catch (e, stack) {
      print('❌ [QuizRepo] Error fetching questions by subject: $e');
      print('❌ [QuizRepo] Stack: $stack');
      rethrow;
    }
  }

  /// Quiz sonucunu kaydet
  Future<void> saveQuizResult({
    required List<UserAnswer> answers,
    required int totalQuestions,
    required int correctAnswers,
    required Duration duration,
    required List<String> topicIds,
  }) async {
    final userId = auth.currentUser?.uid;
    if (userId == null) return;

    // Save to users/{userId}/quiz_results collection
    final result = {
      'userId': userId,
      'totalQuestions': totalQuestions,
      'correctAnswers': correctAnswers,
      'score': (correctAnswers / totalQuestions * 100).round(),
      'duration': duration.inSeconds,
      'topicIds': topicIds,
      'answers': answers.map((a) => a.toMap()).toList(),
      'completedAt': FieldValue.serverTimestamp(),
    };

    await firestore
        .collection('users')
        .doc(userId)
        .collection('quiz_results')
        .add(result);

    // Update daily stats
    await _updateDailyStats(
      userId: userId,
      correctAnswers: correctAnswers,
      totalQuestions: totalQuestions,
      answers: answers,
    );
  }

  /// Günlük istatistikleri güncelle
  Future<void> _updateDailyStats({
    required String userId,
    required int correctAnswers,
    required int totalQuestions,
    List<UserAnswer>? answers,
  }) async {
    final today = DateTime.now();
    final dateStr =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    final docRef = firestore
        .collection('daily_stats')
        .doc('${userId}_$dateStr');

    // Aggregate subject stats from answers
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
        // Create new daily stats
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
        // Update existing daily stats
        final data = snapshot.data()!;
        final updateData = <String, dynamic>{
          'questions_solved': (data['questions_solved'] ?? 0) + totalQuestions,
          'correct_count': (data['correct_count'] ?? 0) + correctAnswers,
          'updatedAt': FieldValue.serverTimestamp(),
        };

        // Merge subject stats
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

        // Merge topic stats
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

  /// Kullanıcının quiz geçmişini getir
  Stream<List<Map<String, dynamic>>> getUserQuizHistory({int limit = 10}) {
    final userId = auth.currentUser?.uid;
    if (userId == null) {
      return Stream.value([]);
    }

    return firestore
        .collection('users')
        .doc(userId)
        .collection('quiz_results')
        .orderBy('completedAt', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => {...doc.data(), 'id': doc.id})
              .toList(),
        );
  }

  /// Bugünün istatistiklerini getir
  Future<Map<String, dynamic>?> getTodayStats() async {
    final userId = auth.currentUser?.uid;
    if (userId == null) return null;

    final today = DateTime.now();
    final dateStr =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    final doc = await firestore
        .collection('daily_stats')
        .doc('${userId}_$dateStr')
        .get();

    return doc.exists ? doc.data() : null;
  }
}
