"""Check specific topic: Ceza Hukuku > Suçun Genel Teorisi > Hukuka Aykırılık"""
import firebase_admin
from firebase_admin import credentials, firestore
from pathlib import Path

BASE_DIR = Path(r'c:\Users\HP\Desktop\StajyerPro')
SERVICE_ACCOUNT_PATH = BASE_DIR / 'service-account.json'

if not firebase_admin._apps:
    cred = credentials.Certificate(str(SERVICE_ACCOUNT_PATH))
    firebase_admin.initialize_app(cred)

db = firestore.client()

# Find Ceza Hukuku topics
ceza_topics = list(db.collection('topics').where('subjectId', '==', 'ceza_hukuku').stream())
print(f"Ceza Hukuku: {len(ceza_topics)} topic\n")

# Find "Hukuka Aykırılık"
hukuka_aykirlik = None
for t in ceza_topics:
    data = t.to_dict()
    if 'Hukuka Aykırılık' in data.get('name', ''):
        hukuka_aykirlik = t
        break

if hukuka_aykirlik:
    data = hukuka_aykirlik.to_dict()
    print(f"=== {data.get('name')} ===")
    print(f"Topic ID: {hukuka_aykirlik.id}")
    print(f"Parent ID: {data.get('parentId', 'ROOT')}")
    print(f"isActive: {data.get('isActive')}")
    print(f"Description length: {len(data.get('description', ''))}")
    print(f"\nDescription content:")
    print(data.get('description', 'YOK'))
    print('\n' + '='*80)
    
    # Check for topic_lessons
    lessons = list(db.collection('topic_lessons').where('topicId', '==', hukuka_aykirlik.id).stream())
    print(f"\nTopic_lessons for this topic: {len(lessons)}")
    
    if lessons:
        lesson_data = lessons[0].to_dict()
        print(f"\nLesson ID: {lessons[0].id}")
        print(f"Steps count: {len(lesson_data.get('steps', []))}")
        if lesson_data.get('steps'):
            print(f"\nFirst step:")
            print(lesson_data['steps'][0])
    
    # Find parent topic
    parent_id = data.get('parentId')
    if parent_id:
        parent = db.collection('topics').document(parent_id).get()
        if parent.exists:
            parent_data = parent.to_dict()
            print(f"\nParent topic: {parent_data.get('name')}")
else:
    print("❌ Hukuka Aykırılık topic'i bulunamadı!")
    print("\nMevcut Ceza Hukuku topic'leri:")
    for t in ceza_topics[:20]:
        data = t.to_dict()
        print(f"  - {data.get('name')}")
