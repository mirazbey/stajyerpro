"""
ADVANCED: Import JSON questions with proper topic_path → topicIds mapping
Uses curriculum_map.json for accurate topic assignment
"""
import firebase_admin
from firebase_admin import credentials, firestore
import json
import re
from pathlib import Path
from difflib import SequenceMatcher

BASE_DIR = Path(r'c:\Users\HP\Desktop\StajyerPro')
SERVICE_ACCOUNT_PATH = BASE_DIR / 'service-account.json'
CURRICULUM_MAP_PATH = BASE_DIR / 'scripts' / 'curriculum_map.json'

if not firebase_admin._apps:
    cred = credentials.Certificate(str(SERVICE_ACCOUNT_PATH))
    firebase_admin.initialize_app(cred)

db = firestore.client()

DIFF_MAP = {1: 'easy', 2: 'medium', 3: 'hard'}
OPT_MAP = {'A': 0, 'B': 1, 'C': 2, 'D': 3, 'E': 4}

# Subject code mapping (from question JSON to Firestore subject IDs)
SUBJECT_CODE_MAP = {
    'CIVIL': 'medeni_hukuk',
    'MEDENI': 'medeni_hukuk',
    'OBLIGATIONS': 'borclar_hukuku',
    'BORCLAR': 'borclar_hukuku',
    'BORCLARHUKUKU': 'borclar_hukuku',
    'CRIMINAL': 'ceza_hukuku',
    'CEZA': 'ceza_hukuku',
    'TCK': 'ceza_hukuku',
    'CRIM_PROC': 'ceza_muhakemesi',
    'CMK': 'ceza_muhakemesi',
    'COMMERCIAL': 'ticaret_hukuku',
    'TTK': 'ticaret_hukuku',
    'ATTORNEY': 'avukatlik_hukuku',
    'AVUKATLIK': 'avukatlik_hukuku',
    'ADMIN': 'idare_hukuku',
    'IDARE': 'idare_hukuku',
    'IYUK': 'idari_yargilama',
    'CONSTITUTION': 'anayasa_hukuku',
    'ANAYASA': 'anayasa_hukuku',
    'HMK': 'hukuk_muhakemeleri',
    'ICRA': 'icra_iflas',
    'IIK': 'icra_iflas',
    'VERGI': 'vergi_hukuku',
    'TAX': 'vergi_hukuku',
    'IS': 'is_hukuku',
    'LABOR': 'is_hukuku',
    'FELSEFE': 'hukuk_felsefesi',
    'PHILOSOPHY': 'hukuk_felsefesi',
    'INTERNATIONAL': 'milletlerarasi_hukuk',
    'MOHUK': 'mohuk',
    'GENERAL': None,  # Will use file name
}

def load_curriculum_map():
    """Load the curriculum mapping from JSON file"""
    with open(CURRICULUM_MAP_PATH, 'r', encoding='utf-8') as f:
        data = json.load(f)
    return data['curriculum'], data['topic_name_to_id']

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

