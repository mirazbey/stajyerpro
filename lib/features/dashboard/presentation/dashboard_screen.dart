import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/services/notification_service.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../shared/widgets/premium_glass_container.dart';
import '../../../shared/widgets/animated_stat_card.dart';
import '../../profile/data/profile_repository.dart';
import '../../quiz/data/quiz_repository.dart';
import '../../notifications/data/notification_repository.dart';
import '../../../shared/widgets/bento_grid/bento_grid.dart';
import 'widgets/smart_suggestion_card.dart';

/// Günlük istatistik sağlayıcı
final todayStatsProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final repo = ref.read(quizRepositoryProvider);
  return repo.getTodayStats();
});

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen>
    with SingleTickerProviderStateMixin {
  bool _initialLoadComplete = false;
  int _tokenRetryCount = 0;
  late AnimationController _floatingController;

  @override
  void initState() {
    super.initState();
    _floatingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _initDashboard();
  }

  @override
  void dispose() {
    _floatingController.dispose();
    super.dispose();
  }

  Future<void> _initDashboard() async {
    bool tokenReady = false;
    while (!tokenReady && _tokenRetryCount < 10 && mounted) {
      _tokenRetryCount++;
      try {
        await FirebaseAuth.instance.currentUser?.getIdToken(true);
        final testDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(FirebaseAuth.instance.currentUser?.uid)
            .get();

        if (testDoc.exists || testDoc.metadata.isFromCache) {
          tokenReady = true;
        } else {
          await Future.delayed(const Duration(seconds: 1));
        }
      } catch (e) {
        if (e.toString().contains('permission-denied')) {
          await Future.delayed(const Duration(seconds: 1));
        } else {
          break;
        }
      }
    }

    if (mounted) {
      setState(() => _initialLoadComplete = true);
      await _initNotifications();
    }
  }

  TimeOfDay _reminderTimeFromIntensity(String intensity) {
    switch (intensity) {
      case 'high':
      case 'hard':
        return const TimeOfDay(hour: 18, minute: 0);
      case 'light':
        return const TimeOfDay(hour: 20, minute: 30);
      case 'medium':
      default:
        return const TimeOfDay(hour: 19, minute: 0);
    }
  }

  Future<void> _initNotifications() async {
    if (!mounted) return;

    final notificationService = ref.read(notificationServiceProvider);
    await notificationService.init();
    await notificationService.requestPermissions();

    if (!mounted) return;

    TimeOfDay reminderTime = const TimeOfDay(hour: 19, minute: 0);
    try {
      final profile = await ref.read(userProfileProvider.future);
      if (profile != null) {
        reminderTime = _reminderTimeFromIntensity(profile.studyIntensity);
      }
    } catch (_) {}

    if (!mounted) return;

    await notificationService.scheduleDailyReminder(
      id: 0,
      title: 'Çalışma Zamanı!',
      body: 'Bugünkü hedefini tamamlamak için harika bir zaman.',
      time: reminderTime,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialLoadComplete) {
      return const Scaffold(
        backgroundColor: Color(0xFF0F172A),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final userProfileAsync = ref.watch(userProfileStreamProvider);
    final todayStatsAsync = ref.watch(todayStatsProvider);

    return Scaffold(
      // Background is handled by the Stack below
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Global Animated Aurora Background
          const _GlobalAnimatedBackground(),

          // 2. Scrollable Content
          SafeArea(
            child: AnimationLimiter(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 16.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: AnimationConfiguration.toStaggeredList(
                    duration: const Duration(milliseconds: 600),
                    childAnimationBuilder: (widget) => SlideAnimation(
                      verticalOffset: 50.0,
                      child: FadeInAnimation(child: widget),
                    ),
                    children: [
                      // Header
                      _DashboardHeader(userProfileAsync: userProfileAsync),
                      const SizedBox(height: 32),

                      // Daily Goal (Hero Section)
                      _DailyGoalHero(statsAsync: todayStatsAsync),
                      const SizedBox(height: 24),

                      // Smart Suggestion
                      const SmartSuggestionCard(),
                      const SizedBox(height: 24),

                      // İstatistik Kartları - Staggered Animation
                      if (todayStatsAsync.hasValue)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 24),
                          child: GridView.count(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisCount: 2,
                            mainAxisSpacing: 16,
                            crossAxisSpacing: 16,
                            childAspectRatio: 1.1,
                            children: [
                              _buildAnimatedStatCard(
                                'Çözülen Soru',
                                todayStatsAsync.value?['questions_solved']
                                        ?.toString() ??
                                    '0',
                                Icons.assignment_turned_in,
                                [
                                  const Color(0xFF3B82F6),
                                  const Color(0xFF2563EB),
                                ],
                                0,
                              ),
                              _buildAnimatedStatCard(
                                'Başarı Oranı',
                                '%${(todayStatsAsync.value?['success_rate'] ?? 0).toStringAsFixed(1)}',
                                Icons.pie_chart,
                                [
                                  const Color(0xFF10B981),
                                  const Color(0xFF059669),
                                ],
                                1,
                              ),
                              _buildAnimatedStatCard(
                                'Seri',
                                '${todayStatsAsync.value?['current_streak'] ?? 0} Gün',
                                Icons.local_fire_department,
                                [
                                  const Color(0xFFF59E0B),
                                  const Color(0xFFD97706),
                                ],
                                2,
                              ),
                              _buildAnimatedStatCard(
                                'Sıralama',
                                '#${todayStatsAsync.value?['rank'] ?? "-"}',
                                Icons.emoji_events,
                                [
                                  const Color(0xFF8B5CF6),
                                  const Color(0xFF7C3AED),
                                ],
                                3,
                                subtitle: 'Bu hafta',
                                onTap: () => context.push('/leaderboard'),
                              ),
                            ],
                          ),
                        ),

                      // Rich Organic Stream Layout
                      const _RichOrganicStreamLayout(),
                      const SizedBox(height: 120), // Bottom padding for Nav Bar
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedStatCard(
    String title,
    String value,
    IconData icon,
    List<Color> gradientColors,
    int index, {
    String? subtitle,
    VoidCallback? onTap,
  }) {
    return AnimatedStatCard(
      title: title,
      value: value,
      icon: icon,
      gradientColors: gradientColors,
      delay: 0.1 * (index + 1),
      subtitle: subtitle,
      onTap: onTap,
    );
  }
}

// --- Sub-Widgets ---

class _GlobalAnimatedBackground extends StatelessWidget {
  const _GlobalAnimatedBackground();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Base Dark Background
        Container(color: const Color(0xFF0F172A)),

        // Moving Aurora Blob 1 (Top Left - Purple/Pink)
        Positioned(
          top: -100,
          left: -100,
          child:
              Container(
                    width: 400,
                    height: 400,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          const Color(0xFF7C3AED).withOpacity(0.3),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  )
                  .animate(
                    onPlay: (controller) => controller.repeat(reverse: true),
                  )
                  .scale(
                    begin: const Offset(1, 1),
                    end: const Offset(1.5, 1.5),
                    duration: 5.seconds,
                  )
                  .move(
                    begin: const Offset(0, 0),
                    end: const Offset(50, 50),
                    duration: 5.seconds,
                  ),
        ),

        // Moving Aurora Blob 2 (Bottom Right - Teal/Blue)
        Positioned(
          bottom: -100,
          right: -100,
          child:
              Container(
                    width: 400,
                    height: 400,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          const Color(0xFF00C896).withOpacity(0.2),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  )
                  .animate(
                    onPlay: (controller) => controller.repeat(reverse: true),
                  )
                  .scale(
                    begin: const Offset(1, 1),
                    end: const Offset(1.3, 1.3),
                    duration: 7.seconds,
                  )
                  .move(
                    begin: const Offset(0, 0),
                    end: const Offset(-30, -30),
                    duration: 7.seconds,
                  ),
        ),

        // Moving Aurora Blob 3 (Center - Orange)
        Positioned(
          top: MediaQuery.of(context).size.height * 0.3,
          left: MediaQuery.of(context).size.width * 0.2,
          child:
              Container(
                    width: 300,
                    height: 300,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          const Color(0xFFFF8F00).withOpacity(0.15),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  )
                  .animate(
                    onPlay: (controller) => controller.repeat(reverse: true),
                  )
                  .fade(begin: 0.3, end: 0.6, duration: 4.seconds)
                  .move(
                    begin: const Offset(0, 0),
                    end: const Offset(20, -20),
                    duration: 6.seconds,
                  ),
        ),

        // Noise Overlay (Texture)
        Opacity(
          opacity: 0.05,
          child: Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage(
                  'assets/images/noise.png',
                ), // Assuming noise asset exists or will fail gracefully if not
                fit: BoxFit.cover,
                repeat: ImageRepeat.repeat,
              ),
            ),
          ),
        ),

        // Glass Overlay (Blur)
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
          child: Container(color: Colors.transparent),
        ),
      ],
    );
  }
}

