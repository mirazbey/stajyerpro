import json
from pathlib import Path

sorular_dir = Path(r'c:\Users\HP\Desktop\StajyerPro\sorular')
total_questions = 0
filled_stems = 0
empty_stems = 0

for file_path in sorular_dir.glob('*.md'):
    content = file_path.read_text(encoding='utf-8')
    start = content.find('[')
    end = content.rfind(']') + 1
    
    if start == -1 or end == 0:
        continue
    
    try:
        data = json.loads(content[start:end])
        for q in data:
            total_questions += 1
            if q.get('stem'):
                filled_stems += 1
            else:
                empty_stems += 1
    except:
        pass

print(f"Total questions: {total_questions}")
print(f"With stem: {filled_stems}")
print(f"Empty stem: {empty_stems}")
