import csv
from collections import defaultdict
from pathlib import Path

import firebase_admin
from firebase_admin import credentials, firestore

# Config
SERVICE_ACCOUNT_PATH = 'service-account.json'
BATCH_SIZE = 450  # below Firestore 500 limit
REPORT_PATH = Path('duplicates_removed.txt')
DUP_CSV_PATH = Path('duplicates_report.csv')

# Init Firebase
if not firebase_admin._apps:
    cred = credentials.Certificate(SERVICE_ACCOUNT_PATH)
    firebase_admin.initialize_app(cred)

db = firestore.client()


def normalize_stem_key(stem: str) -> str:
    stem = (stem or '').strip()
    return stem[:60]


def load_from_csv(csv_path):
    survivors = []
    victims = []
    if not csv_path.exists():
        return survivors, victims
    with csv_path.open('r', encoding='utf-8') as f:
        reader = csv.DictReader(f)
        seen = set()
        for row in reader:
            stem_key = row['stem_key']
            qid = row['question_id']
            if stem_key not in seen:
                survivors.append((stem_key, {'id': qid}))
                seen.add(stem_key)
            else:
                victims.append((stem_key, {'id': qid}))
    return survivors, victims


def fetch_questions():
    questions = list(db.collection('questions').stream())
    stem_map = defaultdict(list)
    for q in questions:
        data = q.to_dict()
        stem = (data.get('stem') or '').strip()
        if not stem:
            continue
        stem_key = normalize_stem_key(stem)
        stem_map[stem_key].append({
            'id': q.id,
            'ref': q.reference,
            'data': data,
            'stem': stem,
        })
    return stem_map


def sort_key(entry):
    created = entry['data'].get('createdAt') or entry['data'].get('created_at')
    # Firestore Timestamp has isoformat; fallback to string for deterministic ordering
    if hasattr(created, 'isoformat'):
        created_val = created.isoformat()
    else:
        created_val = str(created) if created is not None else ''
    return (created_val, entry['id'])


def pick_survivor_and_victims(stem_map):
    victims = []
    survivors = []
    for stem_key, entries in stem_map.items():
        if len(entries) <= 1:
            continue
        entries_sorted = sorted(entries, key=sort_key)
        survivor = entries_sorted[0]
        duplicates = entries_sorted[1:]
        survivors.append((stem_key, survivor))
        for dup in duplicates:
            victims.append((stem_key, dup))
    return survivors, victims


def delete_victims(victims):
    batch = db.batch()
    deleted = 0
    for idx, (_, victim) in enumerate(victims, 1):
        if 'ref' in victim:
            batch.delete(victim['ref'])
        else:
            batch.delete(db.collection('questions').document(victim['id']))
        deleted += 1
        if idx % BATCH_SIZE == 0:
            batch.commit()
            batch = db.batch()
    if deleted % BATCH_SIZE != 0:
        batch.commit()
    return deleted


def write_report(survivors, victims):
    with REPORT_PATH.open('w', encoding='utf-8') as f:
        f.write('Survivors (kept 1 per stem_key)\n')
        for stem_key, survivor in sorted(survivors, key=lambda x: x[0]):
            f.write(f"stem_key={stem_key} keep={survivor['id']}\n")
        f.write('\nDeleted duplicates\n')
        for stem_key, victim in sorted(victims, key=lambda x: x[0]):
            f.write(f"stem_key={stem_key} delete={victim['id']}\n")


def main():
    # Prefer using existing CSV to avoid large reads when quota is tight
    survivors, victims = load_from_csv(DUP_CSV_PATH)
    source = 'csv'
    if not survivors and not victims:
        stem_map = fetch_questions()
        survivors, victims = pick_survivor_and_victims(stem_map)
        source = 'firestore'
    print(f"Source: {source}")
    print(f"Duplicate groups: {len(survivors)}")
    print(f"Rows to delete (leaving 1 each): {len(victims)}")
    if not victims:
        return
    deleted = delete_victims(victims)
    write_report(survivors, victims)
    print(f"Deleted {deleted} duplicates")
    print(f"Report: {REPORT_PATH.resolve()}")


if __name__ == '__main__':
    main()