class _DashboardHeader extends ConsumerWidget {
  final AsyncValue<dynamic> userProfileAsync;

  const _DashboardHeader({required this.userProfileAsync});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadCountAsync = ref.watch(unreadNotificationCountProvider);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              userProfileAsync.when(
                data: (user) => Text(
                  'Merhaba, ${user?.name ?? 'Öğrenci'} 👋',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                loading: () => const SizedBox(height: 20),
                error: (_, __) => const Text('Merhaba!'),
              ),
              const SizedBox(height: 4),
              Text(
                'Bugün hedeflerine ulaşmaya hazır mısın?',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: DesignTokens.textSecondary,
                ),
              ),
            ],
          ),
        ),
        // Bildirim İkonu
        Stack(
          children: [
            PremiumGlassContainer(
              width: 48,
              height: 48,
              padding: EdgeInsets.zero,
              borderRadius: DesignTokens.r12,
              child: IconButton(
                onPressed: () => context.push('/notifications'),
                icon: const Icon(
                  Icons.notifications_outlined,
                  color: Colors.white,
                ),
              ),
            ),
            // Okunmamış bildirim sayısı badge
            unreadCountAsync.when(
              data: (count) => count > 0
                  ? Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        child: Text(
                          count > 9 ? '9+' : count.toString(),
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ],
        ),
        const SizedBox(width: 12),
        // Profil İkonu
        PremiumGlassContainer(
          width: 48,
          height: 48,
          padding: EdgeInsets.zero,
          borderRadius: DesignTokens.r12,
          child: IconButton(
            onPressed: () => context.push('/profile'),
            icon: const Icon(Icons.person_outline, color: Colors.white),
          ),
        ),
      ],
    );
  }
}

