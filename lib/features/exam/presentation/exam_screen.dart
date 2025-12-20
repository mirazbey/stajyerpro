import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/models/exam_model.dart';
import '../../../shared/models/question_model.dart';
import '../data/exam_repository.dart';
import '../../../core/subscription/subscription_service.dart';

class ExamState {
  final ExamModel exam;
  final List<QuestionModel> questions;
  final Map<String, int> answers; // questionId -> selectedOptionIndex
  final int currentQuestionIndex;
  final int remainingSeconds;
  final bool isLoading;
  final String? attemptId;

  ExamState({
    required this.exam,
    required this.questions,
    required this.answers,
    required this.currentQuestionIndex,
    required this.remainingSeconds,
    this.isLoading = false,
    this.attemptId,
  });

  ExamState copyWith({
    ExamModel? exam,
    List<QuestionModel>? questions,
    Map<String, int>? answers,
    int? currentQuestionIndex,
    int? remainingSeconds,
    bool? isLoading,
    String? attemptId,
  }) {
    return ExamState(
      exam: exam ?? this.exam,
      questions: questions ?? this.questions,
      answers: answers ?? this.answers,
      currentQuestionIndex: currentQuestionIndex ?? this.currentQuestionIndex,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      isLoading: isLoading ?? this.isLoading,
      attemptId: attemptId ?? this.attemptId,
    );
  }

  int get totalQuestions => questions.length;
  int get answeredCount => answers.length;
  bool get isCompleted => answeredCount == totalQuestions;

  String get formattedTime {
    final hours = remainingSeconds ~/ 3600;
    final minutes = (remainingSeconds % 3600) ~/ 60;
    final seconds = remainingSeconds % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}

class ExamStateNotifier extends StateNotifier<ExamState?> {
  final ExamRepository _examRepository;
  Timer? _timer;
  String? _attemptId;

  ExamStateNotifier(this._examRepository) : super(null);

