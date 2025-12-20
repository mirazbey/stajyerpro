import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/models/topic_model.dart';
import '../../subjects/data/subjects_repository.dart';
import '../../../core/subscription/subscription_service.dart';

/// Quiz setup state provider
final quizSetupProvider =
    StateNotifierProvider<QuizSetupNotifier, QuizSetupState>((ref) {
      return QuizSetupNotifier();
    });

/// Quiz setup state
class QuizSetupState {
  final List<String> selectedTopicIds;
  final int questionCount;
  final String difficulty;

  QuizSetupState({
    this.selectedTopicIds = const [],
    this.questionCount = 20,
    this.difficulty = 'all',
  });

  QuizSetupState copyWith({
    List<String>? selectedTopicIds,
    int? questionCount,
    String? difficulty,
  }) {
    return QuizSetupState(
      selectedTopicIds: selectedTopicIds ?? this.selectedTopicIds,
      questionCount: questionCount ?? this.questionCount,
      difficulty: difficulty ?? this.difficulty,
    );
  }
}

/// Quiz setup notifier
class QuizSetupNotifier extends StateNotifier<QuizSetupState> {
  QuizSetupNotifier() : super(QuizSetupState());

  void toggleTopic(String topicId) {
    final topics = List<String>.from(state.selectedTopicIds);
    if (topics.contains(topicId)) {
      topics.remove(topicId);
    } else {
      topics.add(topicId);
    }
    state = state.copyWith(selectedTopicIds: topics);
  }

  void setQuestionCount(int count) {
    state = state.copyWith(questionCount: count);
  }

  void setDifficulty(String difficulty) {
    state = state.copyWith(difficulty: difficulty);
  }

  void reset() {
    state = QuizSetupState();
  }
}

/// Quiz baþlatma setup ekraný
class QuizSetupScreen extends ConsumerStatefulWidget {
  final List<String>? preSelectedTopicIds;

  const QuizSetupScreen({super.key, this.preSelectedTopicIds});

  @override
  ConsumerState<QuizSetupScreen> createState() => _QuizSetupScreenState();
}

class _QuizSetupScreenState extends ConsumerState<QuizSetupScreen> {
  @override
  void initState() {
    super.initState();
    if (widget.preSelectedTopicIds != null &&
        widget.preSelectedTopicIds!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final notifier = ref.read(quizSetupProvider.notifier);
        for (final topicId in widget.preSelectedTopicIds!) {
          notifier.toggleTopic(topicId);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final setupState = ref.watch(quizSetupProvider);
    final allTopicsStream = ref.watch(
      subjectsRepositoryProvider.select((repo) => repo.getAllTopics()),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Quiz Ayarlarý'), elevation: 0),
      body: StreamBuilder<List<TopicModel>>(
        stream: allTopicsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Hata: ${snapshot.error}'));
          }

          final allTopics = snapshot.data ?? [];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Soru Sayýsý',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: [10, 20, 30, 50].map((count) {
                    final isSelected = setupState.questionCount == count;
                    return ChoiceChip(
                      label: Text('$count Soru'),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          ref
                              .read(quizSetupProvider.notifier)
                              .setQuestionCount(count);
                        }
                      },
                    );
                  }).toList(),
                ),

                const SizedBox(height: 24),

                Text(
                  'Zorluk Seviyesi',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children:
                      const [
                        {'value': 'all', 'label': 'Hepsi'},
                        {'value': 'easy', 'label': 'Kolay'},
                        {'value': 'medium', 'label': 'Orta'},
                        {'value': 'hard', 'label': 'Zor'},
                      ].map((diff) {
                        return _DifficultyChip(
                          value: diff['value']!,
                          label: diff['label']!,
                        );
                      }).toList(),
                ),

                const SizedBox(height: 24),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Konular',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (setupState.selectedTopicIds.isNotEmpty)
                      TextButton(
                        onPressed: () {
                          ref.read(quizSetupProvider.notifier).reset();
                        },
                        child: const Text('Temizle'),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${setupState.selectedTopicIds.length} konu seçildi',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
                ),
                const SizedBox(height: 12),

                if (allTopics.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Text('Henüz konu eklenmemiþ'),
                    ),
                  )
                else
                  ...allTopics.map((topic) {
                    final isSelected = setupState.selectedTopicIds.contains(
                      topic.id,
                    );
                    return CheckboxListTile(
                      title: Text(topic.name),
                      subtitle: topic.questionCount != null
                          ? Text('${topic.questionCount} soru')
                          : null,
                      value: isSelected,
                      onChanged: (_) {
                        ref
                            .read(quizSetupProvider.notifier)
                            .toggleTopic(topic.id);
                      },
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    );
                  }),

                const SizedBox(height: 80),
              ],
            ),
          );
        },
      ),
      floatingActionButton: setupState.selectedTopicIds.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _handleStartQuiz(context, setupState),
              icon: const Icon(Icons.play_arrow),
              label: const Text('Quiz Baþlat'),
            ),
    );
  }

  Future<void> _handleStartQuiz(
    BuildContext context,
    QuizSetupState setupState,
  ) async {
    final subscriptionService = ref.read(subscriptionServiceProvider);
    final allowed = await subscriptionService.canStartQuiz(
      setupState.questionCount,
    );
    if (!allowed) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Free plan günlük soru limitine ulaþýldý. Pro ile sýnýrsýz eriþim saðlayýn.',
            ),
          ),
        );
      }
      return;
    }

    if (mounted) {
      context.push(
        '/quiz/start',
        extra: {
          'topicIds': setupState.selectedTopicIds,
          'questionCount': setupState.questionCount,
          'difficulty': setupState.difficulty,
        },
      );
    }
  }
}

class _DifficultyChip extends ConsumerWidget {
  final String value;
  final String label;

  const _DifficultyChip({required this.value, required this.label});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final setupState = ref.watch(quizSetupProvider);
    final isSelected = setupState.difficulty == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          ref.read(quizSetupProvider.notifier).setDifficulty(value);
        }
      },
    );
  }
}
