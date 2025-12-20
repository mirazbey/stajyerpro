import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:stajyerpro_app/core/theme/design_tokens.dart';
import 'package:stajyerpro_app/shared/models/question_model.dart';

import 'package:stajyerpro_app/features/exam/data/exam_repository.dart';
import 'package:stajyerpro_app/features/exam/presentation/widgets/question_detail_sheet.dart';

class StudyQuizScreen extends ConsumerStatefulWidget {
  final String topicId;
  final String topicName;
  final String subjectName;

  const StudyQuizScreen({
    super.key,
    required this.topicId,
    required this.topicName,
    required this.subjectName,
  });

  @override
  ConsumerState<StudyQuizScreen> createState() => _StudyQuizScreenState();
}

class _StudyQuizScreenState extends ConsumerState<StudyQuizScreen> {
  List<QuestionModel> _questions = [];
  int _currentIndex = 0;
  bool _isLoading = true;
  String? _error;
  int? _selectedAnswerIndex;
  bool _isAnswered = false;
  int _correctCount = 0;

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    try {
      final repo = ref.read(examRepositoryProvider);
      // Fetch 10 questions for this topic
      // We might need a specific method for this, or use getExamQuestions with filter
      // For now, let's assume getQuestionsByTopic exists or we use a similar logic
      // If not, we might need to add it to repository.
      // Let's try to use getExamQuestions but filtering might be tricky if it's designed for full exams.
      // Actually, ExamRepository has getExamQuestions which returns a map.
      // We need a method to get questions for a specific topic.
      // Let's assume we can fetch them. If not, I'll add the method to repository.

      // Temporary: Fetch all and filter (inefficient but works for now if dataset is small)
      // Or better, add getQuestionsByTopic to ExamRepository.
      // For this step, I will assume I need to implement getQuestionsByTopic in ExamRepository.
      // But to avoid blocking, I'll try to fetch from 'questions' collection directly here or via a new repo method.

      // Let's add the method to ExamRepository first? No, let's stick to the screen creation and mock/todo it.
      // Actually, I can use the existing repository if I can.

      // Let's assume we have a method. I'll implement it in the repository in the next step.
      final questions = await repo.getQuestionsByTopic(
        widget.topicId,
        limit: 10,
      );

      if (mounted) {
        setState(() {
          _questions = questions;
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

  void _handleAnswer(int index) {
    if (_isAnswered) return;

    setState(() {
      _selectedAnswerIndex = index;
      _isAnswered = true;
      if (index == _questions[_currentIndex].correctIndex) {
        _correctCount++;
      }
    });

    // Show explanation sheet immediately
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      enableDrag: false,
      builder: (context) => QuestionDetailSheet(
        question: _questions[_currentIndex],
        userAnswerIndex: index,
        // We can add a "Next" button inside the sheet or as a persistent footer in the sheet
        // Since QuestionDetailSheet doesn't have a next button, we might need to wrap it
        // or modify it. For now, let's wrap it in a Column with a button if possible,
        // but DraggableScrollableSheet takes full height.
        // Better approach: Modify QuestionDetailSheet to accept a custom footer or onNext callback.
        // I will modify QuestionDetailSheet in the next step.
        // For now, I'll pass a dummy callback if I modify it, or just rely on user closing it?
        // No, user needs to go to next question.
        // Let's assume I'll add 'onNext' to QuestionDetailSheet.
        onNext: _nextQuestion,
      ),
    );
  }

  void _nextQuestion() {
    Navigator.pop(context); // Close sheet
    if (_currentIndex < _questions.length - 1) {
      setState(() {
        _currentIndex++;
        _selectedAnswerIndex = null;
        _isAnswered = false;
      });
    } else {
      _showResults();
    }
  }

  void _showResults() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: Text(
          'Tebrikler! 🎉',
          style: GoogleFonts.spaceGrotesk(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          '${_questions.length} soruda $_correctCount doğru yaptın.',
          style: GoogleFonts.inter(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () {
              context.pop(); // Close dialog
              context.pop(); // Go back to topic screen
            },
            child: const Text(
              'Tamam',
              style: TextStyle(color: DesignTokens.accent),
            ),
          ),
        ],
      ),
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
          onPressed: () => context.pop(),
        ),
        title: Column(
          children: [
            Text(
              widget.subjectName,
              style: GoogleFonts.inter(color: Colors.white70, fontSize: 12),
            ),
            Text(
              'Pekiştirme Testi',
              style: GoogleFonts.spaceGrotesk(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // Background
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                ),
              ),
            ),
          ),

          SafeArea(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: DesignTokens.accent,
                    ),
                  )
                : _error != null
                ? Center(
                    child: Text(
                      _error!,
                      style: const TextStyle(color: Colors.white),
                    ),
                  )
                : _questions.isEmpty
                ? const Center(
                    child: Text(
                      'Bu konuda henüz soru yok.',
                      style: TextStyle(color: Colors.white),
                    ),
                  )
                : Column(
                    children: [
                      // Progress Bar
                      LinearProgressIndicator(
                        value: (_currentIndex + 1) / _questions.length,
                        backgroundColor: Colors.white10,
                        color: DesignTokens.accent,
                      ),

                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Question Counter
                              Text(
                                'Soru ${_currentIndex + 1}/${_questions.length}',
                                style: GoogleFonts.inter(
                                  color: DesignTokens.accent,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Question Text
                              Text(
                                _questions[_currentIndex].stem,
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontSize: 18,
                                  height: 1.5,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 32),

                              // Options
                              ...List.generate(
                                _questions[_currentIndex].options.length,
                                (index) => Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: _OptionCard(
                                    text: _questions[_currentIndex]
                                        .options[index],
                                    index: index,
                                    isSelected: _selectedAnswerIndex == index,
                                    isAnswered: _isAnswered,
                                    correctIndex:
                                        _questions[_currentIndex].correctIndex,
                                    onTap: () => _handleAnswer(index),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _OptionCard extends StatelessWidget {
  final String text;
  final int index;
  final bool isSelected;
  final bool isAnswered;
  final int correctIndex;
  final VoidCallback onTap;

  const _OptionCard({
    required this.text,
    required this.index,
    required this.isSelected,
    required this.isAnswered,
    required this.correctIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color backgroundColor = Colors.white.withValues(alpha: 0.05);
    Color borderColor = Colors.white.withValues(alpha: 0.1);
    Color textColor = Colors.white;

    if (isAnswered) {
      if (index == correctIndex) {
        backgroundColor = Colors.green.withValues(alpha: 0.2);
        borderColor = Colors.green;
      } else if (isSelected) {
        backgroundColor = Colors.red.withValues(alpha: 0.2);
        borderColor = Colors.red;
      }
    } else if (isSelected) {
      backgroundColor = DesignTokens.accent.withValues(alpha: 0.2);
      borderColor = DesignTokens.accent;
    }

    return GestureDetector(
      onTap: isAnswered ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  String.fromCharCode(65 + index),
                  style: GoogleFonts.spaceGrotesk(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                text,
                style: GoogleFonts.inter(color: textColor, fontSize: 16),
              ),
            ),
            if (isAnswered && index == correctIndex)
              const Icon(Icons.check_circle, color: Colors.green),
            if (isAnswered && isSelected && index != correctIndex)
              const Icon(Icons.cancel, color: Colors.red),
          ],
        ),
      ),
    );
  }
}
