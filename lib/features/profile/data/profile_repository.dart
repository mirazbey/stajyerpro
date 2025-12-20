import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/user_model.dart';

// Profile Repository Provider
final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(
    firestore: FirebaseFirestore.instance,
    auth: FirebaseAuth.instance,
  );
});

// User Profile Stream Provider (AutoDispose - only active when watched)
final userProfileStreamProvider = StreamProvider.autoDispose<UserModel?>((ref) {
  final repository = ref.watch(profileRepositoryProvider);
  return repository.getUserProfile();
});

// User Profile Future Provider (for one-time fetch)
final userProfileProvider = FutureProvider<UserModel?>((ref) async {
  final currentUserId = FirebaseAuth.instance.currentUser?.uid;
  if (currentUserId == null) return null;

  final doc = await FirebaseFirestore.instance
      .collection('users')
      .doc(currentUserId)
      .get();

  if (!doc.exists) return null;
  return UserModel.fromFirestore(doc);
});

class ProfileRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  ProfileRepository({
    required FirebaseFirestore firestore,
    required FirebaseAuth auth,
  })  : _firestore = firestore,
        _auth = auth;

  // Get current user ID
  String? get _currentUserId => _auth.currentUser?.uid;

  // Get user profile
  Stream<UserModel?> getUserProfile() {
    if (_currentUserId == null) return Stream.value(null);

    return _firestore
        .collection('users')
        .doc(_currentUserId)
        .snapshots()
        .map((doc) {
          if (!doc.exists) return null;
          return UserModel.fromFirestore(doc);
        });
  }

  // Update user profile
  Future<void> updateProfile(Map<String, dynamic> data) async {
    if (_currentUserId == null) {
      throw Exception('No user logged in');
    }

    data['updated_at'] = DateTime.now().toIso8601String();

    await _firestore.collection('users').doc(_currentUserId).update(data);
  }

  // Create initial profile (called during registration)
  Future<void> createProfile({
    required String uid,
    required String email,
    required String name,
  }) async {
    final now = DateTime.now();

    final userModel = UserModel(
      uid: uid,
      email: email,
      name: name,
      targetRoles: [],
      examTargetDate: null,
      studyIntensity: 'medium',
      planType: 'free',
      isAdmin: false,
      createdAt: now,
      updatedAt: now,
    );

    await _firestore.collection('users').doc(uid).set(userModel.toMap());
  }

  // Check if profile is complete
  Future<bool> isProfileComplete() async {
    if (_currentUserId == null) return false;

    final doc = await _firestore.collection('users').doc(_currentUserId).get();

    if (!doc.exists) return false;

    final data = doc.data()!;
    final targetRoles = data['target_roles'] as List?;

    return targetRoles != null && targetRoles.isNotEmpty;
  }

  // Admin: Update user plan by email
  Future<void> updateUserPlanByEmail(String email, String planType) async {
    try {
      // 1. Find user by email
      final querySnapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        throw Exception('Kullanıcı bulunamadı: $email');
      }

      final docId = querySnapshot.docs.first.id;

      // 2. Update plan type
      await _firestore.collection('users').doc(docId).update({
        'plan_type': planType,
        'updated_at': DateTime.now().toIso8601String(),
      });
      
      print('Admin: Updated user $email to $planType successfully.');
    } catch (e) {
      print('Admin Error: $e');
      rethrow;
    }
  }
}
