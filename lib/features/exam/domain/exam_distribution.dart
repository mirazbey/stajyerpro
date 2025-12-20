/// HMGS resmi konu dağılımı sabitleri
///
/// 2024 HMGS sınavındaki resmi ders bazlı soru sayıları
/// Toplam: 120 soru
/// 
/// NOT: Bu ID'ler Firestore'daki subjects koleksiyonundaki document ID'leri ile birebir eşleşmeli!

library exam_distribution;

/// HMGS 2024 resmi soru dağılımı (Firestore subject ID'leri ile)
const Map<String, int> HMGS_DISTRIBUTION = {
  // Ana Dersler (15-12 soru)
  'medeni_hukuk': 15,        // Medeni Hukuk
  'borclar_hukuku': 12,      // Borçlar Hukuku
  'ticaret_hukuku': 12,      // Ticaret Hukuku
  'ceza_hukuku': 12,         // Ceza Hukuku (genel + özel birleşik)
  // CMK ve Anayasa (9'ar soru)
  'ceza_muhakemesi': 9,      // Ceza Muhakemesi Hukuku
  'anayasa_hukuku': 9,       // Anayasa Hukuku
  // İdare Dersleri (9'ar soru)
  'idare_hukuku': 9,         // İdare Hukuku
  'idari_yargilama': 6,      // İdari Yargılama Usulü (İYUK)
  // Özel Hukuk Dersleri
  'icra_iflas': 9,           // İcra ve İflas Hukuku
  'is_hukuku': 9,            // İş Hukuku ve Sosyal Güvenlik
  // Diğer Dersler (3-6 soru)
  'avukatlik_hukuku': 6,     // Avukatlık Hukuku
  'milletlerarasi_hukuk': 3, // Milletlerarası Hukuk
  'hukuk_felsefesi': 3,      // Hukuk Felsefesi ve Sosyolojisi
  'vergi_hukuku': 3,         // Vergi Hukuku
  'mohuk': 3,                // Milletlerarası Özel Hukuk (MÖHUK)
};

/// Toplam deneme soru sayısı
const int TOTAL_EXAM_QUESTIONS = 120;

/// Dağılımı doğrula (toplam 120 olmalı)
bool validateDistribution() {
  final sum = HMGS_DISTRIBUTION.values.reduce((a, b) => a + b);
  if (sum != TOTAL_EXAM_QUESTIONS) {
    throw Exception(
      'HMGS dağılımı hatalı! Toplam: $sum, Beklenen: $TOTAL_EXAM_QUESTIONS',
    );
  }
  return true;
}

/// Ders ID'den Türkçe isim (Firestore subject ID'leri ile)
String getSubjectName(String subjectId) {
  const names = {
    'medeni_hukuk': 'Medeni Hukuk',
    'borclar_hukuku': 'Borçlar Hukuku',
    'ticaret_hukuku': 'Ticaret Hukuku',
    'ceza_hukuku': 'Ceza Hukuku',
    'ceza_muhakemesi': 'Ceza Muhakemesi Hukuku',
    'anayasa_hukuku': 'Anayasa Hukuku',
    'idare_hukuku': 'İdare Hukuku',
    'idari_yargilama': 'İdari Yargılama Usulü',
    'icra_iflas': 'İcra ve İflas Hukuku',
    'is_hukuku': 'İş Hukuku',
    'avukatlik_hukuku': 'Avukatlık Hukuku',
    'milletlerarasi_hukuk': 'Milletlerarası Hukuk',
    'hukuk_felsefesi': 'Hukuk Felsefesi',
    'vergi_hukuku': 'Vergi Hukuku',
    'mohuk': 'Milletlerarası Özel Hukuk (MÖHUK)',
  };
  return names[subjectId] ?? subjectId;
}

/// Eksik soru kontrolü için helper
class DistributionValidationError {
  final String subjectId;
  final int required;
  final int available;

  DistributionValidationError({
    required this.subjectId,
    required this.required,
    required this.available,
  });

  @override
  String toString() {
    return '${getSubjectName(subjectId)}: $available/$required soru';
  }
}
