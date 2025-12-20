import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../shared/widgets/premium_glass_container.dart';
import '../data/gamification_repository.dart';

class LeaderboardScreen extends ConsumerWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repository = ref.watch(gamificationRepositoryProvider);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            'Liderlik Tablosu',
            style: GoogleFonts.spaceGrotesk(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          centerTitle: true,
          bottom: TabBar(
            indicatorColor: DesignTokens.accent,
            labelColor: DesignTokens.accent,
            unselectedLabelColor: Colors.white60,
            labelStyle: GoogleFonts.inter(fontWeight: FontWeight.bold),
            tabs: const [
              Tab(text: 'Haftalık'),
              Tab(text: 'Aylık'),
              Tab(text: 'Tüm Zamanlar'),
            ],
          ),
        ),
        body: Container(
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
          child: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: TabBarView(
                    children: [
                      _LeaderboardList(
                        repository: repository,
                        period: 'weekly',
                      ),
                      _LeaderboardList(
                        repository: repository,
                        period: 'monthly',
                      ),
                      _LeaderboardList(
                        repository: repository,
                        period: 'all_time',
                      ),
                    ],
                  ),
                ),
                _buildInviteSection(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInviteSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Arkadaşlarını Davet Et',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  'Birlikte çalışın, rekabet edin!',
                  style: GoogleFonts.inter(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Share.share(
                'StajyerPro ile HMGS\'ye hazırlanıyorum! Sen de katıl: https://stajyerpro.app',
              );
            },
            icon: const Icon(Icons.share, size: 18),
            label: const Text('Davet Et'),
            style: ElevatedButton.styleFrom(
              backgroundColor: DesignTokens.accent,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LeaderboardList extends StatelessWidget {
  final GamificationRepository repository;
  final String period;

  const _LeaderboardList({required this.repository, required this.period});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: repository.getLeaderboard(period: period),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: DesignTokens.accent),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Hata oluştu', style: TextStyle(color: Colors.white70)),
          );
        }

        final users = snapshot.data ?? [];

        if (users.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.emoji_events_outlined,
                  size: 64,
                  color: Colors.white24,
                ),
                const SizedBox(height: 16),
                Text(
                  'Henüz sıralama yok',
                  style: GoogleFonts.inter(color: Colors.white54),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index];
            final rank = index + 1;
            return _LeaderboardItem(user: user, rank: rank);
          },
        );
      },
    );
  }
}

class _LeaderboardItem extends StatelessWidget {
  final Map<String, dynamic> user;
  final int rank;

  const _LeaderboardItem({required this.user, required this.rank});

  Color _getRankColor() {
    switch (rank) {
      case 1:
        return const Color(0xFFFFD700); // Gold
      case 2:
        return const Color(0xFFC0C0C0); // Silver
      case 3:
        return const Color(0xFFCD7F32); // Bronze
      default:
        return Colors.white;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTop3 = rank <= 3;
    final rankColor = _getRankColor();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: PremiumGlassContainer(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: isTop3
            ? Border.all(color: rankColor.withOpacity(0.5), width: 1)
            : null,
        child: Row(
          children: [
            // Rank
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isTop3 ? rankColor.withOpacity(0.2) : Colors.white10,
                border: isTop3 ? Border.all(color: rankColor, width: 2) : null,
              ),
              child: Text(
                '#$rank',
                style: GoogleFonts.spaceGrotesk(
                  fontWeight: FontWeight.bold,
                  color: isTop3 ? rankColor : Colors.white70,
                  fontSize: 18,
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Avatar
            CircleAvatar(
              radius: 24,
              backgroundColor: Colors.white10,
              backgroundImage: user['avatarUrl'] != null
                  ? NetworkImage(user['avatarUrl'])
                  : null,
              child: user['avatarUrl'] == null
                  ? Text(
                      (user['name'] as String)[0].toUpperCase(),
                      style: GoogleFonts.spaceGrotesk(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 16),
            // Name & Badge
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user['name'],
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (isTop3)
                    Text(
                      rank == 1
                          ? 'Şampiyon 🏆'
                          : rank == 2
                          ? 'Efsane 🔥'
                          : 'Usta ⭐',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: rankColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
            ),
            // Score
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${user['score']}',
                  style: GoogleFonts.spaceGrotesk(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: DesignTokens.accent,
                  ),
                ),
                Text(
                  'Puan',
                  style: GoogleFonts.inter(fontSize: 10, color: Colors.white54),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
