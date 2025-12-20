"""
Firestore'daki mevcut müfredat yapısını çıkarır ve topic_path eşleme haritası oluşturur.
Bu harita import_questions script'i tarafından kullanılacak.
"""
import firebase_admin
from firebase_admin import credentials, firestore
from pathlib import Path
import json
import re

BASE_DIR = Path(r'c:\Users\HP\Desktop\StajyerPro')
SERVICE_ACCOUNT_PATH = BASE_DIR / 'service-account.json'

if not firebase_admin._apps:
    cred = credentials.Certificate(str(SERVICE_ACCOUNT_PATH))
    firebase_admin.initialize_app(cred)

db = firestore.client()

def slugify(text):
    """Türkçe karakterleri dönüştür ve slug oluştur"""
    tr_map = {
        'ç': 'c', 'Ç': 'C', 'ğ': 'g', 'Ğ': 'G', 'ı': 'i', 'İ': 'I',
        'ö': 'o', 'Ö': 'O', 'ş': 's', 'Ş': 'S', 'ü': 'u', 'Ü': 'U'
    }
    for tr, en in tr_map.items():
        text = text.replace(tr, en)
    text = text.lower().strip()
    text = re.sub(r'[^a-z0-9\s]', '', text)
    text = re.sub(r'\s+', '_', text)
    return text

def export_curriculum_map():
    """Tüm müfredatı çıkar ve topic_path → topic_id eşleme haritası oluştur"""
    
    curriculum_map = {}
    topic_name_to_id = {}  # "Teşebbüs" -> {"subjectId": "ceza_hukuku", "topicId": "xxx"}
    
    print("📚 Müfredat yapısı çıkarılıyor...\n")
    
    # 1. Tüm dersleri al
    subjects_ref = db.collection('subjects').order_by('order')
    subjects = {s.id: s.to_dict() for s in subjects_ref.stream()}
    
    # Sadece asıl dersler (order > 0 ve _sorular ile bitmeyenler)
    valid_subjects = {sid: sdata for sid, sdata in subjects.items() 
                      if not sid.endswith('_sorular') and sdata.get('order', 0) > 0}
    
    print(f"📖 {len(valid_subjects)} geçerli ders bulundu\n")
    
    # 2. Tüm topics'leri al (ayrı koleksiyondan)
    all_topics = list(db.collection('topics').stream())
    print(f"📑 {len(all_topics)} konu bulundu\n")
    
    # Topics'leri subjectId'ye göre grupla
    topics_by_subject = {}
    for t in all_topics:
        tdata = t.to_dict()
        subject_id = tdata.get('subjectId')
        if subject_id:
            if subject_id not in topics_by_subject:
                topics_by_subject[subject_id] = {}
            topics_by_subject[subject_id][t.id] = tdata
    
    # 3. Her ders için hiyerarşik yapı oluştur
    for subject_id, subject_data in sorted(valid_subjects.items(), key=lambda x: x[1].get('order', 0)):
        subject_name = subject_data.get('name', subject_id)
        print(f"📖 {subject_name}")
        
        curriculum_map[subject_id] = {
            'name': subject_name,
            'groups': {}
        }
        
        subject_topics = topics_by_subject.get(subject_id, {})
        
        # Ana grupları bul (parentId olmayan veya null olan)
        main_groups = {tid: tdata for tid, tdata in subject_topics.items()
                       if not tdata.get('parentId')}
        
        # Alt konuları bul (parentId olan)
        sub_topics = {tid: tdata for tid, tdata in subject_topics.items()
                      if tdata.get('parentId')}
        
        for group_id, group_data in sorted(main_groups.items(), key=lambda x: x[1].get('order', 0)):
            group_name = group_data.get('name', group_id)
            print(f"  📁 {group_name}")
            
            curriculum_map[subject_id]['groups'][group_id] = {
                'name': group_name,
                'topics': {}
            }
            
            # Bu grubun alt konularını bul
            group_subtopics = {tid: tdata for tid, tdata in sub_topics.items()
                              if tdata.get('parentId') == group_id}
            
            for topic_id, topic_data in sorted(group_subtopics.items(), key=lambda x: x[1].get('order', 0)):
                topic_name = topic_data.get('name', topic_id)
                print(f"    • {topic_name}")
                
                curriculum_map[subject_id]['groups'][group_id]['topics'][topic_id] = {
                    'name': topic_name
                }
                
                # topic_name eşlemesi (farklı varyasyonlar için)
                # Örnek: "Teşebbüs" veya "teşebbüs" -> topic_id
                topic_name_to_id[topic_name.lower()] = {
                    'subjectId': subject_id,
                    'groupId': group_id,
                    'topicId': topic_id
                }
                
                # Slug versiyonu da ekle
                slug = slugify(topic_name)
                if slug != topic_name.lower():
                    topic_name_to_id[slug] = {
                        'subjectId': subject_id,
                        'groupId': group_id,
                        'topicId': topic_id
                    }
            
            # Grup adını da ekle (topic_path sadece 2 elemanlıysa kullanılır)
            topic_name_to_id[group_name.lower()] = {
                'subjectId': subject_id,
                'groupId': group_id,
                'topicId': group_id  # Grup kendisi de bir topic
            }
            
            slug = slugify(group_name)
            if slug != group_name.lower():
                topic_name_to_id[slug] = {
                    'subjectId': subject_id,
                    'groupId': group_id,
                    'topicId': group_id
                }
        
        print()
    
    # JSON olarak kaydet
    output_path = BASE_DIR / 'scripts' / 'curriculum_map.json'
    with open(output_path, 'w', encoding='utf-8') as f:
        json.dump({
            'curriculum': curriculum_map,
            'topic_name_to_id': topic_name_to_id
        }, f, ensure_ascii=False, indent=2)
    
    print(f"✅ Harita kaydedildi: {output_path}")
    print(f"📊 Toplam {len(topic_name_to_id)} konu eşlemesi oluşturuldu")
    
    return curriculum_map, topic_name_to_id

if __name__ == '__main__':
    export_curriculum_map()
