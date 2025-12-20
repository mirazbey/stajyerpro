import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/shadcn_theme.dart';
import '../../../shared/models/exam_model.dart';
import '../../../shared/models/question_model.dart';
import '../data/exam_repository.dart';
import '../domain/exam_distribution.dart';
import '../../../core/subscription/subscription_service.dart';

/// HMGS Deneme Sınavı State
class HMGSExamState {
  final List<QuestionModel> questions;
  final Map<int, int> answers; // questionIndex -> selectedOptionIndex
  final Set<int> markedQuestions; // Sonra bak işaretli sorular
  final int currentQuestionIndex;
  final int remainingSeconds;
  final bool isLoading;
  final String? attemptId;
  final Map<int, int> perQuestionDuration; // Her soruya harcanan süre
  final int currentQuestionStartTime; // Mevcut soruya başlama zamanı (saniye)

  HMGSExamState({
    required this.questions,
    required this.answers,
    required this.markedQuestions,
    required this.currentQuestionIndex,
    required this.remainingSeconds,
    this.isLoading = false,
    this.attemptId,
    this.perQuestionDuration = const {},
    this.currentQuestionStartTime = 0,
  });

  HMGSExamState copyWith({
    List<QuestionModel>? questions,
    Map<int, int>? answers,
    Set<int>? markedQuestions,
    int? currentQuestionIndex,
    int? remainingSeconds,
    bool? isLoading,
    String? attemptId,
    Map<int, int>? perQuestionDuration,
    int? currentQuestionStartTime,
  }) {
    return HMGSExamState(
      questions: questions ?? this.questions,
      answers: answers ?? this.answers,
      markedQuestions: markedQuestions ?? this.markedQuestions,
      currentQuestionIndex: currentQuestionIndex ?? this.currentQuestionIndex,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      isLoading: isLoading ?? this.isLoading,
      attemptId: attemptId ?? this.attemptId,
      perQuestionDuration: perQuestionDuration ?? this.perQuestionDuration,
      currentQuestionStartTime: currentQuestionStartTime ?? this.currentQuestionStartTime,
    );
  }

  // Hesaplamalar
  int get totalQuestions => questions.length;
  int get answeredCount => answers.length;
  int get markedCount => markedQuestions.length;
  int get emptyCount => totalQuestions - answeredCount;
  bool get isLastQuestion => currentQuestionIndex == totalQuestions - 1;
  bool get isFirstQuestion => currentQuestionIndex == 0;

  String get formattedTime {
    final hours = remainingSeconds ~/ 3600;
    final minutes = (remainingSeconds % 3600) ~/ 60;
    final seconds = remainingSeconds % 60;
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  // Renk durumu
  Color get timerColor {
    if (remainingSeconds < 300) return Colors.red; // Son 5 dk
    if (remainingSeconds < 900) return Colors.orange; // Son 15 dk
    return ShadcnColors.primary;
  }
}

/// HMGS Deneme Sınavı State Notifier
class HMGSExamNotifier extends StateNotifier<HMGSExamState?> {
  final ExamRepository _examRepository;
  Timer? _timer;
  String? _attemptId;
  DateTime? _examStartTime;

  HMGSExamNotifier(this._examRepository) : super(null);

