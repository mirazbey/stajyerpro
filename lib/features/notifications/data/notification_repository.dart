import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/notification_model.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository(
    firestore: FirebaseFirestore.instance,
    auth: FirebaseAuth.instance,
  );
});

class NotificationRepository {
  final FirebaseFirestore firestore;
  final FirebaseAuth auth;

  NotificationRepository({required this.firestore, required this.auth});

  String? get currentUserId => auth.currentUser?.uid;

  /// Kullanıcının bildirimlerini getir
  Stream<List<NotificationModel>> getNotifications({int limit = 50}) {
    if (currentUserId == null) return Stream.value([]);

    return firestore
        .collection('users')
        .doc(currentUserId)
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => NotificationModel.fromFirestore(doc))
              .toList(),
        );
  }

  /// Okunmamış bildirim sayısı
  Stream<int> getUnreadCount() {
    if (currentUserId == null) return Stream.value(0);

    return firestore
        .collection('users')
        .doc(currentUserId)
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// Bildirimi okundu olarak işaretle
  Future<void> markAsRead(String notificationId) async {
    if (currentUserId == null) return;

    await firestore
        .collection('users')
        .doc(currentUserId)
        .collection('notifications')
        .doc(notificationId)
        .update({'isRead': true});
  }

  /// Tüm bildirimleri okundu olarak işaretle
  Future<void> markAllAsRead() async {
    if (currentUserId == null) return;

    final batch = firestore.batch();
    final notifications = await firestore
        .collection('users')
        .doc(currentUserId)
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .get();

    for (var doc in notifications.docs) {
      batch.update(doc.reference, {'isRead': true});
    }

    await batch.commit();
  }

  /// Bildirim oluştur
  Future<void> createNotification({
    required NotificationType type,
    required String title,
    required String content,
    String? actionRoute,
  }) async {
    if (currentUserId == null) return;

    final notification = NotificationModel(
      id: '',
      userId: currentUserId!,
      type: type,
      title: title,
      content: content,
      isRead: false,
      createdAt: DateTime.now(),
      actionRoute: actionRoute,
    );

    await firestore
        .collection('users')
        .doc(currentUserId)
        .collection('notifications')
        .add(notification.toFirestore());
  }

  /// Bildirimi sil
  Future<void> deleteNotification(String notificationId) async {
    if (currentUserId == null) return;

    await firestore
        .collection('users')
        .doc(currentUserId)
        .collection('notifications')
        .doc(notificationId)
        .delete();
  }

  /// Tüm bildirimleri sil
  Future<void> clearAllNotifications() async {
    if (currentUserId == null) return;

    final batch = firestore.batch();
    final notifications = await firestore
        .collection('users')
        .doc(currentUserId)
        .collection('notifications')
        .get();

    for (var doc in notifications.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
  }
}

// Providers
final notificationsProvider = StreamProvider<List<NotificationModel>>((ref) {
  final repository = ref.watch(notificationRepositoryProvider);
  return repository.getNotifications();
});

final unreadNotificationCountProvider = StreamProvider<int>((ref) {
  final repository = ref.watch(notificationRepositoryProvider);
  return repository.getUnreadCount();
});
