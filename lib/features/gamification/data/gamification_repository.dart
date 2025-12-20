import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/badge_model.dart';
import '../domain/user_badge_model.dart';

final gamificationRepositoryProvider = Provider<GamificationRepository>((ref) {
  return GamificationRepository(
    firestore: FirebaseFirestore.instance,
    auth: FirebaseAuth.instance,
  );
});

class GamificationRepository {
  final FirebaseFirestore firestore;
  final FirebaseAuth auth;

  GamificationRepository({required this.firestore, required this.auth});

  /// Kullanıcının kazandığı rozetleri getir
  Future<List<UserBadgeModel>> getUserBadges(String userId) async {
    final snapshot = await firestore
        .collection('user_badges')
        .where('userId', isEqualTo: userId)
        .get();

    return snapshot.docs
        .map((doc) => UserBadgeModel.fromMap(doc.data()))
        .toList();
  }

  /// Yeni rozet kontrolü yap ve varsa ekle
  /// [eventType]: 'exam_completed', 'daily_login' vb.
  /// [value]: Kontrol edilecek değer (örn: toplam deneme sayısı)
  Future<List<BadgeModel>> checkAndUnlockBadges(
    String userId,
    BadgeConditionType type,
    int value,
  ) async {
    final newBadges = <BadgeModel>[];

    // Kullanıcının mevcut rozetlerini al
    final existingBadges = await getUserBadges(userId);
    final existingBadgeIds = existingBadges.map((b) => b.badgeId).toSet();

    // İlgili tipteki tüm rozetleri kontrol et
    final potentialBadges = BadgeModel.allBadges.where(
      (b) => b.conditionType == type,
    );

    for (final badge in potentialBadges) {
      // Zaten kazanılmışsa geç
      if (existingBadgeIds.contains(badge.id)) continue;

      // Koşul sağlanmışsa ekle
      if (value >= badge.conditionValue) {
        await _unlockBadge(userId, badge.id);
        newBadges.add(badge);
      }
    }

    return newBadges;
  }

  Future<void> _unlockBadge(String userId, String badgeId) async {
    final userBadge = UserBadgeModel(
      userId: userId,
      badgeId: badgeId,
      earnedAt: DateTime.now(),
    );

    await firestore.collection('user_badges').add(userBadge.toMap());
  }

  /// Liderlik tablosunu getir
  /// [period]: 'weekly', 'monthly', 'all_time'
  Future<List<Map<String, dynamic>>> getLeaderboard({
    String period = 'all_time',
  }) async {
    // Not: Gerçek bir uygulamada bu sorgular için Cloud Functions veya
    // önceden hesaplanmış (aggregated) koleksiyonlar kullanmak daha performanslıdır.
    // Şimdilik basitçe kullanıcıları puanlarına göre sıralayalım.

    // Bu örnekte 'users' koleksiyonundaki 'targetScore' veya benzeri bir alanı kullanacağız.
    // Ancak gerçek bir leaderboard için 'total_score' gibi bir alan tutulmalı.
    // Şimdilik 'exam_credits' veya mock bir skor alanı üzerinden gidelim.
    // İdeal olan: UserAnalytics koleksiyonundan toplam puanı çekmek.

    // Basitlik için users koleksiyonundan çekip client-side sıralama yapalım (demo amaçlı)
    // Prodüksiyonda: .orderBy('totalScore', descending: true).limit(50) olmalı.

    final snapshot = await firestore.collection('users').limit(50).get();

    final users = snapshot.docs.map((doc) {
      final data = doc.data();
      // Mock score calculation if not present
      final score = (data['total_score'] as num?)?.toInt() ?? 0;
      return {
        'userId': doc.id,
        'name': data['name'] ?? 'Kullanıcı',
        'score': score,
        'avatarUrl': data['avatar_url'], // Varsa
      };
    }).toList();

    // Puana göre sırala
    users.sort((a, b) => (b['score'] as int).compareTo(a['score'] as int));

    return users;
  }
}
