"""Check topic_lessons collection in Firestore"""
import firebase_admin
from firebase_admin import credentials, firestore
from pathlib import Path

BASE_DIR = Path(r'c:\Users\HP\Desktop\StajyerPro')
SERVICE_ACCOUNT_PATH = BASE_DIR / 'service-account.json'

if not firebase_admin._apps:
    cred = credentials.Certificate(str(SERVICE_ACCOUNT_PATH))
    firebase_admin.initialize_app(cred)

db = firestore.client()

print('=== TOPIC_LESSONS COLLECTION ===')
try:
    lessons = list(db.collection('topic_lessons').stream())
    print(f'Toplam lesson: {len(lessons)}')
    
    if lessons:
        print('\nİlk 5 lesson:')
        for lesson in lessons[:5]:
            data = lesson.to_dict()
            topic_id = data.get('topicId', 'N/A')
            steps_count = len(data.get('steps', []))
            print(f"  {lesson.id}: topicId={topic_id}, steps={steps_count}")
    else:
        print('\n⚠️ Hiç lesson yok! JSON dosyalarından import edilmemiş.')
        
except Exception as e:
    print(f'❌ Hata: {e}')

# Borçlar Hukuku topiclerini kontrol et
print('\n=== BORÇLAR HUKUKU TOPICS ===')
borclar_topics = list(db.collection('topics').where('subjectId', '==', 'borclar_hukuku').stream())
print(f'Borçlar Hukuku: {len(borclar_topics)} topic')

if borclar_topics:
    print('\nİlk 5 topic:')
    for t in borclar_topics[:5]:
        data = t.to_dict()
        desc_len = len(data.get('description', ''))
        print(f"  - {data.get('name')}: description={desc_len} karakter")
        
    # Eser Sözleşmesi varsa kontrol et
    eser = None
    for t in borclar_topics:
        if 'Eser' in t.to_dict().get('name', ''):
            eser = t
            break
    
    if eser:
        print(f'\n=== ESER SÖZLEŞMESİ ===')
        data = eser.to_dict()
        print(f"Topic ID: {eser.id}")
        print(f"Name: {data.get('name')}")
        print(f"Description: {data.get('description', 'YOK')[:200]}")
        print(f"isActive: {data.get('isActive')}")
        
        # Bu topicin lesson'ını kontrol et
        topic_lessons = list(db.collection('topic_lessons').where('topicId', '==', eser.id).stream())
        print(f"\nBu topic için {len(topic_lessons)} lesson var")
