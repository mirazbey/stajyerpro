import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

// flutter test test/set_admin_script_test.dart

void main() {
  test('Set Admin Role', () async {
    // Initialize Firebase
    // Note: In a test environment, this might require specific setup or mocking.
    // However, for integration tests or if we want to hit real firebase, we need to be careful.
    // Standard flutter test might mock channels.
    // We will try to use the default app if possible, or print instructions if it fails.

    print('🚀 Admin yetkisi verme işlemi başlatılıyor (Test Modu)...');
    const targetEmail = 'haciyatmaz300@gmail.com';
    print('Hedef Email: $targetEmail');

    try {
      // Ensure binding
      TestWidgetsFlutterBinding.ensureInitialized();

      // Initialize Firebase - this might fail in unit test environment without mocks
      // or it might work if we are lucky with the setup.
      // If this fails, we really can't do it from here without a proper backend or admin sdk.
      await Firebase.initializeApp();

      final firestore = FirebaseFirestore.instance;

      // Kullanıcıyı bul
      final querySnapshot = await firestore
          .collection('users')
          .where('email', isEqualTo: targetEmail)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        print('❌ Kullanıcı bulunamadı!');
        return;
      }

      final userDoc = querySnapshot.docs.first;

      // Yetkiyi güncelle
      await userDoc.reference.update({
        'isAdmin': true,
        'updated_at': FieldValue.serverTimestamp(),
      });

      print('✅ BAŞARILI!');
      print('Kullanıcı (${userDoc.id}) artık admin yetkisine sahip.');
    } catch (e) {
      print('❌ Bir hata oluştu: $e');
      // If it's a missing plugin error, we know we can't do it.
    }
  });
}
