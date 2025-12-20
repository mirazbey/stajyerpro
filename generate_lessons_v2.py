import os, sys, time, json, re
from pathlib import Path
from datetime import datetime
import google.generativeai as genai
import firebase_admin
from firebase_admin import credentials, firestore

try:
    from pypdf import PdfReader
except:
    os.system("pip install -q pypdf")
    from pypdf import PdfReader

BASE_DIR = Path.cwd()
OUTPUT_DIR = BASE_DIR / "generated_lessons"
OUTPUT_DIR.mkdir(exist_ok=True)
DOCS_DIR = BASE_DIR / "docs"
DOCS_DIR.mkdir(exist_ok=True)

if not firebase_admin._apps:
    cred = credentials.Certificate("service-account.json")
    firebase_admin.initialize_app(cred)

db = firestore.client()

API_KEYS = [
    "AIzaSyApIRbm-RF9dHQ_99duUH4QUz6_NNJz65E",
    os.getenv("GEMINI_API_KEY"),
]
API_KEYS = [k for k in API_KEYS if k]
key_idx = 0

def get_api_key():
    global key_idx
    k = API_KEYS[key_idx % len(API_KEYS)]
    key_idx += 1
    return k

def slugify(t):
    t = t.lower()
    t = t.replace("Ã§","c").replace("ÄŸ","g").replace("Ä±","i").replace("Ã¶","o").replace("ÅŸ","s").replace("Ã¼","u")
    return re.sub(r"[^a-z0-9]+", "_", t).strip("_")

def extract_pdf(pdf_path, max_chars=8000):
    try:
        reader = PdfReader(pdf_path)
        text = ""
        for p in reader.pages:
            text += p.extract_text() + "\n"
            if len(text) > max_chars: break
        return text[:max_chars]
    except:
        return ""

def find_pdfs(subject, topic):
    texts = []
    if not DOCS_DIR.exists(): return texts
    subj_slug = slugify(subject)
    for pdf in DOCS_DIR.glob("**/*.pdf"):
        if subj_slug in slugify(pdf.stem):
            print(f"  ğŸ“„ {pdf.name}")
            txt = extract_pdf(pdf)
            if txt: texts.append(txt)
    return texts

PROMPT = """HMGS sÄ±navÄ± ders iÃ§eriÄŸi oluÅŸtur.

KONU: {topic}
DERS: {subject}

{pdf_context}

3-4 SAYFA UZUNLUUNDA Ã‡ERK OLUÅTUR:

1. ADIM: Temel Kavramlar (4-6 madde, kÄ±sa Ã¶z)
2. ADIM: Yasal Ã‡erÃ§eve (4-6 madde, kanun maddeleri)
3. ADIM: Pratik Ã–rnekler (4-6 madde, vaka Ã¶rnekleri)
4. ADIM: Dikkat NoktalarÄ± (4-6 madde, sÄ±k hatalar)
5. ADIM: SÄ±nav HazÄ±rlÄ±ÄŸÄ± (4-6 madde, Ã¶zet)

PEKÅTRME SORULARI: 5 adet Ã§oktan seÃ§meli

JSON FORMAT:
{{
  "steps": [
    {{"stepNumber": 1, "title": "Temel Kavramlar", "content": "â€¢ Madde 1\nâ€¢ Madde 2\n..."}},
    {{"stepNumber": 2, "title": "Yasal Ã‡erÃ§eve", "content": "..."}},
    {{"stepNumber": 3, "title": "Pratik Ã–rnekler", "content": "..."}},
    {{"stepNumber": 4, "title": "Dikkat NoktalarÄ±", "content": "..."}},
    {{"stepNumber": 5, "title": "SÄ±nav HazÄ±rlÄ±ÄŸÄ±", "content": "..."}}
  ],
  "practiceQuestions": [
    {{
      "questionNumber": 1,
      "question": "Soru?",
      "options": {{"A": "...", "B": "...", "C": "...", "D": "..."}},
      "correctAnswer": "A",
      "explanation": "AÃ§Ä±klama"
    }}
  ]
}}

SADECE JSON DÃ–NDÃœR!"""

