#!/usr/bin/env python3
"""
Soru Doğrulama Scripti
Tüm soruları AI_SORU_SABLONU.md formatına göre kontrol eder.
"""

import json
import re
import os
from pathlib import Path

# Geçerli subject kodları
VALID_SUBJECTS = [
    "ANAYASA", "MEDENI", "BORCLAR", "TICARET", "CEZA", "CMK",
    "IDARE", "IYUK", "VERGI", "ICRA", "IS", "AVUKATLIK",
    "FELSEFE", "MILLETLERARASI", "MOHUK"
]

# Zorunlu alanlar
REQUIRED_FIELDS = [
    "id", "subject_code", "topic_path", "difficulty", "stem",
    "options", "correct_option", "static_explanation"
]

# Opsiyonel alanlar
OPTIONAL_FIELDS = [
    "exam_weight_tag", "target_roles", "ai_hint", "related_statute",
    "learning_objective", "tags", "status"
]

def extract_questions_from_md(filepath: str) -> list:
    """Markdown dosyasından JSON soruları çıkar"""
    questions = []
    
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # JSON blokları bul
    json_pattern = r'```json\s*([\s\S]*?)\s*```'
    matches = re.findall(json_pattern, content)
    
    for match in matches:
        try:
            data = json.loads(match)
            if isinstance(data, list):
                questions.extend(data)
            elif isinstance(data, dict):
                questions.append(data)
        except json.JSONDecodeError:
            pass
    
    return questions

def validate_question(q: dict, index: int) -> list:
    """Tek bir soruyu doğrula, hata listesi döndür"""
    errors = []
    q_id = q.get('id', f'INDEX-{index}')
    
    # 1. Zorunlu alan kontrolü
    for field in REQUIRED_FIELDS:
        if field not in q:
            errors.append(f"[{q_id}] Zorunlu alan eksik: {field}")
    
    # 2. subject_code kontrolü
    subject = q.get('subject_code', '')
    if subject not in VALID_SUBJECTS:
        errors.append(f"[{q_id}] Geçersiz subject_code: '{subject}'")
    
    # 3. topic_path kontrolü
    topic_path = q.get('topic_path', [])
    if not isinstance(topic_path, list):
        errors.append(f"[{q_id}] topic_path liste olmalı")
    elif len(topic_path) == 0:
        errors.append(f"[{q_id}] topic_path boş olamaz")
    elif len(topic_path) > 2:
        errors.append(f"[{q_id}] topic_path maksimum 2 eleman olmalı, şu an: {len(topic_path)}")
    
    # 4. difficulty kontrolü
    difficulty = q.get('difficulty')
    if difficulty is not None:
        if not isinstance(difficulty, int) or difficulty < 1 or difficulty > 5:
            errors.append(f"[{q_id}] difficulty 1-5 arası integer olmalı, şu an: {difficulty}")
    
    # 5. stem kontrolü
    stem = q.get('stem', '')
    if len(stem) < 20:
        errors.append(f"[{q_id}] stem en az 20 karakter olmalı, şu an: {len(stem)}")
    
    # 6. options kontrolü
    options = q.get('options', [])
    if not isinstance(options, list):
        errors.append(f"[{q_id}] options liste olmalı")
    elif len(options) != 5:
        errors.append(f"[{q_id}] Tam 5 şık olmalı, şu an: {len(options)}")
    else:
        labels = [opt.get('label') for opt in options]
        expected_labels = ['A', 'B', 'C', 'D', 'E']
        if labels != expected_labels:
            errors.append(f"[{q_id}] Şık etiketleri A,B,C,D,E olmalı, şu an: {labels}")
        
        for opt in options:
            if 'text' not in opt or not opt['text']:
                errors.append(f"[{q_id}] Şık metni boş: {opt.get('label')}")
    
    # 7. correct_option kontrolü
    correct = q.get('correct_option', '')
    if correct not in ['A', 'B', 'C', 'D', 'E']:
        errors.append(f"[{q_id}] correct_option A-E arası olmalı, şu an: '{correct}'")
    
    # 8. static_explanation kontrolü
    explanation = q.get('static_explanation', '')
    if len(explanation) < 10:
        errors.append(f"[{q_id}] static_explanation en az 10 karakter olmalı")
    
    return errors

def main():
    base_dir = Path(__file__).parent.parent / "sorular"
    
    total_questions = 0
    valid_questions = 0
    all_errors = []
    file_stats = []
    
    print("=" * 70)
    print("📋 SORU DOĞRULAMA RAPORU")
    print("=" * 70)
    
    for subject in VALID_SUBJECTS:
        filepath = base_dir / f"{subject}_SORULAR.md"
        
        if not filepath.exists():
            print(f"⚠️  {subject}: Dosya bulunamadı")
            continue
        
        questions = extract_questions_from_md(str(filepath))
        total = len(questions)
        errors = []
        
        for i, q in enumerate(questions):
            q_errors = validate_question(q, i)
            errors.extend(q_errors)
        
        invalid = len(set(e.split(']')[0] + ']' for e in errors))
        valid = total - invalid
        
        status = "✅" if invalid == 0 else "⚠️"
        print(f"{status} {subject}: {valid}/{total} geçerli ({invalid} hatalı)")
        
        total_questions += total
        valid_questions += valid
        all_errors.extend(errors)
        file_stats.append({
            'subject': subject,
            'total': total,
            'valid': valid,
            'invalid': invalid
        })
    
    print("\n" + "=" * 70)
    print(f"📊 TOPLAM: {valid_questions}/{total_questions} geçerli soru")
    print(f"❌ Hatalı soru sayısı: {total_questions - valid_questions}")
    print("=" * 70)
    
    if all_errors:
        print(f"\n📝 İLK 30 HATA:")
        print("-" * 70)
        for error in all_errors[:30]:
            print(f"  • {error}")
        
        if len(all_errors) > 30:
            print(f"\n  ... ve {len(all_errors) - 30} hata daha")
    
    # Özet tablo
    print("\n" + "=" * 70)
    print("📈 DERS BAZLI ÖZET")
    print("-" * 70)
    print(f"{'Ders':<20} {'Toplam':>10} {'Geçerli':>10} {'Hatalı':>10}")
    print("-" * 70)
    for stat in file_stats:
        print(f"{stat['subject']:<20} {stat['total']:>10} {stat['valid']:>10} {stat['invalid']:>10}")
    print("-" * 70)
    print(f"{'TOPLAM':<20} {total_questions:>10} {valid_questions:>10} {total_questions - valid_questions:>10}")

if __name__ == "__main__":
    main()
