import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/user_model.dart';

// Auth Repository Provider
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    firebaseAuth: FirebaseAuth.instance,
    firestore: FirebaseFirestore.instance,
    googleSignIn: GoogleSignIn(
      // Web OAuth Client ID - stajyerpro-app project
      serverClientId: '1042135335286-s5jgqgks7mcu0890mce8el3nlvn2smpg.apps.googleusercontent.com',
    ),
  );
});

// Auth State Provider
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

// Current User Data Provider
final currentUserDataProvider = StreamProvider<UserModel?>((ref) {
  final authState = ref.watch(authStateProvider);
  
  return authState.when(
    data: (user) {
      if (user == null) return Stream.value(null);
      return ref.read(authRepositoryProvider).getUserData(user.uid);
    },
    loading: () => Stream.value(null),
    error: (_, __) => Stream.value(null),
  );
});

class AuthRepository {
  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;
  final GoogleSignIn _googleSignIn;

  AuthRepository({
    required FirebaseAuth firebaseAuth,
    required FirebaseFirestore firestore,
    required GoogleSignIn googleSignIn,
  })  : _firebaseAuth = firebaseAuth,
        _firestore = firestore,
        _googleSignIn = googleSignIn;

  // Auth state changes stream
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  // Current user
  User? get currentUser => _firebaseAuth.currentUser;

  // Email/Password ile kayıt
  Future<UserCredential> signUpWithEmailPassword({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Firestore'da kullanıcı dökümanı oluştur
      await _createUserDocument(
        uid: credential.user!.uid,
        email: email,
        name: name,
      );

      return credential;
    } catch (e) {
      rethrow;
    }
  }

  // Email/Password ile giriş
  Future<UserCredential> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    return await _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  // Google ile giriş
  Future<UserCredential> signInWithGoogle() async {
    try {
      print('🔵 Google Sign-In başlatılıyor...');
      
      // Önce disconnect ile önbelleği tamamen temizle
      try {
        await _googleSignIn.disconnect();
        print('🧹 Google önbellek temizlendi');
      } catch (_) {}
      
      // Kısa bir bekleme süresi ekle (Android için)
      await Future.delayed(const Duration(milliseconds: 300));
      
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        print('❌ Google Sign-In iptal edildi (kullanıcı geri döndü)');
        throw Exception('Google ile giriş iptal edildi');
      }

      print('✅ Google hesabı seçildi: ${googleUser.email}');
      
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      print('✅ Google authentication token alındı');

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      print('✅ Firebase credential oluşturuldu');

      final userCredential = await _firebaseAuth.signInWithCredential(credential);
      print('✅ Firebase authentication başarılı: ${userCredential.user?.email}');

      // Eğer yeni kullanıcıysa Firestore'da döküman oluştur
      final docSnapshot = await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();

      if (!docSnapshot.exists) {
        print('📝 Yeni kullanıcı, Firestore dökümanı oluşturuluyor...');
        await _createUserDocument(
          uid: userCredential.user!.uid,
          email: userCredential.user!.email!,
          name: userCredential.user!.displayName ?? 'User',
        );
        print('✅ Firestore dökümanı oluşturuldu');
      } else {
        print('✅ Mevcut kullanıcı, giriş tamamlandı');
      }

      return userCredential;
    } catch (e, stackTrace) {
      print('❌ Google Sign-In HATASI: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  // Çıkış
  Future<void> signOut() async {
    try {
      await _googleSignIn.disconnect();
    } catch (e) {
      print('Google disconnect error: $e');
    }
    
    await Future.wait([
      _firebaseAuth.signOut(),
      _googleSignIn.signOut(),
    ]);
  }

  // Şifre sıfırlama email gönder
  Future<void> sendPasswordResetEmail(String email) async {
    await _firebaseAuth.sendPasswordResetEmail(email: email);
  }

  // Kullanıcı verilerini getir
  Stream<UserModel?> getUserData(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((doc) {
          if (!doc.exists) return null;
          return UserModel.fromFirestore(doc);
        });
  }

  // Kullanıcı dökümanı oluştur
  Future<void> _createUserDocument({
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

    await _firestore
        .collection('users')
        .doc(uid)
        .set(userModel.toMap());
  }

  // Profil güncelle
  Future<void> updateUserProfile(String uid, Map<String, dynamic> data) async {
    data['updated_at'] = DateTime.now().toIso8601String();
    
    await _firestore
        .collection('users')
        .doc(uid)
        .update(data);
  }
}
