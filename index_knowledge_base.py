import os
import glob
import firebase_admin
from firebase_admin import credentials
from firebase_admin import firestore
import google.generativeai as genai
from pathlib import Path
import time

# Configuration
BASE_DIR = Path(r'c:\Users\HP\Desktop\StajyerPro')
DOCS_DIR = BASE_DIR / 'docs'
SERVICE_ACCOUNT_PATH = BASE_DIR / 'service-account.json'

# Initialize Firebase
if not firebase_admin._apps:
    cred = credentials.Certificate(str(SERVICE_ACCOUNT_PATH))
    firebase_admin.initialize_app(cred)

db = firestore.client()

# Configure Gemini
# IMPORTANT: Set your API key in the environment variable GOOGLE_API_KEY
# or replace 'os.environ["GOOGLE_API_KEY"]' with your actual key string for testing (not recommended for production).
GOOGLE_API_KEY = os.environ.get("GOOGLE_API_KEY")

if not GOOGLE_API_KEY:
    print("WARNING: GOOGLE_API_KEY environment variable not set.")
    # Placeholder for user to input key if running interactively or hardcode for local test
    # GOOGLE_API_KEY = "YOUR_API_KEY_HERE" 

if GOOGLE_API_KEY:
    genai.configure(api_key=GOOGLE_API_KEY)

def get_embedding(text):
    if not GOOGLE_API_KEY:
        return []
    try:
        # Using the embedding-001 model
        result = genai.embed_content(
            model="models/embedding-001",
            content=text,
            task_type="retrieval_document",
            title="Legal Document Chunk"
        )
        return result['embedding']
    except Exception as e:
        print(f"Error generating embedding: {e}")
        return []

def chunk_text(text, chunk_size=1000, overlap=100):
    """Simple overlapping chunker."""
    chunks = []
    start = 0
    text_len = len(text)
    
    while start < text_len:
        end = start + chunk_size
        chunk = text[start:end]
        chunks.append(chunk)
        start += chunk_size - overlap
    return chunks

def index_documents():
    print(f"Scanning {DOCS_DIR}...")
    
    files = list(DOCS_DIR.glob('*.txt')) + list(DOCS_DIR.glob('*.md'))
    
    total_chunks = 0
    
    for file_path in files:
        print(f"Processing {file_path.name}...")
        try:
            text = file_path.read_text(encoding='utf-8')
        except Exception as e:
            print(f"Error reading {file_path.name}: {e}")
            continue
            
        # Simple chunking strategy
        # For legal texts, splitting by Article (Madde) might be better, 
        # but for now we use fixed size for simplicity.
        chunks = chunk_text(text)
        
        batch = db.batch()
        batch_count = 0
        
        for i, chunk_text_content in enumerate(chunks):
            if not chunk_text_content.strip():
                continue
                
            embedding = get_embedding(chunk_text_content)
            
            if not embedding:
                print(f"  Skipping chunk {i} due to missing embedding.")
                continue

            doc_id = f"{file_path.stem}_chunk_{i}"
            doc_ref = db.collection('knowledge_base').document(doc_id)
            
            doc_data = {
                'source': file_path.name,
                'content': chunk_text_content,
                'embedding': embedding, # Vector field
                'createdAt': firestore.SERVER_TIMESTAMP
            }
            
            batch.set(doc_ref, doc_data)
            batch_count += 1
            total_chunks += 1
            
            if batch_count >= 400:
                batch.commit()
                batch = db.batch()
                batch_count = 0
                time.sleep(1) # Rate limiting precaution
                
        if batch_count > 0:
            batch.commit()
            
        print(f"  Indexed {len(chunks)} chunks from {file_path.name}")

    print(f"\nIndexing Complete!")
    print(f"Total Chunks Indexed: {total_chunks}")

if __name__ == '__main__':
    if not GOOGLE_API_KEY:
        print("ERROR: Please set GOOGLE_API_KEY environment variable to run this script.")
    else:
        index_documents()
