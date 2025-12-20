// Modern Quiz Setup Screen - Shadcn/UI Style
// Hızlı Quiz, Ders Quiz, Konu Quiz modları

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../shared/widgets/shadcn_ui.dart';
import '../../subjects/data/subjects_repository.dart';
import '../../../core/subscription/subscription_service.dart';

/// Quiz Mode Enum
enum QuizMode {
  quick,    // Hızlı Quiz - 10 rastgele soru
  subject,  // Ders Quiz - Tek ders, tüm konular
  topic,    // Konu Quiz - Seçilen konulardan
}

/// Quiz Setup State
class QuizSetupState {
  final QuizMode mode;
  final String? selectedSubjectId;
  final List<String> selectedTopicIds;
  final int questionCount;
  final String difficulty;
  final bool timedMode;
  final int timeLimit; // dakika

  const QuizSetupState({
    this.mode = QuizMode.quick,
    this.selectedSubjectId,
    this.selectedTopicIds = const [],
    this.questionCount = 10,
    this.difficulty = 'all',
    this.timedMode = false,
    this.timeLimit = 15,
  });

  QuizSetupState copyWith({
    QuizMode? mode,
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

  void setMode(QuizMode mode) {
    state = state.copyWith(
      mode: mode,
      selectedSubjectId: null,
      selectedTopicIds: [],
      questionCount: mode == QuizMode.quick ? 10 : 20,
    );
  }

  void setSubject(String? subjectId) {
    state = state.copyWith(
      selectedSubjectId: subjectId,
      selectedTopicIds: [],
    );
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

  void setQuestionCount(int count) {
    state = state.copyWith(questionCount: count);
  }

  void setDifficulty(String difficulty) {
    state = state.copyWith(difficulty: difficulty);
  }

  void setTimedMode(bool timed) {
    state = state.copyWith(timedMode: timed);
  }

  void setTimeLimit(int minutes) {
    state = state.copyWith(timeLimit: minutes);
  }

  void reset() {
    state = const QuizSetupState();
  }
}

/// Provider
final quizSetupProvider = StateNotifierProvider<QuizSetupNotifier, QuizSetupState>(
  (ref) => QuizSetupNotifier(),
);

/// Mini Exam Configuration
class MiniExamConfig {
  final int questionCount;
  final int timeLimit;
  final String subjectName;

  const MiniExamConfig({
    this.questionCount = 20,
    this.timeLimit = 25,
    this.subjectName = '',
  });
}

/// Quiz Setup Screen
class ModernQuizSetupScreen extends ConsumerStatefulWidget {
  final QuizMode? initialMode;
  final String? preSelectedSubjectId;
  final bool isMiniExam;
  final MiniExamConfig? miniExamConfig;

  const ModernQuizSetupScreen({
    super.key,
    this.initialMode,
    this.preSelectedSubjectId,
    this.isMiniExam = false,
    this.miniExamConfig,
  });

  @override
  ConsumerState<ModernQuizSetupScreen> createState() => _ModernQuizSetupScreenState();
}

class _ModernQuizSetupScreenState extends ConsumerState<ModernQuizSetupScreen> {
  @override
  void initState() {
    super.initState();
    // Apply initial settings if provided
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notifier = ref.read(quizSetupProvider.notifier);
      
      if (widget.initialMode != null) {
        notifier.setMode(widget.initialMode!);
      }
      
      if (widget.preSelectedSubjectId != null) {
        notifier.setSubject(widget.preSelectedSubjectId);
      }
      
      if (widget.isMiniExam && widget.miniExamConfig != null) {
        notifier.setQuestionCount(widget.miniExamConfig!.questionCount);
        notifier.setTimedMode(true);
        notifier.setTimeLimit(widget.miniExamConfig!.timeLimit);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final setupState = ref.watch(quizSetupProvider);
    final subjects = ref.watch(subjectsStreamProvider);

    return Scaffold(
      backgroundColor: ShadcnColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: ShadcnIconButton(
          icon: Icons.arrow_back,
          onPressed: () => context.pop(),
        ),
        title: Text(
          widget.isMiniExam 
              ? 'Mini Sınav - ${widget.miniExamConfig?.subjectName ?? ''}'
              : 'Quiz Oluştur', 
          style: ShadcnTypography.h4,
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Mini Exam Info Banner
              if (widget.isMiniExam) ...[
                _buildMiniExamBanner(),
                const SizedBox(height: 24),
              ],

              // Mode Selection (hidden for mini exam)
              if (!widget.isMiniExam) ...[
                _buildModeSelection(context, ref, setupState),
                const SizedBox(height: 24),
              ],

              // Subject Selection (for subject/topic mode, hidden for mini exam)
              if (!widget.isMiniExam && setupState.mode != QuizMode.quick) ...[
                _buildSubjectSelection(context, ref, setupState, subjects),
                const SizedBox(height: 24),
              ],

              // Topic Selection (for topic mode)
              if (!widget.isMiniExam && setupState.mode == QuizMode.topic && 
                  setupState.selectedSubjectId != null) ...[
                _buildTopicSelection(context, ref, setupState),
                const SizedBox(height: 24),
              ],

              // Question Count (hidden for mini exam - fixed at 20)
              if (!widget.isMiniExam) ...[
                _buildQuestionCount(context, ref, setupState),
                const SizedBox(height: 24),
              ],

              // Difficulty Selection
              _buildDifficultySelection(context, ref, setupState),
              const SizedBox(height: 24),

              // Timer Settings (hidden for mini exam - fixed at 25 min)
              if (!widget.isMiniExam) ...[
                _buildTimerSettings(context, ref, setupState),
                const SizedBox(height: 32),
              ] else ...[
                const SizedBox(height: 16),
              ],

              // Start Button
              _buildStartButton(context, ref, setupState),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMiniExamBanner() {
    return ShadcnCard(
      variant: ShadcnCardVariant.gradient,
      gradient: LinearGradient(
        colors: [
          ShadcnColors.warning.withOpacity(0.2),
          ShadcnColors.warning.withOpacity(0.05),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: ShadcnColors.warning.withOpacity(0.2),
              borderRadius: ShadcnRadius.borderMd,
            ),
            child: const Icon(
              Icons.assignment,
              color: ShadcnColors.warning,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mini Sınav Modu',
                  style: ShadcnTypography.labelLarge.copyWith(
                    color: ShadcnColors.warning,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${widget.miniExamConfig?.questionCount ?? 20} soru • ${widget.miniExamConfig?.timeLimit ?? 25} dakika',
                  style: ShadcnTypography.bodySmall.copyWith(
                    color: ShadcnColors.mutedForeground,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.timer,
            color: ShadcnColors.warning,
            size: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildModeSelection(
    BuildContext context,
    WidgetRef ref,
    QuizSetupState state,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Quiz Modu', style: ShadcnTypography.h4),
        const SizedBox(height: 4),
        Text(
          'Nasıl çalışmak istiyorsun?',
          style: ShadcnTypography.bodySmall.copyWith(
            color: ShadcnColors.mutedForeground,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _ModeCard(
                icon: Icons.bolt,
                title: 'Hızlı Quiz',
                subtitle: '10 rastgele soru',
                isSelected: state.mode == QuizMode.quick,
                color: ShadcnColors.warning,
                onTap: () => ref.read(quizSetupProvider.notifier).setMode(QuizMode.quick),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ModeCard(
                icon: Icons.menu_book,
                title: 'Ders Quiz',
                subtitle: 'Tek dersten',
                isSelected: state.mode == QuizMode.subject,
                color: ShadcnColors.info,
                onTap: () => ref.read(quizSetupProvider.notifier).setMode(QuizMode.subject),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ModeCard(
                icon: Icons.topic,
                title: 'Konu Quiz',
                subtitle: 'Seçilen konular',
                isSelected: state.mode == QuizMode.topic,
                color: ShadcnColors.success,
                onTap: () => ref.read(quizSetupProvider.notifier).setMode(QuizMode.topic),
              ),
            ),
          ],
        ),
      ],
    ).animate().fadeIn().slideY(begin: 0.05);
  }

  Widget _buildSubjectSelection(
    BuildContext context,
    WidgetRef ref,
    QuizSetupState state,
    AsyncValue subjects,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Ders Seç', style: ShadcnTypography.h4),
        const SizedBox(height: 12),
        subjects.when(
          data: (subjectList) => Wrap(
            spacing: 8,
            runSpacing: 8,
            children: (subjectList as List).map<Widget>((subject) {
              final isSelected = state.selectedSubjectId == subject.id;
              return GestureDetector(
                onTap: () => ref.read(quizSetupProvider.notifier).setSubject(subject.id),
                child: AnimatedContainer(
                  duration: ShadcnDurations.fast,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? ShadcnColors.primary 
                        : ShadcnColors.secondary,
                    borderRadius: ShadcnRadius.borderMd,
                    border: Border.all(
                      color: isSelected 
                          ? ShadcnColors.primary 
                          : ShadcnColors.border,
                    ),
                  ),
                  child: Text(
                    subject.name,
                    style: ShadcnTypography.labelMedium.copyWith(
                      color: isSelected 
                          ? ShadcnColors.primaryForeground 
                          : ShadcnColors.foreground,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => const Text('Dersler yüklenemedi'),
        ),
      ],
    ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.05);
  }

  Widget _buildTopicSelection(
    BuildContext context,
    WidgetRef ref,
    QuizSetupState state,
  ) {
    final topicsAsync = ref.watch(
      topicsBySubjectStreamProvider(state.selectedSubjectId!),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Konuları Seç', style: ShadcnTypography.h4),
            if (state.selectedTopicIds.isNotEmpty)
              ShadcnBadge(
                text: '${state.selectedTopicIds.length} seçili',
                variant: ShadcnBadgeVariant.default_,
              ),
          ],
        ),
        const SizedBox(height: 12),
        topicsAsync.when(
          data: (topics) => Wrap(
            spacing: 8,
            runSpacing: 8,
            children: (topics as List).map<Widget>((topic) {
              final isSelected = state.selectedTopicIds.contains(topic.id);
              return GestureDetector(
                onTap: () => ref.read(quizSetupProvider.notifier).toggleTopic(topic.id),
                child: AnimatedContainer(
                  duration: ShadcnDurations.fast,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? ShadcnColors.primaryMuted 
                        : ShadcnColors.secondary,
                    borderRadius: ShadcnRadius.borderMd,
                    border: Border.all(
                      color: isSelected 
                          ? ShadcnColors.primary 
                          : ShadcnColors.border,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isSelected)
                        const Padding(
                          padding: EdgeInsets.only(right: 6),
                          child: Icon(
                            Icons.check,
                            size: 14,
                            color: ShadcnColors.primary,
                          ),
                        ),
                      Text(
                        topic.name,
                        style: ShadcnTypography.labelSmall.copyWith(
                          color: isSelected 
                              ? ShadcnColors.primary 
                              : ShadcnColors.foreground,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => const Text('Konular yüklenemedi'),
        ),
      ],
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.05);
  }

  Widget _buildQuestionCount(
    BuildContext context,
    WidgetRef ref,
    QuizSetupState state,
  ) {
    final counts = state.mode == QuizMode.quick 
        ? [5, 10, 15] 
        : [10, 20, 30, 50];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Soru Sayısı', style: ShadcnTypography.h4),
        const SizedBox(height: 12),
        Row(
          children: counts.map((count) {
            final isSelected = state.questionCount == count;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: count != counts.last ? 8 : 0,
                ),
                child: GestureDetector(
                  onTap: () => ref.read(quizSetupProvider.notifier).setQuestionCount(count),
                  child: AnimatedContainer(
                    duration: ShadcnDurations.fast,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected 
                          ? ShadcnColors.primary 
                          : ShadcnColors.secondary,
                      borderRadius: ShadcnRadius.borderMd,
                      border: Border.all(
                        color: isSelected 
                            ? ShadcnColors.primary 
                            : ShadcnColors.border,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '$count',
                        style: ShadcnTypography.labelLarge.copyWith(
                          color: isSelected 
                              ? ShadcnColors.primaryForeground 
                              : ShadcnColors.foreground,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.05);
  }

  Widget _buildDifficultySelection(
    BuildContext context,
    WidgetRef ref,
    QuizSetupState state,
  ) {
    final difficulties = [
      ('all', 'Karışık', Icons.shuffle, ShadcnColors.info),
      ('easy', 'Kolay', Icons.sentiment_satisfied, ShadcnColors.success),
      ('medium', 'Orta', Icons.sentiment_neutral, ShadcnColors.warning),
      ('hard', 'Zor', Icons.sentiment_dissatisfied, ShadcnColors.error),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Zorluk Seviyesi', style: ShadcnTypography.h4),
        const SizedBox(height: 12),
        Row(
          children: difficulties.map((d) {
            final isSelected = state.difficulty == d.$1;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: d != difficulties.last ? 8 : 0,
                ),
                child: GestureDetector(
                  onTap: () => ref.read(quizSetupProvider.notifier).setDifficulty(d.$1),
                  child: AnimatedContainer(
                    duration: ShadcnDurations.fast,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected 
                          ? d.$4.withOpacity(0.2) 
                          : ShadcnColors.secondary,
                      borderRadius: ShadcnRadius.borderMd,
                      border: Border.all(
                        color: isSelected ? d.$4 : ShadcnColors.border,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          d.$3,
                          size: 20,
                          color: isSelected ? d.$4 : ShadcnColors.mutedForeground,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          d.$2,
                          style: ShadcnTypography.labelSmall.copyWith(
                            color: isSelected ? d.$4 : ShadcnColors.foreground,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.05);
  }

  Widget _buildTimerSettings(
    BuildContext context,
    WidgetRef ref,
    QuizSetupState state,
  ) {
    final card = ShadcnCard(
      variant: ShadcnCardVariant.outline,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.timer_outlined,
                    size: 20,
                    color: ShadcnColors.mutedForeground,
                  ),
                  const SizedBox(width: 8),
                  Text('Zamanlı Mod', style: ShadcnTypography.labelLarge),
                ],
              ),
              ShadcnSwitch(
                value: state.timedMode,
                onChanged: (v) => ref.read(quizSetupProvider.notifier).setTimedMode(v),
              ),
            ],
          ),
          if (state.timedMode) ...[
            const SizedBox(height: 16),
            ShadcnSlider(
              value: state.timeLimit.toDouble(),
              min: 5,
              max: 60,
              divisions: 11,
              label: 'Süre',
              showValue: false,
              onChanged: (v) => ref.read(quizSetupProvider.notifier).setTimeLimit(v.round()),
            ),
            const SizedBox(height: 8),
            Text(
              '${state.timeLimit} dakika',
              style: ShadcnTypography.bodyMedium.copyWith(
                color: ShadcnColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
    return Animate(
      effects: [
        FadeEffect(delay: 500.ms, duration: ShadcnDurations.normal),
        SlideEffect(begin: const Offset(0, 0.05), end: Offset.zero, delay: 500.ms, duration: ShadcnDurations.normal),
      ],
      child: card,
    );
  }

  Widget _buildStartButton(
    BuildContext context,
    WidgetRef ref,
    QuizSetupState state,
  ) {
    final canStart = _canStartQuiz(state);

    return ShadcnButton(
      text: 'Quiz\'i Başlat',
      icon: Icons.play_arrow,
      variant: ShadcnButtonVariant.primary,
      size: ShadcnButtonSize.lg,
      width: double.infinity,
      isDisabled: !canStart,
      onPressed: () => _startQuiz(context, ref, state),
    ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.1);
  }

  bool _canStartQuiz(QuizSetupState state) {
    switch (state.mode) {
      case QuizMode.quick:
        return true;
      case QuizMode.subject:
        return state.selectedSubjectId != null;
      case QuizMode.topic:
        return state.selectedSubjectId != null && 
               state.selectedTopicIds.isNotEmpty;
    }
  }

  Future<void> _startQuiz(
    BuildContext context, 
    WidgetRef ref,
    QuizSetupState state,
  ) async {
    final subscriptionService = ref.read(subscriptionServiceProvider);
    final allowed = await subscriptionService.canStartQuiz(state.questionCount);
    
    if (!allowed) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Günlük soru limitine ulaştın. Pro ile sınırsız erişim sağla.'),
          ),
        );
      }
      return;
    }

    if (context.mounted) {
      context.push('/quiz/start', extra: {
        'mode': state.mode.name,
        'topicIds': state.selectedTopicIds,
        'questionCount': state.questionCount,
        'difficulty': state.difficulty == 'all' ? 'all' : state.difficulty,
        'timeLimit': state.timedMode ? state.timeLimit : null,
      });
    }
  }
}

/// Mode Selection Card
class _ModeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _ModeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: ShadcnDurations.fast,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected 
              ? color.withOpacity(0.15) 
              : ShadcnColors.card,
          borderRadius: ShadcnRadius.borderLg,
          border: Border.all(
            color: isSelected ? color : ShadcnColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected 
                    ? color.withOpacity(0.2) 
                    : ShadcnColors.secondary,
                borderRadius: ShadcnRadius.borderMd,
              ),
              child: Icon(
                icon,
                size: 24,
                color: isSelected ? color : ShadcnColors.mutedForeground,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: ShadcnTypography.labelMedium.copyWith(
                color: isSelected ? color : ShadcnColors.foreground,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: ShadcnTypography.labelSmall.copyWith(
                color: ShadcnColors.mutedForeground,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
