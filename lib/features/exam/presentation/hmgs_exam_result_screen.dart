import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/shadcn_theme.dart';
import '../../../shared/models/exam_model.dart';
import '../../../shared/models/question_model.dart';
import '../data/exam_repository.dart';
import '../domain/exam_distribution.dart';

/// HMGS Sonuç Provider
final hmgsResultProvider = FutureProvider.family<HMGSResultData, String>((ref, attemptId) async {
  final repository = ref.watch(examRepositoryProvider);

  // Get attempt
  final attemptDoc = await repository.firestore
      .collection('exam_attempts')
      .doc(attemptId)
      .get();

  if (!attemptDoc.exists) {
    throw Exception('Sonuç bulunamadı');
  }

  final attempt = ExamAttemptModel.fromFirestore(attemptDoc);

  // Get questions
  final questions = await repository.getExamQuestions(attempt.examId);

  return HMGSResultData(
    attempt: attempt,
    questions: questions,
  );
});

class HMGSResultData {
  final ExamAttemptModel attempt;
  final List<QuestionModel> questions;

  HMGSResultData({
    required this.attempt,
    required this.questions,
  });
}

/// HMGS Deneme Sonuç Ekranı
class HMGSExamResultScreen extends ConsumerWidget {
  final String examId;
  final String attemptId;

