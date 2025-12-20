import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/design_tokens.dart';
import '../../subjects/data/subjects_repository.dart';
import '../../../core/subscription/subscription_service.dart';

/// Quiz Mode Enum
enum QuizFlowMode {
  quick, // Hızlı Quiz - 10 rastgele soru
  custom, // Özel Test - Ders/Konu seçimi
}

/// Quiz Setup State
class QuizSetupState {
  final QuizFlowMode? mode;
  final String? selectedSubjectId;
  final List<String> selectedTopicIds;
  final int questionCount;
  final String difficulty;
  final bool timedMode;
  final int timeLimit;

  const QuizSetupState({
    this.mode,
    this.selectedSubjectId,
    this.selectedTopicIds = const [],
    this.questionCount = 20,
    this.difficulty = 'all',
    this.timedMode = false,
    this.timeLimit = 15,
  });

  QuizSetupState copyWith({
    QuizFlowMode? mode,
    String? selectedSubjectId,
    List<String>? selectedTopicIds,
    int? questionCount,
    String? difficulty,
    bool? timedMode,
    int? timeLimit,
  }) {
    return QuizSetupState(
      mode: mode ?? this.mode,
      selectedSubjectId: selectedSubjectId ?? this.selectedSubjectId,
      selectedTopicIds: selectedTopicIds ?? this.selectedTopicIds,
      questionCount: questionCount ?? this.questionCount,
      difficulty: difficulty ?? this.difficulty,
      timedMode: timedMode ?? this.timedMode,
      timeLimit: timeLimit ?? this.timeLimit,
    );
  }
}

/// Quiz Setup Notifier
class QuizSetupNotifier extends StateNotifier<QuizSetupState> {
  QuizSetupNotifier() : super(const QuizSetupState());

  void setMode(QuizFlowMode mode) {
    if (mode == QuizFlowMode.quick) {
      state = const QuizSetupState(mode: QuizFlowMode.quick, questionCount: 10);
    } else {
      state = state.copyWith(
        mode: mode,
        selectedSubjectId: null,
        selectedTopicIds: [],
      );
    }
  }

  void setSubject(String subjectId) {
    state = state.copyWith(selectedSubjectId: subjectId, selectedTopicIds: []);
  }

  void toggleTopic(String topicId) {
    final topics = List<String>.from(state.selectedTopicIds);
    if (topics.contains(topicId)) {
      topics.remove(topicId);
    } else {
      topics.add(topicId);
    }
    state = state.copyWith(selectedTopicIds: topics);
  }

  void setQuestionCount(int count) =>
      state = state.copyWith(questionCount: count);
  void setDifficulty(String diff) => state = state.copyWith(difficulty: diff);
  void setTimedMode(bool val) => state = state.copyWith(timedMode: val);
  void setTimeLimit(int val) => state = state.copyWith(timeLimit: val);
}

final quizSetupProvider =
    StateNotifierProvider<QuizSetupNotifier, QuizSetupState>((ref) {
      return QuizSetupNotifier();
    });

class QuizSetupFlowScreen extends ConsumerStatefulWidget {
  final QuizFlowMode? initialMode;
  final List<String>? preSelectedTopicIds;

  const QuizSetupFlowScreen({
    super.key,
    this.initialMode,
    this.preSelectedTopicIds,
  });

  @override
  ConsumerState<QuizSetupFlowScreen> createState() =>
      _QuizSetupFlowScreenState();
}

