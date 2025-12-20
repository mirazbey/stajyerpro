import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../shared/widgets/premium_glass_container.dart';
import '../../../shared/models/question_model.dart';
import '../../exam/data/exam_repository.dart';
import '../../ai_coach/data/ai_coach_repository.dart';
import '../data/quiz_repository.dart';

/// Quiz state provider
final quizStateProvider =
    StateNotifierProvider.autoDispose<QuizStateNotifier, QuizState>((ref) {
      return QuizStateNotifier();
    });

/// Quiz state
class QuizState {
  final List<QuestionModel> questions;
  final int currentQuestionIndex;
  final Map<int, int> selectedAnswers;
  final String currentDifficulty;
  final DateTime startTime;
  final bool isLoading;
  final String? error;

  QuizState({
    this.questions = const [],
    this.currentQuestionIndex = 0,
    this.selectedAnswers = const {},
    this.currentDifficulty = 'all',
    DateTime? startTime,
    this.isLoading = false,
    this.error,
  }) : startTime = startTime ?? DateTime.now();

  QuizState copyWith({
    List<QuestionModel>? questions,
    int? currentQuestionIndex,
    Map<int, int>? selectedAnswers,
    String? currentDifficulty,
    DateTime? startTime,
    bool? isLoading,
    String? error,
  }) {
    return QuizState(
      questions: questions ?? this.questions,
      currentQuestionIndex: currentQuestionIndex ?? this.currentQuestionIndex,
      selectedAnswers: selectedAnswers ?? this.selectedAnswers,
      currentDifficulty: currentDifficulty ?? this.currentDifficulty,
      startTime: startTime ?? this.startTime,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  bool get isLastQuestion => currentQuestionIndex >= questions.length - 1;
  int get totalQuestions => questions.length;
  int get answeredCount => selectedAnswers.length;
}

/// Quiz state notifier
class QuizStateNotifier extends StateNotifier<QuizState> {
  QuizStateNotifier() : super(QuizState());

  void setQuestions(List<QuestionModel> questions, {String? difficulty}) {
    state = state.copyWith(
      questions: questions,
      currentDifficulty: difficulty ?? state.currentDifficulty,
      startTime: DateTime.now(),
    );
  }

  void selectAnswer(int optionIndex) {
    final newAnswers = Map<int, int>.from(state.selectedAnswers);
    newAnswers[state.currentQuestionIndex] = optionIndex;
    state = state.copyWith(selectedAnswers: newAnswers);
  }

  void nextQuestion() {
    if (!state.isLastQuestion) {
      state = state.copyWith(
        currentQuestionIndex: state.currentQuestionIndex + 1,
      );
    }
  }

  void previousQuestion() {
    if (state.currentQuestionIndex > 0) {
      state = state.copyWith(
        currentQuestionIndex: state.currentQuestionIndex - 1,
      );
    }
  }

  void goToQuestion(int index) {
    if (index >= 0 && index < state.totalQuestions) {
      state = state.copyWith(currentQuestionIndex: index);
    }
  }

  void changeDifficulty(String newDifficulty) {
    state = state.copyWith(
      currentDifficulty: newDifficulty,
      questions: [],
      currentQuestionIndex: 0,
      selectedAnswers: {},
    );
  }
}

/// Premium Glassmorphism Quiz Screen
class QuizScreen extends ConsumerStatefulWidget {
  final List<String> topicIds;
  final int questionCount;
  final String difficulty;
  final String? mode; // 'fast', 'marathon', null for standard
  final int? timeLimit; // Saniye cinsinden süre sınırı (Fast Test için)

  const QuizScreen({
    super.key,
    required this.topicIds,
    required this.questionCount,
    required this.difficulty,
    this.preloadedQuestions,
    this.mode,
    this.timeLimit,
    this.topicName,
    this.subjectName,
  });

  final List<QuestionModel>? preloadedQuestions;
  final String? topicName;
  final String? subjectName;

  @override
  ConsumerState<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends ConsumerState<QuizScreen> {
  Timer? _timer;
  Duration _elapsed = Duration.zero;

  bool get _isFastTest => widget.mode == 'fast';
  bool get _isMarathon => widget.mode == 'marathon';

  Duration? get _remainingTime {
    if (_isFastTest && widget.timeLimit != null) {
      final limit = Duration(seconds: widget.timeLimit!);
      final remaining = limit - _elapsed;
      return remaining.isNegative ? Duration.zero : remaining;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _loadQuestions();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _elapsed = Duration(seconds: timer.tick);

          // Fast Test modunda süre kontrolü
          if (_isFastTest &&
              _remainingTime != null &&
              _remainingTime!.inSeconds <= 0) {
            _finishQuiz();
          }
        });
      }
    });
  }

  Future<void> _loadQuestions([String? difficulty]) async {
    print('🎯 [QuizScreen] _loadQuestions called');
    print('🎯 [QuizScreen] topicIds: ${widget.topicIds}');
    print('🎯 [QuizScreen] questionCount: ${widget.questionCount}');
    print('🎯 [QuizScreen] difficulty: ${widget.difficulty}');
    print('🎯 [QuizScreen] mode: ${widget.mode}');
    print(
      '🎯 [QuizScreen] preloadedQuestions: ${widget.preloadedQuestions?.length ?? 0}',
    );
    print(
      '🎯 [QuizScreen] topicName: ${widget.topicName}, subjectName: ${widget.subjectName}',
    );

    final repository = ref.read(quizRepositoryProvider);
    final examRepo = ref.read(examRepositoryProvider);
    final diffToUse = difficulty ?? widget.difficulty;

    try {
      List<QuestionModel> questions = [];

      if (widget.preloadedQuestions != null &&
          widget.preloadedQuestions!.isNotEmpty) {
        print('🎯 [QuizScreen] Using preloaded questions');
        questions = widget.preloadedQuestions!;
      } else if (_isFastTest) {
        // Hızlı Test modu: 20 rastgele soru
        print('🎯 [QuizScreen] Fast test mode - calling getFastTestQuestions');
        questions = await examRepo.getFastTestQuestions();
      } else if (_isMarathon) {
        // Maraton modu: 50 soruluk paket
        print('🎯 [QuizScreen] Marathon mode - calling getMarathonQuestions');
        questions = await examRepo.getMarathonQuestions();
      } else if (widget.topicIds.isEmpty) {
        print('🎯 [QuizScreen] No topicIds - calling getRandomQuestions');
        questions = await repository.getRandomQuestions(
          limit: widget.questionCount,
          difficulty: diffToUse,
        );
      } else {
        print('🎯 [QuizScreen] Has topicIds - calling getQuestionsByTopics');
        questions = await repository.getQuestionsByTopics(
          topicIds: widget.topicIds,
          limit: widget.questionCount,
          difficulty: diffToUse,
        );
      }

      print('🎯 [QuizScreen] Loaded ${questions.length} questions');

      // AI Fallback Logic
      if (questions.isEmpty &&
          widget.topicName != null &&
          widget.subjectName != null) {
        print('🎯 [QuizScreen] No questions found, trying AI fallback...');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Soru bulunamadı, AI Koç sizin için soru üretiyor...',
              ),
              duration: Duration(seconds: 4),
            ),
          );
        }

        try {
          final aiRepo = ref.read(aiCoachRepositoryProvider);
          final content = await aiRepo.generateTopicContentJson(
            topicName: widget.topicName!,
            subjectName: widget.subjectName!,
          );

          if (content['questions'] != null) {
            final List<dynamic> qList = content['questions'];
            questions = qList.map((q) {
              return QuestionModel(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                stem: q['text'],
                options: List<String>.from(q['options']),
                correctIndex: q['correctAnswerIndex'],
                explanation: q['explanation'],
                lawArticle: q['lawArticle'],
                source: 'AI Coach',
                subjectId: widget.subjectName!,
                topicIds: widget.topicIds,
                difficulty: diffToUse,
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              );
            }).toList();
          }
        } catch (e) {
          debugPrint('AI Generation Error: $e');
          // AI hatası durumunda sessizce devam et, aşağıda empty check yakalayacak
        }
      }

      if (questions.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Soru bulunamadı')));
          context.pop();
        }
        return;
      }

      ref
          .read(quizStateProvider.notifier)
          .setQuestions(questions, difficulty: diffToUse);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Soru yüklenirken hata: $e')));
        Future.microtask(() => context.pop());
      }
    }
  }

  Future<void> _handleDifficultyChange(String newDifficulty) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Zorluk Değiştir'),
        content: Text(
          'Zorluk seviyesini "${_getDifficultyLabel(newDifficulty)}" olarak değiştirmek istediğinize emin misiniz?\n\nİlerlemeniz sıfırlanacak.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Değiştir'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      ref.read(quizStateProvider.notifier).changeDifficulty(newDifficulty);
      _timer?.cancel();
      setState(() {
        _elapsed = Duration.zero;
      });
      _startTimer();
      await _loadQuestions(newDifficulty);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Zorluk: ${_getDifficultyLabel(newDifficulty)}'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  String _getDifficultyLabel(String difficulty) {
    switch (difficulty) {
      case 'easy':
        return 'Kolay';
      case 'medium':
        return 'Orta';
      case 'hard':
        return 'Zor';
      default:
        return 'Karışık';
    }
  }

  IconData _getDifficultyIcon(String difficulty) {
    switch (difficulty) {
      case 'easy':
        return Icons.sentiment_satisfied;
      case 'medium':
        return Icons.sentiment_neutral;
      case 'hard':
        return Icons.sentiment_very_dissatisfied;
      default:
        return Icons.shuffle;
    }
  }

  void _finishQuiz() async {
    final state = ref.read(quizStateProvider);
    final answers = <UserAnswer>[];

    for (var i = 0; i < state.questions.length; i++) {
      final question = state.questions[i];
      final selectedIndex = state.selectedAnswers[i];
      if (selectedIndex != null) {
        answers.add(
          UserAnswer(
            questionId: question.id,
            selectedIndex: selectedIndex,
            isCorrect: selectedIndex == question.correctIndex,
            answeredAt: DateTime.now(),
            subjectId: question.subjectId, // For analytics
            topicId: question.topicIds.isNotEmpty
                ? question.topicIds.first
                : null, // For weak topics
          ),
        );
      }
    }

    // Save quiz result to Firestore for analytics
    try {
      final repository = ref.read(quizRepositoryProvider);
      await repository.saveQuizResult(
        answers: answers,
        totalQuestions: state.questions.length,
        correctAnswers: answers.where((a) => a.isCorrect).length,
        duration: _elapsed,
        topicIds: widget.topicIds,
      );
    } catch (e) {
      // Ignore save errors, user can still see results
      debugPrint('Error saving quiz result: $e');
    }

    if (mounted) {
      context.push(
        '/quiz/result',
        extra: {
          'questions': state.questions,
          'answers': answers,
          'duration': _elapsed,
          'topicIds': widget.topicIds,
        },
      );
    }
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(quizStateProvider);

    if (state.questions.isEmpty) {
      return Scaffold(
        backgroundColor: DesignTokens.background,
        body: Center(
          child: CircularProgressIndicator(color: DesignTokens.primary),
        ),
      );
    }

    final currentQuestion = state.questions[state.currentQuestionIndex];
    final selectedAnswer = state.selectedAnswers[state.currentQuestionIndex];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Quiz\'den Çık'),
            content: const Text(
              'Quiz\'i bitirmeden çıkmak istediğinize emin misiniz?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Devam Et'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Çık'),
              ),
            ],
          ),
        );

        if ((shouldPop ?? false) && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        body: Stack(
          children: [
            // 1. Background Image
            Positioned.fill(
              child: Image.asset(
                'assets/images/dashboard_bg.png',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  decoration: const BoxDecoration(
                    gradient: DesignTokens.primaryGradient,
                  ),
                ),
              ),
            ),

            // Dark Overlay for Focus
            Positioned.fill(
              child: Container(
                color: DesignTokens.background.withValues(alpha: 0.85),
              ),
            ),

            // Content
            SafeArea(
              child: Column(
                children: [
                  // Top Bar
                  _buildTopBar(state),

                  // Progress Bar
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 8,
                    ),
                    child: Column(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(DesignTokens.r4),
                          child: LinearProgressIndicator(
                            value:
                                (state.currentQuestionIndex + 1) /
                                state.totalQuestions,
                            backgroundColor: Colors.white.withValues(
                              alpha: 0.1,
                            ),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              DesignTokens.primary,
                            ),
                            minHeight: 4,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              '${state.currentQuestionIndex + 1} / ${state.totalQuestions}',
                              style: GoogleFonts.spaceGrotesk(
                                color: Colors.white70,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Question & Options
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Question Card
                          _buildQuestionCard(currentQuestion),
                          const SizedBox(height: 24),

                          // Options
                          ...List.generate(currentQuestion.options.length, (
                            index,
                          ) {
                            final isSelected = selectedAnswer == index;
                            final optionLetter = String.fromCharCode(
                              65 + index,
                            );

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _OptionTile(
                                letter: optionLetter,
                                text: currentQuestion.options[index],
                                isSelected: isSelected,
                                onTap: () {
                                  ref
                                      .read(quizStateProvider.notifier)
                                      .selectAnswer(index);
                                },
                              ),
                            );
                          }),

                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
                  ),

                  // Footer
                  _buildFooter(state, selectedAnswer),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(QuizState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Difficulty Badge with Popup
          GestureDetector(
            onTap: () => _showDifficultyMenu(state),
            child: PremiumGlassContainer(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              borderRadius: DesignTokens.r20,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _getDifficultyIcon(state.currentDifficulty),
                    color: DesignTokens.accent,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _getDifficultyLabel(state.currentDifficulty),
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Timer
          Row(
            children: [
              const Icon(Icons.access_time, color: Colors.white70, size: 16),
              const SizedBox(width: 6),
              Text(
                _formatDuration(_elapsed),
                style: GoogleFonts.spaceGrotesk(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showDifficultyMenu(QuizState state) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'Zorluk Seviyesi',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            _DifficultyOption(
              icon: Icons.shuffle,
              label: 'Karışık',
              value: 'all',
              currentValue: state.currentDifficulty,
              onTap: () {
                Navigator.pop(context);
                _handleDifficultyChange('all');
              },
            ),
            _DifficultyOption(
              icon: Icons.sentiment_satisfied,
              label: 'Kolay',
              value: 'easy',
              color: Colors.green,
              currentValue: state.currentDifficulty,
              onTap: () {
                Navigator.pop(context);
                _handleDifficultyChange('easy');
              },
            ),
            _DifficultyOption(
              icon: Icons.sentiment_neutral,
              label: 'Orta',
              value: 'medium',
              color: Colors.orange,
              currentValue: state.currentDifficulty,
              onTap: () {
                Navigator.pop(context);
                _handleDifficultyChange('medium');
              },
            ),
            _DifficultyOption(
              icon: Icons.sentiment_very_dissatisfied,
              label: 'Zor',
              value: 'hard',
              color: Colors.red,
              currentValue: state.currentDifficulty,
              onTap: () {
                Navigator.pop(context);
                _handleDifficultyChange('hard');
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionCard(QuestionModel question) {
    return Stack(
      children: [
        PremiumGlassContainer(
          padding: const EdgeInsets.all(24),
          borderRadius: DesignTokens.r24,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                question.stem,
                style: GoogleFonts.spaceGrotesk(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
        // AI İpucu Baloncuğu
        Positioned(top: 8, right: 8, child: _AiTipBubble(question: question)),
      ],
    );
  }

  Widget _buildFooter(QuizState state, int? selectedAnswer) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: DesignTokens.surface.withValues(alpha: 0.9),
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
        ),
      ),
      child: Row(
        children: [
          if (state.currentQuestionIndex > 0) ...[
            Expanded(
              child: _GlassButton(
                icon: Icons.arrow_back,
                label: 'Önceki',
                onTap: () =>
                    ref.read(quizStateProvider.notifier).previousQuestion(),
              ),
            ),
            const SizedBox(width: 16),
          ],
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: selectedAnswer != null
                  ? () {
                      if (state.isLastQuestion) {
                        _finishQuiz();
                      } else {
                        ref.read(quizStateProvider.notifier).nextQuestion();
                      }
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: DesignTokens.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(DesignTokens.r16),
                ),
                elevation: 0,
                shadowColor: DesignTokens.primary.withValues(alpha: 0.5),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    state.isLastQuestion ? 'BİTİR' : 'SONRAKİ',
                    style: GoogleFonts.spaceGrotesk(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    state.isLastQuestion
                        ? Icons.check_circle
                        : Icons.arrow_forward_rounded,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Glass Option Tile
class _OptionTile extends StatelessWidget {
  final String letter;
  final String text;
  final bool isSelected;
  final VoidCallback onTap;

  const _OptionTile({
    required this.letter,
    required this.text,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: isSelected ? DesignTokens.primaryGradient : null,
          color: isSelected ? null : Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(DesignTokens.r16),
          border: Border.all(
            color: isSelected
                ? DesignTokens.primary.withValues(alpha: 0.5)
                : Colors.white.withValues(alpha: 0.05),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.2)
                    : Colors.white.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                letter,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                text,
                style: GoogleFonts.inter(
                  color: isSelected
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.9),
                  fontSize: 15,
                  height: 1.4,
                ),
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 12),
              const Icon(Icons.check_circle, color: Colors.white, size: 20),
            ],
          ],
        ),
      ),
    );
  }
}

// Glass Button
class _GlassButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _GlassButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white70, size: 16),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Difficulty Option in Bottom Sheet
class _DifficultyOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String currentValue;
  final Color? color;
  final VoidCallback onTap;

  const _DifficultyOption({
    required this.icon,
    required this.label,
    required this.value,
    required this.currentValue,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = value == currentValue;
    return InkWell(
      onTap: isSelected ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.blue.withValues(alpha: 0.1)
              : Colors.transparent,
        ),
        child: Row(
          children: [
            Icon(icon, color: color ?? Colors.white70, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
            if (isSelected)
              const Icon(Icons.check, color: Colors.blue, size: 24),
          ],
        ),
      ),
    );
  }
}

/// AI İpucu Baloncuğu Widget
class _AiTipBubble extends ConsumerStatefulWidget {
  final QuestionModel question;

  const _AiTipBubble({required this.question});

  @override
  ConsumerState<_AiTipBubble> createState() => _AiTipBubbleState();
}

class _AiTipBubbleState extends ConsumerState<_AiTipBubble> {
  String? _tip;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    // Eğer soru zaten tip içeriyorsa, onu kullan (preloaded)
    if (widget.question.aiTip != null && widget.question.aiTip!.isNotEmpty) {
      _tip = widget.question.aiTip;
    }
  }

  Future<void> _fetchTipIfNeeded() async {
    if (_tip != null || _loading) return;
    setState(() => _loading = true);
    try {
      final aiRepo = ref.read(aiCoachRepositoryProvider);
      final result = await aiRepo.getQuestionTip(question: widget.question);
      if (mounted && result != null && result.isNotEmpty) {
        setState(() {
          _tip = result;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('İpucu alınamadı: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _showTipDialog() async {
    if (_tip == null) {
      await _fetchTipIfNeeded();
    }

    final hasTip = _tip != null && _tip!.isNotEmpty;

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: DesignTokens.accent.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.lightbulb,
                color: DesignTokens.accent,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'AI İpucu',
              style: GoogleFonts.spaceGrotesk(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: hasTip
            ? Text(
                _tip!,
                style: GoogleFonts.inter(
                  color: Colors.white70,
                  fontSize: 15,
                  height: 1.5,
                ),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_loading) ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'İpucu hazırlanıyor...',
                      style: GoogleFonts.inter(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ] else ...[
                    Icon(
                      Icons.lightbulb_outline,
                      color: Colors.amber.withValues(alpha: 0.5),
                      size: 48,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Bu soru için ipucu henüz hazırlanmadı.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        color: Colors.white60,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Soruyu çözmeye devam et! 💪',
                      style: GoogleFonts.inter(
                        color: DesignTokens.accent,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ],
              ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Tamam',
              style: GoogleFonts.inter(color: DesignTokens.primary),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _showTipDialog,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: DesignTokens.accent.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: DesignTokens.accent.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _loading
                  ? Icons.autorenew
                  : (_tip != null ? Icons.lightbulb : Icons.lightbulb_outline),
              color: DesignTokens.accent,
              size: 18,
            ),
            const SizedBox(width: 4),
            Text(
              'İpucu',
              style: GoogleFonts.inter(
                color: DesignTokens.accent,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
