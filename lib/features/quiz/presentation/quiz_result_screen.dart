import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/models/question_model.dart';
import '../data/quiz_repository.dart';
import '../../ai_coach/data/ai_coach_repository.dart';

/// Quiz sonuç ekranı
class QuizResultScreen extends ConsumerStatefulWidget {
  final List<QuestionModel> questions;
  final List<UserAnswer> answers;
  final Duration duration;
  final List<String> topicIds;

  const QuizResultScreen({
    super.key,
    required this.questions,
    required this.answers,
    required this.duration,
    required this.topicIds,
  });

  @override
  ConsumerState<QuizResultScreen> createState() => _QuizResultScreenState();
}

class _QuizResultScreenState extends ConsumerState<QuizResultScreen> {
  @override
  void initState() {
    super.initState();
    _saveResult();
  }

  Future<void> _saveResult() async {
    try {
      final repository = ref.read(quizRepositoryProvider);
      final correctAnswers =
          widget.answers.where((a) => a.isCorrect).length;

      await repository.saveQuizResult(
        answers: widget.answers,
        totalQuestions: widget.questions.length,
        correctAnswers: correctAnswers,
        duration: widget.duration,
        topicIds: widget.topicIds,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sonuç kaydedilemedi: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final correctAnswers = widget.answers.where((a) => a.isCorrect).length;
    final wrongAnswers = widget.answers.length - correctAnswers;
    final score = (correctAnswers / widget.questions.length * 100).round();

    return WillPopScope(
      onWillPop: () async {
        // Sonuç ekranından geri dönüşü dashboard'a yönlendir
        context.go('/dashboard');
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Quiz Sonucu'),
          automaticallyImplyLeading: false,
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              // Skor kartı
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: score >= 70
                        ? [Colors.green.shade400, Colors.green.shade700]
                        : score >= 50
                            ? [Colors.orange.shade400, Colors.orange.shade700]
                            : [Colors.red.shade400, Colors.red.shade700],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  children: [
                    // Skor yüzdesi
                    Text(
                      '%$score',
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _getScoreMessage(score),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                          ),
                    ),
                    const SizedBox(height: 16),
                    // İstatistikler
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _StatCard(
                          icon: Icons.check_circle,
                          label: 'Doğru',
                          value: correctAnswers.toString(),
                          color: Colors.white,
                        ),
                        _StatCard(
                          icon: Icons.cancel,
                          label: 'Yanlış',
                          value: wrongAnswers.toString(),
                          color: Colors.white,
                        ),
                        _StatCard(
                          icon: Icons.timer,
                          label: 'Süre',
                          value: _formatDuration(widget.duration),
                          color: Colors.white,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Soru detayları
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Soru Detayları',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 12),
                    ...List.generate(widget.questions.length, (index) {
                      final question = widget.questions[index];
                      final answer = widget.answers.firstWhere(
                        (a) => a.questionId == question.id,
                        orElse: () => UserAnswer(
                          questionId: question.id,
                          selectedIndex: -1,
                          isCorrect: false,
                          answeredAt: DateTime.now(),
                        ),
                      );

                      return _QuestionResultCard(
                        questionNumber: index + 1,
                        question: question,
                        userAnswer: answer,
                      );
                    }),
                  ],
                ),
              ),

              const SizedBox(height: 80), // Alt butonlar için boşluk
            ],
          ),
        ),
        bottomNavigationBar: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => context.go('/dashboard'),
                  icon: const Icon(Icons.home),
                  label: const Text('Ana Sayfa'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => context.go('/quiz/setup'),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Yeni Quiz'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getScoreMessage(int score) {
    if (score >= 90) return 'Mükemmel! 🎉';
    if (score >= 70) return 'Çok İyi! 👏';
    if (score >= 50) return 'İyi! 👍';
    return 'Biraz daha çalış! 💪';
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes}dk ${seconds}sn';
  }
}

/// İstatistik kartı widget'ı
class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: color.withOpacity(0.9),
              ),
        ),
      ],
    );
  }
}

