import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stajyerpro_app/core/preferences/preferences_repository.dart';
import 'package:stajyerpro_app/core/router/main_layout.dart';
import 'package:stajyerpro_app/shared/widgets/advanced_ui/advanced_ui.dart';
import 'package:stajyerpro_app/features/admin/presentation/admin_dashboard_screen.dart';
import 'package:stajyerpro_app/features/admin/presentation/question_list_screen.dart';
import 'package:stajyerpro_app/features/admin/presentation/question_editor_screen.dart';
import 'package:stajyerpro_app/features/admin/presentation/content_generator_screen.dart';
import 'package:stajyerpro_app/features/admin/presentation/admin_screen.dart';
import 'package:stajyerpro_app/features/ai_coach/presentation/ai_chat_screen.dart';
import 'package:stajyerpro_app/features/analytics/presentation/analytics_screen.dart';
import 'package:stajyerpro_app/features/analytics/presentation/weak_topics_screen.dart';
import 'package:stajyerpro_app/features/auth/data/auth_repository.dart';
import 'package:stajyerpro_app/features/auth/presentation/login_screen.dart';
import 'package:stajyerpro_app/features/auth/presentation/register_screen.dart';
import 'package:stajyerpro_app/features/dashboard/presentation/dashboard_screen.dart'
    show DashboardScreen, todayStatsProvider;
