"""
Kalan soruların subjectId'lerini düzelt
167 soru *_sorular şeklinde yanlış subjectId'lere sahip
"""

import firebase_admin
from firebase_admin import credentials, firestore

# Firebase başlat
if not firebase_admin._apps:
    cred = credentials.Certificate("service-account.json")
    firebase_admin.initialize_app(cred)

db = firestore.client()

# *_sorular -> doğru subject ID mapping
SORULAR_TO_CORRECT = {
    "turk_borclar_kanunu_sorular": "borclar_hukuku",
    "genel_kamu_hukuku_sorular": "anayasa_hukuku",  # Genel kamu hukuku = Anayasa
    "turk_ceza_kanunu_genel_ozel_sorular": "ceza_hukuku",
    "hukuk_muhakemeleri_kanunu_sorular": "idare_hukuku",  # HMK -> idare? veya yeni subject gerekebilir
    "avukatlik_hukuku_sorular": "avukatlik_hukuku",
    "vergi_hukuku_sorular": "vergi_hukuku",
    "medeni_hukuk_sorular": "medeni_hukuk",
    "icra_ve_iflas_hukuku_sorular": "icra_iflas",
    "is_hukuku_sosyal_guvenlik_sorular": "is_hukuku",
    "hukuk_felsefesi_sorular": "hukuk_felsefesi",
    "milletlerarasi_hukuk_sorular": "milletlerarasi_hukuk",
    "idare_yargi_ve_anayasa_sorular": "idare_hukuku",  # veya idari_yargilama
    "ceza_muhakemesi_sorular": "ceza_muhakemesi",
    "9_yargi_paketi_guncellemesi_sorular": "ceza_hukuku",  # 9. yargı paketi
}

def fix_remaining_subject_ids():
    """Kalan soruların yanlış subjectId'lerini düzelt"""
    print("=" * 60)
    print("🔧 Kalan Soruların SubjectId'leri Düzeltiliyor")
    print("=" * 60)
    
    total_fixed = 0
    
    for wrong_id, correct_id in SORULAR_TO_CORRECT.items():
        print(f"\n🔄 {wrong_id} -> {correct_id}")
        
        # Bu subject ID'ye sahip soruları bul
        questions = db.collection('questions').where('subjectId', '==', wrong_id).get()
        
        count = len(questions)
        if count == 0:
            print(f"   ℹ️ Soru bulunamadı")
            continue
        
        print(f"   📊 Bulunan: {count} soru")
        
        batch = db.batch()
        batch_count = 0
        
        for doc in questions:
            batch.update(doc.reference, {'subjectId': correct_id})
            batch_count += 1
            
            if batch_count >= 400:
                batch.commit()
                print(f"   ✅ {batch_count} soru güncellendi")
                total_fixed += batch_count
                batch = db.batch()
                batch_count = 0
        
        if batch_count > 0:
            batch.commit()
            print(f"   ✅ {batch_count} soru güncellendi")
            total_fixed += batch_count
    
    print(f"\n{'=' * 60}")
    print(f"✅ Toplam {total_fixed} soru düzeltildi")
    print(f"{'=' * 60}")
    return total_fixed


def check_remaining_invalid():
    """Hâlâ geçersiz subjectId'li sorular var mı kontrol et"""
    print("\n" + "=" * 60)
    print("🔍 Kalan Geçersiz SubjectId'ler Kontrol Ediliyor")
    print("=" * 60)
    
    # Geçerli subject ID'ler
    valid_subjects = set()
    for doc in db.collection('subjects').get():
        valid_subjects.add(doc.id)
    
    # Tüm soruları kontrol et
    questions = db.collection('questions').get()
    
    invalid_subjects = {}
    for doc in questions:
        data = doc.to_dict()
        sid = data.get('subjectId', '')
        if sid not in valid_subjects:
            if sid not in invalid_subjects:
                invalid_subjects[sid] = 0
            invalid_subjects[sid] += 1
    
    if invalid_subjects:
        print(f"\n⚠️ Hâlâ {sum(invalid_subjects.values())} soru geçersiz subjectId'ye sahip:")
        for sid, count in sorted(invalid_subjects.items(), key=lambda x: -x[1]):
            print(f"   {sid}: {count} soru")
    else:
        print("\n✅ Tüm sorular geçerli subjectId'lere sahip!")
    
    return invalid_subjects


if __name__ == "__main__":
    print("Bu script kalan *_sorular subjectId'lerini düzeltecek.")
    confirm = input("Devam etmek istiyor musunuz? (evet/hayır): ")
    
    if confirm.lower() != 'evet':
        print("İptal edildi.")
    else:
        fix_remaining_subject_ids()
        check_remaining_invalid()
