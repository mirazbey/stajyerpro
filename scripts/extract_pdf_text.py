import os
import json
from pathlib import Path
from PyPDF2 import PdfReader

# Configuration
DOCS_DIR = "docs/"
OUTPUT_FILE = "assets/rag_data.json"
CHUNK_SIZE = 1000  # Characters per chunk (approx 150-200 words)
OVERLAP = 100      # Overlap between chunks to maintain context

# Priority Files (Laws)
PRIORITY_FILES = [
    "TC Anayasası.pdf",
    "türk ceza kanunu.pdf",
    "türk borçlar kanunu.pdf",
    "türk medeni kanunu.pdf",
    "türk ticaret kanunu.pdf",
    "idari yargılama usülü kanunu.pdf",
    "ceza muhakemesi kanunu.pdf",
    "hukuk muhakemeleri kanunu.pdf"
]

def extract_text_from_pdf(pdf_path: str) -> str:
    """Extracts text from a PDF file."""
    print(f"📄 Reading: {pdf_path}")
    try:
        reader = PdfReader(pdf_path)
        text = ""
        # Read all pages
        for page in reader.pages:
            extracted = page.extract_text()
            if extracted:
                text += extracted + "\n"
        return text
    except Exception as e:
        print(f"❌ Error reading {pdf_path}: {e}")
        return ""

def create_chunks(text: str, source: str) -> list:
    """Splits text into chunks with overlap."""
    chunks = []
    start = 0
    text_len = len(text)

    while start < text_len:
        end = start + CHUNK_SIZE
        chunk_text = text[start:end]
        
        # Clean up whitespace
        chunk_text = " ".join(chunk_text.split())
        
        if len(chunk_text) > 50: # Ignore very short chunks
            chunks.append({
                "content": chunk_text,
                "source": source,
                "type": "law",
                "createdAt": "2024-11-29T12:00:00Z" # Placeholder
            })
        
        start += (CHUNK_SIZE - OVERLAP)
    
    return chunks

def main():
    all_data = []
    
    # Ensure output directory exists
    os.makedirs(os.path.dirname(OUTPUT_FILE), exist_ok=True)

    # Process priority files
    for filename in PRIORITY_FILES:
        file_path = os.path.join(DOCS_DIR, filename)
        if os.path.exists(file_path):
            text = extract_text_from_pdf(file_path)
            if text:
                chunks = create_chunks(text, source=filename)
                print(f"✅ {filename}: {len(chunks)} chunks created.")
                all_data.extend(chunks)
        else:
            print(f"⚠️ File not found: {filename}")

    # Save to JSON
    with open(OUTPUT_FILE, 'w', encoding='utf-8') as f:
        json.dump(all_data, f, ensure_ascii=False, indent=2)

    print(f"\n🎉 Success! {len(all_data)} total chunks saved to {OUTPUT_FILE}")

if __name__ == "__main__":
    main()
