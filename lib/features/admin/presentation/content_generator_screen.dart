import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../shared/widgets/premium_glass_container.dart';
import '../../../shared/widgets/gradient_button.dart';
import '../../subjects/data/subjects_repository.dart';
import '../../ai_coach/data/ai_coach_repository.dart';

/// İçerik durumu provider'ı
final contentStatsProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final firestore = FirebaseFirestore.instance;
  
  // Ders sayısı
  final subjectsSnap = await firestore.collection('subjects').get();
  final subjectCount = subjectsSnap.docs.length;
  
  // Konu sayısı
  final topicsSnap = await firestore.collectionGroup('topics').get();
  final topicCount = topicsSnap.docs.length;
  
  // Aktif konu sayısı
  final activeTopics = topicsSnap.docs.where((d) => d.data()['isActive'] == true).length;
  
  // Soru sayısı
  final questionsSnap = await firestore.collection('questions').get();
  final questionCount = questionsSnap.docs.length;
  
  // Ders bazlı soru dağılımı
  final questionsBySubject = <String, int>{};
  for (final doc in questionsSnap.docs) {
    final subjectId = doc.data()['subjectId'] as String?;
    if (subjectId != null) {
      questionsBySubject[subjectId] = (questionsBySubject[subjectId] ?? 0) + 1;
    }
  }
  
  // Eksik içerikli konular (soru sayısı < 5)
  final topicsWithFewQuestions = <String>[];
  for (final topic in topicsSnap.docs) {
    final topicId = topic.id;
    final topicQuestions = questionsSnap.docs.where((q) {
      final topicIds = q.data()['topicIds'] as List<dynamic>?;
      return topicIds?.contains(topicId) ?? false;
    }).length;
    if (topicQuestions < 5 && topic.data()['isActive'] == true) {
      topicsWithFewQuestions.add(topic.data()['name'] as String? ?? topicId);
    }
  }
  
  return {
    'subjectCount': subjectCount,
    'topicCount': topicCount,
    'activeTopics': activeTopics,
    'questionCount': questionCount,
    'questionsBySubject': questionsBySubject,
    'topicsWithFewQuestions': topicsWithFewQuestions.take(10).toList(),
  };
});

class ContentGeneratorScreen extends ConsumerStatefulWidget {
  const ContentGeneratorScreen({super.key});

  @override
  ConsumerState<ContentGeneratorScreen> createState() =>
      _ContentGeneratorScreenState();
}