/// Soru sonuç kartı
class _QuestionResultCard extends ConsumerWidget {
  final int questionNumber;
  final QuestionModel question;
  final UserAnswer userAnswer;

  const _QuestionResultCard({
    required this.questionNumber,
    required this.question,
    required this.userAnswer,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isCorrect = userAnswer.isCorrect;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: isCorrect ? Colors.green : Colors.red,
          child: Icon(
            isCorrect ? Icons.check : Icons.close,
            color: Colors.white,
          ),
        ),
        title: Text(
          'Soru $questionNumber',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          isCorrect ? 'Doğru' : 'Yanlış',
          style: TextStyle(
            color: isCorrect ? Colors.green : Colors.red,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Soru metni
                Text(
                  question.stem,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                ),
                const SizedBox(height: 12),

                // Şıklar
                ...List.generate(question.options.length, (index) {
                  final isUserAnswer = index == userAnswer.selectedIndex;
                  final isCorrectAnswer = index == question.correctIndex;
                  final optionLetter = String.fromCharCode(65 + index);

                  Color? backgroundColor;
                  Color? textColor;

                  if (isCorrectAnswer) {
                    backgroundColor = Colors.green.shade50;
                    textColor = Colors.green.shade700;
                  } else if (isUserAnswer && !isCorrect) {
                    backgroundColor = Colors.red.shade50;
                    textColor = Colors.red.shade700;
                  }

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: backgroundColor,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: backgroundColor != null
                            ? (isCorrectAnswer
                                ? Colors.green.shade300
                                : Colors.red.shade300)
                            : Colors.grey.shade300,
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(
                          '$optionLetter)',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            question.options[index],
                            style: TextStyle(color: textColor),
                          ),
                        ),
                        if (isCorrectAnswer)
                          const Icon(Icons.check_circle, color: Colors.green),
                        if (isUserAnswer && !isCorrect)
                          const Icon(Icons.cancel, color: Colors.red),
                      ],
                    ),
                  );
                }),

                const SizedBox(height: 16),

                // AI Açıklama İste Butonu
                OutlinedButton.icon(
                  onPressed: () => _requestAIExplanation(
                    context, 
                    ref, 
                    question, 
                    userAnswer.selectedIndex,
                  ),
                  icon: const Icon(Icons.psychology),
                  label: const Text('AI Açıklaması İste'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                  ),
                ),

                // Statik Açıklama (varsa)
                if (question.explanation != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue.shade700),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Açıklama',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                question.explanation!,
                                style: TextStyle(color: Colors.blue.shade900),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _requestAIExplanation(
    BuildContext context,
    WidgetRef ref,
    QuestionModel question,
    int userAnswerIndex,
  ) async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('AI açıklama hazırlanıyor...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final aiRepo = ref.read(aiCoachRepositoryProvider);

      final explanation = await aiRepo.getQuestionExplanation(
        question: question,
        userAnswer: userAnswerIndex,
      );

      if (context.mounted) {
        Navigator.pop(context); // Close loading

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                Icon(
                  userAnswerIndex == question.correctIndex 
                    ? Icons.check_circle 
                    : Icons.error,
                  color: userAnswerIndex == question.correctIndex 
                    ? Colors.green 
                    : Colors.red,
                ),
                const SizedBox(width: 8),
                const Expanded(child: Text('AI Açıklama')),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    question.stem,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 16),
                  Text(explanation),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Kapat'),
              ),
              FilledButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  context.push('/ai-coach');
                },
                icon: const Icon(Icons.chat),
                label: const Text('AI Koça Sor'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Close loading

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.error, color: Colors.red),
                SizedBox(width: 8),
                Text('Hata'),
              ],
            ),
            content: Text(
              'AI açıklama alınırken hata oluştu:\n\n$e\n\n'
              'Lütfen internet bağlantınızı kontrol edin veya '
              'AI Coach ekranından sorunuzu sorabilirsiniz.'
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Tamam'),
              ),
              FilledButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  context.push('/ai-coach');
                },
                icon: const Icon(Icons.chat),
                label: const Text('AI Koçuna Git'),
              ),
            ],
          ),
        );
      }
    }
  }
}