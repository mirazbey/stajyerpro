import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../shared/widgets/premium_glass_container.dart';
import '../../../shared/widgets/gradient_button.dart';
import '../../../shared/models/lesson_step_model.dart';
import '../../ai_coach/data/ai_coach_repository.dart';

/// Mikro-öğrenme ekranı
/// Hap Bilgi → 2 Soru → Hap Bilgi → 2 Soru döngüsü
class TopicLessonScreen extends ConsumerStatefulWidget {
  final String topicId;
  final String topicName;
  final String subjectName;
  final String subjectId;

  const TopicLessonScreen({
    super.key,
    required this.topicId,
    required this.topicName,
    required this.subjectName,
    required this.subjectId,
  });

  @override
  ConsumerState<TopicLessonScreen> createState() => _TopicLessonScreenState();
}

class _TopicLessonScreenState extends ConsumerState<TopicLessonScreen> {
  // State
  List<LessonStepModel> _steps = [];
  int _currentStepIndex = 0;
  bool _isLoading = true;
  String? _error;

  // Quiz state
  bool _showingQuiz = false;
  int _currentQuestionIndex = 0;
  int _correctAnswers = 0;
  int _totalQuestionsAnswered = 0;

  // Feedback after each question
  bool _showingFeedback = false;
  bool _lastAnswerCorrect = false;

  @override
  void initState() {
    super.initState();
    _loadLessonSteps();
  }

  Future<void> _loadLessonSteps() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Önce Firestore'dan topic_lessons'ı kontrol et
      final firestore = FirebaseFirestore.instance;
      final lessonDoc = await firestore
          .collection('topic_lessons')
          .doc(widget.topicId)
          .get();

      if (lessonDoc.exists) {
        // Firestore'dan mevcut dersi yükle
        final data = lessonDoc.data()!;
        final stepsData = data['steps'] as List<dynamic>? ?? [];
        final questionsData = data['practiceQuestions'] as List<dynamic>? ?? [];

        final steps = <LessonStepModel>[];

        for (int i = 0; i < stepsData.length; i++) {
          final stepData = stepsData[i] as Map<String, dynamic>;

          // Her adıma 2 soru ata (eğer yeterliyse)
          final stepQuestions = <StepQuestion>[];
          final questionsPerStep = 2;
          final startIdx = i * questionsPerStep;
          final endIdx = (startIdx + questionsPerStep).clamp(
            0,
            questionsData.length,
          );

          for (int q = startIdx; q < endIdx; q++) {
            final qData = questionsData[q] as Map<String, dynamic>;
            final options = qData['options'] as Map<String, dynamic>? ?? {};
            final optionsList = ['A', 'B', 'C', 'D']
                .map((key) => options[key]?.toString() ?? '')
                .where((o) => o.isNotEmpty)
                .toList();

            final correctAnswer = qData['correctAnswer']?.toString() ?? 'A';
            final correctIndex = ['A', 'B', 'C', 'D'].indexOf(correctAnswer);

            stepQuestions.add(
              StepQuestion(
                id: 'q_${i}_$q',
                questionText: qData['question']?.toString() ?? '',
                options: optionsList,
                correctIndex: correctIndex >= 0 ? correctIndex : 0,
                explanation: qData['explanation']?.toString(),
              ),
            );
          }

          steps.add(
            LessonStepModel(
              stepNumber: stepData['stepNumber'] ?? (i + 1),
              title: stepData['title']?.toString() ?? 'Adım ${i + 1}',
              content: stepData['content']?.toString() ?? '',
              questions: stepQuestions,
            ),
          );
        }

        if (mounted) {
          setState(() {
            _steps = steps;
            _isLoading = false;
          });
        }
        return;
      }

      // Firestore'da yoksa AI'dan oluştur (fallback)
      final aiRepo = ref.read(aiCoachRepositoryProvider);
      final steps = await aiRepo.generateLessonSteps(
        topicName: widget.topicName,
        subjectName: widget.subjectName,
        stepCount: 5,
        questionsPerStep: 2,
      );