import 'package:stajyerpro_app/features/exam/presentation/exam_list_screen.dart';
import 'package:stajyerpro_app/features/exam/presentation/exam_result_screen.dart';
import 'package:stajyerpro_app/features/exam/presentation/exam_screen.dart';
import 'package:stajyerpro_app/features/exam/presentation/exam_store_screen.dart';
import 'package:stajyerpro_app/features/exam/presentation/hmgs_exam_screen.dart';
import 'package:stajyerpro_app/features/exam/presentation/hmgs_exam_result_screen.dart';
import 'package:stajyerpro_app/features/onboarding/presentation/splash_intro_screen.dart';
import 'package:stajyerpro_app/features/profile/presentation/onboarding_screen.dart';
import 'package:stajyerpro_app/features/quiz/presentation/quiz_result_screen.dart';
import 'package:stajyerpro_app/features/quiz/presentation/quiz_screen.dart';
import 'package:stajyerpro_app/features/quiz/presentation/quiz_setup_flow_screen.dart';
import 'package:stajyerpro_app/features/quiz/presentation/modern_quiz_setup_screen.dart';
import 'package:stajyerpro_app/features/quiz/presentation/study_modes_screen.dart';
import 'package:stajyerpro_app/features/quiz/presentation/wrong_answers_screen.dart';
import 'package:stajyerpro_app/features/gamification/presentation/badges_screen.dart';
import 'package:stajyerpro_app/features/gamification/presentation/leaderboard_screen.dart';
import 'package:stajyerpro_app/features/profile/presentation/profile_screen.dart';
import 'package:stajyerpro_app/features/notifications/presentation/notification_center_screen.dart';
import 'package:stajyerpro_app/features/settings/presentation/settings_screen.dart';
import 'package:stajyerpro_app/features/study_plan/presentation/study_plan_list_screen.dart';
import 'package:stajyerpro_app/features/study_plan/presentation/create_study_plan_screen.dart';
import 'package:stajyerpro_app/features/study_plan/presentation/personalized_study_plan_screen.dart';
import 'package:stajyerpro_app/features/subjects/presentation/subjects_screen.dart';
import 'package:stajyerpro_app/features/subjects/presentation/topic_detail_screen.dart';
import 'package:stajyerpro_app/features/subjects/presentation/topic_study_screen.dart';
import 'package:stajyerpro_app/features/subjects/presentation/topic_lesson_screen.dart';
import 'package:stajyerpro_app/features/subjects/presentation/lesson_complete_screen.dart';
import 'package:stajyerpro_app/features/subjects/presentation/study_quiz_screen.dart';
import 'package:stajyerpro_app/features/subscription/presentation/paywall_screen.dart';
import 'package:stajyerpro_app/shared/models/question_model.dart';
import 'package:stajyerpro_app/features/topic_map/presentation/topic_map_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authRepo = ref.read(authRepositoryProvider);
  final prefs = PreferencesRepository();

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: GoRouterRefreshStream(authRepo.authStateChanges),
    redirect: (context, state) async {
      final isSplash = state.matchedLocation == '/splash';
      final isAuth = state.matchedLocation.startsWith('/auth');
      final isLoggedIn = authRepo.currentUser != null;
      final onboardingCompleted = await prefs.isOnboardingCompleted();

      if (!onboardingCompleted && !isSplash) {
        return '/splash';
      }

      if (onboardingCompleted && isSplash) {
        return isLoggedIn ? '/dashboard' : '/auth/login';
      }

      if (!isSplash && !isAuth && !isLoggedIn) {
        return '/auth/login';
      }

      if (isAuth && isLoggedIn) {
        return '/dashboard';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => const SplashIntroScreen(),
      ),
      GoRoute(path: '/auth', redirect: (context, state) => '/auth/login'),
      GoRoute(
        path: '/auth/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/auth/register',
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),

      // Main App Shell with Bottom Nav
      ShellRoute(
        builder: (context, state, child) {
          return MainLayout(child: child);
        },
        routes: [
          GoRoute(
            path: '/dashboard',
            name: 'dashboard',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/subjects',
            name: 'subjects',
            builder: (context, state) => const SubjectsScreen(),
          ),
          GoRoute(
            path: '/analytics',
            name: 'analytics',
            builder: (context, state) => const AnalyticsScreen(),
          ),
          GoRoute(
            path: '/profile',
            name: 'profile',
            builder: (context, state) => const ProfileScreen(),
          ),
          GoRoute(
            path: '/settings',
            name: 'settings',
            builder: (context, state) => const SettingsScreen(),
          ),
          GoRoute(
            path: '/notifications',
            name: 'notifications',
            builder: (context, state) => const NotificationCenterScreen(),
          ),
          GoRoute(
            path: '/exams',
            name: 'exams',
            builder: (context, state) => const ExamListScreen(),
          ),
        ],
      ),

      // Other Routes (No Bottom Nav)
      // Ders seçildiğinde konulara yönlendir
      GoRoute(
        path: '/subjects/:subjectId',
        name: 'subject-detail',
        redirect: (context, state) {
          final subjectId = state.pathParameters['subjectId']!;
          return '/subjects/$subjectId/topics';
        },
      ),
      GoRoute(
        path: '/subjects/:subjectId/topics',
        name: 'topics',
        builder: (context, state) {
          final subjectId = state.pathParameters['subjectId']!;
          return TopicDetailScreen(subjectId: subjectId);
        },
      ),
      GoRoute(
        path: '/subjects/:subjectId/topics/:topicId/study',
        name: 'topic-study',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return TopicStudyScreen(
            topicId: state.pathParameters['topicId']!,
            topicName: extra['topicName']!,
            subjectName: extra['subjectName']!,
            subjectId: state.pathParameters['subjectId']!,
          );
        },
      ),
      // Mikro-öğrenme ders ekranı (5 Hap Bilgi + 2'şer Soru döngüsü)
      GoRoute(
        path: '/subjects/:subjectId/topics/:topicId/lesson',
        name: 'topic-lesson',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return TopicLessonScreen(
            topicId: state.pathParameters['topicId']!,
            topicName: extra['topicName']!,
            subjectName: extra['subjectName']!,
            subjectId: state.pathParameters['subjectId']!,
          );
        },
      ),
      // Ders tamamlama / feedback ekranı
      GoRoute(
        path: '/subjects/:subjectId/topics/:topicId/complete',
        name: 'topic-complete',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return LessonCompleteScreen(
            topicId: state.pathParameters['topicId']!,
            topicName: extra['topicName'] as String,
            subjectName: extra['subjectName'] as String,
            subjectId: state.pathParameters['subjectId']!,
            correctAnswers: extra['correctAnswers'] as int,
            totalQuestions: extra['totalQuestions'] as int,
            stepCount: extra['stepCount'] as int,
          );
        },
      ),
      GoRoute(
        path: '/subjects/:subjectId/topics/:topicId/quiz',
        name: 'topic-quiz',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return StudyQuizScreen(
            topicId: state.pathParameters['topicId']!,
            topicName: extra['topicName']!,
            subjectName: extra['subjectName']!,
          );
        },
      ),
      // Mini Sınav - 20 soru, 25 dakika, ders bazlı
      GoRoute(
        path: '/subjects/:subjectId/mini-exam',
        name: 'mini-exam',
        builder: (context, state) {
          final subjectId = state.pathParameters['subjectId']!;
          final extra = state.extra as Map<String, dynamic>?;
          return ModernQuizSetupScreen(
            initialMode: QuizMode.subject,
            preSelectedSubjectId: subjectId,
            isMiniExam: true,
            miniExamConfig: MiniExamConfig(
              questionCount: 20,
              timeLimit: 25,
              subjectName: extra?['subjectName'] as String? ?? '',
            ),
          );
        },
      ),
      GoRoute(
        path: '/quiz/modes',
        name: 'quiz-modes',
        builder: (context, state) => const StudyModesScreen(),
      ),
      // Modern Quiz Setup - Shadcn UI
      GoRoute(
        path: '/quiz/modern-setup',
        name: 'quiz-modern-setup',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return ModernQuizSetupScreen(
            initialMode: extra?['mode'] as QuizMode?,
            preSelectedSubjectId: extra?['subjectId'] as String?,
          );
        },
      ),
      GoRoute(
        path: '/quiz/setup',
        name: 'quiz-setup',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final preSelected = extra?['topicIds'] as List<String>?;
          final initialMode = extra?['initialMode'] as QuizFlowMode?;

          return QuizSetupFlowScreen(
            preSelectedTopicIds: preSelected,
            initialMode: initialMode,
          );
        },
      ),
      GoRoute(
        path: '/quiz/start',
        name: 'quiz-start',
        pageBuilder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return CustomTransitionPage(
            key: state.pageKey,
            child: QuizScreen(
              topicIds: List<String>.from(extra['topicIds'] ?? []),
              questionCount: extra['questionCount'] as int? ?? 20,
              difficulty: extra['difficulty'] as String? ?? 'all',
              mode: extra['mode'] as String?,
              timeLimit: extra['timeLimit'] as int?,
              preloadedQuestions: extra['questions'] != null
                  ? List<QuestionModel>.from(extra['questions'])
                  : null,
              topicName: extra['topicName'] as String?,
              subjectName: extra['subjectName'] as String?,
            ),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  return GooeyPageTransition(
                    animation: animation,
                    child: child,
                  );
                },
          );
        },
      ),
      GoRoute(
        path: '/quiz/result',
        name: 'quiz-result',
        pageBuilder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return CustomTransitionPage(
            key: state.pageKey,
            child: QuizResultScreen(
              questions: List<QuestionModel>.from(extra['questions'] ?? []),
              answers: List<UserAnswer>.from(extra['answers'] ?? []),
              duration: extra['duration'] as Duration? ?? Duration.zero,
              topicIds: List<String>.from(extra['topicIds'] ?? []),
            ),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  return GooeyPageTransition(
                    animation: animation,
                    blobColor: const Color(0xFF10B981), // Green for results
                    child: child,
                  );
                },
          );
        },
      ),
      GoRoute(
        path: '/badges/:userId',
        name: 'badges',
        builder: (context, state) {
          final userId = state.pathParameters['userId']!;
          return BadgesScreen(userId: userId);
        },
      ),
      GoRoute(
        path: '/leaderboard',
        name: 'leaderboard',
        builder: (context, state) => const LeaderboardScreen(),
      ),
      // HMGS Deneme Sınavı - Yeni Modern Ekran
      GoRoute(
        path: '/exam/hmgs/start',
        name: 'hmgs-exam-start',
        pageBuilder: (context, state) {
          return CustomTransitionPage(
            key: state.pageKey,
            child: const HMGSExamScreen(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  return GooeyPageTransition(
                    animation: animation,
                    blobColor: const Color(0xFF8B5CF6), // Purple for exams
                    child: child,
                  );
                },
          );
        },
      ),
      GoRoute(
        path: '/exam/hmgs_simulation/result/:attemptId',
        name: 'hmgs-exam-result',
        pageBuilder: (context, state) {
          final attemptId = state.pathParameters['attemptId']!;
          return CustomTransitionPage(
            key: state.pageKey,
            child: HMGSExamResultScreen(
              examId: 'hmgs_simulation',
              attemptId: attemptId,
            ),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  return GooeyPageTransition(
                    animation: animation,
                    blobColor: const Color(0xFF10B981), // Green for results
                    child: child,
                  );
                },
          );
        },
      ),
      // Eski exam route'ları (geriye uyumluluk için)
      GoRoute(
        path: '/exam/:examId/start',
        name: 'exam-start',
        builder: (context, state) {
          final examId = state.pathParameters['examId']!;
          // HMGS simulation için yeni ekrana yönlendir
          if (examId == 'hmgs_simulation') {
            return const HMGSExamScreen();
          }
          return ExamScreen(examId: examId);
        },
      ),
      GoRoute(
        path: '/exam/:examId/result/:attemptId',
        name: 'exam-result',
        builder: (context, state) {
          final examId = state.pathParameters['examId']!;
          final attemptId = state.pathParameters['attemptId']!;
          return ExamResultScreen(examId: examId, attemptId: attemptId);
        },
      ),
      GoRoute(
        path: '/ai-coach',
        name: 'ai-coach',
        builder: (context, state) => const AIChatScreen(),
      ),
      GoRoute(
        path: '/analytics/weak-topics',
        name: 'weak-topics',
        builder: (context, state) => const WeakTopicsScreen(),
      ),
      GoRoute(
        path: '/ai-coach/:sessionId',
        name: 'ai-coach-session',
        builder: (context, state) {
          final sessionId = state.pathParameters['sessionId']!;
          return AIChatScreen(sessionId: sessionId);
        },
      ),
      GoRoute(
        path: '/paywall',
        name: 'paywall',
        builder: (context, state) => const PaywallScreen(),
      ),
      GoRoute(
        path: '/admin',
        name: 'admin',
        builder: (context, state) => const AdminDashboardScreen(),
        routes: [
          GoRoute(
            path: 'questions',
            builder: (context, state) => const QuestionListScreen(),
            routes: [
              GoRoute(
                path: 'new',
                builder: (context, state) => const QuestionEditorScreen(),
              ),
              GoRoute(
                path: 'edit',
                builder: (context, state) {
                  final question = state.extra as QuestionModel;
                  return QuestionEditorScreen(question: question);
                },
              ),
            ],
          ),
          GoRoute(
            path: 'generator',
            builder: (context, state) => const ContentGeneratorScreen(),
          ),
          GoRoute(
            path: 'rag',
            builder: (context, state) => const AdminScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/study-plan',
        name: 'study-plan',
        builder: (context, state) => const StudyPlanListScreen(),
        routes: [
          GoRoute(
            path: 'create',
            name: 'create-study-plan',
            builder: (context, state) => const CreateStudyPlanScreen(),
          ),
          GoRoute(
            path: 'active',
            name: 'active-study-plan',
            builder: (context, state) => const PersonalizedStudyPlanScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/exam-store',
        name: 'exam-store',
        builder: (context, state) => const ExamStoreScreen(),
      ),
      GoRoute(
        path: '/wrong-answers',
        name: 'wrong-answers',
        builder: (context, state) => const WrongAnswersScreen(),
      ),
      GoRoute(
        path: '/topic-map',
        name: 'topic-map',
        builder: (context, state) => const TopicMapScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text(
              '404 - Sayfa Bulunamadi',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              state.uri.toString(),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 24),
            TextButton.icon(
              onPressed: () => context.go('/dashboard'),
              icon: const Icon(Icons.home),
              label: const Text('Ana sayfaya don'),
            ),
          ],
        ),
      ),
    ),
  );
});

class GoRouterRefreshStream extends ChangeNotifier {
  late final StreamSubscription<dynamic> _subscription;

  GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.asBroadcastStream().listen((_) {
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
