import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:stajyerpro_app/core/theme/design_tokens.dart';
import 'package:stajyerpro_app/core/subscription/subscription_service.dart';
import 'package:stajyerpro_app/features/subjects/data/subjects_repository.dart';
import 'package:stajyerpro_app/features/quiz/presentation/quiz_setup_flow_screen.dart'; // For QuizFlowMode
import 'package:stajyerpro_app/shared/models/subject_model.dart';
import 'package:stajyerpro_app/shared/models/topic_model.dart';

class TopicMapScreen extends ConsumerStatefulWidget {
  const TopicMapScreen({super.key});

  @override
  ConsumerState<TopicMapScreen> createState() => _TopicMapScreenState();
}

class _TopicMapScreenState extends ConsumerState<TopicMapScreen> {
  String? _expandedSubjectId;

  @override
  Widget build(BuildContext context) {
    final subjectsAsync = ref.watch(subjectsStreamProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Deep Space Dark
      body: Stack(
        children: [
          // Background
          const _GlobalAnimatedBackground(),

          SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => context.pop(),
                        icon: const Icon(
                          Icons.arrow_back_ios_new,
                          color: Colors.white,
                        ),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: 0.1),
                          padding: const EdgeInsets.all(12),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        'Konu Haritası',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                // Map Content
                Expanded(
                  child: subjectsAsync.when(
                    data: (subjects) => ListView.builder(
                      padding: const EdgeInsets.all(24),
                      itemCount: subjects.length,
                      itemBuilder: (context, index) {
                        final subject = subjects[index];
                        final isExpanded = _expandedSubjectId == subject.id;

                        return _SubjectNode(
                          subject: subject,
                          isExpanded: isExpanded,
                          index: index,
                          onTap: () {
                            setState(() {
                              if (isExpanded) {
                                _expandedSubjectId = null;
                              } else {
                                _expandedSubjectId = subject.id;
                              }
                            });
                          },
                        );
                      },
                    ),
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (_, __) => const Center(
                      child: Text(
                        'Hata oluştu',
                        style: TextStyle(color: Colors.white),
                      ),
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
}

class _SubjectNode extends ConsumerWidget {
  final SubjectModel subject;
  final bool isExpanded;
  final int index;
  final VoidCallback onTap;

  const _SubjectNode({
    required this.subject,
    required this.isExpanded,
    required this.index,
    required this.onTap,
  });

  void _showTopicQuizSetup(
    BuildContext context,
    WidgetRef ref,
    TopicModel topic,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _TopicQuizSetupSheet(topic: topic),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final topicsAsync = ref.watch(topicsBySubjectStreamProvider(subject.id));
    final color = Colors.primaries[index % Colors.primaries.length];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Subject Card (Root Node)
        GestureDetector(
          onTap: onTap,
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isExpanded
                  ? color.withValues(alpha: 0.2)
                  : Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isExpanded ? color : Colors.white.withValues(alpha: 0.1),
                width: isExpanded ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.book_rounded, color: color),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    subject.name,
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Icon(
                  isExpanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  color: Colors.white70,
                ),
              ],
            ),
          ),
        ).animate().fadeIn(delay: (100 * index).ms).slideX(),

        // Topics (Child Nodes)
        AnimatedSize(
          duration: 300.ms,
          curve: Curves.easeInOut,
          child: isExpanded
              ? topicsAsync.when(
                  data: (topics) => Padding(
                    padding: const EdgeInsets.only(left: 24, bottom: 24),
                    child: IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Connecting Line
                          Container(
                            width: 2,
                            color: color.withValues(alpha: 0.3),
                            margin: const EdgeInsets.only(right: 24),
                          ),

                          // Topics List
                          Expanded(
                            child: Column(
                              children: topics.asMap().entries.map((entry) {
                                final topicIndex = entry.key;
                                final topic = entry.value;
                                return _TopicNode(
                                  topic: topic,
                                  color: color,
                                  index: topicIndex,
                                  onTap: () =>
                                      _showTopicQuizSetup(context, ref, topic),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  loading: () => const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (_, __) => const SizedBox.shrink(),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}

class _TopicNode extends StatelessWidget {
  final TopicModel topic;
  final Color color;
  final int index;
  final VoidCallback onTap;

  const _TopicNode({
    required this.topic,
    required this.color,
    required this.index,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            // Horizontal Connector
            Container(
              width: 16,
              height: 2,
              color: color.withValues(alpha: 0.3),
            ),
            const SizedBox(width: 8),

            // Topic Card
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        topic.name,
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Icon(Icons.play_arrow_rounded, color: color, size: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: (50 * index).ms).slideX(begin: 0.1);
  }
}

class _TopicQuizSetupSheet extends ConsumerStatefulWidget {
  final TopicModel topic;

  const _TopicQuizSetupSheet({required this.topic});

  @override
  ConsumerState<_TopicQuizSetupSheet> createState() =>
      _TopicQuizSetupSheetState();
}

class _TopicQuizSetupSheetState extends ConsumerState<_TopicQuizSetupSheet> {
  int _questionCount = 10;
  String _difficulty = 'all';

  Future<void> _startQuiz() async {
    print('🗺️ [TopicMap] _startQuiz called');
    print('🗺️ [TopicMap] Topic: ${widget.topic.name} (ID: ${widget.topic.id})');
    print('🗺️ [TopicMap] SubjectId: ${widget.topic.subjectId}');
    print('🗺️ [TopicMap] Question count: $_questionCount, difficulty: $_difficulty');
    
    final subscriptionService = ref.read(subscriptionServiceProvider);
    final allowed = await subscriptionService.canStartQuiz(_questionCount);
    print('🗺️ [TopicMap] Subscription check: allowed=$allowed');

    if (!allowed) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Günlük soru limitine ulaşıldı. Pro ile sınırsız erişim sağlayın.',
            ),
          ),
        );
      }
      return;
    }

    if (mounted) {
      final extra = {
        'mode': QuizFlowMode.custom.name,
        'topicIds': [widget.topic.id],
        'questionCount': _questionCount,
        'difficulty': _difficulty,
        'timeLimit': null,
        // AI Fallback için isimleri gönderiyoruz
        'topicName': widget.topic.name,
        'subjectName': widget.topic.subjectId,
      };
      print('🗺️ [TopicMap] Navigating to /quiz/start with extra: $extra');
      
      context.pop(); // Close bottom sheet
      context.push('/quiz/start', extra: extra);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Color(0xFF1E293B), // Slate 800
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Header
          Text(
            widget.topic.name,
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            'Quiz Ayarları',
            style: GoogleFonts.inter(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 32),

          // Question Count
          Text(
            'Soru Sayısı',
            style: GoogleFonts.inter(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [10, 20, 30, 50].map((count) {
              final isSelected = _questionCount == count;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text('$count'),
                  selected: isSelected,
                  onSelected: (val) {
                    if (val) setState(() => _questionCount = count);
                  },
                  backgroundColor: Colors.white.withValues(alpha: 0.05),
                  selectedColor: DesignTokens.accent,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : Colors.white70,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: isSelected
                          ? DesignTokens.accent
                          : Colors.transparent,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          // Difficulty
          Text(
            'Zorluk',
            style: GoogleFonts.inter(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children:
                [
                  ('all', 'Karışık'),
                  ('easy', 'Kolay'),
                  ('medium', 'Orta'),
                  ('hard', 'Zor'),
                ].map((diff) {
                  final isSelected = _difficulty == diff.$1;
                  return ChoiceChip(
                    label: Text(diff.$2),
                    selected: isSelected,
                    onSelected: (val) {
                      if (val) setState(() => _difficulty = diff.$1);
                    },
                    backgroundColor: Colors.white.withValues(alpha: 0.05),
                    selectedColor: DesignTokens.accent,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.white70,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: isSelected
                            ? DesignTokens.accent
                            : Colors.transparent,
                      ),
                    ),
                  );
                }).toList(),
          ),
          const SizedBox(height: 32),

          // Start Button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _startQuiz,
              style: ElevatedButton.styleFrom(
                backgroundColor: DesignTokens.accent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 4,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.play_arrow_rounded),
                  const SizedBox(width: 8),
                  Text(
                    'Testi Başlat',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// Reusing background
class _GlobalAnimatedBackground extends StatelessWidget {
  const _GlobalAnimatedBackground();

  @override
  Widget build(BuildContext context) {
    return Container(color: const Color(0xFF0F172A));
  }
}
