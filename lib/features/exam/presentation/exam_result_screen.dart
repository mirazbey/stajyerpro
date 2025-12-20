import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/models/exam_model.dart';
import '../../../shared/models/question_model.dart';
import '../data/exam_repository.dart';
import 'widgets/question_detail_sheet.dart';
import '../../quiz/data/wrong_answer_repository.dart';
import '../../gamification/data/gamification_repository.dart';
import '../../gamification/domain/badge_model.dart';

// Provider for exam result
final examResultProvider = FutureProvider.family<ExamResultData, String>((
  ref,
  attemptId,
) async {
  final repository = ref.watch(examRepositoryProvider);

  // Get attempt details from Firestore
  final attemptDoc = await repository.firestore
      .collection('exam_attempts')
      .doc(attemptId)
      .get();

  if (!attemptDoc.exists) {
    throw Exception('Deneme sonucu bulunamadı');
  }

  final attempt = ExamAttemptModel.fromFirestore(attemptDoc);

  // Get exam details
  final exam = await repository.getExamById(attempt.examId);
  if (exam == null) throw Exception('Deneme bulunamadı');

  // Get questions to analyze
  final questions = await repository.getExamQuestions(attempt.examId);

  // Fetch all subjects to map IDs to Names
  final subjectsSnapshot = await repository.firestore
      .collection('subjects')
      .get();
  final subjectMap = {
    for (var doc in subjectsSnapshot.docs)
      doc.id: doc.data()['name'] as String? ?? doc.id,
  };

  // Fetch all topics to map IDs to Names
  final topicsSnapshot = await repository.firestore.collection('topics').get();
  final topicMap = {
    for (var doc in topicsSnapshot.docs)
      doc.id: doc.data()['name'] as String? ?? doc.id,
  };

  // Calculate section-wise performance
  final sectionPerformance = _calculateSectionPerformance(
    questions,
    attempt.answers,
    subjectMap,
  );

  // Identify weak topics
  final weakTopics = _identifyWeakTopics(questions, attempt.answers, topicMap);

  return ExamResultData(
    attempt: attempt,
    exam: exam,
    questions: questions,
    sectionPerformance: sectionPerformance,
    weakTopics: weakTopics,
  );
});

class ExamResultData {
  final ExamAttemptModel attempt;
  final ExamModel exam;
  final List<QuestionModel> questions;
  final Map<String, SectionPerformance> sectionPerformance;
  final List<WeakTopic> weakTopics;

  ExamResultData({
    required this.attempt,
    required this.exam,
    required this.questions,
    required this.sectionPerformance,
    required this.weakTopics,
  });
}

class SectionPerformance {
  final String subjectName;
  final int totalQuestions;
  final int correctAnswers;

  SectionPerformance({
    required this.subjectName,
    required this.totalQuestions,
    required this.correctAnswers,
  });

  double get percentage => (correctAnswers / totalQuestions * 100);
}

class WeakTopic {
  final String topicId;
  final String topicName;
  final int incorrectCount;

  WeakTopic({
    required this.topicId,
    required this.topicName,
    required this.incorrectCount,
  });
}

Map<String, SectionPerformance> _calculateSectionPerformance(
  List<QuestionModel> questions,
  Map<int, int> answers,
  Map<String, String> subjectMap,
) {
  final Map<String, SectionPerformance> performance = {};

  for (int i = 0; i < questions.length; i++) {
    final question = questions[i];
    final subjectId = question.subjectId;
    final subjectName = subjectMap[subjectId] ?? subjectId;
    final userAnswer = answers[i];
    final isCorrect = userAnswer != null && userAnswer == question.correctIndex;

    if (!performance.containsKey(subjectId)) {
      performance[subjectId] = SectionPerformance(
        subjectName: subjectName,
        totalQuestions: 0,
        correctAnswers: 0,
      );
    }

    performance[subjectId] = SectionPerformance(
      subjectName: performance[subjectId]!.subjectName,
      totalQuestions: performance[subjectId]!.totalQuestions + 1,
      correctAnswers:
          performance[subjectId]!.correctAnswers + (isCorrect ? 1 : 0),
    );
  }

  return performance;
}

