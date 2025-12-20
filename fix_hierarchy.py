"""
StajyerPro - Hiyerarşi Düzeltme Script'i
Bu script tüm uyum problemlerini düzeltir:
1. Soruların subjectId'lerini düzelt (medeni_hukuku -> medeni_hukuk)
2. TopicIds mapping oluştur ve düzelt
3. Duplicate subject'ları temizle
"""

import firebase_admin
from firebase_admin import credentials, firestore
from collections import defaultdict
import json

# Firebase başlat
if not firebase_admin._apps:
    cred = credentials.Certificate("service-account.json")
    firebase_admin.initialize_app(cred)

db = firestore.client()

# ============================================
# 1. SUBJECT ID DÜZELTMELERİ
# ============================================

SUBJECT_ID_FIXES = {
    # Yanlış -> Doğru
    "medeni_hukuku": "medeni_hukuk",
    # Diğerleri zaten doğru
}

def fix_question_subject_ids():
    """Soruların yanlış subjectId'lerini düzelt"""
    print("\n" + "=" * 60)
    print("1️⃣  SORU SUBJECT ID'LERİ DÜZELTİLİYOR")
    print("=" * 60)
    
    fixed_count = 0
    
    for wrong_id, correct_id in SUBJECT_ID_FIXES.items():
        print(f"\n🔄 {wrong_id} -> {correct_id}")
        
        # Bu subject ID'ye sahip soruları bul
        questions = db.collection('questions').where('subjectId', '==', wrong_id).get()
        
        print(f"   Bulunan soru sayısı: {len(questions)}")
        
        batch = db.batch()
        batch_count = 0
        
        for doc in questions:
            batch.update(doc.reference, {'subjectId': correct_id})
            batch_count += 1
            
            # Firestore batch limiti 500
            if batch_count >= 400:
                batch.commit()
                print(f"   ✅ {batch_count} soru güncellendi")
                fixed_count += batch_count
                batch = db.batch()
                batch_count = 0
        
        # Kalan batch'i commit et
        if batch_count > 0:
            batch.commit()
            print(f"   ✅ {batch_count} soru güncellendi")
            fixed_count += batch_count
    
    print(f"\n✅ Toplam {fixed_count} soru düzeltildi")
    return fixed_count


# ============================================
# 2. TOPIC ID MAPPING OLUŞTUR
# ============================================

def create_topic_mapping():
    """Firestore'daki topic'lerden snake_case -> ID mapping oluştur"""
    print("\n" + "=" * 60)
    print("2️⃣  TOPIC MAPPING OLUŞTURULUYOR")
    print("=" * 60)
    
    topics = db.collection('topics').get()
    
    # snake_case name -> topic ID mapping
    mapping = {}
    
    for doc in topics:
        data = doc.to_dict()
        name = data.get('name', '')
        subject_id = data.get('subjectId', '')
        
        # İsmi snake_case'e çevir
        snake_name = name.lower().replace(' ', '_').replace('ı', 'i').replace('ö', 'o').replace('ü', 'u').replace('ş', 's').replace('ç', 'c').replace('ğ', 'g')
        snake_name = ''.join(c if c.isalnum() or c == '_' else '_' for c in snake_name)
        snake_name = '_'.join(filter(None, snake_name.split('_')))  # Çift alt çizgileri temizle
        
        # Mapping'e ekle (subject_id ile birlikte key oluştur)
        key = f"{subject_id}:{snake_name}"
        mapping[snake_name] = doc.id
        mapping[key] = doc.id
        
        # Orijinal ismi de ekle
        mapping[name.lower()] = doc.id
    
    print(f"✅ {len(mapping)} topic mapping oluşturuldu")
    
    # Örnek mappingler göster
    print("\n📋 Örnek Mappingler:")
    sample = list(mapping.items())[:10]
    for k, v in sample:
        print(f"   '{k}' -> '{v}'")
    
    return mapping


