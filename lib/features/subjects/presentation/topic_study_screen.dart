import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../shared/widgets/premium_glass_container.dart';
import '../../../shared/widgets/gradient_button.dart';
import '../../ai_coach/data/ai_coach_repository.dart';
import '../data/subjects_repository.dart';

class TopicStudyScreen extends ConsumerStatefulWidget {
  final String topicId;
  final String topicName;
  final String subjectName;
  final String subjectId;

  const TopicStudyScreen({
    super.key,
    required this.topicId,
    required this.topicName,
    required this.subjectName,
    required this.subjectId,
  });

  @override
  ConsumerState<TopicStudyScreen> createState() => _TopicStudyScreenState();
}

class _TopicStudyScreenState extends ConsumerState<TopicStudyScreen> {
  String? _summary;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSummary();
  }

  Future<void> _loadSummary() async {
    try {
      // 1. Önce kayıtlı özeti kontrol et
      final subjectsRepo = ref.read(subjectsRepositoryProvider);
      // We need a method to get single topic.
      // Currently we only have getTopicsBySubject.
      // Let's assume we can get it from the list or add getTopicById.
      // For now, let's try to get it from the stream provider if possible, or just add getTopicById to repo.

      // Let's add getTopicById to SubjectsRepository first.
      // But since I can't edit two files in one step easily without context switch,
      // I will assume I will add it.

      final topic = await subjectsRepo.getTopicById(widget.topicId);

      if (topic != null &&
          topic.description != null &&
          topic.description!.length > 100) {
        // Kayıtlı özet var ve yeterince uzun (muhtemelen AI generated)
        if (mounted) {
          setState(() {
            _summary = topic.description;
            _isLoading = false;
          });
        }
        return;
      }

      // 2. Yoksa AI ile oluştur (Fallback)
      final aiRepo = ref.read(aiCoachRepositoryProvider);
      final summary = await aiRepo.generateTopicSummary(
        topicName: widget.topicName,
        subjectName: widget.subjectName,
      );

      if (mounted) {
        setState(() {
          _summary = summary;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Column(
          children: [
            Text(
              widget.subjectName,
              style: GoogleFonts.inter(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              widget.topicName,
              style: GoogleFonts.spaceGrotesk(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
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
            child: Column(
              children: [
                Expanded(
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: DesignTokens.accent,
                          ),
                        )
                      : _error != null
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.error_outline,
                                  color: Colors.redAccent,
                                  size: 48,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Özet oluşturulamadı',
                                  style: GoogleFonts.spaceGrotesk(
                                    color: Colors.white,
                                    fontSize: 18,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _error!,
                                  style: GoogleFonts.inter(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 24),
                                GradientButton(
                                  text: 'Tekrar Dene',
                                  onPressed: () {
                                    setState(() {
                                      _isLoading = true;
                                      _error = null;
                                    });
                                    _loadSummary();
                                  },
                                  icon: Icons.refresh,
                                  width: 200,
                                ),
                              ],
                            ),
                          ),
                        )
                      : SingleChildScrollView(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            children: [
                              // Visual Placeholder (Lottie alternative)
                              Container(
                                height: 120,
                                width: double.infinity,
                                margin: const EdgeInsets.only(bottom: 24),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      DesignTokens.accent.withOpacity(0.2),
                                      DesignTokens.primary.withOpacity(0.2),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: DesignTokens.accent.withOpacity(0.3),
                                  ),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.auto_stories,
                                      size: 48,
                                      color: DesignTokens.accent.withOpacity(
                                        0.8,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Konu Anlatımı',
                                      style: GoogleFonts.spaceGrotesk(
                                        color: Colors.white70,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              PremiumGlassContainer(
                                padding: const EdgeInsets.all(24),
                                child: MarkdownBody(
                                  data: _summary!,
                                  styleSheet: MarkdownStyleSheet(
                                    p: GoogleFonts.inter(
                                      color: Colors.white.withOpacity(0.9),
                                      fontSize: 16,
                                      height: 1.6,
                                    ),
                                    h1: GoogleFonts.spaceGrotesk(
                                      color: DesignTokens.accent,
                                      fontSize: 26,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    h1Padding: const EdgeInsets.only(
                                      bottom: 16,
                                    ),
                                    h2: GoogleFonts.spaceGrotesk(
                                      color: const Color(
                                        0xFF60A5FA,
                                      ), // Blue 400
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    h2Padding: const EdgeInsets.only(
                                      top: 24,
                                      bottom: 12,
                                    ),
                                    h3: GoogleFonts.spaceGrotesk(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    h3Padding: const EdgeInsets.only(
                                      top: 16,
                                      bottom: 8,
                                    ),
                                    listBullet: GoogleFonts.inter(
                                      color: DesignTokens.accent,
                                      fontSize: 16,
                                    ),
                                    strong: GoogleFonts.inter(
                                      color: DesignTokens.accent,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    em: GoogleFonts.inter(
                                      color: Colors.white70,
                                      fontStyle: FontStyle.italic,
                                    ),
                                    blockquote: GoogleFonts.inter(
                                      color: Colors.white70,
                                      fontStyle: FontStyle.italic,
                                      fontSize: 15,
                                    ),
                                    blockquoteDecoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.05),
                                      borderRadius: BorderRadius.circular(8),
                                      border: const Border(
                                        left: BorderSide(
                                          color: DesignTokens.accent,
                                          width: 4,
                                        ),
                                      ),
                                    ),
                                    blockquotePadding: const EdgeInsets.all(16),
                                    code: GoogleFonts.firaCode(
                                      color: const Color(
                                        0xFFF472B6,
                                      ), // Pink 400
                                      backgroundColor: Colors.transparent,
                                      fontSize: 14,
                                    ),
                                    codeblockDecoration: BoxDecoration(
                                      color: Colors.black26,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                ),

                // Footer Action
                if (!_isLoading && _error == null)
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: GradientButton(
                      text: 'Pekiştirme Testi Çöz',
                      onPressed: () {
                        // Navigate to immediate feedback quiz
                        context.push(
                          '/subjects/${widget.subjectId}/topics/${widget.topicId}/quiz',
                          extra: {
                            'topicName': widget.topicName,
                            'subjectName': widget.subjectName,
                          },
                        );
                      },
                      icon: Icons.quiz,
                      width: double.infinity,
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
