// ignore_for_file: avoid_print
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

/// Firestore migration script
/// Mevcut soruları yeni QuestionModel yapısına migrate eder
///
/// Kullanım: dart run scripts/migrate_questions.dart

Future<void> main() async {
  print('🚀 Firestore Migration başlıyor...\n');

  // Firebase'i başlat
  await Firebase.initializeApp();

  final firestore = FirebaseFirestore.instance;
  final questionsRef = firestore.collection('questions');

  // Tüm soruları çek
  print('📥 Sorular yükleniyor...');
  final snapshot = await questionsRef.get();
  print('✅ ${snapshot.docs.length} soru bulundu\n');

  int migratedCount = 0;
  int skippedCount = 0;
  int errorCount = 0;

  for (var doc in snapshot.docs) {
    try {
      final data = doc.data();

      // Eğer zaten yeni alanlar varsa skip
      if (data.containsKey('lawArticle') &&
          data.containsKey('detailedExplanation') &&
          data.containsKey('wrongReasons')) {
        skippedCount++;
        continue;
      }

      // Yeni alanları null olarak ekle (eski veri bozulmasın)
      await doc.reference.update({
        'lawArticle': null,
        'detailedExplanation': null,
        'wrongReasons': null,
        'relatedCases': null,
        'year': null,
        'tags': null,
      });

      migratedCount++;

      if (migratedCount % 10 == 0) {
        print(
          'Progress: $migratedCount/${snapshot.docs.length} sorular migrate edildi',
        );
      }
    } catch (e) {
      errorCount++;
      print('❌ Hata (${doc.id}): $e');
    }
  }

  print('\n${'=' * 50}');
  print('📊 MIGRATION SONUÇLARI:');
  print('=' * 50);
  print('✅ Migrate edilen: $migratedCount');
  print('⏭️  Atlanan: $skippedCount');
  print('❌ Hata: $errorCount');
  print('=' * 50);

  if (errorCount == 0) {
    print('\n🎉 Migration başarıyla tamamlandı!');
  } else {
    print('\n⚠️  Migration tamamlandı ancak $errorCount hata oluştu');
  }
}