  /// Deneme sınavını başlat
  Future<void> startExam() async {
    state = HMGSExamState(
      questions: [],
      answers: {},
      markedQuestions: {},
      currentQuestionIndex: 0,
      remainingSeconds: 150 * 60, // 150 dakika
      isLoading: true,
    );

    try {
      // HMGS dağılımına göre soruları çek
      final questions = await _examRepository.getExamQuestions('hmgs_simulation');
      
      if (questions.isEmpty) {
        throw Exception('Soru bulunamadı. Lütfen admin panelinden soru ekleyin.');
      }

      _examStartTime = DateTime.now();

      // Deneme attempt'ı kaydet
      final attempt = ExamAttemptModel(
        id: '',
        userId: _examRepository.currentUserId!,
        examId: 'hmgs_simulation',
        answers: {},
        markedQuestions: {},
        totalQuestions: questions.length,
        correctAnswers: 0,
        wrongAnswers: 0,
        emptyAnswers: questions.length,
        net: 0,
        score: 0,
        duration: Duration.zero,
        isCompleted: false,
        startedAt: _examStartTime!,
      );

      _attemptId = await _examRepository.saveExamAttempt(attempt);

      state = state!.copyWith(
        questions: questions,
        isLoading: false,
        attemptId: _attemptId,
        currentQuestionStartTime: 150 * 60,
      );

      _startTimer();
    } catch (e) {
      state = state!.copyWith(isLoading: false);
      rethrow;
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state == null) {
        timer.cancel();
        return;
      }

      final newSeconds = state!.remainingSeconds - 1;
      if (newSeconds <= 0) {
        timer.cancel();
        _autoFinishExam();
      } else {
        state = state!.copyWith(remainingSeconds: newSeconds);
      }
    });
  }

  /// Soruyu cevapla
  void answerQuestion(int optionIndex) {
    if (state == null) return;
    
    final newAnswers = Map<int, int>.from(state!.answers);
    newAnswers[state!.currentQuestionIndex] = optionIndex;
    
    state = state!.copyWith(answers: newAnswers);
  }

  /// Cevabı temizle
  void clearAnswer() {
    if (state == null) return;
    
    final newAnswers = Map<int, int>.from(state!.answers);
    newAnswers.remove(state!.currentQuestionIndex);
    
    state = state!.copyWith(answers: newAnswers);
  }

  /// Soruyu işaretle (sonra bak)
  void toggleMark() {
    if (state == null) return;
    
    final newMarked = Set<int>.from(state!.markedQuestions);
    if (newMarked.contains(state!.currentQuestionIndex)) {
      newMarked.remove(state!.currentQuestionIndex);
    } else {
      newMarked.add(state!.currentQuestionIndex);
    }
    
    state = state!.copyWith(markedQuestions: newMarked);
  }

  /// Belirli soruya git
  void goToQuestion(int index) {
    if (state == null) return;
    if (index >= 0 && index < state!.totalQuestions) {
      // Mevcut soruya harcanan süreyi kaydet
      _recordQuestionDuration();
      
      state = state!.copyWith(
        currentQuestionIndex: index,
        currentQuestionStartTime: state!.remainingSeconds,
      );
    }
  }

  /// Sonraki soru
  void nextQuestion() {
    if (state == null || state!.isLastQuestion) return;
    goToQuestion(state!.currentQuestionIndex + 1);
  }

  /// Önceki soru
  void previousQuestion() {
    if (state == null || state!.isFirstQuestion) return;
    goToQuestion(state!.currentQuestionIndex - 1);
  }

  /// İlk işaretli soruya git
  void goToFirstMarked() {
    if (state == null || state!.markedQuestions.isEmpty) return;
    final sorted = state!.markedQuestions.toList()..sort();
    goToQuestion(sorted.first);
  }

  /// İlk boş soruya git
  void goToFirstEmpty() {
    if (state == null) return;
    for (int i = 0; i < state!.totalQuestions; i++) {
      if (!state!.answers.containsKey(i)) {
        goToQuestion(i);
        return;
      }
    }
  }

  void _recordQuestionDuration() {
    if (state == null) return;
    
    final elapsed = state!.currentQuestionStartTime - state!.remainingSeconds;
    if (elapsed > 0) {
      final newDurations = Map<int, int>.from(state!.perQuestionDuration);
      final currentDuration = newDurations[state!.currentQuestionIndex] ?? 0;
      newDurations[state!.currentQuestionIndex] = currentDuration + elapsed;
      state = state!.copyWith(perQuestionDuration: newDurations);
    }
  }

  /// Sınavı bitir
  Future<Map<String, dynamic>> finishExam() async {
    if (state == null || _attemptId == null) {
      return {'error': 'Sınav bulunamadı'};
    }
    
    _timer?.cancel();
    _recordQuestionDuration();

    final elapsedSeconds = (150 * 60) - state!.remainingSeconds;

    final userAnswers = <UserAnswer>[];

    // Doğru, yanlış, boş hesapla
    int correctCount = 0;
    int wrongCount = 0;
    int emptyCount = 0;

    // Ders bazlı sonuçlar
    final Map<String, List<_QuestionResult>> subjectQuestions = {};

    for (int i = 0; i < state!.questions.length; i++) {
      final question = state!.questions[i];
      final userAnswer = state!.answers[i];
      final subjectId = question.subjectId;

      subjectQuestions.putIfAbsent(subjectId, () => []);

      if (userAnswer == null) {
        emptyCount++;
        subjectQuestions[subjectId]!.add(_QuestionResult.empty);
      } else if (userAnswer == question.correctIndex) {
        correctCount++;
        subjectQuestions[subjectId]!.add(_QuestionResult.correct);
        userAnswers.add(
          UserAnswer(
            questionId: question.id,
            selectedIndex: userAnswer,
            isCorrect: true,
            answeredAt: DateTime.now(),
            subjectId: subjectId,
            topicId: question.topicIds.isNotEmpty
                ? question.topicIds.first
                : null,
          ),
        );
      } else {
        wrongCount++;
        subjectQuestions[subjectId]!.add(_QuestionResult.wrong);
        userAnswers.add(
          UserAnswer(
            questionId: question.id,
            selectedIndex: userAnswer,
            isCorrect: false,
            answeredAt: DateTime.now(),
            subjectId: subjectId,
            topicId: question.topicIds.isNotEmpty
                ? question.topicIds.first
                : null,
          ),
        );
      }
    }

    // Net hesapla (HMGS: Doğru - Yanlış/4)
    final net = HMGSNetCalculator.calculateNet(
      correct: correctCount,
      wrong: wrongCount,
      empty: emptyCount,
    );

    // Puan hesapla (Net / 120 * 100)
    final score = HMGSNetCalculator.netToScore(net, totalQuestions: state!.totalQuestions);

    // Ders bazlı sonuçları hesapla
    final Map<String, SubjectResult> subjectResults = {};
    for (var entry in subjectQuestions.entries) {
      final subjectId = entry.key;
      final results = entry.value;
      
      final subjectCorrect = results.where((r) => r == _QuestionResult.correct).length;
      final subjectWrong = results.where((r) => r == _QuestionResult.wrong).length;
      final subjectEmpty = results.where((r) => r == _QuestionResult.empty).length;
      final subjectNet = HMGSNetCalculator.calculateNet(
        correct: subjectCorrect,
        wrong: subjectWrong,
        empty: subjectEmpty,
      );

      subjectResults[subjectId] = SubjectResult(
        subjectId: subjectId,
        subjectName: getSubjectName(subjectId),
        totalQuestions: results.length,
        correctAnswers: subjectCorrect,
        wrongAnswers: subjectWrong,
        emptyAnswers: subjectEmpty,
        net: subjectNet,
      );
    }

    // Firestore'a kaydet
    await _examRepository.updateExamAttempt(_attemptId!, {
      'answers': state!.answers.map((k, v) => MapEntry(k.toString(), v)),
      'markedQuestions': state!.markedQuestions.toList(),
      'correctAnswers': correctCount,
      'wrongAnswers': wrongCount,
      'emptyAnswers': emptyCount,
      'net': net,
      'score': score.round(),
      'durationSeconds': elapsedSeconds,
      'isCompleted': true,
      'completedAt': DateTime.now(),
      'perQuestionDuration': state!.perQuestionDuration.map((k, v) => MapEntry(k.toString(), v)),
      'subjectResults': subjectResults.map((k, v) => MapEntry(k, v.toMap())),
    });

    await _examRepository.decrementExamCredit();

    // Quiz sonucu kaydet (analytics için)
    await _examRepository.saveQuizResult(
      quizType: 'hmgs_exam',
      totalQuestions: state!.totalQuestions,
      correctAnswers: correctCount,
      duration: elapsedSeconds,
      subjectId: null,
      topicId: null,
      answers: userAnswers,
    );

    return {
      'attemptId': _attemptId,
      'correctAnswers': correctCount,
      'wrongAnswers': wrongCount,
      'emptyAnswers': emptyCount,
      'net': net,
      'score': score.round(),
      'passedBaraj': HMGSNetCalculator.passedBaraj(score),
      'subjectResults': subjectResults,
    };
  }

  void _autoFinishExam() async {
    await finishExam();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

enum _QuestionResult { correct, wrong, empty }

/// Provider
final hmgsExamProvider = StateNotifierProvider.autoDispose<HMGSExamNotifier, HMGSExamState?>((ref) {
  final repository = ref.watch(examRepositoryProvider);
  return HMGSExamNotifier(repository);
});

/// HMGS Deneme Sınavı Ekranı
class HMGSExamScreen extends ConsumerStatefulWidget {
  const HMGSExamScreen({super.key});

  @override
  ConsumerState<HMGSExamScreen> createState() => _HMGSExamScreenState();
}

class _HMGSExamScreenState extends ConsumerState<HMGSExamScreen> with WidgetsBindingObserver {
  bool _hasLeftApp = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initExam();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _hasLeftApp = true;
    } else if (state == AppLifecycleState.resumed && _hasLeftApp) {
      _hasLeftApp = false;
      _showStrictModeWarning();
    }
  }

  void _showStrictModeWarning() {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700),
            const SizedBox(width: 8),
            const Text('Dikkat!'),
          ],
        ),
        content: const Text(
          'Sınav esnasında uygulamadan çıktığınız tespit edildi.\n\n'
          'Gerçek HMGS sınavında bu davranış yasaktır. '
          'Lütfen sınav süresince uygulamadan ayrılmayınız.',
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Anlaşıldı'),
          ),
        ],
      ),
    );
  }

  Future<void> _initExam() async {
    final subscriptionService = ref.read(subscriptionServiceProvider);
    final allowed = await subscriptionService.canStartExam();
    
    if (!allowed && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Deneme hakkınız kalmadı. Pro ile sınırsız deneme çözebilirsiniz.'),
          backgroundColor: Colors.orange,
        ),
      );
      context.pop();
      return;
    }

    try {
      await ref.read(hmgsExamProvider.notifier).startExam();
      await subscriptionService.recordExamUsage();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
        );
        context.pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(hmgsExamProvider);

    if (state == null || state.isLoading) {
      return Scaffold(
        backgroundColor: ShadcnColors.background,
        appBar: AppBar(
          title: const Text('HMGS Deneme Sınavı'),
          backgroundColor: ShadcnColors.background,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                'Sorular yükleniyor...',
                style: ShadcnTypography.bodyMedium.copyWith(color: ShadcnColors.mutedForeground),
              ),
              const SizedBox(height: 8),
              Text(
                '120 soru hazırlanıyor',
                style: ShadcnTypography.bodySmall.copyWith(color: ShadcnColors.mutedForeground),
              ),
            ],
          ),
        ),
      );
    }

    if (state.questions.isEmpty) {
      return Scaffold(
        backgroundColor: ShadcnColors.background,
        appBar: AppBar(title: const Text('HMGS Deneme Sınavı')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
              const SizedBox(height: 16),
              const Text('Soru bulunamadı'),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => context.pop(),
                child: const Text('Geri Dön'),
              ),
            ],
          ),
        ),
      );
    }

    final currentQuestion = state.questions[state.currentQuestionIndex];
    final isMarked = state.markedQuestions.contains(state.currentQuestionIndex);
    final selectedAnswer = state.answers[state.currentQuestionIndex];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldExit = await _showExitDialog();
        if (shouldExit && mounted) {
          context.pop();
        }
      },
      child: Scaffold(
        backgroundColor: ShadcnColors.background,
        appBar: _buildAppBar(state, isMarked),
        body: Column(
          children: [
            // Progress bar
            _buildProgressBar(state),
            
            // Question content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Question header
                    _buildQuestionHeader(state, currentQuestion, isMarked),
                    const SizedBox(height: 16),
                    
                    // Question card
                    _buildQuestionCard(currentQuestion, selectedAnswer),
                  ],
                ),
              ),
            ),
            
            // Navigation buttons
            _buildNavigationBar(state),
          ],
        ),
        // Question navigator drawer
        endDrawer: _buildQuestionDrawer(state),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(HMGSExamState state, bool isMarked) {
    return AppBar(
      backgroundColor: ShadcnColors.background,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.close),
        onPressed: () async {
          final shouldExit = await _showExitDialog();
          if (shouldExit && mounted) {
            context.pop();
          }
        },
      ),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.assignment, size: 20),
          const SizedBox(width: 8),
          const Text('HMGS Deneme'),
        ],
      ),
      actions: [
        // Timer
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            color: state.timerColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: state.timerColor.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.timer, size: 18, color: state.timerColor),
              const SizedBox(width: 6),
              Text(
                state.formattedTime,
                style: ShadcnTypography.labelMedium.copyWith(
                  color: state.timerColor,
                  fontWeight: FontWeight.bold,
                  fontFeatures: [const FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ),
        // Question navigator button
        Builder(
          builder: (scaffoldContext) => IconButton(
            icon: Badge(
              isLabelVisible: state.markedCount > 0,
              label: Text('${state.markedCount}'),
              child: const Icon(Icons.grid_view),
            ),
            onPressed: () {
              Scaffold.of(scaffoldContext).openEndDrawer();
            },
          ),
        ),
      ],
    );
  }

  Widget _buildProgressBar(HMGSExamState state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: ShadcnColors.card,
        border: Border(bottom: BorderSide(color: ShadcnColors.border)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Soru ${state.currentQuestionIndex + 1}/${state.totalQuestions}',
                style: ShadcnTypography.labelMedium,
              ),
              Row(
                children: [
                  _buildStatChip('✓ ${state.answeredCount}', Colors.green),
                  const SizedBox(width: 8),
                  _buildStatChip('○ ${state.emptyCount}', Colors.grey),
                  const SizedBox(width: 8),
                  _buildStatChip('⚑ ${state.markedCount}', Colors.orange),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (state.currentQuestionIndex + 1) / state.totalQuestions,
              backgroundColor: ShadcnColors.muted,
              valueColor: AlwaysStoppedAnimation(ShadcnColors.primary),
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: ShadcnTypography.labelSmall.copyWith(color: color),
      ),
    );
  }

  Widget _buildQuestionHeader(HMGSExamState state, QuestionModel question, bool isMarked) {
    return Row(
      children: [
        // Subject chip
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: ShadcnColors.primaryMuted,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            getSubjectName(question.subjectId),
            style: ShadcnTypography.labelSmall.copyWith(
              color: ShadcnColors.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const Spacer(),
        // Mark button
        TextButton.icon(
          onPressed: () => ref.read(hmgsExamProvider.notifier).toggleMark(),
          icon: Icon(
            isMarked ? Icons.flag : Icons.flag_outlined,
            size: 18,
            color: isMarked ? Colors.orange : ShadcnColors.mutedForeground,
          ),
          label: Text(
            isMarked ? 'İşaretli' : 'İşaretle',
            style: ShadcnTypography.labelSmall.copyWith(
              color: isMarked ? Colors.orange : ShadcnColors.mutedForeground,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuestionCard(QuestionModel question, int? selectedAnswer) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ShadcnColors.card,
        borderRadius: ShadcnRadius.borderLg,
        border: Border.all(color: ShadcnColors.border),
        boxShadow: ShadcnShadows.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Question text
          Text(
            question.stem,
            style: ShadcnTypography.bodyLarge.copyWith(
              height: 1.6,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 24),
          
          // Options
          ...List.generate(question.options.length, (index) {
            final isSelected = selectedAnswer == index;
            final optionLetter = String.fromCharCode(65 + index); // A, B, C, D, E
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                onTap: () {
                  if (isSelected) {
                    ref.read(hmgsExamProvider.notifier).clearAnswer();
                  } else {
                    ref.read(hmgsExamProvider.notifier).answerQuestion(index);
                  }
                },
                borderRadius: ShadcnRadius.borderMd,
                child: AnimatedContainer(
                  duration: ShadcnDurations.fast,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected ? ShadcnColors.primaryMuted : ShadcnColors.background,
                    borderRadius: ShadcnRadius.borderMd,
                    border: Border.all(
                      color: isSelected ? ShadcnColors.primary : ShadcnColors.border,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Option letter
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: isSelected ? ShadcnColors.primary : ShadcnColors.muted,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            optionLetter,
                            style: ShadcnTypography.labelMedium.copyWith(
                              color: isSelected ? Colors.white : ShadcnColors.foreground,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Option text
                      Expanded(
                        child: Text(
                          question.options[index],
                          style: ShadcnTypography.bodyMedium.copyWith(
                            color: isSelected ? ShadcnColors.primary : ShadcnColors.foreground,
                            height: 1.5,
                          ),
                        ),
                      ),
                      // Check icon
                      if (isSelected)
                        Icon(Icons.check_circle, color: ShadcnColors.primary, size: 24),
                    ],
                  ),
                ),
              ),
            );
          }),
          
          // Clear answer button
          if (selectedAnswer != null) ...[
            const SizedBox(height: 8),
            Center(
              child: TextButton.icon(
                onPressed: () => ref.read(hmgsExamProvider.notifier).clearAnswer(),
                icon: const Icon(Icons.clear, size: 18),
                label: const Text('Cevabı Temizle'),
                style: TextButton.styleFrom(
                  foregroundColor: ShadcnColors.mutedForeground,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNavigationBar(HMGSExamState state) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ShadcnColors.card,
        border: Border(top: BorderSide(color: ShadcnColors.border)),
        boxShadow: ShadcnShadows.sm,
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Previous button
            Expanded(
              child: OutlinedButton.icon(
                onPressed: state.isFirstQuestion 
                    ? null 
                    : () => ref.read(hmgsExamProvider.notifier).previousQuestion(),
                icon: const Icon(Icons.arrow_back, size: 18),
                label: const Text('Önceki'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 12),
            
            // Finish button (only on last question or when all answered)
            if (state.isLastQuestion || state.answeredCount == state.totalQuestions)
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => _showFinishDialog(state),
                  icon: const Icon(Icons.check, size: 18),
                  label: const Text('Bitir'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              )
            else
              Expanded(
                flex: 2,
                child: FilledButton.icon(
                  onPressed: () => ref.read(hmgsExamProvider.notifier).nextQuestion(),
                  icon: const Icon(Icons.arrow_forward, size: 18),
                  label: const Text('Sonraki'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionDrawer(HMGSExamState state) {
    return Drawer(
      width: 320,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: ShadcnColors.card,
                border: Border(bottom: BorderSide(color: ShadcnColors.border)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Soru Navigasyonu', style: ShadcnTypography.h4),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Stats
                  Row(
                    children: [
                      _buildDrawerStat('Cevaplanan', state.answeredCount, Colors.green),
                      _buildDrawerStat('Boş', state.emptyCount, Colors.grey),
                      _buildDrawerStat('İşaretli', state.markedCount, Colors.orange),
                    ],
                  ),
                ],
              ),
            ),
            
            // Quick actions
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: state.markedCount > 0
                          ? () {
                              ref.read(hmgsExamProvider.notifier).goToFirstMarked();
                              Navigator.pop(context);
                            }
                          : null,
                      icon: const Icon(Icons.flag, size: 16),
                      label: const Text('İlk İşaretli'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.orange,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: state.emptyCount > 0
                          ? () {
                              ref.read(hmgsExamProvider.notifier).goToFirstEmpty();
                              Navigator.pop(context);
                            }
                          : null,
                      icon: const Icon(Icons.radio_button_unchecked, size: 16),
                      label: const Text('İlk Boş'),
                    ),
                  ),
                ],
              ),
            ),
            
            // Question grid
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(12),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 6,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                ),
                itemCount: state.totalQuestions,
                itemBuilder: (context, index) {
                  final isAnswered = state.answers.containsKey(index);
                  final isMarked = state.markedQuestions.contains(index);
                  final isCurrent = index == state.currentQuestionIndex;

                  Color bgColor;
                  Color borderColor;
                  Color textColor;

                  if (isCurrent) {
                    bgColor = ShadcnColors.primary;
                    borderColor = ShadcnColors.primary;
                    textColor = Colors.white;
                  } else if (isAnswered) {
                    bgColor = Colors.green.shade50;
                    borderColor = Colors.green;
                    textColor = Colors.green.shade700;
                  } else {
                    bgColor = ShadcnColors.background;
                    borderColor = ShadcnColors.border;
                    textColor = ShadcnColors.foreground;
                  }

                  return InkWell(
                    onTap: () {
                      ref.read(hmgsExamProvider.notifier).goToQuestion(index);
                      Navigator.pop(context);
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: borderColor, width: isCurrent ? 2 : 1),
                      ),
                      child: Stack(
                        children: [
                          Center(
                            child: Text(
                              '${index + 1}',
                              style: ShadcnTypography.labelSmall.copyWith(
                                color: textColor,
                                fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ),
                          if (isMarked)
                            Positioned(
                              top: 2,
                              right: 2,
                              child: Icon(Icons.flag, size: 10, color: Colors.orange),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            
            // Finish button
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _showFinishDialog(state);
                  },
                  icon: const Icon(Icons.check),
                  label: const Text('Sınavı Bitir'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerStat(String label, int count, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(
            '$count',
            style: ShadcnTypography.h3.copyWith(color: color),
          ),
          Text(
            label,
            style: ShadcnTypography.labelSmall.copyWith(color: ShadcnColors.mutedForeground),
          ),
        ],
      ),
    );
  }

  Future<bool> _showExitDialog() async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sınavdan Çık'),
        content: const Text(
          'Sınavı yarıda bırakmak istediğinize emin misiniz?\n\n'
          'Cevaplarınız kaydedilmeyecek ve deneme hakkınız düşecektir.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Çık'),
          ),
        ],
      ),
    ) ?? false;
  }

  Future<void> _showFinishDialog(HMGSExamState state) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sınavı Bitir'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Toplam ${state.totalQuestions} sorunun:',
              style: ShadcnTypography.bodyMedium,
            ),
            const SizedBox(height: 12),
            _buildFinishStat('✓ Cevaplanan', state.answeredCount, Colors.green),
            _buildFinishStat('○ Boş', state.emptyCount, Colors.grey),
            _buildFinishStat('⚑ İşaretli', state.markedCount, Colors.orange),
            const SizedBox(height: 16),
            if (state.emptyCount > 0)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber, color: Colors.orange.shade700, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${state.emptyCount} soru boş bırakılmış!',
                        style: TextStyle(color: Colors.orange.shade700),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 12),
            const Text(
              'Sınavı bitirmek istediğinize emin misiniz?',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Devam Et'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Bitir'),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Sonuçlar hesaplanıyor...'),
            ],
          ),
        ),
      );

      final examResult = await ref.read(hmgsExamProvider.notifier).finishExam();
      
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        
        if (examResult['attemptId'] != null) {
          context.go('/exam/hmgs_simulation/result/${examResult['attemptId']}');
        }
      }
    }
  }

  Widget _buildFinishStat(String label, int count, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(label, style: TextStyle(color: color)),
          const Spacer(),
          Text(
            '$count',
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