def find_best_topic_match(topic_path, topic_name_to_id):
    """
    Find the best matching topicId from topic_path array
    
    topic_path examples:
    - ["İdari Yargılama Usulü", "İdari Davalar", "Yürütmenin Durdurulması"]
    - ["Temel Hak ve Özgürlükler", "Sınırlandırma Rejimi"]
    - ["Genel"]
    """
    if not topic_path or topic_path == ['Genel'] or topic_path == ['']:
        return None, None
    
    # Try from most specific to least specific
    for i in range(len(topic_path) - 1, -1, -1):
        topic_name = topic_path[i].lower().strip()
        
        # Direct match
        if topic_name in topic_name_to_id:
            match = topic_name_to_id[topic_name]
            return match['subjectId'], match['topicId']
        
        # Try slug version
        slug = slugify(topic_path[i])
        if slug in topic_name_to_id:
            match = topic_name_to_id[slug]
            return match['subjectId'], match['topicId']
        
        # Try fuzzy match (ratio > 0.8)
        best_ratio = 0
        best_match = None
        for key in topic_name_to_id:
            ratio = SequenceMatcher(None, topic_name, key).ratio()
            if ratio > 0.8 and ratio > best_ratio:
                best_ratio = ratio
                best_match = topic_name_to_id[key]
        
        if best_match:
            return best_match['subjectId'], best_match['topicId']
    
    return None, None

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
            elif isinstance(data, dict) and 'questions' in data:
                all_questions.extend(data['questions'])
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
    """Import questions with proper topic mapping"""
    
    # Load curriculum map
    print("📚 Müfredat haritası yükleniyor...")
    curriculum, topic_name_to_id = load_curriculum_map()
    print(f"   {len(topic_name_to_id)} konu eşlemesi yüklendi\n")
    
    total = 0
    imported = 0
    skipped_empty = 0
    skipped_no_topic = 0
    topic_matches = 0
    
    print("🔄 Sorular import ediliyor...\n")
    
    for file_path in sorted(BASE_DIR.glob('sorular/*.md')):
        content = file_path.read_text(encoding='utf-8')
        questions = extract_all_json_blocks(content)
        
        if not questions:
            print(f"❌ {file_path.name}: JSON bulunamadı")
            continue
        
        print(f"📁 {file_path.name}: {len(questions)} soru")
        
        # Determine default subject from filename
        file_subject = file_path.stem.replace('_sorular', '')
        
        batch = db.batch()
        count = 0
        file_ok = 0
        file_skip = 0
        file_matched = 0
        
        for q in questions:
            total += 1
            q_id = q.get('id', f"{file_path.stem}_{total}")
            
            # Skip if no stem
            if not q.get('stem'):
                skipped_empty += 1
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
                skipped_empty += 1
                file_skip += 1
                continue
            
            # Determine subject ID
            subject_code = q.get('subject_code', 'GENERAL')
            subject_id = SUBJECT_CODE_MAP.get(subject_code)
            if not subject_id:
                # Try to infer from file name
                for code, sid in SUBJECT_CODE_MAP.items():
                    if code.lower() in file_subject.lower():
                        subject_id = sid
                        break
                if not subject_id:
                    subject_id = file_subject
            
            # Find topic IDs from topic_path
            topic_path = q.get('topic_path', [])
            matched_subject, matched_topic = find_best_topic_match(topic_path, topic_name_to_id)
            
            # Use matched subject if found
            if matched_subject:
                subject_id = matched_subject
                file_matched += 1
                topic_matches += 1
            
            # Build topicIds array
            topic_ids = []
            if matched_topic:
                topic_ids.append(matched_topic)
            else:
                # Fallback: just use subject_id
                topic_ids.append(subject_id)
            
            doc = {
                'stem': q.get('stem'),
                'options': opts,
                'correctIndex': OPT_MAP.get(q.get('correct_option', 'A'), 0),
                'explanation': q.get('static_explanation', ''),
                'detailedExplanation': q.get('static_explanation', ''),
                'source': q.get('source_pdf', ''),
                'subjectId': subject_id,
                'topicIds': topic_ids,
                'topicPath': topic_path,  # Keep original topic_path for reference
                'difficulty': DIFF_MAP.get(q.get('difficulty', 2), 'medium'),
                'targetRoles': q.get('target_roles', []),
                'aiTip': q.get('ai_hint', ''),
                'lawArticle': q.get('related_statute', ''),
                'tags': q.get('tags', []),
                'learningObjective': q.get('learning_objective', ''),
                'createdAt': firestore.SERVER_TIMESTAMP,
                'updatedAt': firestore.SERVER_TIMESTAMP,
                'status': q.get('status', 'draft')
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
        
        print(f"  ✅ {file_ok} import | 🎯 {file_matched} topic eşlendi | ⏭️ {file_skip} atlandı\n")
    
    print(f"{'='*60}")
    print(f"📊 ÖZET:")
    print(f"  Toplam bulunan: {total}")
    print(f"  Import edilen: {imported}")
    print(f"  Topic eşlenen: {topic_matches} ({100*topic_matches/max(imported,1):.1f}%)")
    print(f"  Atlandı (boş): {skipped_empty}")
    print(f"{'='*60}")

if __name__ == '__main__':
    import_questions()
