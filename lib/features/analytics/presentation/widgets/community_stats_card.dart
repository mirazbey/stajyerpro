import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../shared/widgets/premium_glass_container.dart';
import '../../data/analytics_repository.dart';

class CommunityStatsCard extends ConsumerWidget {
  const CommunityStatsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAnalyticsAsync = ref.watch(userAnalyticsProvider);
    final communityStatsAsync = ref.watch(communityStatsProvider);

    return communityStatsAsync.when(
      data: (communityStats) {
        return userAnalyticsAsync.when(
          data: (userStats) {
            final userRate = userStats.successRate;
            final communityRate = communityStats.averageSuccessRate;
            final diff = userRate - communityRate;
            final isAboveAverage = diff >= 0;

            return PremiumGlassContainer(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'TOPLULUK KIYASLAMASI',
                        style: GoogleFonts.inter(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isAboveAverage
                              ? Colors.green.withOpacity(0.2)
                              : Colors.orange.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          isAboveAverage ? 'Ortalama Üstü' : 'Geliştirilmeli',
                          style: GoogleFonts.inter(
                            color: isAboveAverage
                                ? Colors.greenAccent
                                : Colors.orangeAccent,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildComparisonRow(
                    context,
                    label: 'Sen',
                    value: userRate,
                    color: DesignTokens.accent,
                  ),
                  const SizedBox(height: 12),
                  _buildComparisonRow(
                    context,
                    label: 'Topluluk',
                    value: communityRate,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    isAboveAverage
                        ? 'Harika! Topluluk ortalamasının %${diff.toStringAsFixed(1)} üzerindesin. 🏆'
                        : 'Topluluk ortalamasına ulaşmak için biraz daha pratiğe ihtiyacın var. 💪',
                    style: GoogleFonts.inter(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildComparisonRow(
    BuildContext context, {
    required String label,
    required double value,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: GoogleFonts.spaceGrotesk(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '%${value.toStringAsFixed(1)}',
              style: GoogleFonts.spaceGrotesk(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearPercentIndicator(
          lineHeight: 8.0,
          percent: (value / 100).clamp(0.0, 1.0),
          backgroundColor: Colors.white.withOpacity(0.1),
          progressColor: color,
          barRadius: const Radius.circular(4),
          padding: EdgeInsets.zero,
          animation: true,
        ),
      ],
    );
  }
}
