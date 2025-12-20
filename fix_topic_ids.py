"""
Soruların yanlış topicIds alanlarını düzeltir.
Snake_case formatındaki topicIds'leri gerçek Firestore document ID'leri ile eşleştirir.
"""
import firebase_admin
from firebase_admin import credentials, firestore
from collections import defaultdict
import re

if not firebase_admin._apps:
    cred = credentials.Certificate("service-account.json")
    firebase_admin.initialize_app(cred)

db = firestore.client()

def normalize_name(name):
    """İsmi normalize eder - karşılaştırma için"""
    if not name:
        return ""
    # Küçük harfe çevir, Türkçe karakterleri normalize et
    name = name.lower()
    name = name.replace('ı', 'i').replace('ğ', 'g').replace('ü', 'u')
    name = name.replace('ş', 's').replace('ö', 'o').replace('ç', 'c')
    name = name.replace('İ', 'i').replace('Ğ', 'g').replace('Ü', 'u')
    name = name.replace('Ş', 's').replace('Ö', 'o').replace('Ç', 'c')
    # Sadece alfanumerik karakterleri tut
    name = re.sub(r'[^a-z0-9]', '', name)
    return name

print("=== TOPIC ESLESTIRME HARITASI OLUSTURULUYOR ===")

# Tüm topic'leri al
all_topics = list(db.collection("topics").stream())
valid_topic_ids = set(t.id for t in all_topics)

# İsimden ID'ye eşleştirme haritası
topic_name_to_id = {}
topic_normalized_to_id = {}

for t in all_topics:
    data = t.to_dict()
    name = data.get('name', '')
    
    # Direkt isim eşleştirme
    topic_name_to_id[name.lower()] = t.id
    
    # Normalize edilmiş isim eşleştirme
    normalized = normalize_name(name)
    topic_normalized_to_id[normalized] = t.id
    
    # Snake_case versiyonu
    snake = name.lower().replace(' ', '_').replace('ı', 'i').replace('ğ', 'g')
    snake = snake.replace('ü', 'u').replace('ş', 's').replace('ö', 'o').replace('ç', 'c')
    topic_normalized_to_id[snake] = t.id

print(f"Toplam {len(all_topics)} topic için eşleştirme haritası oluşturuldu")

# Ek manuel eşleştirmeler
MANUAL_MAPPING = {
    'avukatın_hak_ve_yükümlülükleri': None,  # En yakın topic bulunacak
    'ticari_isletme': None,
    'bireysel_is_hukuku': None,
    'borc_iliskisinin_kaynaklari': None,
    'kanunlar_ihtilafi': None,
    'icra_takip_yollari': None,
    'borçlar_hukuku': None,
    'idari_islemler': None,
    'idarenin_kurulusu': None,
    'ceza_hukuku': None,
    'hukuk_muhakemeleri_kanunu': None,
    'ozel_borc_iliskileri': None,
    'avukatlık_hukuku': None,
    'medeni_hukuk': None,
    'i̇cra_ve_i̇flas_hukuku': None,
    'borcun_ifasi_ve_sona_ermesi': None,
    'vergi_suç_ve_cezaları': None,
    'avukatlık_mesleğine_giriş': None,
    'vergi_usul_kanunu': None,
    'iflas': None,
}

def find_matching_topic(invalid_topic_id, subject_id):
    """Geçersiz topic ID için en uygun eşleşmeyi bul"""
    
    # 1. Normalize edilmiş halini dene
    normalized = normalize_name(invalid_topic_id.replace('_', ' '))
    if normalized in topic_normalized_to_id:
        return topic_normalized_to_id[normalized]
    
    # 2. Alt çizgileri boşlukla değiştirip dene
    name_guess = invalid_topic_id.replace('_', ' ')
    if name_guess.lower() in topic_name_to_id:
        return topic_name_to_id[name_guess.lower()]
    
    # 3. Subject'e göre aynı isimli topic'i bul
    for t in all_topics:
        data = t.to_dict()
        if data.get('subjectId') == subject_id:
            topic_name = data.get('name', '').lower()
            topic_normalized = normalize_name(topic_name)
            invalid_normalized = normalize_name(invalid_topic_id.replace('_', ' '))
            
            # Benzerlik kontrolü
            if topic_normalized == invalid_normalized:
                return t.id
            if invalid_normalized in topic_normalized or topic_normalized in invalid_normalized:
                return t.id
    
    return None

print("\n=== SORULARI ANALIZ EDILIYOR ===")
all_questions = list(db.collection("questions").stream())

to_fix = []
not_found = defaultdict(list)

for q in all_questions:
    data = q.to_dict()
    topic_ids = data.get('topicIds', [])
    subject_id = data.get('subjectId')
    
    if not topic_ids:
        continue
    
    first_topic_id = topic_ids[0]
    
    # Zaten geçerliyse atla
    if first_topic_id in valid_topic_ids:
        continue
    
    # Eşleşme bulmaya çalış
    new_topic_id = find_matching_topic(first_topic_id, subject_id)
    
    if new_topic_id:
        to_fix.append({
            'question_id': q.id,
            'old_topic_id': first_topic_id,
            'new_topic_id': new_topic_id,
            'subject_id': subject_id
        })
    else:
        not_found[first_topic_id].append(q.id)

print(f"\n=== SONUCLAR ===")
print(f"Düzeltilebilecek sorular: {len(to_fix)}")
print(f"Eşleşme bulunamayan: {len(not_found)} farklı topicId")

print(f"\n=== ESLESME BULUNAMAYAN TOPICIDS ===")
for tid, qids in sorted(not_found.items(), key=lambda x: -len(x[1]))[:10]:
    print(f"  {tid}: {len(qids)} soru")

# Kullanıcıdan onay al
if to_fix:
    print(f"\n{len(to_fix)} soru düzeltilecek. Devam edilsin mi? (y/n)")
    confirm = input().strip().lower()
    
    if confirm == 'y':
        print("\n=== DUZELTMELER UYGULANIYOR ===")
        batch = db.batch()
        batch_count = 0
        total_fixed = 0
        
        for fix in to_fix:
            ref = db.collection('questions').document(fix['question_id'])
            batch.update(ref, {'topicIds': [fix['new_topic_id']]})
            batch_count += 1
            total_fixed += 1
            
            # Her 500 işlemde bir commit
            if batch_count >= 500:
                batch.commit()
                print(f"  {total_fixed} soru düzeltildi...")
                batch = db.batch()
                batch_count = 0
        
        # Kalan batch'i commit et
        if batch_count > 0:
            batch.commit()
        
        print(f"\n✅ TOPLAM {total_fixed} SORU DÜZELTILDI!")
    else:
        print("İşlem iptal edildi.")
else:
    print("\nDüzeltilecek soru bulunamadı.")