class _ContentGeneratorScreenState
    extends ConsumerState<ContentGeneratorScreen> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
            onPressed: () => context.pop(),
          ),
          title: Text(
            'İçerik Yönetimi',
            style: GoogleFonts.spaceGrotesk(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
          bottom: const TabBar(
            indicatorColor: DesignTokens.accent,
            tabs: [
              Tab(text: 'İçerik Durumu'),
              Tab(text: 'Soru Üretici'),
            ],
          ),
        ),
        body: Stack(
          children: [
            // Background
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: DesignTokens.darkGradient,
                ),
              ),
            ),

            // Content
            SafeArea(
              child: TabBarView(
                children: [const _ContentStatusTab(), const _ContentTab()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// İçerik Durumu Tab'ı - Müfredat yerine geçti
class _ContentStatusTab extends ConsumerWidget {
  const _ContentStatusTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(contentStatsProvider);

    return statsAsync.when(
      data: (stats) => SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Genel İstatistikler
            _SectionTitle(title: 'GENEL DURUM'),
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    icon: Icons.book_outlined,
                    label: 'Ders',
                    value: '${stats['subjectCount']}',
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    icon: Icons.topic_outlined,
                    label: 'Konu',
                    value: '${stats['topicCount']}',
                    color: Colors.purple,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    icon: Icons.check_circle_outline,
                    label: 'Aktif Konu',
                    value: '${stats['activeTopics']}',
                    color: Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    icon: Icons.quiz_outlined,
                    label: 'Toplam Soru',
                    value: '${stats['questionCount']}',
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 32),
            
            // Eksik İçerikli Konular
            _SectionTitle(title: 'EKSİK İÇERİKLİ KONULAR'),
            if ((stats['topicsWithFewQuestions'] as List).isEmpty)
              PremiumGlassContainer(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Tüm aktif konularda yeterli soru bulunuyor!',
                        style: GoogleFonts.inter(color: Colors.white70),
                      ),
                    ),
                  ],
                ),
              )
            else
              PremiumGlassContainer(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.warning_amber, color: Colors.orange, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          '5\'ten az sorusu olan konular:',
                          style: GoogleFonts.inter(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...(stats['topicsWithFewQuestions'] as List).map((topic) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: Colors.orange,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              topic.toString(),
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )),
                  ],
                ),
              ),
              
            const SizedBox(height: 32),
            
            // Bilgi Notu
            PremiumGlassContainer(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: DesignTokens.accent, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Müfredat yapısı Python script ile yönetilmektedir. Yeni konu eklemek için seed_curriculum_hierarchical.py dosyasını kullanın.',
                      style: GoogleFonts.inter(
                        color: Colors.white60,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      loading: () => const Center(
        child: CircularProgressIndicator(color: DesignTokens.accent),
      ),
      error: (err, stack) => Center(
        child: Text(
          'Hata: $err',
          style: const TextStyle(color: Colors.red),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return PremiumGlassContainer(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const Spacer(),
              Text(
                value,
                style: GoogleFonts.spaceGrotesk(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
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
}

class _ContentTab extends ConsumerStatefulWidget {
  const _ContentTab();

  @override
  ConsumerState<_ContentTab> createState() => _ContentTabState();
}

class _ContentTabState extends ConsumerState<_ContentTab> {
  String? _selectedSubjectId;
  String? _selectedSubjectName;
  String? _selectedTopicId;
  String? _selectedTopicName;
  bool _isGenerating = false;
  String? _statusMessage;

  @override
  Widget build(BuildContext context) {
    final subjectsAsync = ref.watch(subjectsStreamProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(title: '1. Ders Seçimi'),
          subjectsAsync.when(
            data: (subjects) {
              return InputDecorator(
                decoration: _inputDecoration(),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedSubjectId,
                    dropdownColor: DesignTokens.surface,
                    style: GoogleFonts.inter(color: Colors.white),
                    icon: const Icon(
                      Icons.arrow_drop_down,
                      color: Colors.white,
                    ),
                    isExpanded: true,
                    items: subjects.map((s) {
                      return DropdownMenuItem(
                        value: s.id,
                        child: Text(s.name),
                        onTap: () => _selectedSubjectName = s.name,
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedSubjectId = value;
                        _selectedTopicId = null; // Reset topic
                      });
                    },
                    hint: const Text(
                      'Ders Seçin',
                      style: TextStyle(color: Colors.white54),
                    ),
                  ),
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(
              child: Text(
                'Hata: $err',
                style: const TextStyle(color: Colors.red),
              ),
            ),
          ),
          const SizedBox(height: 24),

          if (_selectedSubjectId != null) ...[
            _SectionTitle(title: '2. Konu Seçimi'),
            Consumer(
              builder: (context, ref, child) {
                final topicsAsync = ref.watch(
                  topicsBySubjectStreamProvider(_selectedSubjectId!),
                );

                return topicsAsync.when(
                  data: (topics) {
                    if (topics.isEmpty) {
                      return const Text(
                        'Bu derse ait konu bulunamadı.',
                        style: TextStyle(color: Colors.white54),
                      );
                    }

                    return InputDecorator(
                      decoration: _inputDecoration(),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedTopicId,
                          dropdownColor: DesignTokens.surface,
                          style: GoogleFonts.inter(color: Colors.white),
                          icon: const Icon(
                            Icons.arrow_drop_down,
                            color: Colors.white,
                          ),
                          isExpanded: true,
                          items: topics.map((t) {
                            return DropdownMenuItem(
                              value: t.id,
                              child: Text(t.name),
                              onTap: () => _selectedTopicName = t.name,
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() => _selectedTopicId = value);
                          },
                          hint: const Text(
                            'Konu Seçin',
                            style: TextStyle(color: Colors.white54),
                          ),
                        ),
                      ),
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (err, stack) => Center(
                    child: Text(
                      'Hata: $err',
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 32),
          ],

          if (_isGenerating)
            Center(
              child: Column(
                children: [
                  const CircularProgressIndicator(color: DesignTokens.accent),
                  const SizedBox(height: 16),
                  Text(
                    _statusMessage ?? 'İşleniyor...',
                    style: GoogleFonts.inter(color: Colors.white70),
                  ),
                ],
              ),
            )
          else
            GradientButton(
              text: 'İçerik ve Soru Üret (AI)',
              onPressed: _selectedTopicId == null
                  ? null
                  : () => _generateContent(),
              icon: Icons.library_books,
              width: double.infinity,
            ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration() {
    return InputDecoration(
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.1),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    );
  }

  Future<void> _generateContent() async {
    setState(() {
      _isGenerating = true;
      _statusMessage = 'AI Konu İçeriği Hazırlıyor...';
    });

    try {
      final aiRepo = ref.read(aiCoachRepositoryProvider);
      final subjectsRepo = ref.read(subjectsRepositoryProvider);

      // 1. Generate Content
      final content = await aiRepo.generateTopicContentJson(
        topicName: _selectedTopicName!,
        subjectName: _selectedSubjectName!,
      );

      setState(() {
        _statusMessage = 'Veritabanına Kaydediliyor...';
      });

      // 2. Save to Firestore
      await subjectsRepo.saveTopicContent(
        _selectedSubjectId!,
        _selectedTopicId!,
        content,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Konu içeriği ve sorular başarıyla oluşturuldu!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
      }
    }
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        title,
        style: GoogleFonts.inter(
          color: DesignTokens.accent,
          fontSize: 14,
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
        ),
      ),
    );
  }
}
