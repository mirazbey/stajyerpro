import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../shared/widgets/premium_glass_container.dart';
import '../../../shared/models/exam_model.dart';
import '../data/exam_repository.dart';

final examsStreamProvider = StreamProvider<List<ExamModel>>((ref) {
  final repository = ref.watch(examRepositoryProvider);
  return repository.getExams();
});

final examCreditsProvider = FutureProvider<int>((ref) {
  final repository = ref.watch(examRepositoryProvider);
  return repository.getUserExamCredits();
});

/// Kullanıcının satın aldığı denemelerin ID'leri
final userPurchasedExamsProvider = FutureProvider<Set<String>>((ref) {
  final repository = ref.watch(examRepositoryProvider);
  return repository.getUserPurchasedExams();
});

/// Deneme sınavı listesi ekranı
class ExamListScreen extends ConsumerWidget {
  const ExamListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final examsAsync = ref.watch(examsStreamProvider);
    final purchasedAsync = ref.watch(userPurchasedExamsProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Deneme Sınavları',
          style: GoogleFonts.spaceGrotesk(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_bag_outlined, color: Colors.white),
            onPressed: () => context.push('/exam-store'),
            tooltip: 'Mağaza',
          ),
        ],
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
                  colors: [
                    Color(0xFF0F172A), // Slate 900
                    Color(0xFF1E293B), // Slate 800
                    Color(0xFF0F172A), // Slate 900
                  ],
                ),
              ),
            ),
          ),

          // Content
          SafeArea(
            child: Column(
              children: [
                // HMGS Featured Card
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: _HMGSFeaturedCard(
                    onTap: () => context.push('/exam/hmgs/start'),
                  ),
                ),

                // Exam list
                Expanded(
                  child: examsAsync.when(
                    data: (exams) {
                      if (exams.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.assignment_outlined,
                                size: 64,
                                color: Colors.white24,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Ek deneme sınavı yok',
                                style: GoogleFonts.inter(
                                  color: Colors.white60,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: exams.length,
                        itemBuilder: (context, index) {
                          final exam = exams[index];
                          final purchasedIds = purchasedAsync.valueOrNull ?? {};
                          final hasAccess =
                              exam.isFree || purchasedIds.contains(exam.id);

                          return _ExamCard(
                            exam: exam,
                            hasAccess: hasAccess,
                            onTap: () async {
                              // Erişim kontrolü
                              if (!hasAccess) {
                                if (context.mounted) {
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      backgroundColor: const Color(0xFF1E293B),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      title: Text(
                                        'Deneme Satın Alınmamış',
                                        style: GoogleFonts.spaceGrotesk(
                                          color: Colors.white,
                                        ),
                                      ),
                                      content: Text(
                                        'Bu deneme sınavını çözmek için önce satın almanız gerekiyor.',
                                        style: GoogleFonts.inter(
                                          color: Colors.white70,
                                        ),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context),
                                          child: const Text('İptal'),
                                        ),
                                        FilledButton.icon(
                                          onPressed: () {
                                            Navigator.pop(context);
                                            context.push('/exam-store');
                                          },
                                          icon: const Icon(
                                            Icons.shopping_cart,
                                            size: 18,
                                          ),
                                          style: FilledButton.styleFrom(
                                            backgroundColor:
                                                DesignTokens.accent,
                                            foregroundColor: Colors.black,
                                          ),
                                          label: const Text('Mağazaya Git'),
                                        ),
                                      ],
                                    ),
                                  );
                                }
                                return;
                              }

                              if (context.mounted) {
                                context.push('/exam/${exam.id}/start');
                              }
                            },
                          );
                        },
                      );
                    },
                    loading: () => const Center(
                      child: CircularProgressIndicator(
                        color: DesignTokens.accent,
                      ),
                    ),
                    error: (error, stack) => Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 64,
                            color: Colors.redAccent,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Denemeler yüklenemedi',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            error.toString(),
                            style: GoogleFonts.inter(
                              color: Colors.white54,
                              fontSize: 12,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/exams/new'),
        backgroundColor: DesignTokens.accent,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add),
        label: Text(
          'Yeni Deneme',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

class _ExamCard extends StatelessWidget {
  final ExamModel exam;
  final bool hasAccess;
  final VoidCallback onTap;

  const _ExamCard({
    required this.exam,
    required this.hasAccess,
    required this.onTap,
  });

  Color _getBadgeColor() {
    switch (exam.badge) {
      case 'ÜCRETSİZ':
        return Colors.greenAccent;
      case 'POPÜLER':
        return Colors.orange;
      case 'ZOR':
        return Colors.redAccent;
      case 'ÖNERİLEN':
        return Colors.purpleAccent;
      default:
        return DesignTokens.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: onTap,
        child: PremiumGlassContainer(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _getBadgeColor().withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _getBadgeColor().withValues(alpha: 0.3),
                      ),
                    ),
                    child: Icon(
                      exam.isFree ? Icons.card_giftcard : Icons.assignment,
                      color: _getBadgeColor(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                exam.name,
                                style: GoogleFonts.spaceGrotesk(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            if (exam.badge != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _getBadgeColor().withValues(
                                    alpha: 0.2,
                                  ),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  exam.badge!,
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: _getBadgeColor(),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          exam.description ?? '',
                          style: GoogleFonts.inter(
                            color: Colors.white60,
                            fontSize: 12,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _InfoChip(
                    icon: Icons.quiz_outlined,
                    label: '${exam.totalQuestions} soru',
                  ),
                  const SizedBox(width: 8),
                  _InfoChip(
                    icon: Icons.timer_outlined,
                    label: '${exam.durationMinutes} dk',
                  ),
                  const SizedBox(width: 8),
                  _InfoChip(
                    icon: Icons.trending_up,
                    label: exam.difficultyLabel,
                  ),
                  const Spacer(),
                  // Access status
                  if (hasAccess)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.check_circle,
                            size: 14,
                            color: Colors.greenAccent,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Erişilebilir',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.greenAccent,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: DesignTokens.accent.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.lock,
                            size: 14,
                            color: DesignTokens.accent,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${exam.price}₺',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: DesignTokens.accent,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white70),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.inter(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// HMGS Featured Card - Öne çıkan HMGS Deneme kartı
class _HMGSFeaturedCard extends StatelessWidget {
  final VoidCallback onTap;

  const _HMGSFeaturedCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF6366F1), // Indigo 500
              Color(0xFF8B5CF6), // Violet 500
              Color(0xFFA855F7), // Purple 500
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6366F1).withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.assignment,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'HMGS Deneme Sınavı',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Gerçek sınav formatında tam deneme',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: Colors.white.withOpacity(0.85),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Info chips
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _FeaturedChip(icon: Icons.quiz_outlined, label: '120 Soru'),
                _FeaturedChip(icon: Icons.timer_outlined, label: '150 Dakika'),
                _FeaturedChip(icon: Icons.trending_up, label: '70 Baraj'),
              ],
            ),
            const SizedBox(height: 16),

            // Features row
            Row(
              children: [
                Expanded(
                  child: _FeatureItem(
                    icon: Icons.calculate,
                    label: 'Net Hesaplama',
                  ),
                ),
                Expanded(
                  child: _FeatureItem(
                    icon: Icons.bar_chart,
                    label: 'Ders Analizi',
                  ),
                ),
                Expanded(
                  child: _FeatureItem(
                    icon: Icons.flag,
                    label: 'Soru İşaretleme',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FeaturedChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _FeaturedChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureItem extends StatelessWidget {
  final IconData icon;
  final String label;

  const _FeatureItem({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 20, color: Colors.white.withOpacity(0.9)),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.inter(
            color: Colors.white.withOpacity(0.8),
            fontSize: 10,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
