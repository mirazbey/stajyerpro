import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../data/wrong_answer_repository.dart';
import '../domain/wrong_answer_model.dart';
import '../../../shared/models/question_model.dart';

final wrongAnswersStreamProvider = StreamProvider<List<WrongAnswerModel>>((
  ref,
) {
  final repository = ref.watch(wrongAnswerRepositoryProvider);
  return repository.getWrongAnswers();
});

// Helper provider to fetch single question
final questionDetailsProvider = FutureProvider.family<QuestionModel?, String>((
  ref,
  id,
) async {
  final firestore = FirebaseFirestore.instance;
  final doc = await firestore.collection('questions').doc(id).get();
  if (doc.exists) {
    return QuestionModel.fromFirestore(doc);
  }
  return null;
});

class WrongAnswersScreen extends ConsumerWidget {
  const WrongAnswersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wrongAnswersAsync = ref.watch(wrongAnswersStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Yanlışlarım'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Yanlış Havuzu Nedir?'),
                  content: const Text(
                    'Yanlış yaptığınız sorular buraya eklenir. '
                    'Bu soruları tekrar çözerek pekiştirebilirsiniz. '
                    'Doğru cevapladığınızda sorulur havuzdan silinir.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Tamam'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: wrongAnswersAsync.when(
        data: (wrongAnswers) {
          if (wrongAnswers.isEmpty) {
            return _buildEmptyState(context);
          }
          return _buildContent(context, ref, wrongAnswers);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Hata: $error')),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 80,
            color: Colors.green.shade300,
          ),
          const SizedBox(height: 16),
          const Text(
            'Harika! Yanlış havuzunuz boş.',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Yanlış yaptığınız sorular burada birikir.',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () => context.go('/dashboard'),
            child: const Text('Soru Çözmeye Devam Et'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    List<WrongAnswerModel> wrongAnswers,
  ) {
    return Column(
      children: [
        // Stats Header
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.orange.shade50,
          child: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange.shade800),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Toplam ${wrongAnswers.length} soru tekrar bekliyor.',
                  style: TextStyle(
                    color: Colors.orange.shade900,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),

        // List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: wrongAnswers.length,
            itemBuilder: (context, index) {
              return _WrongAnswerCard(wrongAnswer: wrongAnswers[index]);
            },
          ),
        ),

        // Action Button
        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            height: 50,
            child: FilledButton.icon(
              onPressed: () => _startWrongQuiz(context, ref),
              icon: const Icon(Icons.play_arrow),
              label: const Text('Hataları Tekrar Et (20 Soru)'),
            ),
          ),
        ),
      ],
    );
  }

  void _startWrongQuiz(BuildContext context, WidgetRef ref) async {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final questions = await ref
          .read(wrongAnswerRepositoryProvider)
          .getRandomWrongQuestions(20);

      if (context.mounted) {
        Navigator.pop(context); // Hide loading
        if (questions.isEmpty) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Soru yüklenemedi.')));
          return;
        }
        // Navigate to quiz with questions
        context.push('/quiz/start', extra: {'questions': questions});
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Hide loading
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Hata: $e')));
      }
    }
  }
}

class _WrongAnswerCard extends ConsumerWidget {
  final WrongAnswerModel wrongAnswer;

  const _WrongAnswerCard({required this.wrongAnswer});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Fetch question details to show stem
    final questionFuture = ref.watch(
      questionDetailsProvider(wrongAnswer.questionId),
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.red.shade100,
          child: Text(
            '${wrongAnswer.attemptCount}',
            style: TextStyle(color: Colors.red.shade900),
          ),
        ),
        title: questionFuture.when(
          data: (question) => Text(
            question?.stem ?? 'Soru yüklenemedi',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          loading: () => const LinearProgressIndicator(),
          error: (_, __) => const Text('Hata'),
        ),
        subtitle: Text(
          'Eklendi: ${DateFormat('dd.MM.yyyy').format(wrongAnswer.addedAt)}',
          style: const TextStyle(fontSize: 12),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline),
          onPressed: () {
            ref
                .read(wrongAnswerRepositoryProvider)
                .removeFromWrongPool(wrongAnswer.questionId);
          },
        ),
      ),
    );
  }
}