class _DailyGoalHero extends StatelessWidget {
  final AsyncValue<Map<String, dynamic>?> statsAsync;

  const _DailyGoalHero({required this.statsAsync});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF4F46E5), // Indigo
            Color(0xFF7C3AED), // Violet
            Color(0xFFDB2777), // Pink
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4F46E5).withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Abstract Shapes (Placeholder for image)
          Positioned(
            top: -50,
            right: -50,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.1),
              ),
            ),
          ),
          Positioned(
            bottom: -30,
            left: -30,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.1),
              ),
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: statsAsync.when(
              data: (stats) {
                final questionsSolved = stats?['questions_solved'] ?? 0;
                final goalQuestions = 20;
                final progress = (questionsSolved / goalQuestions).clamp(
                  0.0,
                  1.0,
                );

                return Row(
                  children: [
                    CircularPercentIndicator(
                      radius: 60,
                      lineWidth: 12,
                      percent: progress,
                      center: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${(progress * 100).round()}%',
                            style: GoogleFonts.spaceGrotesk(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      progressColor: Colors.white,
                      backgroundColor: Colors.white.withOpacity(0.2),
                      circularStrokeCap: CircularStrokeCap.round,
                      animation: true,
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'GÜNLÜK HEDEF',
                            style: GoogleFonts.inter(
                              color: Colors.white70,
                              fontSize: 12,
                              letterSpacing: 2.0,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '$questionsSolved / $goalQuestions',
                            style: GoogleFonts.spaceGrotesk(
                              color: Colors.white,
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Soru Tamamlandı',
                            style: GoogleFonts.inter(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
              error: (_, __) => const Text(
                'Veri yüklenemedi',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RichOrganicStreamLayout extends StatelessWidget {
  const _RichOrganicStreamLayout();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header - Keşfet
        _buildSectionHeader('Keşfet', Icons.explore_rounded, const [
          Color(0xFF6366F1),
          Color(0xFF8B5CF6),
        ]),
        const SizedBox(height: 16),

        // Bento Grid - Modern Layout
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 0),
          child: Column(
            children: [
              // Row 1: Dersler + Özel Test (yanyana)
              Row(
                children: [
                  Expanded(
                        child: SizedBox(
                          height: 200,
                          child: ModernBentoCard(
                            title: 'Dersler',
                            subtitle: 'Konu çalış',
                            icon: Icons.menu_book_rounded,
                            gradientColors: const [
                              Color(0xFF6366F1),
                              Color(0xFF8B5CF6),
                            ],
                            onTap: () => context.push('/subjects'),
                            size: BentoCardSize.medium,
                          ),
                        ),
                      )
                      .animate()
                      .fadeIn(duration: 500.ms)
                      .slideX(begin: -0.1, end: 0),
                  const SizedBox(width: 12),
                  Expanded(
                        child: SizedBox(
                          height: 200,
                          child: ModernBentoCard(
                            title: 'Özel Test',
                            subtitle: 'Kişiselleştir',
                            icon: Icons.tune_rounded,
                            gradientColors: const [
                              Color(0xFFEC4899),
                              Color(0xFFDB2777),
                            ],
                            onTap: () => context.push('/quiz/setup'),
                            size: BentoCardSize.medium,
                          ),
                        ),
                      )
                      .animate()
                      .fadeIn(duration: 500.ms, delay: 100.ms)
                      .slideX(begin: 0.1, end: 0),
                ],
              ),
              const SizedBox(height: 14),

              // Row 2: HMGS Deneme + AI Koç (yanyana)
              Row(
                children: [
                  Expanded(
                        child: SizedBox(
                          height: 200,
                          child: ModernBentoCard(
                            title: 'HMGS Deneme',
                            subtitle: '120 soru • 150 dakika',
                            icon: Icons.assignment_rounded,
                            gradientColors: const [
                              Color(0xFF8B5CF6),
                              Color(0xFF7C3AED),
                            ],
                            onTap: () => context.push('/exam/hmgs/start'),
                            size: BentoCardSize.medium,
                            isPremium: true,
                          ),
                        ),
                      )
                      .animate()
                      .fadeIn(duration: 500.ms, delay: 200.ms)
                      .slideX(begin: -0.1, end: 0),
                  const SizedBox(width: 12),
                  Expanded(
                        child: SizedBox(
                          height: 200,
                          child: ModernBentoCard(
                            title: 'AI Koç',
                            subtitle: 'Sor & Öğren',
                            icon: Icons.auto_awesome_rounded,
                            gradientColors: const [
                              Color(0xFF10B981),
                              Color(0xFF059669),
                            ],
                            onTap: () => context.push('/ai-coach'),
                            size: BentoCardSize.medium,
                            badge: 'YENİ',
                          ),
                        ),
                      )
                      .animate()
                      .fadeIn(duration: 500.ms, delay: 300.ms)
                      .slideX(begin: 0.1, end: 0),
                ],
              ),
              const SizedBox(height: 14),

              // Row 3: Hızlı Quiz (geniş kart)
              SizedBox(
                    height: 130,
                    child: ModernBentoCard(
                      title: 'Hızlı Quiz',
                      subtitle: '10 soru • Hemen başla',
                      icon: Icons.bolt_rounded,
                      gradientColors: const [
                        Color(0xFFF59E0B),
                        Color(0xFFD97706),
                      ],
                      onTap: () => context.push('/quiz/modern-setup'),
                      size: BentoCardSize.wide,
                      isPremium: true,
                    ),
                  )
                  .animate()
                  .fadeIn(duration: 500.ms, delay: 400.ms)
                  .slideY(begin: 0.1, end: 0),
            ],
          ),
        ),

        const SizedBox(height: 32),

        // Section Header - Analiz
        _buildSectionHeader('Analiz & Takip', Icons.insights_rounded, const [
          Color(0xFF3B82F6),
          Color(0xFF2563EB),
        ]),
        const SizedBox(height: 16),

        // Insights Row - Horizontal scroll
        SizedBox(
          height: 120,
          child: ListView(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            physics: const BouncingScrollPhysics(),
            children: [
              // Yanlışlarım
              SizedBox(
                    width: 200,
                    child: _InsightCard(
                      title: 'Yanlışlarım',
                      subtitle: 'Tekrar et',
                      icon: Icons.warning_amber_rounded,
                      color: const Color(0xFFEF4444),
                      onTap: () => context.push('/wrong-answers'),
                    ),
                  )
                  .animate()
                  .fadeIn(duration: 500.ms, delay: 500.ms)
                  .slideX(begin: 0.2, end: 0),
              const SizedBox(width: 12),

              // İstatistikler
              SizedBox(
                    width: 200,
                    child: _InsightCard(
                      title: 'İstatistikler',
                      subtitle: 'Gelişim',
                      icon: Icons.analytics_rounded,
                      color: const Color(0xFF3B82F6),
                      onTap: () => context.push('/analytics'),
                    ),
                  )
                  .animate()
                  .fadeIn(duration: 500.ms, delay: 600.ms)
                  .slideX(begin: 0.2, end: 0),
              const SizedBox(width: 12),

              // Liderlik
              SizedBox(
                    width: 200,
                    child: _InsightCard(
                      title: 'Liderlik',
                      subtitle: 'Sıralama',
                      icon: Icons.leaderboard_rounded,
                      color: const Color(0xFFF59E0B),
                      onTap: () => context.push('/leaderboard'),
                    ),
                  )
                  .animate()
                  .fadeIn(duration: 500.ms, delay: 700.ms)
                  .slideX(begin: 0.2, end: 0),
              const SizedBox(width: 24), // End padding
            ],
          ),
        ),

        const SizedBox(height: 32), // Bottom padding
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, List<Color> colors) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: colors),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: colors.first.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(icon, color: Colors.white, size: 18),
        ),
        const SizedBox(width: 14),
        Text(
          title,
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ),
      ],
    ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.1, end: 0);
  }
}

/// Insight kartı - kompakt tasarım
class _InsightCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _InsightCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  State<_InsightCard> createState() => _InsightCardState();
}

class _InsightCardState extends State<_InsightCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _isPressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1F2E),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: widget.color.withValues(alpha: 0.2),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: 0.1),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: widget.color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(widget.icon, color: widget.color, size: 20),
                  ),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: Colors.white.withValues(alpha: 0.3),
                    size: 14,
                  ),
                ],
              ),
              const Spacer(),
              Text(
                widget.title,
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                widget.subtitle,
                style: GoogleFonts.inter(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