List<WeakTopic> _identifyWeakTopics(
  List<QuestionModel> questions,
  Map<int, int> answers,
  Map<String, String> topicMap,
) {
  final Map<String, WeakTopic> topicMapResult = {};

  for (int i = 0; i < questions.length; i++) {
    final question = questions[i];
    final userAnswer = answers[i];
    final isIncorrect =
        userAnswer == null || userAnswer != question.correctIndex;

    if (isIncorrect) {
      for (var topicId in question.topicIds) {
        final topicName = topicMap[topicId] ?? topicId;
        if (!topicMapResult.containsKey(topicId)) {
          topicMapResult[topicId] = WeakTopic(
            topicId: topicId,
            topicName: topicName,
            incorrectCount: 0,
          );
        }

        topicMapResult[topicId] = WeakTopic(
          topicId: topicMapResult[topicId]!.topicId,
          topicName: topicMapResult[topicId]!.topicName,
          incorrectCount: topicMapResult[topicId]!.incorrectCount + 1,
        );
      }
    }
  }

  // Sort by incorrect count and return top 5
  final weakTopics = topicMapResult.values.toList()
    ..sort((a, b) => b.incorrectCount.compareTo(a.incorrectCount));

  return weakTopics.take(5).toList();
}

// ... (imports remain the same, just adding above)

// Exam Result Screen
class ExamResultScreen extends ConsumerStatefulWidget {
  final String examId;
  final String attemptId;

  const ExamResultScreen({
    super.key,
    required this.examId,
    required this.attemptId,
  });

  @override
  ConsumerState<ExamResultScreen> createState() => _ExamResultScreenState();
}

class _ExamResultScreenState extends ConsumerState<ExamResultScreen> {
  bool _badgesChecked = false;

