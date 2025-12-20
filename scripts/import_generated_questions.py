"""
Üretilen Soruları Firestore'a Import Eden Script
"""

import os
import json
import firebase_admin
from firebase_admin import credentials, firestore
from pathlib import Path
from datetime import datetime

def init_firebase():
    """Firebase'i başlatır"""
    cred_path = os.path.join(os.path.dirname(__file__), '..', 'serviceAccountKey.json')
    
    if not os.path.exists(cred_path):
        print(f"❌ serviceAccountKey.json bulunamadı: {cred_path}")
        print("Firebase Console'dan service account key indirip proje root'a koy.")
        exit(1)
    
    cred = credentials.Certificate(cred_path)
    firebase_admin.initialize_app(cred)
    return firestore.client()

def import_questions_to_firestore(json_file: str, db):
    """JSON dosyasındaki soruları Firestore'a yükler"""
    print(f"\n📥 Import ediliyor: {json_file}")
    
    with open(json_file, 'r', encoding='utf-8') as f:
        questions = json.load(f)
    
    print(f"📊 Toplam {len(questions)} soru bulundu")
    
    imported_count = 0
    failed_count = 0
    
    for i, question in enumerate(questions, 1):
        try:
            # Firestore dokümanı oluştur
            question_data = {
                'stem': question['stem'],
                'options': question['options'],
                'correctIndex': question['correctIndex'],
                'difficulty': question.get('difficulty', 'medium'),
                'lawArticle': question.get('lawArticle', ''),
                'detailedExplanation': question.get('detailedExplanation', ''),
                'wrongReasons': question.get('wrongReasons', {}),
                'subjectId': question.get('subjectId', 'unknown'),
                'topicIds': question.get('topicIds', []),
                'source': 'ai_generated',
                'createdAt': firestore.SERVER_TIMESTAMP,
                'updatedAt': firestore.SERVER_TIMESTAMP,
                'isActive': True
            }
            
            # Firestore'a ekle
            db.collection('questions').add(question_data)
            imported_count += 1
            
            if i % 10 == 0:
                print(f"✅ {i}/{len(questions)} soru import edildi...")
        
        except Exception as e:
            print(f"❌ Soru {i} import edilemedi: {e}")
            failed_count += 1
    
    print(f"\n✅ Import tamamlandı!")
    print(f"📈 Başarılı: {imported_count}")
    print(f"❌ Başarısız: {failed_count}")

def main():
    import argparse
    
    parser = argparse.ArgumentParser(description='JSON sorularını Firestore\'a import et')
    parser.add_argument('--file', type=str, help='Import edilecek JSON dosyası')
    parser.add_argument('--dir', type=str, default='generated_questions/', help='JSON klasörü')
    
    args = parser.parse_args()
    
    db = init_firebase()
    
    if args.file:
        # Tek dosya import
        import_questions_to_firestore(args.file, db)
    else:
        # Klasördeki tüm JSON dosyalarını import
        json_dir = Path(args.dir)
        json_files = list(json_dir.glob("*_questions.json"))
        
        print(f"📁 {len(json_files)} JSON dosyası bulundu")
        
        for json_file in json_files:
            import_questions_to_firestore(str(json_file), db)

if __name__ == "__main__":
    main()
