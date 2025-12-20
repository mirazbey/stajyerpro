"""
Firestore yapısını debug et - topics nasıl saklanıyor?
"""
import firebase_admin
from firebase_admin import credentials, firestore
from pathlib import Path

BASE_DIR = Path(r'c:\Users\HP\Desktop\StajyerPro')
SERVICE_ACCOUNT_PATH = BASE_DIR / 'service-account.json'

if not firebase_admin._apps:
    cred = credentials.Certificate(str(SERVICE_ACCOUNT_PATH))
    firebase_admin.initialize_app(cred)

db = firestore.client()

def debug_firestore():
    print("🔍 Firestore Yapısı Debug\n")
    
    # 1. subjects koleksiyonunu kontrol et
    print("=" * 50)
    print("SUBJECTS KOLEKSİYONU")
    print("=" * 50)
    
    subjects = list(db.collection('subjects').limit(5).stream())
    for s in subjects:
        data = s.to_dict()
        print(f"\n📖 {s.id}")
        print(f"   name: {data.get('name')}")
        print(f"   order: {data.get('order')}")
        
        # topics subcollection'ı var mı?
        topics_ref = db.collection('subjects').document(s.id).collection('topics')
        topics = list(topics_ref.limit(3).stream())
        print(f"   topics subcollection: {len(topics)} doc")
        
        for t in topics:
            tdata = t.to_dict()
            print(f"      - {t.id}: {tdata.get('name')} (parent: {tdata.get('parentTopicId')})")
    
    # 2. Ayrı topics koleksiyonu var mı?
    print("\n" + "=" * 50)
    print("AYRI TOPICS KOLEKSİYONU")
    print("=" * 50)
    
    topics_root = list(db.collection('topics').limit(5).stream())
    print(f"Toplam: {len(topics_root)} doc")
    for t in topics_root:
        data = t.to_dict()
        print(f"   - {t.id}: {data}")
    
    # 3. collectionGroup ile tüm topics'leri al
    print("\n" + "=" * 50)
    print("COLLECTION GROUP - TÜM TOPICS")
    print("=" * 50)
    
    all_topics = list(db.collection_group('topics').limit(10).stream())
    print(f"Toplam: {len(all_topics)} doc")
    for t in all_topics:
        data = t.to_dict()
        print(f"   - {t.id}: {data.get('name')} (parent: {data.get('parentTopicId')})")

if __name__ == '__main__':
    debug_firestore()