def generate(topic, subject, pdfs, api_key):
    try:
        genai.configure(api_key=api_key)
        model = genai.GenerativeModel("gemini-2.5-flash")
        
        pdf_ctx = ""
        if pdfs:
            pdf_ctx = "PDF KAYNAK:\n" + "\n".join(pdfs[:2])
        
        prompt = PROMPT.format(topic=topic, subject=subject, pdf_context=pdf_ctx)
        resp = model.generate_content(prompt)
        text = resp.text.strip()
        
        if "```json" in text:
            text = text.split("```json")[1].split("```")[0]
        elif "```" in text:
            text = text.split("```")[1].split("```")[0]
        
        data = json.loads(text.strip())
        
        if len(data.get("steps", [])) < 5:
            print(f"  âš ï¸ Only {len(data.get('steps',[]))} steps")
            return None
        if len(data.get("practiceQuestions", [])) < 3:
            print(f"  âš ï¸ Only {len(data.get('practiceQuestions',[]))} questions")
            return None
        
        return data
    except Exception as e:
        print(f"  âŒ Error: {e}")
        return None

def upload(topic_id, data):
    try:
        doc = {
            "topicId": topic_id,
            "steps": data["steps"],
            "practiceQuestions": data.get("practiceQuestions", []),
            "createdAt": firestore.SERVER_TIMESTAMP,
            "updatedAt": firestore.SERVER_TIMESTAMP
        }
        db.collection("topic_lessons").document(topic_id).set(doc)
        return True
    except Exception as e:
        print(f"  âŒ Upload: {e}")
        return False

print("="*80)
print("COMPREHENSIVE LESSON GENERATOR")
print("="*80)
print(f"Output: {OUTPUT_DIR}")
print(f"PDFs: {DOCS_DIR}")
print(f"API Keys: {len(API_KEYS)}")

subjects = {s.id: s.to_dict().get("name") for s in db.collection("subjects").stream()}
all_topics = list(db.collection("topics").stream())
empty = [(t.id, t.to_dict()) for t in all_topics if len(t.to_dict().get("description", "").strip()) < 10]

print(f"\nTopics: {len(all_topics)}, Empty: {len(empty)}")
print(f"Estimated time: ~{len(empty)*0.5:.0f} minutes\n")

if input("Start? (y/n): ").lower() != "y":
    sys.exit(0)

print("\n" + "="*80)
success, uploaded, failed = 0, 0, []
start = datetime.now()

for idx, (tid, tdata) in enumerate(empty, 1):
    tname = tdata.get("name", "Unknown")
    sid = tdata.get("subjectId", "")
    sname = subjects.get(sid, sid)
    
    print(f"\n[{idx}/{len(empty)}] {tname} ({sname})")
    
    pdfs = find_pdfs(sname, tname)
    api_key = get_api_key()
    
    data = generate(tname, sname, pdfs, api_key)
    
    if data:
        slug = f"{slugify(sname)}__{slugify(tname)}"
        jpath = OUTPUT_DIR / f"{slug}.json"
        with open(jpath, "w", encoding="utf-8") as f:
            json.dump(data, f, ensure_ascii=False, indent=2)
        print(f"  âœ… Saved: {jpath.name}")
        success += 1
        
        if upload(tid, data):
            print(f"  â˜ï¸  Uploaded")
            uploaded += 1
        
        time.sleep(3)
    else:
        failed.append((tid, tname, sname))
        time.sleep(1)
    
    if idx % 10 == 0:
        elapsed = (datetime.now() - start).total_seconds() / 60
        rate = idx / elapsed if elapsed > 0 else 0
        remain = (len(empty) - idx) / rate if rate > 0 else 0
        print(f"\n{'='*80}")
        print(f"Progress: {idx}/{len(empty)} | Success: {success} | Uploaded: {uploaded}")
        print(f"Time: {elapsed:.1f}min | Remaining: ~{remain:.1f}min")
        print(f"{'='*80}\n")

total_time = (datetime.now() - start).total_seconds() / 60

print("\n" + "="*80)
print("COMPLETE")
print(f"Generated: {success}/{len(empty)}")
print(f"Uploaded: {uploaded}/{len(empty)}")
print(f"Failed: {len(failed)}")
print(f"Time: {total_time:.1f} minutes")
print("="*80)

if failed:
    fpath = OUTPUT_DIR / "_failed.json"
    with open(fpath, "w", encoding="utf-8") as f:
        json.dump([{"id": t[0], "name": t[1], "subject": t[2]} for t in failed], f, ensure_ascii=False, indent=2)
    print(f"\nFailed saved: {fpath}")
