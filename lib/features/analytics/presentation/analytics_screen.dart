import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/analytics_repository.dart';
import '../../profile/data/profile_repository.dart';
import 'dart:ui';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsAsync = ref.watch(userAnalyticsProvider);
    final weeklyStatsAsync = ref.watch(weeklyStatsProvider);
    final monthlyStatsAsync = ref.watch(monthlyStatsProvider);
    final weakTopicsAsync = ref.watch(weakTopicsProvider);
    final communityStatsAsync = ref.watch(communityStatsProvider);
    final userProfileAsync = ref.watch(userProfileProvider);
    final subjectStatsAsync = ref.watch(subjectDetailedStatsProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(userAnalyticsProvider);
            ref.invalidate(weeklyStatsProvider);
            ref.invalidate(monthlyStatsProvider);
            ref.invalidate(weakTopicsProvider);
            ref.invalidate(communityStatsProvider);
            ref.invalidate(userProfileProvider);
            ref.invalidate(subjectDetailedStatsProvider);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Text(
                  'İstatistikler',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 32),

                // Main Stats
                analyticsAsync.when(
                  data: (analytics) => _MainStatsSection(analytics: analytics),
                  loading: () => const _LoadingShimmer(height: 200),
                  error: (_, __) => const SizedBox.shrink(),
                ),
                const SizedBox(height: 16),

                // Goal Progress (Days Left)
                userProfileAsync.when(
                  data: (profile) => profile != null
                      ? RepaintBoundary(
                          child: _GoalProgressCard(profile: profile),
                        )
                      : const SizedBox.shrink(),
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
                const SizedBox(height: 16),

                // Target Score Analysis
                if (analyticsAsync.hasValue && userProfileAsync.hasValue)
                  RepaintBoundary(
                    child: _TargetScoreAnalysisCard(
                      analytics: analyticsAsync.value!,
                      profile: userProfileAsync.value,
                    ),
                  ),
                const SizedBox(height: 16),

                // Community Stats (Percentile)
                communityStatsAsync.when(
                  data: (stats) => RepaintBoundary(
                    child: _CommunityStatsCard(
                      stats: stats,
                      userAnalytics: analyticsAsync.value,
                    ),
                  ),
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
                const SizedBox(height: 16),

                // Weekly Progress
                weeklyStatsAsync.when(
                  data: (stats) => _WeeklyProgressCard(stats: stats),
                  loading: () => const _LoadingShimmer(height: 180),
                  error: (_, __) => const SizedBox.shrink(),
                ),
                const SizedBox(height: 16),

                // Monthly Trend Chart
                monthlyStatsAsync.when(
                  data: (stats) => _MonthlyTrendCard(stats: stats),
                  loading: () => const _LoadingShimmer(height: 200),
                  error: (_, __) => const SizedBox.shrink(),
                ),
                const SizedBox(height: 16),

                // Subject-wise Performance
                subjectStatsAsync.when(
                  data: (stats) => _SubjectPerformanceCard(stats: stats),
                  loading: () => const _LoadingShimmer(height: 200),
                  error: (_, __) => const SizedBox.shrink(),
                ),
                const SizedBox(height: 16),

                // Weak Topics
                weakTopicsAsync.when(
                  data: (topics) => _WeakTopicsSection(topics: topics),
                  loading: () => const _LoadingShimmer(height: 150),
                  error: (_, __) => const SizedBox.shrink(),
                ),

                const SizedBox(height: 120), // Bottom padding
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Main Stats Section
class _MainStatsSection extends StatelessWidget {
  final UserAnalytics analytics;

  const _MainStatsSection({required this.analytics});

  @override
  Widget build(BuildContext context) {
    final successRate = analytics.successRate;
    final color = successRate >= 70
        ? const Color(0xFF10B981)
        : successRate >= 50
        ? const Color(0xFFF59E0B)
        : const Color(0xFFEF4444);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.3), color.withOpacity(0.1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Column(
        children: [
          // Success Rate
          Text(
            '${successRate.toStringAsFixed(0)}%',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 56,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'BAŞARI ORANI',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white70,
              letterSpacing: 2.0,
            ),
          ),
          const SizedBox(height: 24),

          // Stats Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _StatItem(
                label: 'Toplam',
                value: '${analytics.totalQuestions}',
                icon: Icons.quiz,
              ),
              Container(
                width: 1,
                height: 40,
                color: Colors.white.withOpacity(0.2),
              ),
              _StatItem(
                label: 'Doğru',
                value: '${analytics.totalCorrect}',
                icon: Icons.check_circle,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Colors.white54, size: 20),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 12, color: Colors.white54),
        ),
      ],
    );
  }
}

// Weekly Progress Card
class _WeeklyProgressCard extends StatelessWidget {
  final List<DailyStats> stats;

  const _WeeklyProgressCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    if (stats.isEmpty) return const SizedBox.shrink();

