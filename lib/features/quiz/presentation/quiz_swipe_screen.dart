import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flip_card/flip_card.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../shared/widgets/premium_glass_container.dart';
import '../../../shared/widgets/advanced_ui/advanced_ui.dart';
import '../../../shared/models/question_model.dart';
import '../../exam/data/exam_repository.dart';
import '../data/quiz_repository.dart';

/// Quiz Swipe State
class QuizSwipeState {
  final List<QuestionModel> questions;
  final int currentIndex;
  final Map<int, int> selectedAnswers;
  final Map<int, bool> answeredCorrectly;
  final DateTime startTime;
  final bool isLoading;
  final bool showingResult;

  QuizSwipeState({
    this.questions = const [],
    this.currentIndex = 0,
    this.selectedAnswers = const {},
    this.answeredCorrectly = const {},
    DateTime? startTime,
    this.isLoading = true,
    this.showingResult = false,
  }) : startTime = startTime ?? DateTime.now();

  QuizSwipeState copyWith({
    List<QuestionModel>? questions,
    int? currentIndex,
    Map<int, int>? selectedAnswers,
    Map<int, bool>? answeredCorrectly,
    DateTime? startTime,
    bool? isLoading,
    bool? showingResult,
  }) {
    return QuizSwipeState(
      questions: questions ?? this.questions,
      currentIndex: currentIndex ?? this.currentIndex,
      selectedAnswers: selectedAnswers ?? this.selectedAnswers,
      answeredCorrectly: answeredCorrectly ?? this.answeredCorrectly,
      startTime: startTime ?? this.startTime,
      isLoading: isLoading ?? this.isLoading,
      showingResult: showingResult ?? this.showingResult,
    );
  }

  int get correctCount => answeredCorrectly.values.where((v) => v).length;
  int get wrongCount => answeredCorrectly.values.where((v) => !v).length;
  double get progress => questions.isEmpty ? 0 : (currentIndex + 1) / questions.length;
}

/// Swipe Quiz State Notifier
class QuizSwipeNotifier extends StateNotifier<QuizSwipeState> {
  QuizSwipeNotifier() : super(QuizSwipeState());

  void setQuestions(List<QuestionModel> questions) {
    state = QuizSwipeState(
      questions: questions,
      isLoading: false,
      startTime: DateTime.now(),
    );
  }

  void answerQuestion(int questionIndex, int selectedOption, bool isCorrect) {
    final newAnswers = Map<int, int>.from(state.selectedAnswers);
    final newCorrectly = Map<int, bool>.from(state.answeredCorrectly);
    
    newAnswers[questionIndex] = selectedOption;
    newCorrectly[questionIndex] = isCorrect;
    
    state = state.copyWith(
      selectedAnswers: newAnswers,
      answeredCorrectly: newCorrectly,
    );
  }

  void nextQuestion() {
    if (state.currentIndex < state.questions.length - 1) {
      state = state.copyWith(currentIndex: state.currentIndex + 1);
    }
  }

  void showResult() {
    state = state.copyWith(showingResult: true);
  }
}

final quizSwipeProvider = StateNotifierProvider.autoDispose<QuizSwipeNotifier, QuizSwipeState>(
  (ref) => QuizSwipeNotifier(),
);

/// Modern Card Swipe Quiz Screen
class QuizSwipeScreen extends ConsumerStatefulWidget {
  final List<String> topicIds;
  final int questionCount;
  final String difficulty;
  final String? mode;
  final int? timeLimit;
  final List<QuestionModel>? preloadedQuestions;

  const QuizSwipeScreen({
    super.key,
    required this.topicIds,
    required this.questionCount,
    required this.difficulty,
    this.mode,
    this.timeLimit,
    this.preloadedQuestions,
  });

  @override
  ConsumerState<QuizSwipeScreen> createState() => _QuizSwipeScreenState();
}

