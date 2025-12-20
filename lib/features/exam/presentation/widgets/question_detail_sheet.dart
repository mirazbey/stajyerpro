import 'package:flutter/material.dart';
import '../../../../shared/models/question_model.dart';

class QuestionDetailSheet extends StatelessWidget {
  final QuestionModel question;
  final int userAnswerIndex;
  final VoidCallback? onAddToWrongPool;
  final VoidCallback? onNext;

  const QuestionDetailSheet({
    super.key,
    required this.question,
    required this.userAnswerIndex,
    this.onAddToWrongPool,
    this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final isCorrect = userAnswerIndex == question.correctIndex;

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Handle bar
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),

                    // Status header
                    _buildStatusHeader(isCorrect),

                    const SizedBox(height: 24),

                    // Soru metni
                    Text(
                      question.stem,
                      style: const TextStyle(fontSize: 16, height: 1.5),
                    ),

                    const SizedBox(height: 24),

                    // Şıklar
                    ...List.generate(question.options.length, (index) {
                      return _buildOptionTile(index);
                    }),

                    const SizedBox(height: 24),

                    // Kanun maddesi
                    if (question.lawArticle != null) ...[
                      _buildSectionHeader('📖 İlgili Kanun'),
                      _buildInfoCard(question.lawArticle!),
                      const SizedBox(height: 16),
                    ],

                    // Açıklama
                    if (question.detailedExplanation != null) ...[
                      _buildSectionHeader('✅ Doğru Cevap Açıklaması'),
                      _buildInfoCard(question.detailedExplanation!),
                      const SizedBox(height: 16),
                    ] else if (question.explanation != null) ...[
                      // Fallback to old explanation if new one is missing
                      _buildSectionHeader('💡 Açıklama'),
                      _buildInfoCard(question.explanation!),
                      const SizedBox(height: 16),
                    ],

                    // Yanlış şık açıklamaları
                    if (!isCorrect && question.wrongReasons != null) ...[
                      _buildSectionHeader('❌ Neden Yanlış?'),
                      _buildInfoCard(
                        question.wrongReasons![userAnswerIndex] ??
                            'Bu seçenek için özel bir açıklama bulunmuyor.',
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Action buttons
                    if (!isCorrect && onAddToWrongPool != null)
                      ElevatedButton.icon(
                        onPressed: () {
                          onAddToWrongPool!();
                          // Don't pop here if onNext is present, let user decide
                          if (onNext == null) Navigator.pop(context);
                        },
                        icon: const Icon(Icons.bookmark_add),
                        label: const Text('Yanlış Havuzuna Ekle'),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 48),
                        ),
                      ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),

              // Next Button Footer
              if (onNext != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: onNext,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Sonraki Soru',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusHeader(bool isCorrect) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCorrect
            ? Colors.green.withOpacity(0.1)
            : Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            isCorrect ? Icons.check_circle : Icons.cancel,
            color: isCorrect ? Colors.green : Colors.red,
            size: 32,
          ),
          const SizedBox(width: 12),
          Text(
            isCorrect ? 'Doğru! 🎉' : 'Yanlış 😔',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isCorrect ? Colors.green : Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionTile(int index) {
    final isUserAnswer = index == userAnswerIndex;
    final isCorrectAnswer = index == question.correctIndex;

    Color? backgroundColor;
    Color? borderColor;

    if (isCorrectAnswer) {
      backgroundColor = Colors.green.withOpacity(0.1);
      borderColor = Colors.green;
    } else if (isUserAnswer) {
      backgroundColor = Colors.red.withOpacity(0.1);
      borderColor = Colors.red;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border.all(color: borderColor ?? Colors.grey[300]!, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${String.fromCharCode(65 + index)})',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              question.options[index],
              style: const TextStyle(fontSize: 15),
            ),
          ),
          if (isCorrectAnswer) const Icon(Icons.check, color: Colors.green),
          if (isUserAnswer && !isCorrectAnswer)
            const Icon(Icons.close, color: Colors.red),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.blue,
        ),
      ),
    );
  }

  Widget _buildInfoCard(String content) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withOpacity(0.2)),
      ),
      child: Text(content, style: const TextStyle(fontSize: 14, height: 1.6)),
    );
  }
}
