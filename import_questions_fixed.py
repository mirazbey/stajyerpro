"""
FIXED: Import JSON questions from all sources in .md files
- Extracts both direct JSON arrays AND ```json code blocks
- Validates and imports valid questions
"""
import firebase_admin
from firebase_admin import credentials, firestore
import json
import re
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
    'BORCLARHUKUKU': 'borclar_hukuku',
    'CRIMINAL': 'ceza_hukuku',
    'CRIM_PROC': 'ceza_muhakemesi',
    'CMK': 'ceza_muhakemesi',
    'COMMERCIAL': 'ticaret_hukuku',
    'ATTORNEY': 'avukatlik_hukuku',
}

def extract_all_json_blocks(content):
    """Extract ALL JSON from file: both direct arrays and ```json blocks"""
    all_questions = []
    
    # Method 1: Extract ```json code blocks
    json_blocks = re.findall(r'```json\s*(.*?)\s*```', content, re.DOTALL)
    for block in json_blocks:
        try:
            data = json.loads(block.strip())
            if isinstance(data, list):
                all_questions.extend(data)
        except:
            pass
    
    # Method 2: Extract direct JSON array (first '[' to matching ']')
    json_start = content.find('[')
    if json_start != -1 and not content[max(0, json_start-10):json_start].strip().endswith('```json'):
        bracket_count = 0
        json_end = json_start
        in_string = False
        escape = False
        
        for i in range(json_start, len(content)):
            c = content[i]
            
            if escape:
                escape = False
                continue
            
            if c == '\\':
                escape = True
                continue
            
            if c == '"':
                in_string = not in_string
            
            if not in_string:
                if c == '[':
                    bracket_count += 1
                elif c == ']':
                    bracket_count -= 1
                    if bracket_count == 0:
                        json_end = i + 1
                        break
        
        if bracket_count == 0:
            try:
                data = json.loads(content[json_start:json_end])
                if isinstance(data, list):
                    all_questions.extend(data)
            except:
                pass
    
    return all_questions

def import_questions():
    total = 0
    imported = 0
    skipped = 0
    
    print("🔄 Importing questions...\n")
    
    for file_path in sorted(BASE_DIR.glob('sorular/*.md')):
        content = file_path.read_text(encoding='utf-8')
        questions = extract_all_json_blocks(content)
        
        if not questions:
            print(f"❌ {file_path.name}: No JSON")
            continue
        
        print(f"📁 {file_path.name}: {len(questions)} questions")
        
        batch = db.batch()
        count = 0
        file_ok = 0
        file_skip = 0
        
        for q in questions:
            total += 1
            q_id = q.get('id', f"{file_path.stem}_{total}")
            
            # Skip if no stem
            if not q.get('stem'):
                skipped += 1
                file_skip += 1
                continue
            
            # Extract options
            opts = []
            for opt in q.get('options', []):
                if isinstance(opt, dict):
                    opts.append(opt.get('text', ''))
                else:
                    opts.append(str(opt))
            
            # Skip if no options
            if not any(opts):
                skipped += 1
                file_skip += 1
                continue
            
            # Convert
            subject_code = q.get('subject_code', 'CIVIL')
            subject_id = SUBJ_MAP.get(subject_code, file_path.stem.lower())
            
            doc = {
                'stem': q.get('stem'),
                'options': opts,
                'correctIndex': OPT_MAP.get(q.get('correct_option', 'A'), 0),
                'explanation': q.get('static_explanation', ''),
                'detailedExplanation': q.get('static_explanation', ''),
                'source': q.get('source_pdf', ''),
                'subjectId': subject_id,
                'topicIds': [subject_id],
                'difficulty': DIFF_MAP.get(q.get('difficulty', 2), 'medium'),
                'targetRoles': q.get('target_roles', []),
                'aiTip': q.get('ai_hint', ''),  # Hazır ipucu
                'lawArticle': q.get('related_statute', ''),  # İlgili kanun maddesi
                'createdAt': firestore.SERVER_TIMESTAMP,
                'updatedAt': firestore.SERVER_TIMESTAMP
            }
            
            ref = db.collection('questions').document(q_id)
            batch.set(ref, doc)
            count += 1
            file_ok += 1
            imported += 1
            
            if count >= 400:
                batch.commit()
                batch = db.batch()
                count = 0
        
        if count > 0:
            batch.commit()
        
        print(f"  ✅ {file_ok} | ⏭️  {file_skip}\n")
    
    print(f"{'='*50}")
    print(f"📊 Summary:")
    print(f"  Total found: {total}")
    print(f"  Imported: {imported}")
    print(f"  Skipped (empty): {skipped}")
    print(f"{'='*50}")

if __name__ == '__main__':
    import_questions()
