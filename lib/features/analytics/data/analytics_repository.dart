import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Models
class UserAnalytics {
  final int totalQuestions;
  final int totalCorrect;
  final Map<String, SubjectStats> subjectStats;
  final List<int> recentExamScores;

  UserAnalytics({
    required this.totalQuestions,
    required this.totalCorrect,
    required this.subjectStats,
    required this.recentExamScores,
  });

  double get successRate =>
      totalQuestions > 0 ? (totalCorrect / totalQuestions * 100) : 0.0;

  factory UserAnalytics.empty() {
    return UserAnalytics(
      totalQuestions: 0,
      totalCorrect: 0,
      subjectStats: {},
      recentExamScores: [],
    );
  }
}

class SubjectStats {
  final String subjectId;
  final int correct;
  final int total;

  SubjectStats({
    required this.subjectId,
    required this.correct,
    required this.total,
  });

  double get successRate => total > 0 ? (correct / total * 100) : 0.0;
}

class DailyStats {
  final DateTime date;
  final int questionsSolved;
  final int correctCount;

  DailyStats({
    required this.date,
    required this.questionsSolved,
    required this.correctCount,
  });
}

class WeakTopicData {
  final String topicId;
  final String topicName;
  final int correct;
  final int total;
  final double successRate;

  WeakTopicData({
    required this.topicId,
    required this.topicName,
    required this.correct,
    required this.total,
    required this.successRate,
  });
}

class TopicPerformance {
  final String topicId;
  final int correct;
  final int total;

  TopicPerformance({
    required this.topicId,
    required this.correct,
    required this.total,
  });
}

class PersonalizedAnalysis {
  final List<WeakTopicData> weakTopics;
  final List<String> recommendations;

  PersonalizedAnalysis({
    required this.weakTopics,
    required this.recommendations,
  });
}

class AdvancedStats {
  final double averageTimePerQuestion; // in seconds
  final double accuracyTrend; // positive or negative change
  final int totalExams;
  final int passedExams;

  AdvancedStats({
    required this.averageTimePerQuestion,
    required this.accuracyTrend,
    required this.totalExams,
    required this.passedExams,
  });
}

class CommunityStats {
  final double averageSuccessRate;
  final int totalQuestionsSolved;
  final int activeUserCount;

  CommunityStats({
    required this.averageSuccessRate,
    required this.totalQuestionsSolved,
    required this.activeUserCount,
  });
}

class SubjectDetailedStats {
  final String subjectId;
  final String subjectName;
  final int totalQuestions;
  final int correctAnswers;
  final double averageTime;
  final DateTime lastAttemptDate;

  SubjectDetailedStats({
    required this.subjectId,
    required this.subjectName,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.averageTime,
    required this.lastAttemptDate,
  });

  double get successRate =>
      totalQuestions > 0 ? (correctAnswers / totalQuestions * 100) : 0.0;
}

final analyticsRepositoryProvider = Provider<AnalyticsRepository>((ref) {
  return AnalyticsRepository(
    firestore: FirebaseFirestore.instance,
    auth: FirebaseAuth.instance,
  );
});

final communityStatsProvider = FutureProvider<CommunityStats>((ref) async {
  final repository = ref.watch(analyticsRepositoryProvider);
  return await repository.getCommunityStats();
});

class AnalyticsRepository {
  final FirebaseFirestore firestore;
  final FirebaseAuth auth;

  AnalyticsRepository({required this.firestore, required this.auth});

  String? get currentUserId => auth.currentUser?.uid;

