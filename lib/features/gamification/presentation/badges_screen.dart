import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stajyerpro_app/shared/widgets/glass_container.dart';
import '../data/gamification_repository.dart';
import '../domain/badge_model.dart';

class BadgesScreen extends ConsumerWidget {
  final String userId;

  const BadgesScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repository = ref.watch(gamificationRepositoryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Rozetlerim')),
      body: FutureBuilder(
        future: repository.getUserBadges(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Hata: ${snapshot.error}'));
          }

          final userBadges = snapshot.data ?? [];
          final earnedBadgeIds = userBadges.map((b) => b.badgeId).toSet();

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.8,
            ),
            itemCount: BadgeModel.allBadges.length,
            itemBuilder: (context, index) {
              final badge = BadgeModel.allBadges[index];
              final isEarned = earnedBadgeIds.contains(badge.id);

              return _BadgeCard(badge: badge, isEarned: isEarned);
            },
          );
        },
      ),
    );
  }
}

class _BadgeCard extends StatelessWidget {
  final BadgeModel badge;
  final bool isEarned;

  const _BadgeCard({required this.badge, required this.isEarned});

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      padding: const EdgeInsets.all(16),
      opacity: isEarned ? 0.2 : 0.1,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Badge Icon
          Container(
            height: 80,
            width: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: isEarned
                  ? [
                      BoxShadow(
                        color: badge.color.withOpacity(0.5),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
            child: ColorFiltered(
              colorFilter: isEarned
                  ? const ColorFilter.mode(
                      Colors.transparent,
                      BlendMode.multiply,
                    )
                  : const ColorFilter.mode(Colors.grey, BlendMode.saturation),
              child: Image.asset(
                badge.iconPath,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    Icons.emoji_events,
                    size: 48,
                    color: isEarned ? badge.color : Colors.grey,
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            badge.name,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: isEarned ? Colors.white : Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            badge.description,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: isEarned ? Colors.white70 : Colors.grey,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (isEarned) ...[
            const SizedBox(height: 8),
            const Icon(Icons.check_circle, color: Colors.green, size: 20),
          ],
        ],
      ),
    );
  }
}
