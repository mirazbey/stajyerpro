import firebase_admin
from firebase_admin import credentials
from firebase_admin import firestore
import os

# Initialize Firebase Admin
cred_path = os.path.join(os.path.dirname(__file__), '..', 'serviceAccountKey.json')
if not os.path.exists(cred_path):
    print(f"Error: serviceAccountKey.json not found at {cred_path}")
    print("Please download your service account key from Firebase Console and place it in the root directory.")
    exit(1)

cred = credentials.Certificate(cred_path)
firebase_admin.initialize_app(cred)

db = firestore.client()

def update_questions_schema():
    print("Updating 'questions' schema...")
    questions_ref = db.collection('questions')
    docs = questions_ref.stream()
    
    count = 0
    updated_count = 0
    
    for doc in docs:
        count += 1
        data = doc.to_dict()
        updates = {}
        
        # Check for missing 'lawArticle'
        if 'lawArticle' not in data:
            updates['lawArticle'] = ''
            
        # Check for missing 'detailedExplanation'
        if 'detailedExplanation' not in data:
            updates['detailedExplanation'] = 'Bu soru için detaylı açıklama henüz eklenmemiştir.'
            
        # Check for missing 'wrongReasons'
        if 'wrongReasons' not in data:
            updates['wrongReasons'] = {}
            
        if updates:
            doc.reference.update(updates)
            updated_count += 1
            print(f"Updated question {doc.id}")
            
    print(f"Total questions scanned: {count}")
    print(f"Total questions updated: {updated_count}")

def init_collections():
    print("\nInitializing other collections if empty...")
    
    # Ensure 'wrong_answers' collection exists (by creating a dummy doc and deleting it if needed, 
    # but Firestore collections are virtual. We just need to make sure we can access it.)
    # Actually, we don't need to do anything for empty collections in Firestore.
    print("Collections are virtual in Firestore. No initialization needed.")

if __name__ == "__main__":
    print("Starting Schema Update...")
    try:
        update_questions_schema()
        init_collections()
        print("\nSchema update completed successfully.")
    except Exception as e:
        print(f"\nError updating schema: {e}")
