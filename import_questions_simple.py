"""Simple question importer
- Skips questions with empty stem
- Imports valid questions to Firestore
"""
import firebase_admin
from firebase_admin import credentials, firestore
import json
from pathlib import Path

BASE_DIR = Path(r'c:\Users\HP\Desktop\StajyerPro')
SERVICE_ACCOUNT_PATH = BASE_DIR / 'service-account.json'

if not firebase_admin._apps:
    cred = credentials.Certificate(str(SERVICE_ACCOUNT_PATH))
    firebase_admin.initialize_app(cred)

db = firestore.client()

DIFF_MAP = {1: 'easy', 2: 'medium', 3: 'hard'}
OPT_MAP = {'A': 0, 'B': 1, 'C': 2, 'D': 3, 'E': 4}

SUBJ_MAP = {
    'CIVIL': 'medeni_hukuk',
    'OBLIGATIONS': 'borclar_hukuku',
    'CRIMINAL': 'ceza_hukuku',
    'CRIM_PROC': 'ceza_muhakemesi',
    'COMMERCIAL': 'ticaret_hukuku',
    'ATTORNEY': 'avukatlik_hukuku',
}

def import_questions():
    total = 0
    imported = 0
    skipped = 0
    
    for file_path in sorted(BASE_DIR.glob('sorular/*.md')):
        content = file_path.read_text(encoding='utf-8')
        start = content.find('[')
        end = content.rfind(']') + 1
        
        if start == -1:
            continue
        
        try:
            questions = json.loads(content[start:end])
        except:
            print(f"❌ {file_path.name}: JSON error")
            continue
        
        batch = db.batch()
        count = 0
        
        for q in questions:
            total += 1
            
            # Skip if no stem
            if not q.get('stem'):
                skipped += 1
                continue
            
            # Extract options
            opts = []
            for opt in q.get('options', []):
                if isinstance(opt, dict):
                    opts.append(opt.get('text', ''))
                else:
                    opts.append(str(opt))
            
            # Skip if no options text
            if not any(opts):
                skipped += 1
                continue
            
            # Convert
            subject_code = q.get('subject_code', 'CIVIL')
            subject_id = SUBJ_MAP.get(subject_code, file_path.stem.lower())
            
            doc = {
                'stem': q.get('stem'),
                'options': opts,
                'correctIndex': OPT_MAP.get(q.get('correct_option', 'A'), 0),
                'explanation': q.get('static_explanation', ''),
                'source': q.get('source_pdf', ''),
                'subjectId': subject_id,
                'topicIds': [subject_id],
                'difficulty': DIFF_MAP.get(q.get('difficulty', 2), 'medium'),
                'targetRoles': q.get('target_roles', []),
                'createdAt': firestore.SERVER_TIMESTAMP,
                'updatedAt': firestore.SERVER_TIMESTAMP
            }
            
            ref = db.collection('questions').document(q.get('id', f"{file_path.stem}_{total}"))
            batch.set(ref, doc)
            count += 1
            imported += 1
            
            if count >= 400:
                batch.commit()
                batch = db.batch()
                count = 0
        
        if count > 0:
            batch.commit()
        
        print(f"✅ {file_path.name}: {imported} imported")
    
    print(f"\n{'='*40}")
    print(f"Total: {total}")
    print(f"Imported: {imported}")
    print(f"Skipped (empty): {skipped}")
    print(f"{'='*40}")

if __name__ == '__main__':
    import_questions()
