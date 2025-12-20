import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../shared/models/exam_model.dart';
import '../../../shared/widgets/premium_glass_container.dart';
import '../data/exam_repository.dart';

/// Satın alınabilecek denemeleri stream olarak getir
final purchasableExamsProvider = StreamProvider<List<ExamModel>>((ref) {
  final repository = ref.watch(examRepositoryProvider);
  return repository.getExams();
});

/// Kullanıcının satın aldığı denemelerin ID'leri
final userPurchasedExamsProvider = FutureProvider<Set<String>>((ref) {
  final repository = ref.watch(examRepositoryProvider);
  return repository.getUserPurchasedExams();
});

class ExamStoreScreen extends ConsumerWidget {
  const ExamStoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final examsAsync = ref.watch(purchasableExamsProvider);
    final purchasedAsync = ref.watch(userPurchasedExamsProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Deneme Mağazası',
          style: GoogleFonts.spaceGrotesk(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // Background gradient
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF0F172A),
                    Color(0xFF1E293B),
                    Color(0xFF0F172A),
                  ],
                ),
              ),
            ),
          ),

          // Content
          SafeArea(
            child: examsAsync.when(
              data: (exams) {
                final purchasedIds = purchasedAsync.valueOrNull ?? {};

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header card
                      _HeaderCard(),
                      const SizedBox(height: 24),

                      // Free exam section
                      Text(
                        '🎁 Ücretsiz Deneme',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),

                      ...exams
                          .where((e) => e.isFree)
                          .map(
                            (exam) => _ExamPurchaseCard(
                              exam: exam,
                              isPurchased:
                                  true, // Ücretsiz her zaman erişilebilir
                              onPurchase: () {},
                            ),
                          ),

                      const SizedBox(height: 24),

                      // Premium exams section
                      Text(
                        '⭐ Premium Denemeler',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Her deneme ayrı satılır. Bir kez satın alın, sınırsız çözün.',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Colors.white60,
                        ),
                      ),
                      const SizedBox(height: 12),

                      ...exams
                          .where((e) => !e.isFree)
                          .map(
                            (exam) => _ExamPurchaseCard(
                              exam: exam,
                              isPurchased: purchasedIds.contains(exam.id),
                              onPurchase: () =>
                                  _showPurchaseDialog(context, ref, exam),
                            ),
                          ),

                      const SizedBox(height: 24),

                      // Info section
                      _InfoSection(),
                      const SizedBox(height: 32),
                    ],
                  ),
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(color: DesignTokens.accent),
              ),
              error: (error, stack) => Center(
                child: Text(
                  'Hata: $error',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showPurchaseDialog(
    BuildContext context,
    WidgetRef ref,
    ExamModel exam,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          exam.name,
          style: GoogleFonts.spaceGrotesk(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              exam.description ?? '',
              style: GoogleFonts.inter(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: Colors.greenAccent,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Bir kez satın alın, istediğiniz kadar çözün!',
                      style: GoogleFonts.inter(
                        color: Colors.greenAccent,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${exam.price}',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: DesignTokens.accent,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '₺',
                  style: GoogleFonts.inter(fontSize: 20, color: Colors.white60),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          FilledButton.icon(
            onPressed: () async {
              Navigator.pop(context);
              await _processPurchase(context, ref, exam);
            },
            icon: const Icon(Icons.shopping_cart),
            style: FilledButton.styleFrom(
              backgroundColor: DesignTokens.accent,
              foregroundColor: Colors.black,
            ),
            label: const Text('Satın Al'),
          ),
        ],
      ),
    );
  }

  Future<void> _processPurchase(
    BuildContext context,
    WidgetRef ref,
    ExamModel exam,
  ) async {
    // TODO: RevenueCat entegrasyonu
    // Şimdilik test amaçlı doğrudan kayıt
    try {
      await ref
          .read(examRepositoryProvider)
          .recordPurchase(
            examId: exam.id,
            productId: exam.productId ?? '',
            transactionId: 'test_${DateTime.now().millisecondsSinceEpoch}',
            price: exam.price.toDouble(),
            platform: 'test',
          );

      // Provider'ı yenile
      ref.invalidate(userPurchasedExamsProvider);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${exam.name} satın alındı!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Satın alma hatası: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

class _HeaderCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return PremiumGlassContainer(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: DesignTokens.accent.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.shopping_bag,
              size: 40,
              color: DesignTokens.accent,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Deneme Sınavları',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Pro üyelikten bağımsız olarak istediğiniz denemeyi satın alın',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 14, color: Colors.white60),
          ),
        ],
      ),
    );
  }
}

class _ExamPurchaseCard extends StatelessWidget {
  final ExamModel exam;
  final bool isPurchased;
  final VoidCallback onPurchase;

  const _ExamPurchaseCard({
    required this.exam,
    required this.isPurchased,
    required this.onPurchase,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: PremiumGlassContainer(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Icon
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _getBadgeColor().withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getExamIcon(),
                    color: _getBadgeColor(),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),

                // Title & description
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
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
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
                                color: _getBadgeColor().withValues(alpha: 0.2),
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
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.white60,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Info row
            Row(
              children: [
                _InfoChip(
                  icon: Icons.quiz_outlined,
                  label: '${exam.totalQuestions} Soru',
                ),
                const SizedBox(width: 8),
                _InfoChip(
                  icon: Icons.timer_outlined,
                  label: '${exam.durationMinutes} dk',
                ),
                const SizedBox(width: 8),
                _InfoChip(icon: Icons.trending_up, label: exam.difficultyLabel),
              ],
            ),

            const SizedBox(height: 16),

            // Price & button
            Row(
              children: [
                // Price
                if (exam.isFree)
                  Text(
                    'ÜCRETSİZ',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.greenAccent,
                    ),
                  )
                else
                  Row(
                    children: [
                      Text(
                        '${exam.price}',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: DesignTokens.accent,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '₺',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          color: Colors.white60,
                        ),
                      ),
                    ],
                  ),

                const Spacer(),

                // Button
                if (isPurchased)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.green.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.check_circle,
                          color: Colors.greenAccent,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          exam.isFree ? 'Erişilebilir' : 'Satın Alındı',
                          style: GoogleFonts.inter(
                            color: Colors.greenAccent,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  FilledButton.icon(
                    onPressed: onPurchase,
                    icon: const Icon(Icons.shopping_cart, size: 18),
                    style: FilledButton.styleFrom(
                      backgroundColor: DesignTokens.accent,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                    label: const Text('Satın Al'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

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

  IconData _getExamIcon() {
    if (exam.isFree) return Icons.card_giftcard;
    if (exam.badge == 'ZOR') return Icons.whatshot;
    if (exam.badge == 'ÖNERİLEN') return Icons.star;
    return Icons.assignment;
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white60),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.inter(fontSize: 11, color: Colors.white70),
          ),
        ],
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return PremiumGlassContainer(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ℹ️ Bilgilendirme',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          _InfoRow(
            icon: Icons.check_circle_outline,
            text: 'Her deneme bir kez satın alınır, sınırsız çözülebilir',
          ),
          _InfoRow(
            icon: Icons.check_circle_outline,
            text: 'Satın alımlar Pro üyelikten bağımsızdır',
          ),
          _InfoRow(
            icon: Icons.check_circle_outline,
            text: 'Her deneme 120 soru, 150 dakika süre içerir',
          ),
          _InfoRow(
            icon: Icons.check_circle_outline,
            text: 'Detaylı analiz ve çözüm videoları dahil',
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.greenAccent),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(fontSize: 13, color: Colors.white70),
            ),
          ),
        ],
      ),
    );
  }
}