  const HMGSExamResultScreen({
    super.key,
    required this.examId,
    required this.attemptId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resultAsync = ref.watch(hmgsResultProvider(attemptId));

    return Scaffold(
      backgroundColor: ShadcnColors.background,
      appBar: AppBar(
        backgroundColor: ShadcnColors.background,
        title: const Text('HMGS Deneme Sonucu'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.go('/dashboard'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              // TODO: Share result
            },
          ),
        ],
      ),
      body: resultAsync.when(
        data: (result) => _buildResultContent(context, ref, result),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
              const SizedBox(height: 16),
              Text('Hata: $error'),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => context.go('/dashboard'),
                child: const Text('Ana Sayfaya Dön'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultContent(BuildContext context, WidgetRef ref, HMGSResultData result) {
    final attempt = result.attempt;
    final passedBaraj = attempt.passedBaraj;

    return SingleChildScrollView(
      child: Column(
        children: [
          // Hero Score Card
          _buildHeroScoreCard(context, attempt, passedBaraj),
          
          // Net Calculation Card
          _buildNetCalculationCard(context, attempt),
          
          // 70 Baraj Card
          _buildBarajCard(context, attempt, passedBaraj),
          
          // Subject Performance
          _buildSubjectPerformance(context, attempt),
          
          // Time Analysis
          _buildTimeAnalysis(context, attempt),
          
          // Question Review
          _buildQuestionReview(context, result),
          
          // Action Buttons
          _buildActionButtons(context),
          
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildHeroScoreCard(BuildContext context, ExamAttemptModel attempt, bool passedBaraj) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: passedBaraj
              ? [Colors.green.shade400, Colors.green.shade700]
              : [Colors.orange.shade400, Colors.orange.shade700],
        ),
        borderRadius: ShadcnRadius.borderXl,
        boxShadow: [
          BoxShadow(
            color: (passedBaraj ? Colors.green : Colors.orange).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Status icon
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              passedBaraj ? Icons.emoji_events : Icons.trending_up,
              size: 48,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          
          // Score
          Text(
            '${attempt.score}',
            style: const TextStyle(
              fontSize: 72,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              height: 1,
            ),
          ),
          Text(
            'PUAN',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.8),
              letterSpacing: 4,
            ),
          ),
          const SizedBox(height: 24),
          
          // Stats row
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: ShadcnRadius.borderLg,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildHeroStat('Doğru', '${attempt.correctAnswers}', Icons.check_circle),
                _buildVerticalDivider(),
                _buildHeroStat('Yanlış', '${attempt.wrongAnswers}', Icons.cancel),
                _buildVerticalDivider(),
                _buildHeroStat('Boş', '${attempt.emptyAnswers}', Icons.remove_circle_outline),
                _buildVerticalDivider(),
                _buildHeroStat('Net', attempt.net.toStringAsFixed(2), Icons.calculate),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          // Duration
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.timer, size: 18, color: Colors.white.withOpacity(0.8)),
              const SizedBox(width: 8),
              Text(
                'Süre: ${_formatDuration(attempt.duration.inSeconds)}',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeroStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 20, color: Colors.white.withOpacity(0.8)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.white.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      width: 1,
      height: 40,
      color: Colors.white.withOpacity(0.2),
    );
  }

  Widget _buildNetCalculationCard(BuildContext context, ExamAttemptModel attempt) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ShadcnColors.card,
        borderRadius: ShadcnRadius.borderLg,
        border: Border.all(color: ShadcnColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.calculate, color: ShadcnColors.primary, size: 24),
              const SizedBox(width: 12),
              Text('HMGS Net Hesaplama', style: ShadcnTypography.h4),
            ],
          ),
          const SizedBox(height: 16),
          
          // Formula
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: ShadcnColors.muted.withOpacity(0.5),
              borderRadius: ShadcnRadius.borderMd,
            ),
            child: Column(
              children: [
                Text(
                  'Net = Doğru - (Yanlış ÷ 4)',
                  style: ShadcnTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildFormulaBox('${attempt.correctAnswers}', Colors.green),
                    const Text(' - (', style: TextStyle(fontSize: 18)),
                    _buildFormulaBox('${attempt.wrongAnswers}', Colors.red),
                    const Text(' ÷ 4) = ', style: TextStyle(fontSize: 18)),
                    _buildFormulaBox(attempt.net.toStringAsFixed(2), ShadcnColors.primary),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          // Info
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: ShadcnRadius.borderMd,
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue.shade600, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'HMGS\'de her 4 yanlış 1 doğruyu götürür. Boş bırakılan sorular nete etki etmez.',
                    style: TextStyle(
                      color: Colors.blue.shade700,
                      fontSize: 13,
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

  Widget _buildFormulaBox(String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        value,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _buildBarajCard(BuildContext context, ExamAttemptModel attempt, bool passedBaraj) {
    final pointsToBaraj = attempt.pointsToBaraj;
    final progress = (attempt.score / 100).clamp(0.0, 1.0);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ShadcnColors.card,
        borderRadius: ShadcnRadius.borderLg,
        border: Border.all(color: ShadcnColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                passedBaraj ? Icons.check_circle : Icons.flag,
                color: passedBaraj ? Colors.green : Colors.orange,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text('70 Baraj Durumu', style: ShadcnTypography.h4),
            ],
          ),
          const SizedBox(height: 16),
          
          // Progress bar
          Stack(
            children: [
              Container(
                height: 32,
                decoration: BoxDecoration(
                  color: ShadcnColors.muted,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              FractionallySizedBox(
                widthFactor: progress,
                child: Container(
                  height: 32,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: passedBaraj
                          ? [Colors.green.shade400, Colors.green.shade600]
                          : [Colors.orange.shade400, Colors.orange.shade600],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              // Baraj line at 70%
              Positioned(
                left: MediaQuery.of(context).size.width * 0.7 - 48, // Adjust for padding
                top: 0,
                bottom: 0,
                child: Container(
                  width: 3,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // Score label
              Positioned.fill(
                child: Center(
                  child: Text(
                    '${attempt.score} / 100',
                    style: TextStyle(
                      color: progress > 0.4 ? Colors.white : ShadcnColors.foreground,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          // Labels
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('0', style: ShadcnTypography.labelSmall),
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text('70 (Baraj)', style: ShadcnTypography.labelSmall.copyWith(color: Colors.red)),
                ],
              ),
              Text('100', style: ShadcnTypography.labelSmall),
            ],
          ),
          const SizedBox(height: 16),
          
          // Result message
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: passedBaraj ? Colors.green.shade50 : Colors.orange.shade50,
              borderRadius: ShadcnRadius.borderMd,
              border: Border.all(
                color: passedBaraj ? Colors.green.shade200 : Colors.orange.shade200,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  passedBaraj ? Icons.celebration : Icons.trending_up,
                  color: passedBaraj ? Colors.green.shade700 : Colors.orange.shade700,
                  size: 32,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        passedBaraj ? 'Tebrikler! 🎉' : 'Hedefe Yaklaşıyorsun! 💪',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: passedBaraj ? Colors.green.shade700 : Colors.orange.shade700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        passedBaraj
                            ? 'Baraj puanını ${attempt.score - 70} puan geçtiniz!'
                            : 'Baraj için ${pointsToBaraj.toStringAsFixed(0)} puan daha gerekiyor.',
                        style: TextStyle(
                          color: passedBaraj ? Colors.green.shade600 : Colors.orange.shade600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectPerformance(BuildContext context, ExamAttemptModel attempt) {
    final subjectResults = attempt.subjectResults;
    if (subjectResults == null || subjectResults.isEmpty) {
      return const SizedBox.shrink();
    }

    // Sort by net (descending)
    final sortedResults = subjectResults.entries.toList()
      ..sort((a, b) => b.value.net.compareTo(a.value.net));

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ShadcnColors.card,
        borderRadius: ShadcnRadius.borderLg,
        border: Border.all(color: ShadcnColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bar_chart, color: ShadcnColors.primary, size: 24),
              const SizedBox(width: 12),
              Text('Ders Bazlı Performans', style: ShadcnTypography.h4),
            ],
          ),
          const SizedBox(height: 16),
          
          // Legend
          Row(
            children: [
              _buildLegendItem('Doğru', Colors.green),
              const SizedBox(width: 16),
              _buildLegendItem('Yanlış', Colors.red),
              const SizedBox(width: 16),
              _buildLegendItem('Boş', Colors.grey),
            ],
          ),
          const SizedBox(height: 16),
          
          // Subject bars
          ...sortedResults.map((entry) {
            final result = entry.value;
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          result.subjectName,
                          style: ShadcnTypography.labelMedium,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        'Net: ${result.net.toStringAsFixed(2)}',
                        style: ShadcnTypography.labelSmall.copyWith(
                          color: result.net >= 0 ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  
                  // Stacked bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: SizedBox(
                      height: 24,
                      child: Row(
                        children: [
                          if (result.correctAnswers > 0)
                            Expanded(
                              flex: result.correctAnswers,
                              child: Container(
                                color: Colors.green,
                                child: Center(
                                  child: Text(
                                    '${result.correctAnswers}',
                                    style: const TextStyle(color: Colors.white, fontSize: 11),
                                  ),
                                ),
                              ),
                            ),
                          if (result.wrongAnswers > 0)
                            Expanded(
                              flex: result.wrongAnswers,
                              child: Container(
                                color: Colors.red,
                                child: Center(
                                  child: Text(
                                    '${result.wrongAnswers}',
                                    style: const TextStyle(color: Colors.white, fontSize: 11),
                                  ),
                                ),
                              ),
                            ),
                          if (result.emptyAnswers > 0)
                            Expanded(
                              flex: result.emptyAnswers,
                              child: Container(
                                color: Colors.grey.shade300,
                                child: Center(
                                  child: Text(
                                    '${result.emptyAnswers}',
                                    style: TextStyle(color: Colors.grey.shade700, fontSize: 11),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${result.totalQuestions} soru',
                    style: ShadcnTypography.labelSmall.copyWith(color: ShadcnColors.mutedForeground),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: ShadcnTypography.labelSmall),
      ],
    );
  }

  Widget _buildTimeAnalysis(BuildContext context, ExamAttemptModel attempt) {
    final analysis = attempt.getTimeManagementAnalysis();
    if (analysis.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ShadcnColors.card,
        borderRadius: ShadcnRadius.borderLg,
        border: Border.all(color: ShadcnColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.timer, color: ShadcnColors.primary, size: 24),
              const SizedBox(width: 12),
              Text('Zaman Yönetimi', style: ShadcnTypography.h4),
            ],
          ),
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: _buildTimeStat(
                  'Toplam Süre',
                  _formatDuration(analysis['totalSeconds']),
                  Icons.timelapse,
                ),
              ),
              Expanded(
                child: _buildTimeStat(
                  'Ort. / Soru',
                  '${analysis['averageSeconds']} sn',
                  Icons.av_timer,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildTimeStat(
                  'En Hızlı',
                  '${analysis['fastestSeconds']} sn',
                  Icons.flash_on,
                  color: Colors.green,
                ),
              ),
              Expanded(
                child: _buildTimeStat(
                  'En Yavaş',
                  '${analysis['slowestSeconds']} sn',
                  Icons.hourglass_bottom,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimeStat(String label, String value, IconData icon, {Color? color}) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: (color ?? ShadcnColors.primary).withOpacity(0.1),
        borderRadius: ShadcnRadius.borderMd,
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: color ?? ShadcnColors.primary),
          const SizedBox(height: 8),
          Text(
            value,
            style: ShadcnTypography.h4.copyWith(color: color ?? ShadcnColors.primary),
          ),
          Text(
            label,
            style: ShadcnTypography.labelSmall.copyWith(color: ShadcnColors.mutedForeground),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionReview(BuildContext context, HMGSResultData result) {
    final attempt = result.attempt;
    final questions = result.questions;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ShadcnColors.card,
        borderRadius: ShadcnRadius.borderLg,
        border: Border.all(color: ShadcnColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.quiz, color: ShadcnColors.primary, size: 24),
                  const SizedBox(width: 12),
                  Text('Soru İnceleme', style: ShadcnTypography.h4),
                ],
              ),
              TextButton(
                onPressed: () {
                  // TODO: Navigate to full question review
                },
                child: const Text('Tümünü Gör'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Only show wrong and empty questions
          ...questions.asMap().entries
              .where((entry) {
                final userAnswer = attempt.answers[entry.key];
                return userAnswer == null || userAnswer != entry.value.correctIndex;
              })
              .take(5)
              .map((entry) {
                final index = entry.key;
                final question = entry.value;
                final userAnswer = attempt.answers[index];
                final isEmpty = userAnswer == null;
                
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isEmpty 
                        ? Colors.grey.shade50 
                        : Colors.red.shade50,
                    borderRadius: ShadcnRadius.borderMd,
                    border: Border.all(
                      color: isEmpty 
                          ? Colors.grey.shade200 
                          : Colors.red.shade200,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: isEmpty ? Colors.grey : Colors.red,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Soru ${index + 1}',
                              style: const TextStyle(color: Colors.white, fontSize: 12),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: ShadcnColors.muted,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              getSubjectName(question.subjectId),
                              style: ShadcnTypography.labelSmall,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            isEmpty ? 'Boş' : 'Yanlış',
                            style: TextStyle(
                              color: isEmpty ? Colors.grey : Colors.red,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        question.stem,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: ShadcnTypography.bodySmall,
                      ),
                    ],
                  ),
                );
              }),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => context.go('/dashboard'),
              icon: const Icon(Icons.home),
              label: const Text('Ana Sayfaya Dön'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => context.push('/exams'),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Yeni Deneme'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => context.push('/wrong-answers'),
                  icon: const Icon(Icons.error_outline),
                  label: const Text('Yanlışlarım'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;
    
    if (hours > 0) {
      return '${hours}s ${minutes}dk ${secs}sn';
    } else if (minutes > 0) {
      return '${minutes}dk ${secs}sn';
    }
    return '${secs}sn';
  }
}