class _QuizSwipeScreenState extends ConsumerState<QuizSwipeScreen>
    with TickerProviderStateMixin {
  Timer? _timer;
  Duration _elapsed = Duration.zero;
  late AnimationController _pulseController;
  late AnimationController _progressController;
  final CardSwiperController _cardController = CardSwiperController();
  final List<GlobalKey<FlipCardState>> _flipCardKeys = [];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    
    _loadQuestions();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    _progressController.dispose();
    _cardController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() => _elapsed = Duration(seconds: timer.tick));
        
        // Time limit check
        if (widget.timeLimit != null && _elapsed.inMinutes >= widget.timeLimit!) {
          _finishQuiz();
        }
      }
    });
  }

  Future<void> _loadQuestions() async {
    final repository = ref.read(quizRepositoryProvider);
    final examRepo = ref.read(examRepositoryProvider);

    try {
      List<QuestionModel> questions;

      if (widget.preloadedQuestions != null && widget.preloadedQuestions!.isNotEmpty) {
        questions = widget.preloadedQuestions!;
      } else if (widget.mode == 'fast') {
        questions = await examRepo.getFastTestQuestions();
      } else if (widget.mode == 'marathon') {
        questions = await examRepo.getMarathonQuestions();
      } else if (widget.topicIds.isEmpty) {
        questions = await repository.getRandomQuestions(
          limit: widget.questionCount,
          difficulty: widget.difficulty,
        );
      } else {
        questions = await repository.getQuestionsByTopics(
          topicIds: widget.topicIds,
          limit: widget.questionCount,
          difficulty: widget.difficulty,
        );
      }

      if (questions.isEmpty && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Soru bulunamadı')),
        );
        context.pop();
        return;
      }

      // Create flip card keys
      _flipCardKeys.clear();
      for (var i = 0; i < questions.length; i++) {
        _flipCardKeys.add(GlobalKey<FlipCardState>());
      }

      ref.read(quizSwipeProvider.notifier).setQuestions(questions);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e')),
        );
        context.pop();
      }
    }
  }

  bool _onSwipe(int previousIndex, int? currentIndex, CardSwiperDirection direction) {
    final state = ref.read(quizSwipeProvider);
    final selectedAnswer = state.selectedAnswers[previousIndex];
    
    if (selectedAnswer == null) {
      // Cevap seçilmeden swipe edildi - otomatik olarak yanlış say
      ref.read(quizSwipeProvider.notifier).answerQuestion(
        previousIndex,
        -1,
        false,
      );
    }
    
    if (currentIndex != null) {
      ref.read(quizSwipeProvider.notifier).nextQuestion();
    } else {
      // Kartlar bitti
      _finishQuiz();
    }
    return true;
  }

  void _onAnswer(int questionIndex, int optionIndex, bool isCorrect) {
    ref.read(quizSwipeProvider.notifier).answerQuestion(
      questionIndex,
      optionIndex,
      isCorrect,
    );

    // Flip card to show result
    if (_flipCardKeys.length > questionIndex) {
      _flipCardKeys[questionIndex].currentState?.toggleCard();
    }

    // Auto swipe after delay
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        final state = ref.read(quizSwipeProvider);
        if (state.currentIndex < state.questions.length - 1) {
          _cardController.swipe(CardSwiperDirection.right);
        } else {
          _finishQuiz();
        }
      }
    });
  }

  void _finishQuiz() async {
    final state = ref.read(quizSwipeProvider);
    final answers = <UserAnswer>[];

    for (var i = 0; i < state.questions.length; i++) {
      final question = state.questions[i];
      final selectedIndex = state.selectedAnswers[i];
      if (selectedIndex != null && selectedIndex >= 0) {
        answers.add(
          UserAnswer(
            questionId: question.id,
            selectedIndex: selectedIndex,
            isCorrect: selectedIndex == question.correctIndex,
            answeredAt: DateTime.now(),
            subjectId: question.subjectId,
            topicId: question.topicIds.isNotEmpty ? question.topicIds.first : null,
          ),
        );
      }
    }

    // Save result
    try {
      final repository = ref.read(quizRepositoryProvider);
      await repository.saveQuizResult(
        answers: answers,
        totalQuestions: state.questions.length,
        correctAnswers: state.correctCount,
        duration: _elapsed,
        topicIds: widget.topicIds,
      );
    } catch (e) {
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

  String _formatDuration(Duration d) {
    final m = d.inMinutes.toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(quizSwipeProvider);

    if (state.isLoading) {
      return Scaffold(
        backgroundColor: DesignTokens.background,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: 1.0 + (_pulseController.value * 0.1),
                    child: child,
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: DesignTokens.primaryGradient,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.quiz,
                    color: Colors.white,
                    size: 48,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Sorular Hazırlanıyor...',
                style: GoogleFonts.spaceGrotesk(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return WillPopScope(
      onWillPop: () async {
        final shouldPop = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: DesignTokens.surface,
            title: const Text('Quiz\'den Çık', style: TextStyle(color: Colors.white)),
            content: const Text(
              'Çıkmak istediğine emin misin? İlerleme kaydedilmeyecek.',
              style: TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Devam Et'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Çık', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        );
        return shouldPop ?? false;
      },
      child: Scaffold(
        body: Stack(
          children: [
            // Background
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF0F172A),
                    Color(0xFF1E293B),
                    Color(0xFF0F172A),
                  ],
                ),
              ),
            ),

            // Decorative circles
            Positioned(
              top: -100,
              right: -100,
              child: AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Container(
                    width: 300,
                    height: 300,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          DesignTokens.primary.withOpacity(0.2 * _pulseController.value),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            SafeArea(
              child: Column(
                children: [
                  // Top Bar
                  _buildTopBar(state),

                  // Progress & Stats
                  _buildProgressSection(state),

                  // Card Swiper
                  Expanded(
                    child: state.questions.isEmpty
                        ? const Center(child: Text('Soru yok'))
                        : CardSwiper(
                            controller: _cardController,
                            cardsCount: state.questions.length,
                            numberOfCardsDisplayed: math.min(3, state.questions.length),
                            backCardOffset: const Offset(0, 30),
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                            onSwipe: _onSwipe,
                            onUndo: (previousIndex, currentIndex, direction) => true,
                            cardBuilder: (context, index, horizontalOffsetPercentage, verticalOffsetPercentage) {
                              return _buildQuestionCard(
                                state.questions[index],
                                index,
                                state,
                              );
                            },
                          ),
                  ),

                  // Bottom Actions
                  _buildBottomActions(state),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(QuizSwipeState state) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Back button
          GlowCard(
            glowColor: Colors.white.withOpacity(0.1),
            child: IconButton(
              onPressed: () => Navigator.maybePop(context),
              icon: const Icon(Icons.close, color: Colors.white),
            ),
          ),
          
          const Spacer(),
          
          // Timer
          PremiumGlassContainer(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Icon(
                  Icons.timer,
                  color: widget.timeLimit != null && 
                         _elapsed.inMinutes >= (widget.timeLimit! - 2)
                      ? Colors.red
                      : Colors.white70,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  _formatDuration(_elapsed),
                  style: GoogleFonts.spaceGrotesk(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSection(QuizSwipeState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: state.progress,
              backgroundColor: Colors.white.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation<Color>(
                state.correctCount > state.wrongCount
                    ? Colors.green
                    : state.wrongCount > state.correctCount
                        ? Colors.red
                        : DesignTokens.primary,
              ),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 12),
          
          // Stats
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatBadge(
                Icons.check_circle,
                '${state.correctCount}',
                Colors.green,
              ),
              Text(
                '${state.currentIndex + 1} / ${state.questions.length}',
                style: GoogleFonts.spaceGrotesk(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              _buildStatBadge(
                Icons.cancel,
                '${state.wrongCount}',
                Colors.red,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatBadge(IconData icon, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 6),
          Text(
            value,
            style: GoogleFonts.spaceGrotesk(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(QuestionModel question, int index, QuizSwipeState state) {
    // ignore: unused_local_variable
    final isAnswered = state.selectedAnswers.containsKey(index);
    final selectedOption = state.selectedAnswers[index];
    final isCorrect = state.answeredCorrectly[index];

    return FlipCard(
      key: index < _flipCardKeys.length ? _flipCardKeys[index] : null,
      flipOnTouch: false,
      direction: FlipDirection.HORIZONTAL,
      front: _buildQuestionFront(question, index, state),
      back: _buildQuestionBack(question, selectedOption, isCorrect),
    );
  }

  Widget _buildQuestionFront(QuestionModel question, int index, QuizSwipeState state) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1E293B),
            const Color(0xFF0F172A).withOpacity(0.95),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: DesignTokens.primary.withOpacity(0.2),
            blurRadius: 20,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Question number badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                gradient: DesignTokens.primaryGradient,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Soru ${index + 1}',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Question text
            Expanded(
              flex: 2,
              child: SingleChildScrollView(
                child: Text(
                  question.stem,
                  style: GoogleFonts.spaceGrotesk(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    height: 1.5,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Options
            Expanded(
              flex: 3,
              child: AnimationLimiter(
                child: ListView.builder(
                  itemCount: question.options.length,
                  itemBuilder: (context, optionIndex) {
                    final letter = String.fromCharCode(65 + optionIndex);
                    final isSelected = state.selectedAnswers[index] == optionIndex;
                    
                    return AnimationConfiguration.staggeredList(
                      position: optionIndex,
                      duration: const Duration(milliseconds: 300),
                      child: SlideAnimation(
                        horizontalOffset: 50,
                        child: FadeInAnimation(
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _buildOptionButton(
                              letter,
                              question.options[optionIndex],
                              isSelected,
                              () {
                                final correct = optionIndex == question.correctIndex;
                                _onAnswer(index, optionIndex, correct);
                              },
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionButton(String letter, String text, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: isSelected ? DesignTokens.primaryGradient : null,
          color: isSelected ? null : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? Colors.transparent
                : Colors.white.withOpacity(0.1),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withOpacity(0.2)
                    : Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
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
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 14,
                  height: 1.3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionBack(QuestionModel question, int? selectedOption, bool? isCorrect) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isCorrect == true
              ? [Colors.green.shade900, Colors.green.shade800]
              : [Colors.red.shade900, Colors.red.shade800],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: (isCorrect == true ? Colors.green : Colors.red).withOpacity(0.3),
            blurRadius: 20,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isCorrect == true ? Icons.check_circle : Icons.cancel,
              color: Colors.white,
              size: 80,
            ),
            const SizedBox(height: 20),
            Text(
              isCorrect == true ? 'DOĞRU!' : 'YANLIŞ!',
              style: GoogleFonts.spaceGrotesk(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (isCorrect != true) ...[
              const SizedBox(height: 16),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      'Doğru Cevap:',
                      style: GoogleFonts.inter(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${String.fromCharCode(65 + question.correctIndex)}) ${question.options[question.correctIndex]}',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBottomActions(QuizSwipeState state) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Swipe hint
          Text(
            'Cevapladıktan sonra kartı kaydır →',
            style: GoogleFonts.inter(
              color: Colors.white54,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
