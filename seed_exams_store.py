"""
Deneme Sınavları Seed Script
Firestore'a deneme sınavlarını ekler

1 Ücretsiz + 5 Premium deneme:
- Deneme 1: Başlangıç (Ücretsiz, kolay-orta)
- Deneme 2-4: HMGS Simülasyon (49₺, gerçek dağılım)
- Deneme 5: Zor Seviye (59₺, zor ağırlıklı)
- Deneme 6: Final Hazırlık (59₺, gerçek dağılım)
"""

import firebase_admin
from firebase_admin import credentials, firestore
from datetime import datetime

# Firebase init
if not firebase_admin._apps:
    cred = credentials.Certificate('service-account.json')
    firebase_admin.initialize_app(cred)

db = firestore.client()

# Deneme sınavları tanımları
EXAMS = [
    {
        'id': 'deneme_1_baslangic',
        'name': 'Deneme 1 - Başlangıç',
        'description': 'HMGS sınavına hazırlık için ideal başlangıç. Kolay ve orta seviye sorulardan oluşan 120 soruluk deneme.',
        'totalQuestions': 120,
        'durationMinutes': 150,
        'isActive': True,
        'isFree': True,
        'price': 0,
        'productId': None,
        'difficultyDistribution': 'mixed',
        'easyPercent': 40,  # %40 kolay
        'mediumPercent': 50,  # %50 orta
        'hardPercent': 10,  # %10 zor
        'badge': 'ÜCRETSİZ',
        'orderIndex': 1,
    },
    {
        'id': 'deneme_2_hmgs',
        'name': 'Deneme 2 - HMGS Simülasyon',
        'description': 'Gerçek HMGS sınavı formatında 120 soru. Ders dağılımı ve zorluk seviyesi gerçek sınavla aynı.',
        'totalQuestions': 120,
        'durationMinutes': 150,
        'isActive': True,
        'isFree': False,
        'price': 49,
        'productId': 'exam_hmgs_2',
        'difficultyDistribution': 'hmgs_real',
        'easyPercent': 25,
        'mediumPercent': 50,
        'hardPercent': 25,
        'badge': 'POPÜLER',
        'orderIndex': 2,
    },
    {
        'id': 'deneme_3_hmgs',
        'name': 'Deneme 3 - HMGS Simülasyon',
        'description': 'Gerçek HMGS sınavı formatında 120 soru. Farklı soru seti ile kendinizi test edin.',
        'totalQuestions': 120,
        'durationMinutes': 150,
        'isActive': True,
        'isFree': False,
        'price': 49,
        'productId': 'exam_hmgs_3',
        'difficultyDistribution': 'hmgs_real',
        'easyPercent': 25,
        'mediumPercent': 50,
        'hardPercent': 25,
        'badge': None,
        'orderIndex': 3,
    },
    {
        'id': 'deneme_4_hmgs',
        'name': 'Deneme 4 - HMGS Simülasyon',
        'description': 'Gerçek HMGS sınavı formatında 120 soru. Eksik konularınızı keşfedin.',
        'totalQuestions': 120,
        'durationMinutes': 150,
        'isActive': True,
        'isFree': False,
        'price': 49,
        'productId': 'exam_hmgs_4',
        'difficultyDistribution': 'hmgs_real',
        'easyPercent': 25,
        'mediumPercent': 50,
        'hardPercent': 25,
        'badge': None,
        'orderIndex': 4,
    },
    {
        'id': 'deneme_5_zor',
        'name': 'Deneme 5 - Zor Seviye',
        'description': 'İleri seviye hazırlık için zor sorulardan oluşan deneme. Barajı geçenler için ideal.',
        'totalQuestions': 120,
        'durationMinutes': 150,
        'isActive': True,
        'isFree': False,
        'price': 59,
        'productId': 'exam_hard_5',
        'difficultyDistribution': 'hard',
        'easyPercent': 10,
        'mediumPercent': 30,
        'hardPercent': 60,
        'badge': 'ZOR',
        'orderIndex': 5,
    },
    {
        'id': 'deneme_6_final',
        'name': 'Deneme 6 - Final Hazırlık',
        'description': 'Sınav öncesi son hazırlık. Gerçek sınav formatında, en güncel konulardan.',
        'totalQuestions': 120,
        'durationMinutes': 150,
        'isActive': True,
        'isFree': False,
        'price': 59,
        'productId': 'exam_final_6',
        'difficultyDistribution': 'hmgs_real',
        'easyPercent': 20,
        'mediumPercent': 50,
        'hardPercent': 30,
        'badge': 'ÖNERİLEN',
        'orderIndex': 6,
    },
]


def seed_exams():
    """Deneme sınavlarını Firestore'a ekle"""
    
    print("🎓 Deneme Sınavları Firestore'a ekleniyor...\n")
    
    now = datetime.now()
    
    for exam in EXAMS:
        exam_id = exam.pop('id')
        exam['createdAt'] = now
        exam['updatedAt'] = now
        
        # Firestore'a ekle
        db.collection('exams').document(exam_id).set(exam)
        
        price_str = f"{exam['price']}₺" if exam['price'] > 0 else "ÜCRETSİZ"
        badge_str = f" [{exam['badge']}]" if exam.get('badge') else ""
        
        print(f"✅ {exam['name']} - {price_str}{badge_str}")
        print(f"   Zorluk: {exam['difficultyDistribution']}")
        print(f"   Dağılım: {exam.get('easyPercent', 0)}% kolay, {exam.get('mediumPercent', 0)}% orta, {exam.get('hardPercent', 0)}% zor")
        print()
    
    print(f"\n🎉 {len(EXAMS)} deneme sınavı başarıyla eklendi!")


def create_user_purchases_collection():
    """Kullanıcı satın alımları için collection yapısını oluştur"""
    
    print("\n📦 user_exam_purchases collection yapısı hazırlanıyor...")
    
    # Örnek bir purchase document yapısı (gerçek kullanıcı için değil, şema gösterimi için)
    sample_purchase = {
        'userId': 'sample_user_id',
        'examId': 'deneme_2_hmgs',
        'productId': 'exam_hmgs_2',
        'purchaseDate': datetime.now(),
        'transactionId': 'sample_transaction_123',
        'price': 49,
        'currency': 'TRY',
        'platform': 'android',  # veya 'ios'
        'isRefunded': False,
    }
    
    print("   Yapı örneği:")
    for key, value in sample_purchase.items():
        print(f"      {key}: {type(value).__name__}")
    
    print("\n✅ Collection yapısı hazır!")


if __name__ == '__main__':
    seed_exams()
    create_user_purchases_collection()
    
    print("\n" + "="*60)
    print("SONRAKI ADIMLAR:")
    print("="*60)
    print("1. RevenueCat'te aşağıdaki product ID'leri oluşturun:")
    print("   - exam_hmgs_2 (49₺)")
    print("   - exam_hmgs_3 (49₺)")
    print("   - exam_hmgs_4 (49₺)")
    print("   - exam_hard_5 (59₺)")
    print("   - exam_final_6 (59₺)")
    print("\n2. App Store Connect ve Google Play Console'da")
    print("   aynı ID'lerle ürünler oluşturun.")
    print("\n3. Uygulamada satın alma akışını test edin.")
