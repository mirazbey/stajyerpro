import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../shared/widgets/premium_glass_container.dart';
import '../../../shared/models/subject_model.dart';
import '../../../shared/models/topic_model.dart';
import '../data/subjects_repository.dart';

/// Topics by subject provider
final topicsStreamProvider = StreamProvider.family<List<TopicModel>, String>((
  ref,
  subjectId,
) {
  final repository = ref.watch(subjectsRepositoryProvider);
  return repository.getTopicsBySubject(subjectId);
});

/// Subject by ID provider
final subjectProvider = FutureProvider.family<SubjectModel?, String>((
  ref,
  subjectId,
) {
  final repository = ref.watch(subjectsRepositoryProvider);
  return repository.getSubjectById(subjectId);
});

/// Kullanıcının tamamladığı topic ID'leri provider
final completedTopicsProvider = StreamProvider<Set<String>>((ref) {
  final userId = FirebaseAuth.instance.currentUser?.uid;
  if (userId == null) return Stream.value({});
  
  return FirebaseFirestore.instance
      .collection('users')
      .doc(userId)
      .collection('lesson_progress')
      .where('isPassed', isEqualTo: true)
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) => doc.id).toSet());
});

/// Seçilen dersin alt konularını gösteren ekran
class TopicDetailScreen extends ConsumerWidget {
  final String subjectId;

