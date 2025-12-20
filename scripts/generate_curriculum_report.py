"""
Müfredat Raporu Oluşturma Script'i
Firestore'daki tüm dersleri, başlıkları ve alt konuları rapor haline getirir.
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

def generate_report():
    print("Müfredat raporu oluşturuluyor...")
    
    # Get all active subjects
    subjects = {}
    for s in db.collection('subjects').where('isActive', '==', True).stream():
        data = s.to_dict()
        subjects[s.id] = {
            'name': data.get('name'),
            'order': data.get('order', 999)
        }
    
    # Get all topics
    topics = list(db.collection('topics').stream())
    
    # Build report
    report = []
    report.append('# HMGS Müfredat Raporu')
    report.append('**Hakim ve Savcı Adaylığı Sınavı Müfredatı**')
    report.append('')
    report.append(f'Toplam: **{len(subjects)} ders**, **{len(topics)} konu**')
    report.append('')
    report.append('---')
    report.append('')
    
    # Sort subjects by order
    sorted_subjects = sorted(subjects.items(), key=lambda x: x[1]['order'])
    
    for subj_id, subj_data in sorted_subjects:
        subj_topics = [t for t in topics if t.to_dict().get('subjectId') == subj_id]
        
        if not subj_topics:
            continue
        
        # Root topics (parentId is None)
        root_topics = [t for t in subj_topics if t.to_dict().get('parentId') is None]
        root_topics.sort(key=lambda x: x.to_dict().get('order', 0))
        
        # Count children
        child_count = len([t for t in subj_topics if t.to_dict().get('parentId') is not None])
        
        report.append(f'## {subj_data["name"]}')
        report.append(f'*{len(root_topics)} ana başlık, {child_count} alt konu*')
        report.append('')
        
        for root in root_topics:
            root_data = root.to_dict()
            report.append(f'### {root_data.get("name")}')
            
            # Child topics
            children = [t for t in subj_topics if t.to_dict().get('parentId') == root.id]
            children.sort(key=lambda x: x.to_dict().get('order', 0))
            
            if children:
                for child in children:
                    child_data = child.to_dict()
                    report.append(f'- {child_data.get("name")}')
            else:
                report.append('*(Alt konu yok)*')
            
            report.append('')
        
        report.append('---')
        report.append('')
    
    # Write to file
    output_path = BASE_DIR / 'reports' / 'mufredat_raporu.md'
    output_path.parent.mkdir(exist_ok=True)
    
    with open(output_path, 'w', encoding='utf-8') as f:
        f.write('\n'.join(report))
    
    print(f'✅ Rapor yazıldı: {output_path}')
    print(f'   - {len(subjects)} ders')
    print(f'   - {len(topics)} konu')
    
    return output_path

if __name__ == '__main__':
    generate_report()
