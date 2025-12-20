import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../shared/models/chat_model.dart';
import '../data/ai_coach_repository.dart';
import '../../../core/subscription/subscription_service.dart';
import '../../../core/theme/design_tokens.dart';

final chatMessagesProvider = StreamProvider.family<List<ChatMessage>, String>(
  (ref, sessionId) {
    final repository = ref.watch(aiCoachRepositoryProvider);
    return repository.getMessages(sessionId);
  },
);

final chatSessionsProvider = StreamProvider<List<ChatSession>>((ref) {
  final repository = ref.watch(aiCoachRepositoryProvider);
  return repository.getChatSessions();
});

class AIChatScreen extends ConsumerStatefulWidget {
  final String? sessionId;

  const AIChatScreen({super.key, this.sessionId});

  @override
  ConsumerState<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends ConsumerState<AIChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String? _activeSessionId;
  bool _isLoading = false;

  // Mock data for demonstration if real data is empty
  final List<ChatMessage> _mockMessages = [
    ChatMessage(
      id: '1',
      userId: 'mock_user',
      role: 'user',
      content: 'TCK madde 81 hakkında bilgi verir misin?',
      createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
    ),
    ChatMessage(
      id: '2',
      userId: 'mock_user',
      role: 'assistant',
      content:
          'Elbette. Türk Ceza Kanunu\'nun 81. maddesi "Kasten Öldürme" suçunu düzenler. Madde metni şöyledir: "Bir insanı kasten öldüren kişi, müebbet hapis cezası ile cezalandırılır."',
      createdAt: DateTime.now().subtract(const Duration(minutes: 4)),
    ),
    ChatMessage(
      id: '3',
      userId: 'mock_user',
      role: 'user',
      content: 'Peki nitelikli halleri nelerdir?',
      createdAt: DateTime.now().subtract(const Duration(minutes: 3)),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _activeSessionId = widget.sessionId;
    _initializeSession();
  }

  Future<void> _initializeSession() async {
    if (_activeSessionId == null) {
      try {
        final repository = ref.read(aiCoachRepositoryProvider);
        _activeSessionId = await repository.createChatSession();
        if (mounted) setState(() {});
      } catch (e) {
        // Handle error silently or show snackbar
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    if (_controller.text.trim().isEmpty || _activeSessionId == null) return;

    final subscriptionService = ref.read(subscriptionServiceProvider);
    final allowed = await subscriptionService.canUseAi();
    if (!allowed) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Free planda günlük AI limitine ulaşıldı. Pro ile sınırsız erişim sağlayın.',
            ),
            backgroundColor: DesignTokens.warning,
          ),
        );
      }
      return;
    }

    final content = _controller.text.trim();
    _controller.clear();

    setState(() {
      _isLoading = true;
    });

    try {
      await ref
          .read(aiCoachRepositoryProvider)
          .sendMessage(sessionId: _activeSessionId!, content: content);

      await subscriptionService.recordAiUsage();

      Future.delayed(const Duration(milliseconds: 300), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $e'),
            backgroundColor: DesignTokens.error,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = _activeSessionId != null
        ? ref.watch(chatMessagesProvider(_activeSessionId!))
        : const AsyncValue.loading();
    final sessionsAsync = ref.watch(chatSessionsProvider);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      extendBodyBehindAppBar: true,
      drawer: _buildChatHistoryDrawer(sessionsAsync),
      body: Builder(
        builder: (context) => Stack(
          fit: StackFit.expand,
          children: [
            // Layer 1: Background Image
            Image.asset(
              'assets/images/yenigorseller/ai_chat_bot.png',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                color: const Color(0xFF0F172A), // Fallback dark color
              ),
            ),

            // Layer 2: Overlay
            Container(color: Colors.black.withOpacity(0.6)),

            // Content
            SafeArea(
              child: Column(
                children: [
                  // Top Bar
                  _buildTopBar(context),

                  // Chat Area
                  Expanded(
                    child: messagesAsync.when(
                      data: (messages) {
                        // Use mock data if real data is empty for demonstration
                        final displayMessages = messages.isEmpty
                            ? _mockMessages
                            : messages;
                        return _buildMessageList(displayMessages);
                      },
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (e, _) => Center(
                        child: Text(
                          'Hata oluştu',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ),

                  // Suggested Questions (only show when no messages)
                  if (messagesAsync.hasValue && messagesAsync.value!.isEmpty)
                    _buildSuggestedQuestions(),

                  // Input Area
                  _buildInputArea(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatHistoryDrawer(AsyncValue<List<ChatSession>> sessionsAsync) {
    return Drawer(
      backgroundColor: const Color(0xFF1E293B),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B82F6).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.history,
                      color: Color(0xFF3B82F6),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Sohbet Geçmişi',
                    style: GoogleFonts.spaceGrotesk(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(color: Colors.white12),

            // New Chat Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    Navigator.pop(context);
                    final repository = ref.read(aiCoachRepositoryProvider);
                    final newSessionId = await repository.createChatSession();
                    setState(() {
                      _activeSessionId = newSessionId;
                    });
                  },
                  icon: const Icon(Icons.add, size: 20),
                  label: Text(
                    'Yeni Sohbet',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B82F6),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Sessions List
            Expanded(
              child: sessionsAsync.when(
                data: (sessions) {
                  if (sessions.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.chat_bubble_outline,
                            color: Colors.white24,
                            size: 48,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Henüz sohbet yok',
                            style: GoogleFonts.inter(
                              color: Colors.white38,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: sessions.length,
                    itemBuilder: (context, index) {
                      final session = sessions[index];
                      final isActive = session.id == _activeSessionId;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: isActive
                              ? const Color(0xFF3B82F6).withOpacity(0.2)
                              : Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: isActive
                              ? Border.all(
                                  color: const Color(0xFF3B82F6).withOpacity(0.5),
                                )
                              : null,
                        ),
                        child: ListTile(
                          onTap: () {
                            Navigator.pop(context);
                            setState(() {
                              _activeSessionId = session.id;
                            });
                          },
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isActive
                                  ? const Color(0xFF3B82F6).withOpacity(0.3)
                                  : Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.chat,
                              color: isActive
                                  ? const Color(0xFF3B82F6)
                                  : Colors.white54,
                              size: 18,
                            ),
                          ),
                          title: Text(
                            session.title,
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight:
                                  isActive ? FontWeight.w600 : FontWeight.normal,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            _formatDate(session.updatedAt),
                            style: GoogleFonts.inter(
                              color: Colors.white38,
                              fontSize: 11,
                            ),
                          ),
                          trailing: isActive
                              ? const Icon(
                                  Icons.check_circle,
                                  color: Color(0xFF3B82F6),
                                  size: 18,
                                )
                              : null,
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(color: Colors.white54),
                ),
                error: (_, __) => Center(
                  child: Text(
                    'Yüklenemedi',
                    style: GoogleFonts.inter(color: Colors.white38),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 60) {
      return '${diff.inMinutes} dk önce';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} saat önce';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} gün önce';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  Widget _buildSuggestedQuestions() {
    final suggestions = [
      'TCK madde 81 nedir?',
      'Ceza muhakemesinde tutuklama şartları',
      'İdari yargıda iptal davası',
      'Borçlar hukukunda temerrüt',
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Önerilen Sorular',
            style: GoogleFonts.inter(
              color: Colors.white54,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: suggestions.map((q) {
              return GestureDetector(
                onTap: () {
                  _controller.text = q;
                  _sendMessage();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.15)),
                  ),
                  child: Text(
                    q,
                    style: GoogleFonts.inter(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        children: [
          // Menu Button for Chat History
          GestureDetector(
            onTap: () => Scaffold.of(context).openDrawer(),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withOpacity(0.2)),
                  ),
                  child: const Icon(
                    Icons.menu,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Filter Chips
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildGlassChip("Tüm Kaynaklar", isActive: true),
                  const SizedBox(width: 8),
                  _buildGlassChip("TCK", isActive: false),
                  const SizedBox(width: 8),
                  _buildGlassChip("CMK", isActive: false),
                  const SizedBox(width: 8),
                  _buildGlassChip("Anayasa", isActive: false),
                ],
              ),
            ),
          ),

          // Usage Limit Badge
          const SizedBox(width: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                ),
                child: Text(
                  "AI 3/5",
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassChip(String label, {required bool isActive}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(isActive ? 0.15 : 0.05),
            borderRadius: BorderRadius.circular(20),
            border: isActive
                ? Border.all(color: const Color(0xFF3B82F6), width: 1)
                : Border.all(color: Colors.transparent),
          ),
          child: Text(
            label,
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 13,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMessageList(List<ChatMessage> messages) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final msg = messages[index];
        final isUser = msg.role == 'user';
        return Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: isUser
              ? _buildUserMessageBubble(msg.content)
              : _buildAIMessageBubble(msg.content),
        );
      },
    );
  }

  Widget _buildUserMessageBubble(String text) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(4),
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          text,
          style: GoogleFonts.inter(
            color: Colors.black87,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildAIMessageBubble(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(4),
          topRight: Radius.circular(20),
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.85,
            ),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 0.5,
              ),
            ),
            child: Text(
              text,
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 15,
                height: 1.5,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.3),
            border: Border(
              top: BorderSide(color: Colors.white.withOpacity(0.1)),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: TextField(
                    controller: _controller,
                    style: GoogleFonts.inter(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Bir mesaj yazın...',
                      hintStyle: GoogleFonts.inter(color: Colors.white54),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: IconButton(
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.send, color: Colors.white),
                  onPressed: _isLoading ? null : _sendMessage,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