  @override
  Widget build(BuildContext context) {
    final resultAsync = ref.watch(examResultProvider(widget.attemptId));

    ref.listen(examResultProvider(widget.attemptId), (previous, next) {
      if (next.hasValue && !_badgesChecked) {
        _checkBadges(next.value!);
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Deneme Sonucu'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.go('/dashboard'),
        ),
      ),
      body: resultAsync.when(
        data: (result) {
          // Initial check if not triggered by listen (e.g. if data was already available)
          if (!_badgesChecked) {
            // Use microtask to avoid building during build
            Future.microtask(() => _checkBadges(result));
          }
          return _buildResultContent(context, ref, result);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Hata: $error'),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => context.go('/dashboard'),
                child: const Text('Ana Sayfaya Dön'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _checkBadges(ExamResultData result) async {
    if (_badgesChecked) return;
    _badgesChecked = true;

    final repository = ref.read(gamificationRepositoryProvider);
    final userId = result.attempt.userId;

    // 1. Check for "First Exam" or "Exam Count" badges
    // We need to know total exam count. For now, let's assume this is the Nth exam.
    // Ideally, we fetch user stats.
    // For MVP, let's just check "score" based badges and "first exam" if we can determine it.

    // Check Score Badges
    if (result.attempt.score >= 80) {
      final newBadges = await repository.checkAndUnlockBadges(
        userId,
        BadgeConditionType.score,
        result.attempt.score,
      );
      if (newBadges.isNotEmpty && mounted) {
        _showBadgeDialog(newBadges);
      }
    }

    // Check Exam Count (Mocking count as 1 for now or fetching from somewhere)
    // In a real app, we would fetch the count.
    // Let's just try to unlock 'first_exam' blindly, the repository checks if it's already earned.
    final newExamBadges = await repository.checkAndUnlockBadges(
      userId,
      BadgeConditionType.examCount,
      1, // Assuming at least 1
    );

    if (newExamBadges.isNotEmpty && mounted) {
      _showBadgeDialog(newExamBadges);
    }
  }

  void _showBadgeDialog(List<BadgeModel> badges) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Yeni Rozet Kazandın! 🎉'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: badges
              .map(
                (badge) => Column(
                  children: [
                    Image.asset(badge.iconPath, height: 80, width: 80),
                    const SizedBox(height: 8),
                    Text(
                      badge.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(badge.description, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                  ],
                ),
              )
              .toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Harika!'),
          ),
        ],
      ),
    );
  }

  Widget _buildResultContent(
    BuildContext context,
    WidgetRef ref,
    ExamResultData result,
  ) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Score card with gradient
          _buildScoreCard(context, result),

          const SizedBox(height: 16),

          // Baraj simulation graph
          _buildBarajSimulation(context, result),

          const SizedBox(height: 16),

          // Section-wise performance
          _buildSectionPerformance(context, result),

          const SizedBox(height: 16),

          // Weak topics
          _buildWeakTopics(context, result),

          const SizedBox(height: 16),

          // Question Analysis
          _buildQuestionAnalysis(context, ref, result),

          const SizedBox(height: 16),

          // Action buttons
          _buildActionButtons(context, result),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildScoreCard(BuildContext context, ExamResultData result) {
    final successRate =
        (result.attempt.correctAnswers / result.attempt.totalQuestions * 100);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: successRate >= 60
              ? [Colors.green.shade400, Colors.green.shade700]
              : [Colors.orange.shade400, Colors.orange.shade700],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Puanınız',
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            '${result.attempt.score}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 64,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildScoreStat(
                'Doğru',
                '${result.attempt.correctAnswers}',
                Colors.white,
              ),
              Container(width: 1, height: 40, color: Colors.white30),
              _buildScoreStat(
                'Yanlış',
                '${result.attempt.totalQuestions - result.attempt.correctAnswers}',
                Colors.white,
              ),
              Container(width: 1, height: 40, color: Colors.white30),
              _buildScoreStat(
                'Başarı',
                '%${successRate.toStringAsFixed(1)}',
                Colors.white,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Süre: ${_formatDuration(result.attempt.duration.inSeconds)}',
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(color: color.withOpacity(0.7), fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildBarajSimulation(BuildContext context, ExamResultData result) {
    const barajThreshold = 60.0;
    final userScore = result.attempt.score.toDouble();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Baraj Simülasyonu',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      // User bar
                      Row(
                        children: [
                          const SizedBox(
                            width: 80,
                            child: Text('Sizin Puanınız'),
                          ),
                          Expanded(
                            child: Stack(
                              children: [
                                Container(
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade200,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                FractionallySizedBox(
                                  widthFactor: userScore / 100,
                                  child: Container(
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: userScore >= barajThreshold
                                          ? Colors.green
                                          : Colors.orange,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Center(
                                      child: Text(
                                        '${userScore.toInt()}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Baraj bar
                      Row(
                        children: [
                          const SizedBox(width: 80, child: Text('Baraj Puanı')),
                          Expanded(
                            child: Stack(
                              children: [
                                Container(
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade200,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                FractionallySizedBox(
                                  widthFactor: barajThreshold / 100,
                                  child: Container(
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: Colors.blue.shade600,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Center(
                                      child: Text(
                                        '60',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: userScore >= barajThreshold
                    ? Colors.green.shade50
                    : Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    userScore >= barajThreshold
                        ? Icons.check_circle
                        : Icons.info,
                    color: userScore >= barajThreshold
                        ? Colors.green
                        : Colors.orange,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      userScore >= barajThreshold
                          ? 'Tebrikler! Baraj puanını geçtiniz.'
                          : 'Baraj puanının ${(barajThreshold - userScore).toInt()} puan altındasınız.',
                      style: TextStyle(
                        color: userScore >= barajThreshold
                            ? Colors.green.shade800
                            : Colors.orange.shade800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionPerformance(BuildContext context, ExamResultData result) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Bölüm Bazlı Performans',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...result.sectionPerformance.entries.map((entry) {
              final section = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          section.subjectName,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        Text(
                          '${section.correctAnswers}/${section.totalQuestions} (%${section.percentage.toStringAsFixed(0)})',
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: section.percentage / 100,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        section.percentage >= 60 ? Colors.green : Colors.orange,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionAnalysis(
    BuildContext context,
    WidgetRef ref,
    ExamResultData result,
  ) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Soru Analizi',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Detaylı çözüm için sorulara tıklayın.',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: result.questions.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final question = result.questions[index];
                final userAnswer = result.attempt.answers[index];
                final isCorrect = userAnswer == question.correctIndex;
                final isEmpty = userAnswer == null;

                return InkWell(
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => QuestionDetailSheet(
                        question: question,
                        userAnswerIndex: userAnswer ?? -1,
                        onAddToWrongPool: () async {
                          try {
                            await ref
                                .read(wrongAnswerRepositoryProvider)
                                .addToWrongPool(question.id);

                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Soru yanlış havuzuna eklendi!',
                                  ),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Hata: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: isCorrect
                                ? Colors.green.withOpacity(0.1)
                                : (isEmpty
                                      ? Colors.grey.withOpacity(0.1)
                                      : Colors.red.withOpacity(0.1)),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isCorrect
                                ? Icons.check
                                : (isEmpty ? Icons.remove : Icons.close),
                            color: isCorrect
                                ? Colors.green
                                : (isEmpty ? Colors.grey : Colors.red),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Soru ${index + 1}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                question.stem,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right, color: Colors.grey),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeakTopics(BuildContext context, ExamResultData result) {
    if (result.weakTopics.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Zayıf Konularınız',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Bu konularda daha fazla pratik yapmanız önerilir:',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ...result.weakTopics.map((topic) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.error_outline,
                        color: Colors.red.shade700,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            topic.topicName,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          Text(
                            '${topic.incorrectCount} yanlış cevap',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    OutlinedButton(
                      onPressed: () {
                        // Navigate to quiz with this topic
                        context.push('/quiz/setup?topicId=${topic.topicId}');
                      },
                      child: const Text('Quiz Başlat'),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, ExamResultData result) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => context.go('/dashboard'),
              icon: const Icon(Icons.home),
              label: const Text('Ana Sayfaya Dön'),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => context.push('/exams'),
              icon: const Icon(Icons.refresh),
              label: const Text('Yeni Deneme Başlat'),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
}
