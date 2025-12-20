import csv
import time
from pathlib import Path
from collections import defaultdict

import firebase_admin
from firebase_admin import credentials, firestore
from google.api_core.exceptions import ResourceExhausted, RetryError

# Firebase init
if not firebase_admin._apps:
    cred = credentials.Certificate('service-account.json')
    firebase_admin.initialize_app(cred)

db = firestore.client()

# Output path
OUTPUT_PATH = Path('duplicates_report.csv')

# Pagination and retry settings to reduce quota spikes
PAGE_SIZE = 20
MAX_RETRIES = 12
BACKOFF_SECONDS = 3


def stream_questions_paginated():
    query = db.collection('questions').order_by('__name__').limit(PAGE_SIZE)
    last_doc = None
    while True:
        if last_doc is not None:
            query = db.collection('questions').order_by('__name__').start_after(last_doc).limit(PAGE_SIZE)
        page = None
        for attempt in range(MAX_RETRIES):
            try:
                page = list(query.stream())
                break
            except (ResourceExhausted, RetryError):
                sleep_s = BACKOFF_SECONDS * (attempt + 1)
                time.sleep(sleep_s)
        if page is None:
            raise RuntimeError('Failed to read questions due to repeated quota errors')
        if not page:
            break
        last_doc = page[-1]
        for doc in page:
            yield doc


def collect_duplicates():
    stem_map = defaultdict(list)
    for q in stream_questions_paginated():
        data = q.to_dict()
        stem = (data.get('stem') or '').strip()
        if not stem:
            continue
        stem_key = stem[:60]  # same heuristic used in analyze_topics.py
        stem_map[stem_key].append({
            'id': q.id,
            'stem': stem,
            'subjectId': data.get('subjectId', ''),
            'topicIds': ','.join(data.get('topicIds', []) if isinstance(data.get('topicIds'), list) else [data.get('topicIds') or '']),
            'difficulty': data.get('difficulty', ''),
        })

    duplicates = {k: v for k, v in stem_map.items() if len(v) > 1}
    return duplicates


def write_csv(duplicates):
    with OUTPUT_PATH.open('w', newline='', encoding='utf-8') as f:
        writer = csv.writer(f)
        writer.writerow(['stem_key', 'question_id', 'subjectId', 'topicIds', 'difficulty', 'stem_full'])
        for stem_key, entries in sorted(duplicates.items(), key=lambda x: x[0]):
            for e in entries:
                writer.writerow([
                    stem_key,
                    e['id'],
                    e['subjectId'],
                    e['topicIds'],
                    e['difficulty'],
                    e['stem'],
                ])


def main():
    duplicates = collect_duplicates()
    print(f"Duplicate stems: {len(duplicates)} groups")
    total_rows = sum(len(v) for v in duplicates.values())
    print(f"Total duplicate rows (including originals): {total_rows}")
    if not duplicates:
        return
    write_csv(duplicates)
    print(f"Written: {OUTPUT_PATH.resolve()}")


if __name__ == '__main__':
    main()