  Future<void> loadExam(String examId) async {
    final exam = await _examRepository.getExamById(examId);
    if (exam == null) throw Exception('Deneme bulunamadı');

    final questions = await _examRepository.getExamQuestions(examId);

    state = ExamState(
      exam: exam,
      questions: questions,
      answers: {},
      currentQuestionIndex: 0,
      remainingSeconds: exam.durationMinutes * 60,
    );

    final attempt = ExamAttemptModel(
      id: '',
      userId: _examRepository.currentUserId!,
      examId: examId,
      answers: {},
      totalQuestions: questions.length,
      correctAnswers: 0,
      score: 0,
      duration: Duration.zero,
      isCompleted: false,
      startedAt: DateTime.now(),
    );

    _attemptId = await _examRepository.saveExamAttempt(attempt);
    state = state!.copyWith(attemptId: _attemptId);
    _startTimer();
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

  void answerQuestion(String questionId, int optionIndex) {
    if (state == null) return;
    final newAnswers = Map<String, int>.from(state!.answers);
    newAnswers[questionId] = optionIndex;
    state = state!.copyWith(answers: newAnswers);
  }

  void goToQuestion(int index) {
    if (state == null) return;
    if (index >= 0 && index < state!.totalQuestions) {
      state = state!.copyWith(currentQuestionIndex: index);
    }
  }

  void nextQuestion() {
    if (state == null) return;
    if (state!.currentQuestionIndex < state!.totalQuestions - 1) {
      state = state!.copyWith(
        currentQuestionIndex: state!.currentQuestionIndex + 1,
      );
    }
  }

  void previousQuestion() {
    if (state == null) return;
    if (state!.currentQuestionIndex > 0) {
      state = state!.copyWith(
        currentQuestionIndex: state!.currentQuestionIndex - 1,
      );
    }
  }

  Future<void> finishExam() async {
    if (state == null || _attemptId == null) return;
    _timer?.cancel();
    final elapsedSeconds =
        (state!.exam.durationMinutes * 60) - state!.remainingSeconds;

    int correctCount = 0;
    for (var question in state!.questions) {
      final userAnswer = state!.answers[question.id];
      if (userAnswer != null && userAnswer == question.correctIndex) {
        correctCount++;
      }
    }

    final score = (correctCount / state!.totalQuestions * 100).round();

    await _examRepository.updateExamAttempt(_attemptId!, {
      'answers': state!.answers,
      'correctAnswers': correctCount,
      'score': score,
      'durationSeconds': elapsedSeconds,
      'isCompleted': true,
      'updatedAt': DateTime.now(),
    });

    await _examRepository.decrementExamCredit();
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

final examStateProvider =
    StateNotifierProvider.family<ExamStateNotifier, ExamState?, String>((
      ref,
      examId,
    ) {
      final repository = ref.watch(examRepositoryProvider);
      final notifier = ExamStateNotifier(repository);
      notifier.loadExam(examId);
      return notifier;
    });

class ExamScreen extends ConsumerStatefulWidget {
  final String examId;

  const ExamScreen({super.key, required this.examId});

  @override
  ConsumerState<ExamScreen> createState() => _ExamScreenState();
}

class _ExamScreenState extends ConsumerState<ExamScreen>
    with WidgetsBindingObserver {
  bool _showQuestionGrid = false;
  bool _isInitializing = true;
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
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
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
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange),
            SizedBox(width: 8),
            Text('Dikkat!'),
          ],
        ),
        content: const Text(
          'Sınav esnasında uygulamadan çıktığınız tespit edildi.\n\n'
          'Gerçek sınav simülasyonu için lütfen sınav süresince uygulamadan ayrılmayınız.',
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
    if (!allowed) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Free plan aylık deneme hakkı doldu. Pro ile sınırsız deneme çözebilirsiniz.',
            ),
          ),
        );
        context.pop();
      }
      return;
    }

    await ref
        .read(examStateProvider(widget.examId).notifier)
        .loadExam(widget.examId);
    await subscriptionService.recordExamUsage();

    if (mounted) {
      setState(() {
        _isInitializing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return Scaffold(
        appBar: AppBar(title: const Text('Deneme Sınavı')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final state = ref.watch(examStateProvider(widget.examId));

    if (state == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Deneme Sınavı')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final currentQuestion = state.questions[state.currentQuestionIndex];

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        final shouldExit = await _showExitDialog(context);
        if (shouldExit && context.mounted) {
          context.pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(state.exam.name),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => _showExitDialog(context),
          ),
          actions: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: state.remainingSeconds < 600
                    ? Colors.red.shade100
                    : Colors.green.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                state.formattedTime,
                style: TextStyle(
                  color: state.remainingSeconds < 600
                      ? Colors.red
                      : Colors.green,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(context, state),
                    const SizedBox(height: 16),
                    _buildQuestionCard(context, currentQuestion),
                  ],
                ),
              ),
            ),
            _buildNavigationButtons(context, state),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            setState(() {
              _showQuestionGrid = !_showQuestionGrid;
            });
          },
          child: Icon(_showQuestionGrid ? Icons.close : Icons.grid_view),
        ),
        bottomSheet: _showQuestionGrid
            ? _buildQuestionGrid(context, state)
            : null,
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ExamState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Soru ${state.currentQuestionIndex + 1}/${state.totalQuestions}',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: (state.currentQuestionIndex + 1) / state.totalQuestions,
        ),
      ],
    );
  }

  Widget _buildQuestionGrid(BuildContext context, ExamState state) {
    return Container(
      height: 240,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: GridView.builder(
        itemCount: state.totalQuestions,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 6,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
        ),
        itemBuilder: (context, index) {
          final answered = state.answers.containsKey(state.questions[index].id);
          final isCurrent = index == state.currentQuestionIndex;
          return InkWell(
            onTap: () {
              ref
                  .read(examStateProvider(widget.examId).notifier)
                  .goToQuestion(index);
              setState(() {
                _showQuestionGrid = false;
              });
            },
            child: Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: answered
                    ? Colors.green.shade100
                    : isCurrent
                    ? Colors.blue.shade100
                    : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isCurrent ? Colors.blue : Colors.grey.shade300,
                ),
              ),
              child: Text('${index + 1}'),
            ),
          );
        },
      ),
    );
  }

  Widget _buildQuestionCard(BuildContext context, QuestionModel question) {
    final notifier = ref.read(examStateProvider(widget.examId).notifier);
    final state = ref.read(examStateProvider(widget.examId));

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              question.stem,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...List.generate(question.options.length, (index) {
              final isSelected = state?.answers[question.id] == index;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  onTap: () {
                    notifier.answerQuestion(question.id, index);
                    setState(() {});
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected ? Colors.blue : Colors.grey.shade300,
                      ),
                      color: isSelected
                          ? Colors.blue.shade50
                          : Colors.transparent,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isSelected
                              ? Icons.radio_button_checked
                              : Icons.radio_button_off,
                          color: isSelected ? Colors.blue : Colors.grey,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            question.options[index],
                            style: const TextStyle(fontSize: 15, height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationButtons(BuildContext context, ExamState state) {
    final isLastQuestion =
        state.currentQuestionIndex == state.totalQuestions - 1;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (state.currentQuestionIndex > 0)
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  ref
                      .read(examStateProvider(widget.examId).notifier)
                      .previousQuestion();
                },
                icon: const Icon(Icons.arrow_back),
                label: const Text('Önceki'),
              ),
            ),
          if (state.currentQuestionIndex > 0) const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: FilledButton.icon(
              onPressed: () async {
                if (isLastQuestion) {
                  final shouldFinish = await _showFinishDialog(context, state);
                  if (shouldFinish && context.mounted) {
                    await ref
                        .read(examStateProvider(widget.examId).notifier)
                        .finishExam();
                    if (context.mounted && state.attemptId != null) {
                      context.go(
                        '/exam/${widget.examId}/result/${state.attemptId}',
                      );
                    }
                  }
                } else {
                  ref
                      .read(examStateProvider(widget.examId).notifier)
                      .nextQuestion();
                }
              },
              icon: Icon(isLastQuestion ? Icons.check : Icons.arrow_forward),
              label: Text(isLastQuestion ? 'Sınavı Bitir' : 'Sonraki'),
            ),
          ),
        ],
      ),
    );
  }

  Future<bool> _showExitDialog(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Sınavdan Çık'),
            content: const Text(
              'Sınavı yarıda bırakmak istediğinize emin misiniz? İşlemeniz kaydedilmeyecek.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('İptal'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Çık'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<bool> _showFinishDialog(BuildContext context, ExamState state) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Sınavı Bitir'),
            content: Text(
              'Toplam ${state.totalQuestions} sorunun ${state.answeredCount} tanesini cevapladınız.\n\n'
              'Sınavı bitirmek istediğinize emin misiniz?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('İptal'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Bitir'),
              ),
            ],
          ),
        ) ??
        false;
  }
}