class _QuizSetupFlowScreenState extends ConsumerState<QuizSetupFlowScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notifier = ref.read(quizSetupProvider.notifier);

      if (widget.initialMode != null) {
        notifier.setMode(widget.initialMode!);
      }

      if (widget.preSelectedTopicIds != null &&
          widget.preSelectedTopicIds!.isNotEmpty) {
        notifier.setMode(QuizFlowMode.custom);
        for (final id in widget.preSelectedTopicIds!) {
          notifier.toggleTopic(id);
        }
      }
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: 500.ms,
          curve: Curves.easeOutQuart,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(quizSetupProvider);
    final subjectsAsync = ref.watch(subjectsStreamProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Deep Space Dark
      body: Stack(
        children: [
          // Global Background
          const _GlobalAnimatedBackground(),

          SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => context.pop(),
                        icon: const Icon(
                          Icons.arrow_back_ios_new,
                          color: Colors.white,
                        ),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(0.1),
                          padding: const EdgeInsets.all(12),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        'Quiz Oluştur',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                // Flow Content
                Expanded(
                  child: ListView(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    children: [
                      // 1. Mode Selection Node
                      _QuizFlowNode(
                        title: 'Mod Seçimi',
                        isActive: true,
                        isCompleted: state.mode != null,
                        child: Row(
                          children: [
                            Expanded(
                              child: _SelectionCard(
                                title: 'Hızlı Quiz',
                                subtitle: '10 Rastgele Soru',
                                icon: Icons.bolt_rounded,
                                color: const Color(0xFFFFD700),
                                isSelected: state.mode == QuizFlowMode.quick,
                                onTap: () {
                                  ref
                                      .read(quizSetupProvider.notifier)
                                      .setMode(QuizFlowMode.quick);
                                  _scrollToBottom();
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _SelectionCard(
                                title: 'Özel Test',
                                subtitle: 'Konu & Ayarlar',
                                icon: Icons.tune_rounded,
                                color: const Color(0xFF7C3AED),
                                isSelected: state.mode == QuizFlowMode.custom,
                                onTap: () {
                                  ref
                                      .read(quizSetupProvider.notifier)
                                      .setMode(QuizFlowMode.custom);
                                  _scrollToBottom();
                                },
                              ),
                            ),
                          ],
                        ),
                      ),

                      // 2. Subject Selection Node (Only for Custom)
                      if (state.mode == QuizFlowMode.custom)
                        _QuizFlowNode(
                          title: 'Ders Seçimi',
                          isActive: true,
                          isCompleted: state.selectedSubjectId != null,
                          child: subjectsAsync.when(
                            data: (subjects) => SizedBox(
                              height: 120,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: subjects.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(width: 12),
                                itemBuilder: (context, index) {
                                  final subject = subjects[index];
                                  return SizedBox(
                                    width: 140,
                                    child: _SelectionCard(
                                      title: subject.name,
                                      subtitle: '',
                                      icon: Icons.book_rounded,
                                      color:
                                          Colors.primaries[index %
                                              Colors.primaries.length],
                                      isSelected:
                                          state.selectedSubjectId == subject.id,
                                      onTap: () {
                                        ref
                                            .read(quizSetupProvider.notifier)
                                            .setSubject(subject.id);
                                        _scrollToBottom();
                                      },
                                      isCompact: true,
                                    ),
                                  );
                                },
                              ),
                            ),
                            loading: () => const Center(
                              child: CircularProgressIndicator(),
                            ),
                            error: (_, __) => const Text(
                              'Hata oluştu',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ).animate().fadeIn().slideY(begin: 0.2),

                      // 3. Topic Selection Node (Only if Subject Selected)
                      if (state.mode == QuizFlowMode.custom &&
                          state.selectedSubjectId != null)
                        _TopicSelectionNode(
                          subjectId: state.selectedSubjectId!,
                          selectedTopicIds: state.selectedTopicIds,
                          onToggle: (id) => ref
                              .read(quizSetupProvider.notifier)
                              .toggleTopic(id),
                        ).animate().fadeIn().slideY(begin: 0.2),

                      // 4. Settings Node (Always visible for Custom, or hidden for Quick)
                      if (state.mode == QuizFlowMode.custom &&
                          state.selectedTopicIds.isNotEmpty)
                        _SettingsNode(
                          state: state,
                        ).animate().fadeIn().slideY(begin: 0.2),

                      const SizedBox(height: 32),

                      // Start Button
                      if (state.mode != null &&
                          (state.mode == QuizFlowMode.quick ||
                              state.selectedTopicIds.isNotEmpty))
                        SizedBox(
                          width: double.infinity,
                          height: 60,
                          child: ElevatedButton(
                            onPressed: () => _startQuiz(context, state),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: DesignTokens.accent,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              elevation: 8,
                              shadowColor: DesignTokens.accent.withOpacity(0.5),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Testi Başlat',
                                  style: GoogleFonts.outfit(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Icon(Icons.arrow_forward_rounded),
                              ],
                            ),
                          ),
                        ).animate().scale(
                          delay: 200.ms,
                          duration: 400.ms,
                          curve: Curves.elasticOut,
                        ),

                      const SizedBox(height: 50),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _startQuiz(BuildContext context, QuizSetupState state) async {
    final subscriptionService = ref.read(subscriptionServiceProvider);
    final allowed = await subscriptionService.canStartQuiz(state.questionCount);

    if (!allowed) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Günlük soru limitine ulaşıldı. Pro ile sınırsız erişim sağlayın.',
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
          'mode': state.mode?.name,
          'topicIds': state.selectedTopicIds,
          'questionCount': state.questionCount,
          'difficulty': state.difficulty,
          'timeLimit': state.timedMode ? state.timeLimit : null,
        },
      );
    }
  }
}

class _QuizFlowNode extends StatelessWidget {
  final String title;
  final Widget child;
  final bool isActive;
  final bool isCompleted;

  const _QuizFlowNode({
    required this.title,
    required this.child,
    this.isActive = false,
    this.isCompleted = false,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline Line
          Column(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: isCompleted
                      ? DesignTokens.accent
                      : Colors.white.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isActive
                        ? DesignTokens.accent
                        : Colors.white.withOpacity(0.2),
                    width: 2,
                  ),
                ),
                child: isCompleted
                    ? const Icon(Icons.check, size: 14, color: Colors.white)
                    : null,
              ),
              Expanded(
                child: Container(
                  width: 2,
                  color: isCompleted
                      ? DesignTokens.accent.withOpacity(0.5)
                      : Colors.white.withOpacity(0.1),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    color: isActive
                        ? Colors.white
                        : Colors.white.withOpacity(0.5),
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                child,
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SelectionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isCompact;

  const _SelectionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.onTap,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: 300.ms,
        height: isCompact ? 120 : 140,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: isSelected
              ? color.withOpacity(0.2)
              : Colors.white.withOpacity(0.05),
          border: Border.all(
            color: isSelected ? color : Colors.white.withOpacity(0.1),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Stack(
          children: [
            if (isSelected)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [color.withOpacity(0.3), Colors.transparent],
                    ),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isSelected ? color : Colors.white.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icon,
                      color: Colors.white,
                      size: isCompact ? 20 : 24,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    title,
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: isCompact ? 14 : 18,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            if (isSelected)
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, size: 12, color: Colors.white),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TopicSelectionNode extends ConsumerWidget {
  final String subjectId;
  final List<String> selectedTopicIds;
  final Function(String) onToggle;

  const _TopicSelectionNode({
    required this.subjectId,
    required this.selectedTopicIds,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final topicsAsync = ref.watch(topicsBySubjectStreamProvider(subjectId));

    return _QuizFlowNode(
      title: 'Konu Seçimi',
      isActive: true,
      isCompleted: selectedTopicIds.isNotEmpty,
      child: topicsAsync.when(
        data: (topics) => Wrap(
          spacing: 8,
          runSpacing: 8,
          children: topics.map((topic) {
            final isSelected = selectedTopicIds.contains(topic.id);
            return FilterChip(
              label: Text(topic.name),
              selected: isSelected,
              onSelected: (_) => onToggle(topic.id),
              backgroundColor: Colors.white.withOpacity(0.05),
              selectedColor: DesignTokens.accent.withOpacity(0.3),
              checkmarkColor: DesignTokens.accent,
              labelStyle: TextStyle(
                color: isSelected ? DesignTokens.accent : Colors.white70,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: isSelected
                      ? DesignTokens.accent
                      : Colors.white.withOpacity(0.1),
                ),
              ),
            );
          }).toList(),
        ),
        loading: () => const CircularProgressIndicator(),
        error: (_, __) =>
            const Text('Hata', style: TextStyle(color: Colors.white)),
      ),
    );
  }
}

class _SettingsNode extends ConsumerWidget {
  final QuizSetupState state;

  const _SettingsNode({required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _QuizFlowNode(
      title: 'Ayarlar',
      isActive: true,
      isCompleted: true,
      child: Column(
        children: [
          // Question Count
          _SettingRow(
            label: 'Soru Sayısı',
            child: Row(
              children: [10, 20, 30, 50].map((count) {
                final isSelected = state.questionCount == count;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text('$count'),
                    selected: isSelected,
                    onSelected: (val) {
                      if (val) {
                        ref
                            .read(quizSetupProvider.notifier)
                            .setQuestionCount(count);
                      }
                    },
                    backgroundColor: Colors.white.withOpacity(0.05),
                    selectedColor: DesignTokens.accent,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.white70,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          // Difficulty
          _SettingRow(
            label: 'Zorluk',
            child: Row(
              children:
                  [
                    ('all', 'Karışık'),
                    ('easy', 'Kolay'),
                    ('medium', 'Orta'),
                    ('hard', 'Zor'),
                  ].map((diff) {
                    final isSelected = state.difficulty == diff.$1;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(diff.$2),
                        selected: isSelected,
                        onSelected: (val) {
                          if (val) {
                            ref
                                .read(quizSetupProvider.notifier)
                                .setDifficulty(diff.$1);
                          }
                        },
                        backgroundColor: Colors.white.withOpacity(0.05),
                        selectedColor: DesignTokens.accent,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : Colors.white70,
                        ),
                      ),
                    );
                  }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  final String label;
  final Widget child;

  const _SettingRow({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 14),
        ),
        const SizedBox(height: 8),
        child,
        const SizedBox(height: 16),
      ],
    );
  }
}

// Reusing the background from Dashboard
class _GlobalAnimatedBackground extends StatelessWidget {
  const _GlobalAnimatedBackground();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(color: const Color(0xFF0F172A)),
        // Ideally reuse the one from DashboardScreen or move to shared
      ],
    );
  }
}
