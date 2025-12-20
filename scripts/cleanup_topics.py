import firebase_admin
from firebase_admin import credentials
from firebase_admin import firestore

# Initialize Firebase Admin
cred = credentials.Certificate('service-account.json')
firebase_admin.initialize_app(cred)

db = firestore.client()

def cleanup_topics():
    # IDs to delete (from previous step output)
    ids_to_delete = [
        '8Sm4pXnLMzAgYnaNLGbA', # Kişiler Hukuku
        'EypO1Eqc1or64RIO7zO2', # Temel Kavramlar
        'Lih1t2r5bNPjSlvFL8TA', # Miras Hukuku
        'YgpiQJBvJZr3CFyvTSWy', # Aile Hukuku
        'ZXJrDXK3yUUg7izO45ip', # Eşya Hukuku
        'avukatlik_hukuku_sorular' # Avukatlik Hukuku
    ]
    
    print(f"Deleting {len(ids_to_delete)} unwanted topics...")
    
    batch = db.batch()
    for doc_id in ids_to_delete:
        doc_ref = db.collection('topics').document(doc_id)
        batch.delete(doc_ref)
        
    batch.commit()
    print("Cleanup complete.")

if __name__ == '__main__':
    cleanup_topics()
