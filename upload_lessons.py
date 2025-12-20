"""
JSON dosyalarını Firestore topic_lessons collection'a yükleyen script.
Kullanım: python upload_lessons.py
"""

import firebase_admin
from firebase_admin import credentials, firestore
import os
import json
from datetime import datetime

# Firebase başlat
if not firebase_admin._apps:
    cred = credentials.Certificate("service-account.json")
    firebase_admin.initialize_app(cred)

db = firestore.client()

def upload_lessons():
    """lesson_content klasöründeki tüm JSON dosyalarını Firestore'a yükle."""
    
    content_dir = "lesson_content"
    uploaded = 0
    skipped = 0
    errors = 0
    
    print("📤 Ders içerikleri yükleniyor...\n")
    
    for subject_folder in os.listdir(content_dir):
        folder_path = os.path.join(content_dir, subject_folder)
        
        # Sadece klasörleri işle
        if not os.path.isdir(folder_path):
            continue
        
        print(f"📁 {subject_folder}")
        
        for json_file in os.listdir(folder_path):
            if not json_file.endswith('.json'):
                continue
            
            json_path = os.path.join(folder_path, json_file)
            topic_id = json_file.replace('.json', '')
            
            try:
                with open(json_path, 'r', encoding='utf-8') as f:
                    data = json.load(f)
                
                # Boş şablon kontrolü - steps[0].content içeriği varsayılan mı?
                if data.get('steps') and len(data['steps']) > 0:
                    first_step = data['steps'][0]
                    if first_step.get('content', '').startswith('## Başlık\n\nİçerik'):
                        print(f"   ⏭️  {topic_id}: Boş şablon, atlandı")
                        skipped += 1
                        continue
                
                # createdAt ekle
                if not data.get('createdAt'):
                    data['createdAt'] = datetime.now().isoformat()
                
                # Firestore'a yükle
                db.collection('topic_lessons').document(topic_id).set(data)
                print(f"   ✅ {topic_id}: Yüklendi")
                uploaded += 1
                
            except json.JSONDecodeError as e:
                print(f"   ❌ {topic_id}: JSON hatası - {e}")
                errors += 1
            except Exception as e:
                print(f"   ❌ {topic_id}: Hata - {e}")
                errors += 1
    
    print(f"\n{'='*50}")
    print(f"📊 ÖZET:")
    print(f"   ✅ Yüklenen: {uploaded}")
    print(f"   ⏭️  Atlanan (boş): {skipped}")
    print(f"   ❌ Hatalı: {errors}")
    print(f"{'='*50}")

if __name__ == "__main__":
    upload_lessons()