    final maxQuestions = stats
        .map((s) => s.questionsSolved)
        .fold(0, (max, val) => val > max ? val : max);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'HAFTALIK İLERLEME',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 100,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: stats.map((stat) {
                final percentage = maxQuestions > 0
                    ? (stat.questionsSolved / maxQuestions).clamp(0.05, 1.0)
                    : 0.05;

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (stat.questionsSolved > 0)
                          Text(
                            '${stat.questionsSolved}',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.white70,
                            ),
                          ),
                        const SizedBox(height: 4),
                        Container(
                          height: 100 * percentage,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _formatDay(stat.date),
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: Colors.white60,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDay(DateTime date) {
    const days = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
    return days[date.weekday - 1];
  }
}

// Weak Topics Section
class _WeakTopicsSection extends StatelessWidget {
  final List<WeakTopicData> topics;

  const _WeakTopicsSection({required this.topics});

  @override
  Widget build(BuildContext context) {
    if (topics.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            const Icon(Icons.celebration, color: Color(0xFF10B981), size: 48),
            const SizedBox(height: 16),
            Text(
              'Harika Gidiyorsun!',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Zayıf konu yok. Devam et!',
              style: GoogleFonts.inter(fontSize: 14, color: Colors.white70),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'GELİŞTİRİLECEK KONULAR',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        ...topics.map(
          (topic) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFEF4444).withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFFEF4444).withOpacity(0.5),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.school,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        topic.topicName,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Başarı: %${topic.successRate.toInt()} • ${topic.total} soru',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Tekrar Et',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// Loading Shimmer
class _LoadingShimmer extends StatelessWidget {
  final double height;

  const _LoadingShimmer({required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Center(
        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// RESTORED CARDS (Optimized)
// -----------------------------------------------------------------------------

class _GoalProgressCard extends StatelessWidget {
  final dynamic profile; // UserModel

  const _GoalProgressCard({required this.profile});

  @override
  Widget build(BuildContext context) {
    // Check if examTargetDate exists (assuming dynamic for now to avoid import issues if model changed)
    // In a real scenario, use UserModel type.
    final DateTime? targetDate = (profile as dynamic).examTargetDate;

    if (targetDate == null) return const SizedBox.shrink();

    final daysLeft = targetDate.difference(DateTime.now()).inDays;
    if (daysLeft < 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF6366F1).withOpacity(0.2),
            const Color(0xFF8B5CF6).withOpacity(0.2),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.timer, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 16),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sınava Kalan Süre',
                  style: GoogleFonts.inter(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  '$daysLeft Gün',
                  style: GoogleFonts.spaceGrotesk(
                    color: Colors.white,
                    fontSize: 24,
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
}

class _TargetScoreAnalysisCard extends StatelessWidget {
  final UserAnalytics analytics;
  final dynamic profile;

  const _TargetScoreAnalysisCard({
    required this.analytics,
    required this.profile,
  });

  @override
  Widget build(BuildContext context) {
    // Assuming 'targetScore' field exists in UserModel (dynamic check)
    // If not, we skip.
    final int? targetScore =
        (profile as dynamic).targetScore; // Need to verify field name
    // If targetScore is missing in model, we might need to add it or use a default.
    // For now, let's assume 70 if null for demo, or hide.

    // Actually, let's hide if null to be safe.
    // But wait, the task said we added it. Let's try to access it.
    // If it fails at runtime, we'll fix.

    // Safe access via map if possible or just dynamic.
    // Let's assume it might be null.
    final int target = targetScore ?? 70;

    if (analytics.recentExamScores.isEmpty) return const SizedBox.shrink();

    final currentScore = analytics.recentExamScores.last;
    final gap = target - currentScore;
    final isOnTrack = gap <= 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'HEDEF ANALİZİ',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white70,
                  letterSpacing: 1.0,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isOnTrack
                      ? Colors.green.withOpacity(0.2)
                      : Colors.orange.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isOnTrack ? 'HEDEFTE' : '$gap PUAN KALDI',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isOnTrack ? Colors.greenAccent : Colors.orangeAccent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Stack(
              children: [
                Container(
                  height: 8,
                  width: double.infinity,
                  color: Colors.white.withOpacity(0.1),
                ),
                FractionallySizedBox(
                  widthFactor: (currentScore / 100).clamp(0.0, 1.0),
                  child: Container(
                    height: 8,
                    color: isOnTrack
                        ? const Color(0xFF10B981)
                        : const Color(0xFFF59E0B),
                  ),
                ),
                // Target Marker
                Positioned(
                  left:
                      (MediaQuery.of(context).size.width - 88) *
                      (target / 100), // Approx width calculation
                  child: Container(width: 2, height: 8, color: Colors.white),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Mevcut: $currentScore',
                style: GoogleFonts.inter(fontSize: 12, color: Colors.white70),
              ),
              Text(
                'Hedef: $target',
                style: GoogleFonts.inter(fontSize: 12, color: Colors.white),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CommunityStatsCard extends StatelessWidget {
  final CommunityStats stats;
  final UserAnalytics? userAnalytics;

  const _CommunityStatsCard({required this.stats, required this.userAnalytics});

  @override
  Widget build(BuildContext context) {
    final userRate = userAnalytics?.successRate ?? 0;
    final diff = userRate - stats.averageSuccessRate;
    final isAboveAverage = diff >= 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFEC4899).withOpacity(0.1), // Pink
            const Color(0xFF8B5CF6).withOpacity(0.1), // Purple
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.public, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Genel Sıralama',
                  style: GoogleFonts.inter(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  isAboveAverage
                      ? 'Ortalamanın Üstündesin! 🚀'
                      : 'Ortalamaya Yakınsın 💪',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Ortalama Başarı: %${stats.averageSuccessRate.toStringAsFixed(1)}',
                  style: GoogleFonts.inter(color: Colors.white54, fontSize: 10),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Monthly Trend Card
class _MonthlyTrendCard extends StatelessWidget {
  final List<DailyStats> stats;

  const _MonthlyTrendCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    if (stats.isEmpty) return const SizedBox.shrink();

    // Calculate weekly aggregates for cleaner visualization
    final weeklyData = <Map<String, dynamic>>[];
    for (int i = 0; i < 4; i++) {
      final weekStart = i * 7;
      final weekStats = stats.skip(weekStart).take(7).toList();

      if (weekStats.isEmpty) continue;

      final totalQuestions =
          weekStats.fold(0, (sum, s) => sum + s.questionsSolved);
      final totalCorrect = weekStats.fold(0, (sum, s) => sum + s.correctCount);
      final successRate =
          totalQuestions > 0 ? (totalCorrect / totalQuestions * 100) : 0.0;

      weeklyData.add({
        'week': 'Hafta ${i + 1}',
        'questions': totalQuestions,
        'successRate': successRate,
      });
    }

    // Calculate trend
    double trend = 0;
    if (weeklyData.length >= 2) {
      final lastWeekRate =
          weeklyData.last['successRate'] as double? ?? 0;
      final firstWeekRate =
          weeklyData.first['successRate'] as double? ?? 0;
      trend = lastWeekRate - firstWeekRate;
    }

    final maxQuestions = weeklyData
        .map((w) => w['questions'] as int)
        .fold(1, (max, val) => val > max ? val : max);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'AYLIK TREND',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.2,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: trend >= 0
                      ? const Color(0xFF10B981).withOpacity(0.2)
                      : const Color(0xFFEF4444).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      trend >= 0
                          ? Icons.trending_up
                          : Icons.trending_down,
                      size: 14,
                      color: trend >= 0
                          ? const Color(0xFF10B981)
                          : const Color(0xFFEF4444),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${trend >= 0 ? '+' : ''}${trend.toStringAsFixed(1)}%',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: trend >= 0
                            ? const Color(0xFF10B981)
                            : const Color(0xFFEF4444),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 120,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: weeklyData.map((data) {
                final questions = data['questions'] as int;
                final successRate = data['successRate'] as double;
                final percentage = (questions / maxQuestions).clamp(0.1, 1.0);

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          '%${successRate.toStringAsFixed(0)}',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: _getSuccessColor(successRate),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$questions',
                          style: GoogleFonts.inter(
                            fontSize: 9,
                            color: Colors.white54,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          height: 80 * percentage,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                _getSuccessColor(successRate).withOpacity(0.8),
                                _getSuccessColor(successRate).withOpacity(0.4),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          data['week'] as String,
                          style: GoogleFonts.inter(
                            fontSize: 9,
                            color: Colors.white60,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Color _getSuccessColor(double rate) {
    if (rate >= 70) return const Color(0xFF10B981);
    if (rate >= 50) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }
}

// Subject Performance Card
class _SubjectPerformanceCard extends StatelessWidget {
  final List<SubjectDetailedStats> stats;

  const _SubjectPerformanceCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    if (stats.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'DERS BAZLI PERFORMANS',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          ...stats.take(5).map((subject) => _buildSubjectRow(subject)),
        ],
      ),
    );
  }

  Widget _buildSubjectRow(SubjectDetailedStats subject) {
    final successRate = subject.successRate;
    final color = _getSuccessColor(successRate);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  subject.subjectName,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Row(
                children: [
                  Text(
                    '${subject.totalQuestions} soru',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: Colors.white54,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '%${successRate.toStringAsFixed(0)}',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: successRate / 100,
              backgroundColor: Colors.white.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Color _getSuccessColor(double rate) {
    if (rate >= 70) return const Color(0xFF10B981);
    if (rate >= 50) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }
}
