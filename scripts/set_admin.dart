// ignore_for_file: avoid_print
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

/// Admin yetkisi verme scripti
/// Kullanım: dart run scripts/set_admin.dart <email>
/// Örnek: dart run scripts/set_admin.dart haciyatmaz300@gmail.com

Future<void> main(List<String> args) async {
  if (args.isEmpty) {
    print('❌ Lütfen bir email adresi belirtin.');
    print('Örnek: dart run scripts/set_admin.dart user@example.com');
    return;
  }

  final targetEmail = args[0];
  print('🚀 Admin yetkisi verme işlemi başlatılıyor...');
  print('Hedef Email: $targetEmail');

  try {
    // Firebase'i başlat
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
      print(
        'Lütfen email adresini kontrol edin veya kullanıcının kayıtlı olduğundan emin olun.',
      );
      return;
    }

    final userDoc = querySnapshot.docs.first;
    final userData = userDoc.data();
    final currentStatus = userData['isAdmin'] ?? false;

    if (currentStatus == true) {
      print('ℹ️  Bu kullanıcı zaten admin yetkisine sahip.');
      return;
    }

    // Yetkiyi güncelle
    await userDoc.reference.update({
      'isAdmin': true,
      'updated_at': FieldValue.serverTimestamp(),
    });

    print('✅ BAŞARILI!');
    print('Kullanıcı (${userDoc.id}) artık admin yetkisine sahip.');
    print(
      'Değişikliklerin görünmesi için kullanıcının uygulamayı yeniden başlatması gerekebilir.',
    );
  } catch (e) {
    print('❌ Bir hata oluştu: $e');
  }
}
