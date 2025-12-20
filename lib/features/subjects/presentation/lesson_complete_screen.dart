import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../shared/widgets/premium_glass_container.dart';
import '../../../shared/widgets/gradient_button.dart';
import 'dart:math' as math;

/// Ders tamamlama ekranı - Detaylı Feedback ve analiz
class LessonCompleteScreen extends ConsumerStatefulWidget {
  final String topicId;
  final String topicName;
  final String subjectName;
  final String subjectId;
  final int correctAnswers;
  final int totalQuestions;
  final int stepCount;
  final List<Map<String, dynamic>>? questionDetails; // Soru detayları

  const LessonCompleteScreen({
    super.key,
    required this.topicId,
    required this.topicName,
    required this.subjectName,
    required this.subjectId,
    required this.correctAnswers,
    required this.totalQuestions,
    required this.stepCount,
    this.questionDetails,
  });

  @override
  ConsumerState<LessonCompleteScreen> createState() => _LessonCompleteScreenState();
}

class _LessonCompleteScreenState extends ConsumerState<LessonCompleteScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  bool _progressSaved = false;

  double get _scorePercent =>
      widget.totalQuestions > 0 ? widget.correctAnswers / widget.totalQuestions : 0;

  bool get _isPassed => _scorePercent >= 0.6; // %60 ve üzeri başarılı

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 1.0, curve: Curves.easeIn),
      ),
    );

    _controller.forward();
    _saveProgress();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _saveProgress() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      final now = DateTime.now();
      final todayKey = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      // 1. Save lesson progress
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('lesson_progress')
          .doc(widget.topicId)
          .set({
        'topicId': widget.topicId,
        'topicName': widget.topicName,
        'subjectId': widget.subjectId,
        'subjectName': widget.subjectName,
        'correctAnswers': widget.correctAnswers,
        'totalQuestions': widget.totalQuestions,
        'stepCount': widget.stepCount,
        'scorePercent': _scorePercent,
        'isPassed': _isPassed,
        'completedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // 2. Update general statistics (for analytics screen)
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('statistics')
          .doc('overall')
          .set({
        'totalLessonsCompleted': FieldValue.increment(1),
        'totalQuestionsAnswered': FieldValue.increment(widget.totalQuestions),
        'totalCorrectAnswers': FieldValue.increment(widget.correctAnswers),
        'lastStudyDate': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // 3. Update daily statistics
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('daily_stats')
          .doc(todayKey)
          .set({
        'date': todayKey,
        'lessonsCompleted': FieldValue.increment(1),
        'questionsAnswered': FieldValue.increment(widget.totalQuestions),
        'correctAnswers': FieldValue.increment(widget.correctAnswers),
        'studyMinutes': FieldValue.increment(5), // Approximate 5 min per lesson
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // 4. Update subject-specific statistics
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('subject_stats')
          .doc(widget.subjectId)
          .set({
        'subjectId': widget.subjectId,
        'subjectName': widget.subjectName,
        'lessonsCompleted': FieldValue.increment(1),
        'questionsAnswered': FieldValue.increment(widget.totalQuestions),
        'correctAnswers': FieldValue.increment(widget.correctAnswers),
        'lastStudyDate': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // 5. Update topic completion status if passed
      if (_isPassed) {
        await FirebaseFirestore.instance
            .collection('subjects')
            .doc(widget.subjectId)
            .collection('topics')
            .doc(widget.topicId)
            .update({
          'isCompleted': true,
          'completedAt': FieldValue.serverTimestamp(),
          'completedBy': FieldValue.arrayUnion([userId]),
        });
      }

      // 6. Add to study history for analytics
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('study_history')
          .add({
        'type': 'lesson',
        'topicId': widget.topicId,
        'topicName': widget.topicName,
        'subjectId': widget.subjectId,
        'subjectName': widget.subjectName,
        'correctAnswers': widget.correctAnswers,
        'totalQuestions': widget.totalQuestions,
        'scorePercent': _scorePercent,
        'isPassed': _isPassed,
        'completedAt': FieldValue.serverTimestamp(),
      });

      setState(() {
        _progressSaved = true;
      });
    } catch (e) {
      print('Progress save error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background
          _buildBackground(),

          // Content
          SafeArea(
            child: Column(
              children: [
                // App bar
                _buildAppBar(),

                // Main content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        const SizedBox(height: 40),

                        // Result icon with animation
                        _buildResultIcon(),

                        const SizedBox(height: 24),

                        // Title
                        FadeTransition(
                          opacity: _opacityAnimation,
                          child: Text(
                            _isPassed ? 'Tebrikler!' : 'Ders Tamamlandı',
                            style: GoogleFonts.spaceGrotesk(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),

                        const SizedBox(height: 8),

                        FadeTransition(
                          opacity: _opacityAnimation,
                          child: Text(
                            widget.topicName,
                            style: GoogleFonts.inter(
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),

                        const SizedBox(height: 40),

                        // Stats cards
                        _buildStatsGrid(),

                        const SizedBox(height: 24),
                        
                        // Detailed Analysis Card
                        _buildDetailedAnalysis(),

                        const SizedBox(height: 24),

                        // Feedback message
                        _buildFeedbackCard(),

                        const SizedBox(height: 24),

                        // Achievement badge (if passed)
                        if (_isPassed) _buildAchievementBadge(),

                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),

                // Bottom buttons
                _buildBottomButtons(),
              ],
            ),
          ),

          // Confetti overlay (if passed)
          if (_isPassed) _buildConfetti(),
        ],
      ),
    );
  }

  Widget _buildBackground() {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: _isPassed
                ? [
                    const Color(0xFF064E3B),
                    const Color(0xFF0F172A),
                    const Color(0xFF1E293B),
                  ]
                : [
                    const Color(0xFF0F172A),
                    const Color(0xFF1E293B),
                    const Color(0xFF0F172A),
                  ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white70),
            onPressed: () => context.go('/subjects/${widget.subjectId}'),
          ),
          const Spacer(),
          if (_progressSaved)
            Row(
              children: [
                Icon(
                  Icons.cloud_done,
                  size: 16,
                  color: DesignTokens.success.withOpacity(0.7),
                ),
                const SizedBox(width: 4),
                Text(
                  'Kaydedildi',
                  style: GoogleFonts.inter(
                    color: Colors.white60,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildResultIcon() {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          color: _isPassed
              ? DesignTokens.success.withOpacity(0.2)
              : DesignTokens.primary.withOpacity(0.2),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: (_isPassed ? DesignTokens.success : DesignTokens.primary)
                  .withOpacity(0.3),
              blurRadius: 30,
              spreadRadius: 10,
            ),
          ],
        ),
        child: Icon(
          _isPassed ? Icons.check_circle_rounded : Icons.school_rounded,
          color: _isPassed ? DesignTokens.success : DesignTokens.primary,
          size: 60,
        ),
      ),
    );
  }

  Widget _buildStatsGrid() {
    return FadeTransition(
      opacity: _opacityAnimation,
      child: Row(
        children: [
          // Score card
          Expanded(
            child: _buildStatCard(
              icon: Icons.percent,
              label: 'Başarı',
              value: '${(_scorePercent * 100).toInt()}%',
              color: _isPassed ? DesignTokens.success : Colors.orange,
            ),
          ),
          const SizedBox(width: 12),
          // Correct answers
          Expanded(
            child: _buildStatCard(
              icon: Icons.check_circle_outline,
              label: 'Doğru',
              value: '${widget.correctAnswers}/${widget.totalQuestions}',
              color: DesignTokens.success,
            ),
          ),
          const SizedBox(width: 12),
          // Steps completed
          Expanded(
            child: _buildStatCard(
              icon: Icons.layers_outlined,
              label: 'Adım',
              value: '${widget.stepCount}/${widget.stepCount}',
              color: DesignTokens.accent,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return PremiumGlassContainer(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.spaceGrotesk(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              color: Colors.white60,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedAnalysis() {
    final wrongAnswers = widget.totalQuestions - widget.correctAnswers;
    
    // Performance level
    String performanceLevel;
    Color performanceColor;
    String performanceEmoji;
    
    if (_scorePercent >= 0.9) {
      performanceLevel = 'Üstün Başarı';
      performanceColor = const Color(0xFFFFD700);
      performanceEmoji = '🏆';
    } else if (_scorePercent >= 0.8) {
      performanceLevel = 'Çok İyi';
      performanceColor = DesignTokens.success;
      performanceEmoji = '⭐';
    } else if (_scorePercent >= 0.7) {
      performanceLevel = 'İyi';
      performanceColor = const Color(0xFF60A5FA);
      performanceEmoji = '👍';
    } else if (_scorePercent >= 0.6) {
      performanceLevel = 'Geçer';
      performanceColor = Colors.orange;
      performanceEmoji = '✅';
    } else if (_scorePercent >= 0.4) {
      performanceLevel = 'Geliştirilmeli';
      performanceColor = Colors.orange;
      performanceEmoji = '📚';
    } else {
      performanceLevel = 'Tekrar Gerekli';
      performanceColor = Colors.redAccent;
      performanceEmoji = '🔄';
    }

    return FadeTransition(
      opacity: _opacityAnimation,
      child: PremiumGlassContainer(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: DesignTokens.accent.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.analytics_outlined,
                    color: DesignTokens.accent,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Detaylı Analiz',
                  style: GoogleFonts.spaceGrotesk(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Performance level badge
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: performanceColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: performanceColor.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(performanceEmoji, style: const TextStyle(fontSize: 24)),
                  const SizedBox(width: 12),
                  Text(
                    performanceLevel,
                    style: GoogleFonts.spaceGrotesk(
                      color: performanceColor,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Stats table
            _buildAnalysisRow(
              icon: Icons.check_circle,
              iconColor: DesignTokens.success,
              label: 'Doğru Cevap',
              value: '${widget.correctAnswers}',
              detail: 'soru',
            ),
            const Divider(color: Colors.white12, height: 24),
            _buildAnalysisRow(
              icon: Icons.cancel,
              iconColor: Colors.redAccent,
              label: 'Yanlış Cevap',
              value: '$wrongAnswers',
              detail: 'soru',
            ),
            const Divider(color: Colors.white12, height: 24),
            _buildAnalysisRow(
              icon: Icons.layers,
              iconColor: DesignTokens.primary,
              label: 'Tamamlanan Adım',
              value: '${widget.stepCount}',
              detail: 'adım',
            ),
            const Divider(color: Colors.white12, height: 24),
            _buildAnalysisRow(
              icon: Icons.percent,
              iconColor: _isPassed ? DesignTokens.success : Colors.orange,
              label: 'Başarı Oranı',
              value: '${(_scorePercent * 100).toInt()}%',
              detail: _isPassed ? 'Geçti' : 'Kaldı',
            ),
            
            const SizedBox(height: 20),
            
            // Recommendation
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    color: DesignTokens.accent,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _getRecommendation(),
                      style: GoogleFonts.inter(
                        color: Colors.white70,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalysisRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required String detail,
  }) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.inter(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.spaceGrotesk(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          detail,
          style: GoogleFonts.inter(
            color: Colors.white38,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  String _getRecommendation() {
    if (_scorePercent >= 0.9) {
      return 'Harika! Bu konuya hakimsiniz. Bir sonraki konuya geçebilir veya quiz ile pekiştirebilirsiniz.';
    } else if (_scorePercent >= 0.7) {
      return 'İyi gidiyorsunuz! Yanlış yaptığınız konuları tekrar gözden geçirmenizi öneririz.';
    } else if (_scorePercent >= 0.6) {
      return 'Geçtiniz ama temel kavramları tekrar çalışmanızı öneriyoruz. Notlarınıza bakın.';
    } else {
      return 'Bu konuyu tekrar çalışmanız gerekiyor. Adım adım ilerleyin ve her kavramı anlayın.';
    }
  }

  Widget _buildFeedbackCard() {
    String title;
    String message;
    IconData icon;
    Color color;

    if (_scorePercent >= 0.9) {
      title = 'Mükemmel!';
      message = 'Bu konuyu çok iyi öğrendiniz. Bir sonraki konuya geçebilirsiniz.';
      icon = Icons.star;
      color = const Color(0xFFFFD700);
    } else if (_scorePercent >= 0.7) {
      title = 'Çok İyi!';
      message = 'Konuyu iyi kavramışsınız. İsterseniz bir sonraki konuya geçebilirsiniz.';
      icon = Icons.thumb_up;
      color = DesignTokens.success;
    } else if (_scorePercent >= 0.6) {
      title = 'Geçti!';
      message = 'Konuyu geçtiniz ama tekrar çalışmanızı öneririz.';
      icon = Icons.check;
      color = DesignTokens.primary;
    } else {
      title = 'Tekrar Gerekli';
      message = 'Bu konuyu tekrar çalışmanızı öneririz. Endişelenmeyin, pratik yaparak öğreneceksiniz!';
      icon = Icons.refresh;
      color = Colors.orange;
    }

    return FadeTransition(
      opacity: _opacityAnimation,
      child: PremiumGlassContainer(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.spaceGrotesk(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message,
                    style: GoogleFonts.inter(
                      color: Colors.white70,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAchievementBadge() {
    return FadeTransition(
      opacity: _opacityAnimation,
      child: PremiumGlassContainer(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    DesignTokens.success.withOpacity(0.3),
                    DesignTokens.accent.withOpacity(0.3),
                  ],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.verified,
                color: DesignTokens.success,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Konu Tamamlandı ✓',
                    style: GoogleFonts.spaceGrotesk(
                      color: DesignTokens.success,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Bu konu artık yeşil tik ile işaretlendi',
                    style: GoogleFonts.inter(
                      color: Colors.white60,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        border: Border(
          top: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Retry button (only if not passed)
            if (!_isPassed)
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    context.pushReplacement(
                      '/subjects/${widget.subjectId}/topics/${widget.topicId}/lesson',
                    );
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Tekrar Çalış'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white70,
                    side: BorderSide(color: Colors.white.withOpacity(0.3)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            if (!_isPassed) const SizedBox(width: 12),
            // Continue button
            Expanded(
              child: GradientButton(
                text: 'Konulara Dön',
                onPressed: () {
                  context.go('/subjects/${widget.subjectId}');
                },
                icon: Icons.arrow_forward,
                width: double.infinity,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfetti() {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            size: Size.infinite,
            painter: ConfettiPainter(
              progress: _controller.value,
            ),
          );
        },
      ),
    );
  }
}

/// Confetti painter for celebration effect
class ConfettiPainter extends CustomPainter {
  final double progress;
  final math.Random random = math.Random(42);

  ConfettiPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress < 0.3) return;

    final effectProgress = (progress - 0.3) / 0.7;
    final colors = [
      DesignTokens.success,
      DesignTokens.accent,
      DesignTokens.primary,
      const Color(0xFFFFD700),
      Colors.orange,
    ];

    for (int i = 0; i < 50; i++) {
      final x = random.nextDouble() * size.width;
      final startY = -50.0;
      final endY = size.height + 50;
      final y = startY + (endY - startY) * effectProgress;

      final color = colors[i % colors.length].withOpacity(1 - effectProgress);
      final paint = Paint()..color = color;

      final particleSize = 4 + random.nextDouble() * 6;
      canvas.drawCircle(
        Offset(x + math.sin(y * 0.02 + i) * 30, y),
        particleSize,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(ConfettiPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
