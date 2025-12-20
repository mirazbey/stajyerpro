/// Mikro-öğrenme adımı modeli
/// Her adım: Hap Bilgi + 2 Soru içerir
class LessonStepModel {
  final int stepNumber;
  final String title;
  final String content; // Markdown formatında hap bilgi
  final List<StepQuestion> questions; // 2 soru
  final bool isCompleted;

  LessonStepModel({
    required this.stepNumber,
    required this.title,
    required this.content,
    required this.questions,
    this.isCompleted = false,
  });

  LessonStepModel copyWith({
    int? stepNumber,
    String? title,
    String? content,
    List<StepQuestion>? questions,
    bool? isCompleted,
  }) {
    return LessonStepModel(
      stepNumber: stepNumber ?? this.stepNumber,
      title: title ?? this.title,
      content: content ?? this.content,
      questions: questions ?? this.questions,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}

/// Adım sorusu modeli
class StepQuestion {
  final String id;
  final String questionText;
  final List<String> options;
  final int correctIndex;
  final String? explanation;
  final int? userAnswer;

  StepQuestion({
    required this.id,
    required this.questionText,
    required this.options,
    required this.correctIndex,
    this.explanation,
    this.userAnswer,
  });

  bool get isAnswered => userAnswer != null;
  bool get isCorrect => userAnswer == correctIndex;

  StepQuestion copyWith({
    String? id,
    String? questionText,
    List<String>? options,
    int? correctIndex,
    String? explanation,
    int? userAnswer,
  }) {
    return StepQuestion(
      id: id ?? this.id,
      questionText: questionText ?? this.questionText,
      options: options ?? this.options,
      correctIndex: correctIndex ?? this.correctIndex,
      explanation: explanation ?? this.explanation,
      userAnswer: userAnswer,
    );
  }
}

/// Ders ilerleme durumu
class LessonProgress {
  final String topicId;
  final int currentStep;
  final int totalSteps;
  final int correctAnswers;
  final int totalQuestions;
  final bool isCompleted;
  final DateTime? completedAt;

  LessonProgress({
    required this.topicId,
    required this.currentStep,
    required this.totalSteps,
    required this.correctAnswers,
    required this.totalQuestions,
    this.isCompleted = false,
    this.completedAt,
  });

  double get progressPercent => totalSteps > 0 ? currentStep / totalSteps : 0;
  double get scorePercent => totalQuestions > 0 ? correctAnswers / totalQuestions : 0;

  Map<String, dynamic> toMap() {
    return {
      'topicId': topicId,
      'currentStep': currentStep,
      'totalSteps': totalSteps,
      'correctAnswers': correctAnswers,
      'totalQuestions': totalQuestions,
      'isCompleted': isCompleted,
      'completedAt': completedAt?.toIso8601String(),
    };
  }

  factory LessonProgress.fromMap(Map<String, dynamic> map) {
    return LessonProgress(
      topicId: map['topicId'] ?? '',
      currentStep: map['currentStep'] ?? 0,
      totalSteps: map['totalSteps'] ?? 0,
      correctAnswers: map['correctAnswers'] ?? 0,
      totalQuestions: map['totalQuestions'] ?? 0,
      isCompleted: map['isCompleted'] ?? false,
      completedAt: map['completedAt'] != null 
          ? DateTime.parse(map['completedAt']) 
          : null,
    );
  }
}
