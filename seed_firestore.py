import firebase_admin
from firebase_admin import credentials
from firebase_admin import firestore
import re
from pathlib import Path
import datetime

# Configuration
BASE_DIR = Path(r'c:\Users\HP\Desktop\StajyerPro')
QUESTIONS_DIR = BASE_DIR / 'sorular'
SERVICE_ACCOUNT_PATH = BASE_DIR / 'service-account.json'

# Initialize Firebase
if not firebase_admin._apps:
    cred = credentials.Certificate(str(SERVICE_ACCOUNT_PATH))
    firebase_admin.initialize_app(cred)

db = firestore.client()

SUBJECT_MAPPING = {
    'CONST': 'Anayasa Hukuku',
    'CIVIL': 'Medeni Hukuk',
    'OBLIGATIONS': 'Borçlar Hukuku',
    'PENAL': 'Ceza Hukuku',
    'CMK': 'Ceza Muhakemesi Hukuku',
    'ADMIN': 'İdare Hukuku',
    'ADMIN_PROC': 'İdari Yargılama Hukuku',
    'HMK': 'Hukuk Muhakemeleri Kanunu',
    'COMMERCIAL': 'Ticaret Hukuku',
    'EXECUTION': 'İcra ve İflas Hukuku',
    'LABOR': 'İş ve Sosyal Güvenlik Hukuku',
    'TAX': 'Vergi Hukuku',
    'INT_PUBLIC': 'Devletler Umumi Hukuku',
    'LAWYER': 'Avukatlık Hukuku',
    'PHILOSOPHY': 'Hukuk Felsefesi ve Sosyolojisi',
    'UNKNOWN': 'Diğer'
}

DIFFICULTY_MAPPING = {
    1: 'easy',
    2: 'medium',
    3: 'hard'
}

OPTION_MAPPING = {
    'A': 0, 'B': 1, 'C': 2, 'D': 3, 'E': 4
}

def parse_markdown_questions(text, filename_stem):
    questions = []
    blocks = text.split('[QUESTION]')
    
    for i, block in enumerate(blocks):
        if not block.strip():
            continue
            
        lines = block.strip().split('\n')
        q_data = {
            'id': f"{filename_stem}_{i}",
            'options': [],
            'tags': []
        }
        
        current_field = None
        current_value = []
        
        def save_field():
            if current_field and current_value:
                val = '\n'.join(current_value).strip()
                if current_field == 'Options':
                    opt_lines = val.split('\n')
                    current_opt_id = None
                    current_opt_text = []
                    
                    for line in opt_lines:
                        match = re.match(r'^([A-E])\)\s*(.*)', line)
                        if match:
                            if current_opt_id:
                                q_data['options'].append(
                                    '\n'.join(current_opt_text).strip()
                                )
                            current_opt_id = match.group(1)
                            current_opt_text = [match.group(2)]
                        else:
                            if current_opt_id:
                                current_opt_text.append(line)
                    
                    if current_opt_id:
                        q_data['options'].append(
                            '\n'.join(current_opt_text).strip()
                        )

                elif current_field == 'TopicPath':
                     q_data['topic_path'] = [t.strip() for t in val.split('>')]
                elif current_field == 'TargetRoles':
                     q_data['tags'].extend([t.strip() for t in val.split(',') if t.strip()])
                elif current_field == 'ExamWeightTag':
                     q_data['tags'].append(val)
                else:
                    key_map = {
                        'SubjectCode': 'subject_code',
                        'Difficulty': 'difficulty',
                        'Stem': 'stem',
                        'CorrectOption': 'correct_option',
                        'StaticExplanation': 'explanation',
                        'AIHint': 'ai_hint',
                        'RelatedStatute': 'related_statute',
                        'LearningObjective': 'learning_objective',
                        'SourceReference': 'source_reference'
                    }
                    if current_field in key_map:
                        q_data[key_map[current_field]] = val
            
        for line in lines:
            match = re.match(r'^(SubjectCode|TopicPath|Difficulty|ExamWeightTag|TargetRoles|SourceReference|Stem|Options|CorrectOption|StaticExplanation|AIHint|RelatedStatute|LearningObjective):\s*(.*)', line)
            if match:
                save_field()
                current_field = match.group(1)
                val = match.group(2)
                current_value = [val] if val else []
            else:
                if current_field:
                    current_value.append(line)
        
        save_field()
        
        if 'subject_code' in q_data:
            questions.append(q_data)
            
    return questions

