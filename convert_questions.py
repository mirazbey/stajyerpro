import json
import re
import datetime
from pathlib import Path

BASE_DIR = Path(r'c:\Users\HP\Desktop\StajyerPro')
QUESTIONS_DIR = BASE_DIR / 'sorular'
ALLOWED_TAGS = {'core', 'supporting', 'longtail'}
ROLE_MAP = {
    'avukat': 'avukat',
    'avukatlik': 'avukat',
    'hakim': 'hakim',
    'hakimlik': 'hakim',
    'savci': 'savci',
    'savcilik': 'savci',
    'savcı': 'savci',
    'noter': 'noter',
    'noterlik': 'noter',
}
LABEL_ORDER = ['A', 'B', 'C', 'D', 'E']
INTRO_TEMPLATE = "# {title}\n\nBu dosya, {lower_title} kapsaminda uretilen sorulari standart formatta sunar.\n\n"


def extract_json_blocks(text: str):
    return re.findall(r"```json\s*(.*?)\s*```", text, re.S)


def parse_topic_path(value):
    if not value:
        return []
    if isinstance(value, list):
        return [str(v).strip() for v in value if str(v).strip()]
    parts = [part.strip() for part in str(value).split('>')]
    return [p for p in parts if p]


def extract_roles(value):
    if not value:
        return []
    text = str(value).lower().replace('ı', 'i')
    result = []
    for key, role in ROLE_MAP.items():
        if key in text and role not in result:
            result.append(role)
    return result


def parse_options(value):
    if not value:
        return []
    if isinstance(value, dict):
        return [{'label': label, 'text': str(value[label]).strip()} for label in LABEL_ORDER if label in value]
    if isinstance(value, list):
        result = []
        for item in value:
            label = item.get('label')
            text = item.get('text')
            if label and text:
                result.append({'label': label, 'text': str(text)})
        return result
    return []


def extract_source_pdf(ref):
    if not ref:
        return ''
    return str(ref).split(',')[0].strip()


def extract_source_page(ref, fallback):
    if isinstance(fallback, (int, float)):
        return int(fallback)
    if isinstance(ref, (int, float)):
        return int(ref)
    if ref:
        match = re.search(r"(\d+)", str(ref))
        if match:
            return int(match.group(1))
    return 0


def normalize_exam_tag(tag):
    if not tag:
        return 'supporting'
    tag_lower = str(tag).strip().lower()
    return tag_lower if tag_lower in ALLOWED_TAGS else 'supporting'


def ensure_difficulty(value):
    try:
        diff = int(value)
    except (TypeError, ValueError):
        return 2
    return min(3, max(1, diff))


def normalize_entry(entry):
    if isinstance(entry, dict) and 'meta_bilgiler' in entry:
        meta = entry.get('meta_bilgiler') or {}
        body = {k: v for k, v in entry.items() if k != 'meta_bilgiler'}
    else:
        meta = entry if isinstance(entry, dict) else {}
        body = entry if isinstance(entry, dict) else {}

    subject_code = meta.get('Subject Code') or meta.get('SubjectCode') or body.get('Subject Code') or body.get('SubjectCode') or meta.get('subject_code') or body.get('subject_code')
    topic_path_raw = meta.get('Topic Path') or meta.get('TopicPath') or body.get('Topic Path')
    difficulty = meta.get('Difficulty') or body.get('Difficulty')
    exam_tag = meta.get('Exam Weight Tag') or meta.get('ExamWeightTag') or body.get('Exam Weight Tag')
    target = meta.get('Target Role Emphasis') or body.get('Target Role Emphasis')
    source_ref = meta.get('Source Reference') or body.get('Source Reference')
    related = meta.get('RelatedStatute') or body.get('RelatedStatute') or body.get('related_statute')
    stem = body.get('Question') or body.get('question') or body.get('Stem') or body.get('stem')
    options = body.get('Options') or body.get('options')
    correct = body.get('Answer') or body.get('answer') or body.get('CorrectOption')
    explanation = body.get('Explanation') or body.get('explanation') or body.get('StaticExplanation')
    source_page_value = body.get('source_page') or meta.get('source_page')

    return {
        'subject_code': str(subject_code).strip().upper() if subject_code else 'GENERAL',
        'topic_path': parse_topic_path(topic_path_raw) or ['Genel'],
        'difficulty': ensure_difficulty(difficulty),
        'exam_weight_tag': normalize_exam_tag(exam_tag),
        'target_roles': extract_roles(target),
        'source_reference': source_ref or '',
        'stem': str(stem).strip() if stem else '',
        'options_raw': options,
        'correct_option': str(correct).strip().upper() if correct else 'A',
        'static_explanation': str(explanation).strip() if explanation else '',
        'related_statute': str(related).strip() if related else '',
        'source_page_value': source_page_value,
    }