  /// Get user's overall analytics
  Future<UserAnalytics> getUserAnalytics() async {
    debugPrint('AnalyticsRepository: getUserAnalytics started');
    if (currentUserId == null) {
      return UserAnalytics.empty();
    }

    try {
      // Get all daily stats
      // Note: Removed orderBy to avoid missing index crash. Sorting in memory.
      final dailyStatsSnapshot = await firestore
          .collection('daily_stats')
          .where('userId', isEqualTo: currentUserId)
          .get();

      final docs = dailyStatsSnapshot.docs;
      // Sort in memory
      docs.sort((a, b) {
        final dateA =
            (a.data()['date'] as Timestamp?)?.toDate() ?? DateTime(1970);
        final dateB =
            (b.data()['date'] as Timestamp?)?.toDate() ?? DateTime(1970);
        return dateB.compareTo(dateA);
      });

      final recentDocs = docs.take(30);

      int totalQuestions = 0;
      int totalCorrect = 0;
      final Map<String, SubjectStats> subjectStatsMap = {};

      for (var doc in recentDocs) {
        final data = doc.data();
        totalQuestions += (data['questions_solved'] as int?) ?? 0;
        totalCorrect += (data['correct_count'] as int?) ?? 0;

        // Subject-wise stats (if available)
        final subjectStats = data['subject_stats'] as Map<String, dynamic>?;
        if (subjectStats != null) {
          subjectStats.forEach((subjectId, stats) {
            final statsMap = stats as Map<String, dynamic>;
            final correct = (statsMap['correct'] as int?) ?? 0;
            final total = (statsMap['total'] as int?) ?? 0;

            if (!subjectStatsMap.containsKey(subjectId)) {
              subjectStatsMap[subjectId] = SubjectStats(
                subjectId: subjectId,
                correct: 0,
                total: 0,
              );
            }

            subjectStatsMap[subjectId] = SubjectStats(
              subjectId: subjectId,
              correct: subjectStatsMap[subjectId]!.correct + correct,
              total: subjectStatsMap[subjectId]!.total + total,
            );
          });
        }
      }

      // Get recent exam scores
      final examAttemptsSnapshot = await firestore
          .collection('exam_attempts')
          .where('userId', isEqualTo: currentUserId)
          .where('isCompleted', isEqualTo: true)
          .orderBy('startedAt', descending: true)
          .limit(5)
          .get();

      final recentExamScores = examAttemptsSnapshot.docs
          .map((doc) => (doc.data()['score'] as int?) ?? 0)
          .toList();

      debugPrint('AnalyticsRepository: getUserAnalytics completed');
      return UserAnalytics(
        totalQuestions: totalQuestions,
        totalCorrect: totalCorrect,
        subjectStats: subjectStatsMap,
        recentExamScores: recentExamScores,
      );
    } catch (e, stack) {
      debugPrint('AnalyticsRepository: getUserAnalytics ERROR: $e');
      debugPrint(stack.toString());
      return UserAnalytics.empty();
    }
  }