      if (mounted) {
        setState(() {
          _steps = steps;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  LessonStepModel? get _currentStep =>
      _steps.isNotEmpty && _currentStepIndex < _steps.length
      ? _steps[_currentStepIndex]
      : null;

  double get _overallProgress {
    if (_steps.isEmpty) return 0;
    return (_currentStepIndex + (_showingQuiz ? 0.5 : 0)) / _steps.length;
  }

  void _startQuiz() {
    final step = _currentStep;
    // Soru yoksa direkt sonraki adıma geç
    if (step == null || step.questions.isEmpty) {
      _goToNextStep();
      return;
    }
    setState(() {
      _showingQuiz = true;
      _currentQuestionIndex = 0;
    });
  }

  void _goToNextStep() {
    setState(() {
      if (_currentStepIndex < _steps.length - 1) {
        _currentStepIndex++;
        _showingQuiz = false;
        _currentQuestionIndex = 0;
      } else {
        // Tüm ders bitti
        _navigateToCompletion();
      }
    });
  }

  void _answerQuestion(int answerIndex) {
    final step = _currentStep;
    if (step == null ||
        step.questions.isEmpty ||
        _currentQuestionIndex >= step.questions.length) {
      return;
    }
    final question = step.questions[_currentQuestionIndex];
    final isCorrect = answerIndex == question.correctIndex;

    setState(() {
      _showingFeedback = true;
      _lastAnswerCorrect = isCorrect;
      _totalQuestionsAnswered++;
      if (isCorrect) _correctAnswers++;

      // Update question with user's answer
      _steps[_currentStepIndex] = step.copyWith(
        questions: step.questions.map((q) {
          if (q.id == question.id) {
            return q.copyWith(userAnswer: answerIndex);
          }
          return q;
        }).toList(),
      );
    });
  }

  void _nextAfterFeedback() {
    final step = _currentStep;
    if (step == null) {
      _navigateToCompletion();
      return;
    }

    setState(() {
      _showingFeedback = false;

      if (_currentQuestionIndex < step.questions.length - 1) {
        // Sonraki soruya geç
        _currentQuestionIndex++;
      } else {
        // Bu adımın soruları bitti
        _steps[_currentStepIndex] = step.copyWith(isCompleted: true);

        if (_currentStepIndex < _steps.length - 1) {
          // Sonraki adıma geç
          _currentStepIndex++;
          _showingQuiz = false;
          _currentQuestionIndex = 0;
        } else {
          // Tüm ders bitti - feedback ekranına git
          _navigateToCompletion();
        }
      }
    });
  }

  void _navigateToCompletion() {
    context.pushReplacement(
      '/subjects/${widget.subjectId}/topics/${widget.topicId}/complete',
      extra: {
        'topicName': widget.topicName,
        'subjectName': widget.subjectName,
        'correctAnswers': _correctAnswers,
        'totalQuestions': _totalQuestionsAnswered,
        'stepCount': _steps.length,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => _showExitDialog(),
        ),
        title: Column(
          children: [
            Text(
              widget.subjectName,
              style: GoogleFonts.inter(color: Colors.white70, fontSize: 11),
            ),
            Text(
              widget.topicName,
              style: GoogleFonts.spaceGrotesk(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          if (_steps.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Text(
                  '${_currentStepIndex + 1}/${_steps.length}',
                  style: GoogleFonts.spaceGrotesk(
                    color: DesignTokens.accent,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Stack(
        children: [
          // Background
          _buildBackground(),

          // Content
          SafeArea(
            child: _isLoading
                ? _buildLoading()
                : _error != null
                ? _buildError()
                : _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildBackground() {
    return Positioned.fill(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0F172A), Color(0xFF1E293B), Color(0xFF0F172A)],
          ),
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: DesignTokens.accent),
          const SizedBox(height: 24),
          Text(
            'Ders hazırlanıyor...',
            style: GoogleFonts.inter(color: Colors.white70),
          ),
          const SizedBox(height: 8),
          Text(
            'Hap bilgiler ve sorular oluşturuluyor',
            style: GoogleFonts.inter(color: Colors.white38, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
            const SizedBox(height: 16),
            Text(
              'Ders yüklenemedi',
              style: GoogleFonts.spaceGrotesk(
                color: Colors.white,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: GoogleFonts.inter(color: Colors.white70, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            GradientButton(
              text: 'Tekrar Dene',
              onPressed: _loadLessonSteps,
              icon: Icons.refresh,
              width: 200,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      children: [
        // Progress bar
        _buildProgressBar(),

        // Main content
        Expanded(
          child: _showingFeedback
              ? _buildFeedback()
              : _showingQuiz
              ? _buildQuiz()
              : _buildLessonContent(),
        ),
      ],
    );
  }

  Widget _buildProgressBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        children: [
          // Overall progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: _overallProgress,
              backgroundColor: Colors.white.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation<Color>(DesignTokens.accent),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 12),
          // Step indicators
          Row(
            children: List.generate(_steps.length, (index) {
              final isCompleted =
                  index < _currentStepIndex ||
                  (index == _currentStepIndex && _steps[index].isCompleted);
              final isCurrent = index == _currentStepIndex;

              return Expanded(
                child: Container(
                  height: 4,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? DesignTokens.success
                        : isCurrent
                        ? DesignTokens.accent
                        : Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          // Step label
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _showingQuiz
                    ? 'Pekiştirme Soruları'
                    : 'Hap Bilgi ${_currentStepIndex + 1}',
                style: GoogleFonts.inter(color: Colors.white60, fontSize: 12),
              ),
              Row(
                children: [
                  Text(
                    '%${(_overallProgress * 100).toInt()}',
                    style: GoogleFonts.spaceGrotesk(
                      color: DesignTokens.accent,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Icon(
                    Icons.check_circle,
                    size: 14,
                    color: DesignTokens.success.withOpacity(0.7),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$_correctAnswers/$_totalQuestionsAnswered doğru',
                    style: GoogleFonts.inter(
                      color: Colors.white60,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLessonContent() {
    final step = _currentStep;
    if (step == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: PremiumGlassContainer(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Step title
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: DesignTokens.accent.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Adım ${_currentStepIndex + 1}',
                          style: GoogleFonts.spaceGrotesk(
                            color: DesignTokens.accent,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          step.title,
                          style: GoogleFonts.spaceGrotesk(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Content
                  MarkdownBody(
                    data: step.content,
                    styleSheet: _markdownStyleSheet,
                  ),
                ],
              ),
            ),
          ),
        ),

        // Continue button
        Padding(
          padding: const EdgeInsets.all(16),
          child: GradientButton(
            text: 'Pekiştirme Sorularına Geç',
            onPressed: _startQuiz,
            icon: Icons.quiz,
            width: double.infinity,
          ),
        ),
      ],
    );
  }

  Widget _buildQuiz() {
    final step = _currentStep;
    if (step == null ||
        step.questions.isEmpty ||
        _currentQuestionIndex >= step.questions.length) {
      return const Center(
        child: Text('Soru bulunamadı', style: TextStyle(color: Colors.white)),
      );
    }
    final question = step.questions[_currentQuestionIndex];

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Question card
                PremiumGlassContainer(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: DesignTokens.primary.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'Soru ${_currentQuestionIndex + 1}/${step.questions.length}',
                              style: GoogleFonts.spaceGrotesk(
                                color: DesignTokens.primary,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        question.questionText,
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 16,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Options
                ...List.generate(question.options.length, (index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildOptionButton(
                      option: question.options[index],
                      index: index,
                      onTap: () => _answerQuestion(index),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOptionButton({
    required String option,
    required int index,
    required VoidCallback onTap,
  }) {
    final letters = ['A', 'B', 'C', 'D', 'E'];

    return GestureDetector(
      onTap: onTap,
      child: PremiumGlassContainer(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: DesignTokens.accent.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: DesignTokens.accent.withOpacity(0.3)),
              ),
              child: Center(
                child: Text(
                  letters[index],
                  style: GoogleFonts.spaceGrotesk(
                    color: DesignTokens.accent,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                option,
                style: GoogleFonts.inter(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 15,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeedback() {
    final step = _currentStep;
    if (step == null ||
        step.questions.isEmpty ||
        _currentQuestionIndex >= step.questions.length) {
      return const SizedBox.shrink();
    }
    final question = step.questions[_currentQuestionIndex];
    final isLast =
        _currentQuestionIndex >= step.questions.length - 1 &&
        _currentStepIndex >= _steps.length - 1;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Result icon
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: _lastAnswerCorrect
                        ? DesignTokens.success.withOpacity(0.2)
                        : Colors.redAccent.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _lastAnswerCorrect
                        ? Icons.check_rounded
                        : Icons.close_rounded,
                    color: _lastAnswerCorrect
                        ? DesignTokens.success
                        : Colors.redAccent,
                    size: 48,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _lastAnswerCorrect ? 'Doğru!' : 'Yanlış',
                  style: GoogleFonts.spaceGrotesk(
                    color: _lastAnswerCorrect
                        ? DesignTokens.success
                        : Colors.redAccent,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),

                // Explanation
                if (question.explanation != null)
                  PremiumGlassContainer(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.lightbulb_outline,
                              color: DesignTokens.accent,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Açıklama',
                              style: GoogleFonts.spaceGrotesk(
                                color: DesignTokens.accent,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          question.explanation!,
                          style: GoogleFonts.inter(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 15,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),

        // Continue button
        Padding(
          padding: const EdgeInsets.all(16),
          child: GradientButton(
            text: isLast ? 'Dersi Tamamla' : 'Devam Et',
            onPressed: _nextAfterFeedback,
            icon: isLast ? Icons.check_circle : Icons.arrow_forward,
            width: double.infinity,
          ),
        ),
      ],
    );
  }

  void _showExitDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Dersten Çık',
          style: GoogleFonts.spaceGrotesk(color: Colors.white),
        ),
        content: Text(
          'İlerlemeniz kaydedilmeyecek. Çıkmak istediğinizden emin misiniz?',
          style: GoogleFonts.inter(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Vazgeç',
              style: GoogleFonts.inter(color: Colors.white60),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.pop();
            },
            child: Text(
              'Çık',
              style: GoogleFonts.inter(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
  }

  MarkdownStyleSheet get _markdownStyleSheet {
    return MarkdownStyleSheet(
      p: GoogleFonts.inter(
        color: Colors.white.withOpacity(0.9),
        fontSize: 15,
        height: 1.6,
      ),
      h1: GoogleFonts.spaceGrotesk(
        color: DesignTokens.accent,
        fontSize: 22,
        fontWeight: FontWeight.bold,
      ),
      h2: GoogleFonts.spaceGrotesk(
        color: const Color(0xFF60A5FA),
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
      h3: GoogleFonts.spaceGrotesk(
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
      listBullet: GoogleFonts.inter(color: DesignTokens.accent, fontSize: 15),
      strong: GoogleFonts.inter(
        color: DesignTokens.accent,
        fontWeight: FontWeight.bold,
      ),
      em: GoogleFonts.inter(color: Colors.white70, fontStyle: FontStyle.italic),
      blockquote: GoogleFonts.inter(
        color: Colors.white70,
        fontStyle: FontStyle.italic,
        fontSize: 14,
      ),
      blockquoteDecoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: const Border(
          left: BorderSide(color: DesignTokens.accent, width: 4),
        ),
      ),
      blockquotePadding: const EdgeInsets.all(12),
    );
  }
}