def convert_files():
    now_iso = datetime.datetime.now(datetime.timezone.utc).replace(microsecond=0).isoformat()
    converted = []
    for file_path in sorted(QUESTIONS_DIR.glob('*.md')):
        text = file_path.read_text(encoding='utf-8')
        blocks = extract_json_blocks(text)
        if not blocks:
            continue
        entries = []
        for block in blocks:
            block = block.strip()
            try:
                obj = json.loads(block)
            except json.JSONDecodeError:
                continue
            if isinstance(obj, list):
                entries.extend(obj)
            else:
                entries.append(obj)
        if not entries:
            continue
        normalized = [normalize_entry(entry) for entry in entries]
        base_name = file_path.stem
        prefix = re.sub(r'[^A-Za-z0-9]', '', base_name).upper() or 'QUESTION'
        new_questions = []
        for idx, norm in enumerate(normalized, start=1):
            options = parse_options(norm['options_raw'])
            if not options:
                options = [{'label': label, 'text': ''} for label in LABEL_ORDER]
            topic_path = norm['topic_path']
            subject_code = norm['subject_code']
            source_ref = norm['source_reference']
            source_pdf = extract_source_pdf(source_ref)
            source_page = extract_source_page(source_ref, norm['source_page_value'])
            related = norm['related_statute']
            ai_hint = f"{related or subject_code} kapsaminda {topic_path[-1]} konusuna odaklan." if topic_path else (related or subject_code)
            learning = f"{topic_path[-1]} bilgisini pekistirme" if topic_path else 'Konu bilgisini pekistirme'
            question_id = f"{prefix}-{idx:03d}"
            new_questions.append({
                'id': question_id,
                'subject_code': subject_code,
                'topic_path': topic_path,
                'difficulty': norm['difficulty'],
                'exam_weight_tag': norm['exam_weight_tag'],
                'target_roles': norm['target_roles'],
                'stem': norm['stem'],
                'options': options,
                'correct_option': norm['correct_option'],
                'static_explanation': norm['static_explanation'],
                'ai_hint': ai_hint,
                'related_statute': related,
                'learning_objective': learning,
                'source_pdf': source_pdf,
                'source_page': source_page,
                'created_at': now_iso,
                'status': 'draft'
            })

        def question_block(qdict, source_reference):
            topic_display = ' > '.join(qdict['topic_path']) if qdict['topic_path'] else ''
            target_str = ', '.join(qdict['target_roles']) if qdict['target_roles'] else 'genel'
            lines = [
                '[QUESTION]',
                f"SubjectCode: {qdict['subject_code']}",
                f"TopicPath: {topic_display}",
                f"Difficulty: {qdict['difficulty']}",
                f"ExamWeightTag: {qdict['exam_weight_tag']}",
                f"TargetRoles: {target_str}",
                f"SourceReference: {source_reference}",
                f"Stem: {qdict['stem']}",
                'Options:'
            ]
            for opt in qdict['options']:
                lines.append(f"{opt['label']}) {opt['text']}")
            lines.extend([
                f"CorrectOption: {qdict['correct_option']}",
                f"StaticExplanation: {qdict['static_explanation']}",
                f"AIHint: {qdict['ai_hint']}",
                f"RelatedStatute: {qdict['related_statute']}",
                f"LearningObjective: {qdict['learning_objective']}",
            ])
            return '\n'.join(lines)

        blocks_output = [question_block(qdict, norm['source_reference']) for norm, qdict in zip(normalized, new_questions)]
        json_output = json.dumps(new_questions, ensure_ascii=False, indent=2)
        title = base_name.replace('_', ' ').title()
        intro = INTRO_TEMPLATE.format(title=title, lower_title=title.lower())
        content = intro + "## Soru Bloklari\n\n" + '\n\n'.join(blocks_output) + "\n\n## JSON Ciktisi\n\n```json\n" + json_output + "\n```\n"
        file_path.write_text(content, encoding='utf-8')
        converted.append(file_path.name)

    print(f"Donusturulen dosya sayisi: {len(converted)}")


if __name__ == '__main__':
    convert_files()