def fix_question_topic_ids(mapping):
    """Soruların topicIds'lerini düzelt"""
    print("\n" + "=" * 60)
    print("3️⃣  SORU TOPIC ID'LERİ DÜZELTİLİYOR")
    print("=" * 60)
    
    questions = db.collection('questions').get()
    
    fixed_count = 0
    not_found_topics = set()
    
    batch = db.batch()
    batch_count = 0
    
    for doc in questions:
        data = doc.to_dict()
        subject_id = data.get('subjectId', '')
        topic_ids = data.get('topicIds', [])
        
        if not topic_ids:
            continue
        
        new_topic_ids = []
        needs_update = False
        
        for tid in topic_ids:
            # Zaten geçerli bir Firestore ID mi kontrol et (uzun rastgele string)
            if len(tid) > 15 and tid.isalnum():
                new_topic_ids.append(tid)
                continue
            
            # Mapping'de ara
            # Önce subject_id ile dene
            new_id = mapping.get(f"{subject_id}:{tid}")
            
            # Subject_id olmadan dene
            if not new_id:
                new_id = mapping.get(tid)
            
            # Küçük harf versiyonu dene
            if not new_id:
                new_id = mapping.get(tid.lower())
            
            if new_id:
                new_topic_ids.append(new_id)
                needs_update = True
            else:
                # Bulunamadı, orijinalini koru
                new_topic_ids.append(tid)
                not_found_topics.add(tid)
        
        if needs_update:
            batch.update(doc.reference, {'topicIds': new_topic_ids})
            batch_count += 1
            
            if batch_count >= 400:
                batch.commit()
                print(f"   ✅ {batch_count} soru güncellendi")
                fixed_count += batch_count
                batch = db.batch()
                batch_count = 0
    
    # Kalan batch
    if batch_count > 0:
        batch.commit()
        print(f"   ✅ {batch_count} soru güncellendi")
        fixed_count += batch_count
    
    print(f"\n✅ Toplam {fixed_count} soru düzeltildi")
    
    if not_found_topics:
        print(f"\n⚠️  Eşleştirilemeyen topic ID'ler ({len(not_found_topics)}):")
        for t in list(not_found_topics)[:20]:
            print(f"      '{t}'")
    
    return fixed_count


# ============================================
# 3. DUPLICATE SUBJECT'LARI TEMİZLE
# ============================================

def cleanup_duplicate_subjects():
    """*_sorular olan pasif subject'ları sil"""
    print("\n" + "=" * 60)
    print("4️⃣  DUPLICATE SUBJECT'LAR TEMİZLENİYOR")
    print("=" * 60)
    
    # Silinecek pattern'ler
    to_delete = []
    
    subjects = db.collection('subjects').get()
    
    for doc in subjects:
        data = doc.to_dict()
        if doc.id.endswith('_sorular'):
            to_delete.append({
                'id': doc.id,
                'name': data.get('name', 'N/A'),
                'isActive': data.get('isActive', False)
            })
    
    print(f"\n🗑️  Silinecek {len(to_delete)} subject:")
    for s in to_delete:
        status = "pasif" if not s['isActive'] else "AKTİF!"
        print(f"   [{status}] {s['id']}: {s['name']}")
    
    # Kullanıcı onayı
    confirm = input("\n⚠️  Bu subject'ları silmek istiyor musunuz? (evet/hayır): ")
    
    if confirm.lower() == 'evet':
        batch = db.batch()
        for s in to_delete:
            batch.delete(db.collection('subjects').document(s['id']))
        batch.commit()
        print(f"✅ {len(to_delete)} subject silindi")
        return len(to_delete)
    else:
        print("❌ İptal edildi")
        return 0


# ============================================
# ANA FONKSİYON
# ============================================

def main():
    print("=" * 80)
    print("🔧 StajyerPro - Hiyerarşi Düzeltme Script'i")
    print("=" * 80)
    
    print("\nBu script şunları yapacak:")
    print("1. Soruların yanlış subjectId'lerini düzeltecek (medeni_hukuku -> medeni_hukuk)")
    print("2. Topic mapping oluşturacak")
    print("3. Soruların topicIds'lerini düzeltecek")
    print("4. Duplicate subject'ları temizleyecek (opsiyonel)")
    
    confirm = input("\n⚠️  Devam etmek istiyor musunuz? (evet/hayır): ")
    
    if confirm.lower() != 'evet':
        print("❌ İptal edildi")
        return
    
    # 1. Subject ID'leri düzelt
    fix_question_subject_ids()
    
    # 2. Topic mapping oluştur
    mapping = create_topic_mapping()
    
    # 3. Topic ID'leri düzelt
    fix_question_topic_ids(mapping)
    
    # 4. Duplicate subject'ları temizle (opsiyonel)
    cleanup_duplicate_subjects()
    
    print("\n" + "=" * 80)
    print("✅ TÜM DÜZELTMELER TAMAMLANDI!")
    print("=" * 80)


if __name__ == "__main__":
    main()