  const TopicDetailScreen({super.key, required this.subjectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subjectAsync = ref.watch(subjectProvider(subjectId));
    final topicsAsync = ref.watch(topicsStreamProvider(subjectId));
    final completedTopics = ref.watch(completedTopicsProvider).valueOrNull ?? {};

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: subjectAsync.when(
          data: (subject) => Text(
            subject?.name ?? 'Konular',
            style: GoogleFonts.spaceGrotesk(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          loading: () => Text(
            'Yükleniyor...',
            style: GoogleFonts.spaceGrotesk(color: Colors.white70),
          ),
          error: (_, __) => Text(
            'Konular',
            style: GoogleFonts.spaceGrotesk(color: Colors.white),
          ),
        ),
        centerTitle: true,
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
            child: topicsAsync.when(
              data: (topics) {
                if (topics.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.topic_outlined,
                          size: 64,
                          color: Colors.white24,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Bu derste henüz konu yok',
                          style: GoogleFonts.inter(
                            color: Colors.white60,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Konular yakında eklenecek',
                          style: GoogleFonts.inter(
                            color: Colors.white38,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 24),
                        const SizedBox(height: 24),
                        // Seed button removed to prevent confusion
                        /*
                        OutlinedButton.icon(
                          onPressed: () async {
                            final repo = ref.read(subjectsRepositoryProvider);
                            await repo.seedTopics(subjectId);
                            // Refresh is automatic via stream
                          },
                          icon: const Icon(Icons.download),
                          label: const Text('Örnek Konuları Yükle'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: DesignTokens.accent,
                            side: const BorderSide(color: DesignTokens.accent),
                          ),
                        ),
                        */
                      ],
                    ),
                  );
                }

                return Column(
                  children: [
                    // Ders özeti (Opsiyonel, eğer subject description varsa)
                    if (subjectAsync.hasValue &&
                        subjectAsync.value?.description != null)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: Text(
                          subjectAsync.value!.description!,
                          style: GoogleFonts.inter(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ),

                    // Mini Sınav Butonu
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: _MiniExamButton(
                        subjectId: subjectId,
                        subjectName: subjectAsync.value?.name ?? '',
                      ),
                    ),

                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: topics
                            .where((t) => t.parentId == null)
                            .length,
                        itemBuilder: (context, index) {
                          final rootTopics = topics
                              .where((t) => t.parentId == null)
                              .toList();
                          final topic = rootTopics[index];
                          final subtopics = topics
                              .where((t) => t.parentId == topic.id)
                              .toList();

                          if (subtopics.isEmpty) {
                            return _TopicCard(
                              topic: topic,
                              isCompleted: completedTopics.contains(topic.id),
                              onTap: () => _navigateToLesson(
                                context,
                                topic,
                                subjectAsync.value?.name,
                              ),
                            );
                          } else {
                            return _TopicAccordion(
                              rootTopic: topic,
                              subtopics: subtopics,
                              completedTopicIds: completedTopics,
                              onSubtopicTap: (subtopic) => _navigateToLesson(
                                context,
                                subtopic,
                                subjectAsync.value?.name,
                              ),
                            );
                          }
                        },
                      ),
                    ),
                  ],
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(color: DesignTokens.accent),
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
                      'Konular yüklenemedi',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () {
                        ref.invalidate(topicsStreamProvider(subjectId));
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Tekrar Dene'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: DesignTokens.accent,
                        foregroundColor: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: topicsAsync.when(
        data: (topics) => topics.isNotEmpty
            ? FloatingActionButton.extended(
                onPressed: () {
                  final topicIds = topics.map((t) => t.id).toList();
                  context.push('/quiz/setup', extra: {'topicIds': topicIds});
                },
                backgroundColor: DesignTokens.accent,
                foregroundColor: Colors.black,
                icon: const Icon(Icons.play_arrow_rounded),
                label: Text(
                  'Tüm Konularla Quiz',
                  style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                ),
              )
            : null,
        loading: () => null,
        error: (_, __) => null,
      ),
    );
  }

  void _navigateToLesson(
    BuildContext context,
    TopicModel topic,
    String? subjectName,
  ) {
    context.push(
      '/subjects/$subjectId/topics/${topic.id}/lesson',
      extra: {'topicName': topic.name, 'subjectName': subjectName ?? ''},
    );
  }
}

class _TopicAccordion extends StatelessWidget {
  final TopicModel rootTopic;
  final List<TopicModel> subtopics;
  final Set<String> completedTopicIds;
  final Function(TopicModel) onSubtopicTap;

  const _TopicAccordion({
    required this.rootTopic,
    required this.subtopics,
    required this.completedTopicIds,
    required this.onSubtopicTap,
  });

  // Ana konunun tüm alt konuları tamamlandı mı?
  bool get isRootCompleted {
    if (subtopics.isEmpty) return false;
    return subtopics.every((t) => completedTopicIds.contains(t.id));
  }

  // Tamamlanan alt konu sayısı
  int get completedCount => subtopics.where((t) => completedTopicIds.contains(t.id)).length;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: PremiumGlassContainer(
        padding: EdgeInsets.zero,
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.all(16),
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isRootCompleted 
                    ? DesignTokens.success.withOpacity(0.2) 
                    : DesignTokens.primary.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isRootCompleted 
                      ? DesignTokens.success.withOpacity(0.5) 
                      : DesignTokens.primary.withOpacity(0.3),
                ),
              ),
              child: Icon(
                isRootCompleted ? Icons.check_circle_rounded : Icons.folder_open_rounded,
                size: 24,
                color: isRootCompleted ? DesignTokens.success : DesignTokens.primary,
              ),
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    rootTopic.name,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
                // Progress badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: completedCount > 0 
                        ? DesignTokens.success.withOpacity(0.2) 
                        : Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$completedCount/${subtopics.length}',
                    style: GoogleFonts.spaceGrotesk(
                      color: completedCount > 0 ? DesignTokens.success : Colors.white54,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            subtitle: rootTopic.description != null
                ? Text(
                    rootTopic.description!,
                    style: GoogleFonts.inter(
                      color: Colors.white60,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  )
                : null,
            collapsedIconColor: Colors.white54,
            iconColor: DesignTokens.accent,
            children: subtopics.map((subtopic) {
              final isCompleted = completedTopicIds.contains(subtopic.id);
              return InkWell(
                onTap: () => onSubtopicTap(subtopic),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(color: Colors.white.withOpacity(0.05)),
                    ),
                    color: isCompleted 
                        ? DesignTokens.success.withOpacity(0.05) 
                        : Colors.black12,
                  ),
                  child: Row(
                    children: [
                      // Yeşil tik veya normal ikon
                      isCompleted
                          ? const Icon(
                              Icons.check_circle_rounded,
                              color: DesignTokens.success,
                              size: 18,
                            )
                          : const Icon(
                              Icons.subdirectory_arrow_right_rounded,
                              color: Colors.white38,
                              size: 18,
                            ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          subtopic.name,
                          style: GoogleFonts.inter(
                            color: isCompleted 
                                ? DesignTokens.success.withOpacity(0.9) 
                                : Colors.white.withOpacity(0.9),
                            fontSize: 14,
                            fontWeight: isCompleted ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ),
                      // Tamamlandı rozeti veya ok
                      if (isCompleted)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: DesignTokens.success.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Tamamlandı',
                            style: GoogleFonts.inter(
                              color: DesignTokens.success,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      else
                        const Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: Colors.white24,
                          size: 14,
                        ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

/// Konu kartı widget'ı
class _TopicCard extends StatelessWidget {
  final TopicModel topic;
  final bool isCompleted;
  final VoidCallback onTap;

  const _TopicCard({
    required this.topic, 
    required this.isCompleted,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: onTap,
        child: PremiumGlassContainer(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // İkon - tamamlandıysa yeşil tik
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isCompleted 
                      ? DesignTokens.success.withOpacity(0.2) 
                      : DesignTokens.primary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isCompleted 
                        ? DesignTokens.success.withOpacity(0.5) 
                        : DesignTokens.primary.withOpacity(0.3),
                  ),
                ),
                child: Icon(
                  isCompleted ? Icons.check_circle_rounded : Icons.topic_rounded,
                  size: 24,
                  color: isCompleted ? DesignTokens.success : DesignTokens.primary,
                ),
              ),
              const SizedBox(width: 16),
              // Konu bilgileri
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            topic.name,
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: isCompleted 
                                  ? DesignTokens.success 
                                  : Colors.white,
                            ),
                          ),
                        ),
                        if (isCompleted)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: DesignTokens.success.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Tamamlandı',
                              style: GoogleFonts.inter(
                                color: DesignTokens.success,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (topic.description != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        topic.description!,
                        style: GoogleFonts.inter(
                          color: Colors.white60,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (topic.questionCount != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.quiz_outlined,
                            size: 14,
                            color: DesignTokens.accent,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${topic.questionCount} soru',
                            style: GoogleFonts.inter(
                              color: Colors.white70,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isCompleted ? Icons.refresh_rounded : Icons.arrow_forward_ios_rounded,
                  color: isCompleted ? DesignTokens.success.withOpacity(0.7) : Colors.white54,
                  size: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Mini Sınav Butonu - 20 soru, 25 dakika
class _MiniExamButton extends StatelessWidget {
  final String subjectId;
  final String subjectName;

  const _MiniExamButton({
    required this.subjectId,
    required this.subjectName,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(
        '/subjects/$subjectId/mini-exam',
        extra: {'subjectName': subjectName},
      ),
      child: PremiumGlassContainer(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    DesignTokens.warning.withOpacity(0.3),
                    DesignTokens.warning.withOpacity(0.1),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.assignment_outlined,
                color: DesignTokens.warning,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Mini Sınav',
                    style: GoogleFonts.spaceGrotesk(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '20 soru • 25 dakika',
                    style: GoogleFonts.inter(
                      color: Colors.white60,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            // Arrow
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: DesignTokens.warning.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.play_arrow_rounded,
                color: DesignTokens.warning,
                size: 24,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
