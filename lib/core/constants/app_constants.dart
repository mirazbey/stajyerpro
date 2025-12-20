class AppConstants {
  // App Info
  static const String appName = 'StajyerPro';
  static const String appVersion = '1.0.0';
  
  // Firebase Collections
  static const String usersCollection = 'users';
  static const String subjectsCollection = 'subjects';
  static const String topicsCollection = 'topics';
  static const String questionsCollection = 'questions';
  static const String examsCollection = 'exams';
  static const String examAttemptsCollection = 'exam_attempts';
  static const String dailyStatsCollection = 'daily_stats';
  
  // Limits
  static const int freeDailyQuestionLimit = 40;
  static const int freeAiExplanationLimit = 5;
  static const int proDailyQuestionLimit = 999;
  static const int proAiExplanationLimit = 200;
  
  // Target Roles
  static const List<String> targetRoles = [
    'Avukatlık',
    'Hakimlik',
    'Savcılık',
    'Noterlik',
  ];
  
  // Study Intensity
  static const Map<String, String> studyIntensity = {
    'light': 'Hafif (20-30 soru/gün)',
    'medium': 'Orta (40-60 soru/gün)',
    'intense': 'Yoğun (80+ soru/gün)',
  };
}