  /// Get last 7 days stats for chart
  Future<List<DailyStats>> getWeeklyStats() async {
    if (currentUserId == null) {
      return [];
    }

    final now = DateTime.now();
    final List<DailyStats> weeklyStats = [];

    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dateKey =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

      final doc = await firestore
          .collection('daily_stats')
          .doc('${currentUserId}_$dateKey')
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        weeklyStats.add(
          DailyStats(
            date: date,
            questionsSolved: (data['questions_solved'] as int?) ?? 0,
            correctCount: (data['correct_count'] as int?) ?? 0,
          ),
        );
      } else {
        weeklyStats.add(
          DailyStats(date: date, questionsSolved: 0, correctCount: 0),
        );
      }
    }

    return weeklyStats;
  }

  /// Get last 30 days stats for monthly chart
  Future<List<DailyStats>> getMonthlyStats() async {
    if (currentUserId == null) {
      return [];
    }

    final now = DateTime.now();
    final List<DailyStats> monthlyStats = [];

    for (int i = 29; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dateKey =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

      final doc = await firestore
          .collection('daily_stats')
          .doc('${currentUserId}_$dateKey')
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        monthlyStats.add(
          DailyStats(
            date: date,
            questionsSolved: (data['questions_solved'] as int?) ?? 0,
            correctCount: (data['correct_count'] as int?) ?? 0,
          ),
        );
      } else {
        monthlyStats.add(
          DailyStats(date: date, questionsSolved: 0, correctCount: 0),
        );
      }
    }

    return monthlyStats;
  }

  /// Get subject-wise detailed statistics
  Future<List<SubjectDetailedStats>> getSubjectDetailedStats() async {
    if (currentUserId == null) return [];

    try {
      // Get all quiz results
      final quizResultsSnapshot = await firestore
          .collection('users')
          .doc(currentUserId)
          .collection('quiz_results')
          .orderBy('completedAt', descending: true)
          .limit(100)
          .get();

      final Map<String, SubjectDetailedStats> subjectStatsMap = {};

      for (var doc in quizResultsSnapshot.docs) {
        final data = doc.data();
        final subjectIds = List<String>.from(data['subjectIds'] ?? []);
        final answers = data['answers'] as List<dynamic>?;

        if (answers == null) continue;

        for (var subjectId in subjectIds) {
          if (!subjectStatsMap.containsKey(subjectId)) {
            subjectStatsMap[subjectId] = SubjectDetailedStats(
              subjectId: subjectId,
              subjectName: subjectId, // Will update below
              totalQuestions: 0,
              correctAnswers: 0,
              averageTime: 0,
              lastAttemptDate: DateTime.now(),
            );
          }
        }

        for (var answer in answers) {
          final answerMap = answer as Map<String, dynamic>;
          final isCorrect = answerMap['isCorrect'] as bool? ?? false;
          final timeSpent = answerMap['timeSpent'] as int? ?? 0;

          for (var subjectId in subjectIds) {
            final existing = subjectStatsMap[subjectId]!;
            subjectStatsMap[subjectId] = SubjectDetailedStats(
              subjectId: subjectId,
              subjectName: existing.subjectName,
              totalQuestions: existing.totalQuestions + 1,
              correctAnswers: existing.correctAnswers + (isCorrect ? 1 : 0),
              averageTime: ((existing.averageTime * existing.totalQuestions) +
                      timeSpent) /
                  (existing.totalQuestions + 1),
              lastAttemptDate: existing.lastAttemptDate,
            );
          }
        }
      }

      // Fetch subject names
      final subjectIds = subjectStatsMap.keys.toSet();
      final Map<String, String> subjectNames = {};

      await Future.wait(
        subjectIds.map((subjectId) async {
          try {
            final subjectDoc =
                await firestore.collection('subjects').doc(subjectId).get();
            if (subjectDoc.exists) {
              subjectNames[subjectId] =
                  subjectDoc.data()?['name'] as String? ?? subjectId;
            } else {
              subjectNames[subjectId] = subjectId;
            }
          } catch (e) {
            subjectNames[subjectId] = subjectId;
          }
        }),
      );

      // Update names and create result
      final result = subjectStatsMap.entries.map((entry) {
        final stats = entry.value;
        return SubjectDetailedStats(
          subjectId: stats.subjectId,
          subjectName: subjectNames[stats.subjectId] ?? stats.subjectId,
          totalQuestions: stats.totalQuestions,
          correctAnswers: stats.correctAnswers,
          averageTime: stats.averageTime,
          lastAttemptDate: stats.lastAttemptDate,
        );
      }).toList();

      // Sort by total questions descending
      result.sort((a, b) => b.totalQuestions.compareTo(a.totalQuestions));

      return result;
    } catch (e) {
      debugPrint('getSubjectDetailedStats ERROR: $e');
      return [];
    }
  }

  /// Get weak topics (< 50% success rate)
  Future<List<WeakTopicData>> getWeakTopics() async {
    debugPrint('AnalyticsRepository: getWeakTopics started');
    if (currentUserId == null) {
      return [];
    }

    try {
      // Get all quiz results
      final quizResultsSnapshot = await firestore
          .collection('users')
          .doc(currentUserId)
          .collection('quiz_results')
          .orderBy('completedAt', descending: true)
          .limit(50)
          .get();

      debugPrint(
        'AnalyticsRepository: getWeakTopics - Fetched ${quizResultsSnapshot.docs.length} quiz results',
      );

      final Map<String, TopicPerformance> topicPerformanceMap = {};

      for (var doc in quizResultsSnapshot.docs) {
        final data = doc.data();
        final fallbackTopicIds = List<String>.from(data['topicIds'] ?? []);
        final answers = data['answers'] as List<dynamic>?;

        if (answers != null) {
          for (var answer in answers) {
            final answerMap = answer as Map<String, dynamic>;
            final isCorrect = answerMap['isCorrect'] as bool? ?? false;
            final answerTopic = answerMap['topicId'] as String?;
            final topicsToCount = <String>{};
            if (answerTopic != null && answerTopic.isNotEmpty) {
              topicsToCount.add(answerTopic);
            } else {
              topicsToCount.addAll(fallbackTopicIds);
            }

            for (var topicId in topicsToCount) {
              if (!topicPerformanceMap.containsKey(topicId)) {
                topicPerformanceMap[topicId] = TopicPerformance(
                  topicId: topicId,
                  correct: 0,
                  total: 0,
                );
              }

              topicPerformanceMap[topicId] = TopicPerformance(
                topicId: topicId,
                correct:
                    topicPerformanceMap[topicId]!.correct + (isCorrect ? 1 : 0),
                total: topicPerformanceMap[topicId]!.total + 1,
              );
            }
          }
        }
      }

      // Filter weak topics (< 50% success rate) and sort
      final weakTopicsList = topicPerformanceMap.entries.where((entry) {
        final successRate = entry.value.total > 0
            ? (entry.value.correct / entry.value.total * 100)
            : 0.0;
        return successRate < 50 &&
            entry.value.total >= 5; // At least 5 questions
      }).toList();

      debugPrint(
        'AnalyticsRepository: getWeakTopics - Found ${weakTopicsList.length} weak topics (raw)',
      );

      // Fetch topic names in parallel to avoid N+1 reads
      final topicIdsToFetch = weakTopicsList.map((e) => e.key).toSet();
      final Map<String, String> topicNames = {};

      await Future.wait(
        topicIdsToFetch.map((topicId) async {
          try {
            final topicDoc = await firestore
                .collection('topics')
                .doc(topicId)
                .get();
            if (topicDoc.exists) {
              topicNames[topicId] =
                  topicDoc.data()?['name'] as String? ?? topicId;
            } else {
              topicNames[topicId] = topicId;
            }
          } catch (e) {
            topicNames[topicId] = topicId;
          }
        }),
      );

      final List<WeakTopicData> result = [];
      for (var entry in weakTopicsList) {
        final topicId = entry.key;
        final topicName = topicNames[topicId] ?? topicId;

        final successRate = entry.value.total > 0
            ? (entry.value.correct / entry.value.total * 100)
            : 0.0;

        result.add(
          WeakTopicData(
            topicId: topicId,
            topicName: topicName,
            correct: entry.value.correct,
            total: entry.value.total,
            successRate: successRate,
          ),
        );
      }

      result.sort((a, b) => a.successRate.compareTo(b.successRate));

      debugPrint(
        'AnalyticsRepository: getWeakTopics completed with ${result.length} items',
      );
      return result.take(5).toList();
    } catch (e, stack) {
      debugPrint('AnalyticsRepository: getWeakTopics ERROR: $e');
      debugPrint(stack.toString());
      return [];
    }
  }

  /// Get community stats (Global averages)
  Future<CommunityStats> getCommunityStats() async {
    debugPrint('AnalyticsRepository: getCommunityStats started');
    try {
      final doc = await firestore.collection('stats').doc('global').get();
      if (doc.exists) {
        final data = doc.data()!;
        return CommunityStats(
          averageSuccessRate:
              (data['average_success_rate'] as num?)?.toDouble() ?? 0.0,
          totalQuestionsSolved: (data['total_questions_solved'] as int?) ?? 0,
          activeUserCount: (data['active_user_count'] as int?) ?? 0,
        );
      }
    } catch (e, stack) {
      debugPrint('AnalyticsRepository: getCommunityStats ERROR: $e');
      debugPrint(stack.toString());
    }

    // Default values if no global stats exist yet
    return CommunityStats(
      averageSuccessRate: 45.0, // Reasonable default
      totalQuestionsSolved: 0,
      activeUserCount: 0,
    );
  }

  /// Helper to update global stats (Simulating backend aggregation)
  Future<void> updateGlobalStats() async {
    try {
      final snapshot = await firestore
          .collection('daily_stats')
          .orderBy('date', descending: true)
          .limit(100)
          .get();

      if (snapshot.docs.isEmpty) return;

      int totalCorrect = 0;
      int totalQuestions = 0;
      final userIds = <String>{};

      for (var doc in snapshot.docs) {
        final data = doc.data();
        totalCorrect += (data['correct_count'] as int?) ?? 0;
        totalQuestions += (data['questions_solved'] as int?) ?? 0;
        if (data['userId'] != null) userIds.add(data['userId'] as String);
      }

      final avgSuccess = totalQuestions > 0
          ? (totalCorrect / totalQuestions * 100)
          : 0.0;

      await firestore.collection('stats').doc('global').set({
        'average_success_rate': avgSuccess,
        'total_questions_solved': totalQuestions,
        'active_user_count': userIds.length,
        'last_updated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('AnalyticsRepository: updateGlobalStats ERROR: $e');
    }
  }

  /// Get personalized analysis with recommendations
  Future<PersonalizedAnalysis> getPersonalizedAnalysis() async {
    debugPrint('AnalyticsRepository: getPersonalizedAnalysis started');
    try {
      final weakTopics = await getWeakTopics();
      debugPrint(
        'AnalyticsRepository: getPersonalizedAnalysis fetched ${weakTopics.length} weak topics',
      );

      final recommendations = <String>[];

      if (weakTopics.isEmpty) {
        recommendations.add(
          "Henüz yeterli veri yok. Biraz soru çözmeye başla!",
        );
      } else {
        recommendations.add(
          "Öncelikle '${weakTopics.first.topicName}' konusuna odaklanmalısın.",
        );
        recommendations.add(
          "Bu konuda başarı oranın %${weakTopics.first.successRate.toStringAsFixed(1)}. Konu tekrarı yapmanı öneririm.",
        );
        if (weakTopics.length > 1) {
          recommendations.add(
            "Ayrıca '${weakTopics[1].topicName}' konusunda da eksiklerin var.",
          );
        }
      }

      debugPrint('AnalyticsRepository: getPersonalizedAnalysis completed');
      return PersonalizedAnalysis(
        weakTopics: weakTopics,
        recommendations: recommendations,
      );
    } catch (e, stack) {
      debugPrint('AnalyticsRepository: getPersonalizedAnalysis ERROR: $e');
      debugPrint(stack.toString());
      rethrow;
    }
  }

  /// Get advanced statistics
  Future<AdvancedStats> getAdvancedStats() async {
    debugPrint('AnalyticsRepository: getAdvancedStats started');
    if (currentUserId == null) {
      debugPrint('AnalyticsRepository: getAdvancedStats - No user ID');
      return AdvancedStats(
        averageTimePerQuestion: 0,
        accuracyTrend: 0,
        totalExams: 0,
        passedExams: 0,
      );
    }

    try {
      // Get completed exams
      final examsSnapshot = await firestore
          .collection('exam_attempts')
          .where('userId', isEqualTo: currentUserId)
          .where('isCompleted', isEqualTo: true)
          .orderBy('startedAt', descending: true)
          .limit(20)
          .get();

      debugPrint(
        'AnalyticsRepository: getAdvancedStats - Fetched ${examsSnapshot.docs.length} exams',
      );

      if (examsSnapshot.docs.isEmpty) {
        return AdvancedStats(
          averageTimePerQuestion: 0,
          accuracyTrend: 0,
          totalExams: 0,
          passedExams: 0,
        );
      }

      int totalExams = examsSnapshot.docs.length;
      int passedExams = 0;
      double totalTime = 0;
      int totalQuestions = 0;
      List<double> scores = [];

      for (var doc in examsSnapshot.docs) {
        final data = doc.data();
        final score = (data['score'] as int?) ?? 0;
        scores.add(score.toDouble());

        if (score >= 70) passedExams++;

        final duration = (data['duration'] as int?) ?? 0; // in seconds
        totalTime += duration;

        final answers = data['answers'] as Map<String, dynamic>?;
        totalQuestions += answers?.length ?? 120;
      }

      double averageTime = totalQuestions > 0
          ? totalTime / totalQuestions
          : 0.0;

      // Calculate trend (last 5 vs previous 5)
      double accuracyTrend = 0.0;
      if (scores.length >= 2) {
        final recentAvg =
            scores.take(5).reduce((a, b) => a + b) /
            (scores.length < 5 ? scores.length : 5);

        final oldestAvg = scores.last;
        accuracyTrend = recentAvg - oldestAvg;
      }

      debugPrint('AnalyticsRepository: getAdvancedStats completed');
      return AdvancedStats(
        averageTimePerQuestion: averageTime,
        accuracyTrend: accuracyTrend,
        totalExams: totalExams,
        passedExams: passedExams,
      );
    } catch (e, stack) {
      debugPrint('AnalyticsRepository: getAdvancedStats ERROR: $e');
      debugPrint(stack.toString());
      return AdvancedStats(
        averageTimePerQuestion: 0,
        accuracyTrend: 0,
        totalExams: 0,
        passedExams: 0,
      );
    }
  }
}

// Providers
final userAnalyticsProvider = FutureProvider<UserAnalytics>((ref) async {
  final repository = ref.watch(analyticsRepositoryProvider);
  return await repository.getUserAnalytics();
});

final weeklyStatsProvider = FutureProvider<List<DailyStats>>((ref) async {
  final repository = ref.watch(analyticsRepositoryProvider);
  return await repository.getWeeklyStats();
});

final weakTopicsProvider = FutureProvider<List<WeakTopicData>>((ref) async {
  final repository = ref.watch(analyticsRepositoryProvider);
  return await repository.getWeakTopics();
});

final personalizedAnalysisProvider = FutureProvider<PersonalizedAnalysis>((
  ref,
) async {
  final repository = ref.watch(analyticsRepositoryProvider);
  return await repository.getPersonalizedAnalysis();
});

final advancedStatsProvider = FutureProvider<AdvancedStats>((ref) async {
  final repository = ref.watch(analyticsRepositoryProvider);
  return await repository.getAdvancedStats();
});

final monthlyStatsProvider = FutureProvider<List<DailyStats>>((ref) async {
  final repository = ref.watch(analyticsRepositoryProvider);
  return await repository.getMonthlyStats();
});

final subjectDetailedStatsProvider =
    FutureProvider<List<SubjectDetailedStats>>((ref) async {
  final repository = ref.watch(analyticsRepositoryProvider);
  return await repository.getSubjectDetailedStats();
});