def seed_firestore():
    print(f"Scanning {QUESTIONS_DIR}...")
    
    total_questions = 0
    
    for file_path in QUESTIONS_DIR.glob('*.md'):
        print(f"Processing {file_path.name}...")
        try:
            text = file_path.read_text(encoding='utf-8')
        except Exception as e:
            print(f"Error reading {file_path.name}: {e}")
            continue
            
        questions = parse_markdown_questions(text, file_path.stem)
        
        if not questions:
            print(f"  No questions found in {file_path.name}")
            continue

        batch = db.batch()
        batch_count = 0
        
        for q in questions:
            # 1. Subject & Topic Strategy: Use File Name
            # User requested: "Konu başlıkları, aynı sorular klasöründeki dosya isimleri gibi olmalı."
            # We will use the file name to define both the Subject and the single Topic.
            
            # Sanitize file stem for ID (lowercase, no spaces/special chars)
            safe_id = re.sub(r'[^a-z0-9_]', '', file_path.stem.lower())
            
            # Format name for display (Title Case, replace underscores)
            display_name = file_path.stem.replace('_', ' ').replace('sorular', '').strip().title()
            if not display_name: display_name = file_path.stem # Fallback
            
            subject_id = safe_id
            subject_name = display_name
            
            topic_id = safe_id
            topic_name = display_name

            # Create Subject Doc
            subject_ref = db.collection('subjects').document(subject_id)
            batch.set(subject_ref, {
                'code': subject_id,
                'name': subject_name,
                'isActive': True,
                'order': 0,
                'updatedAt': firestore.SERVER_TIMESTAMP
            }, merge=True)
            
            # Create Topic Doc
            topic_ref = db.collection('topics').document(topic_id)
            batch.set(topic_ref, {
                'name': topic_name,
                'subjectId': subject_id,
                'full_path': topic_name,
                'isActive': True,
                'updatedAt': firestore.SERVER_TIMESTAMP
            }, merge=True)
            
            # 3. Question
            q_id = q['id']
            question_ref = db.collection('questions').document(q_id)
            
            try:
                diff_int = int(q.get('difficulty', 2))
            except:
                diff_int = 2
            difficulty = DIFFICULTY_MAPPING.get(diff_int, 'medium')
            
            correct_opt_char = q.get('correct_option', 'A').strip()
            correct_index = OPTION_MAPPING.get(correct_opt_char, 0)
            
            explanation = q.get('explanation', '')
            ai_hint = q.get('ai_hint', '')
            full_explanation = explanation
            if ai_hint:
                full_explanation += f"\n\nİpucu: {ai_hint}"

            # Store original metadata
            original_subject_code = q.get('subject_code', 'UNKNOWN')

            firestore_q = {
                'stem': q.get('stem', ''),
                'options': q.get('options', []),
                'correctIndex': correct_index,
                'explanation': full_explanation,
                'source': q.get('source_reference', ''),
                'subjectId': subject_id,
                'topicIds': [topic_id],
                'originalSubjectCode': original_subject_code, # Keep for reference
                'difficulty': difficulty,
                'targetRoles': q.get('tags', []),
                'createdAt': firestore.SERVER_TIMESTAMP,
                'updatedAt': firestore.SERVER_TIMESTAMP
            }
            
            batch.set(question_ref, firestore_q, merge=True)
            
            batch_count += 1
            total_questions += 1
            
            if batch_count >= 400:
                batch.commit()
                batch = db.batch()
                batch_count = 0
                
        if batch_count > 0:
            batch.commit()
            
        print(f"  Imported {len(questions)} questions from {file_path.name}")

    print(f"\nSeeding Complete!")
    print(f"Total Questions Imported: {total_questions}")

if __name__ == '__main__':
    seed_firestore()
