import sys
import time
from pathlib import Path
import re
from datetime import datetime, timezone

BASE_DIR = Path(__file__).resolve().parent
PRD_PATH = BASE_DIR / "StajyerPro_PRD_v1.md"
REPORT_PATH = BASE_DIR / "Workflow_UI_Report.md"
LOG_PATH = BASE_DIR / "yapilan_islemler.md"
NOTES_DIR = BASE_DIR / "dev_notes"

TODO_PATTERN = re.compile(r"^- \[ \] .+$", re.MULTILINE)
LAST_LOG_WRITE_MTIME = 0.0


def current_timestamp() -> str:
    return datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M:%SZ")


def read_file(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def write_file(path: Path, content: str) -> None:
    path.write_text(content, encoding="utf-8")


def append_log(message: str) -> None:
    global LAST_LOG_WRITE_MTIME
    entry = f"- {current_timestamp()} – {message}\n"
    with LOG_PATH.open("a", encoding="utf-8") as handle:
        handle.write(entry)
    try:
        LAST_LOG_WRITE_MTIME = LOG_PATH.stat().st_mtime
    except FileNotFoundError:
        LAST_LOG_WRITE_MTIME = time.time()


def safe_display(text: str) -> str:
    encoding = sys.stdout.encoding or "utf-8"
    try:
        return text.encode(encoding, errors="replace").decode(encoding, errors="replace")
    except Exception:
        return text


def ensure_dir(path: Path) -> None:
    path.mkdir(parents=True, exist_ok=True)


def write_text_file(path: Path, content: str) -> None:
    path.write_text(content, encoding="utf-8")


def setup_flutter_firebase(task_text: str) -> bool:
    """Create/update flutter+firebase setup plan."""
    ensure_dir(NOTES_DIR)
    plan_path = NOTES_DIR / "flutter_firebase_setup.md"
    plan_content = f"""# Flutter + Firebase Setup Plan


Bu plan, StajyerPro için Flutter istemcisi ile Firebase (Auth, Firestore, Storage) entegrasyonunu kurarken izlenecek adımları özetler.

## 1. Flutter Projesi
- Flutter 3.19+ sürümünün kurulu olduğunu doğrula (`flutter --version`).
- Projeyi `stajyerpro_app` adıyla oluştur: `flutter create stajyerpro_app`.
- `lib/` altına `core`, `features`, `shared` klasörlerini ekle; Riverpod ve go_router bağımlılıkları için `pubspec.yaml` güncelle.

## 2. Firebase Entegrasyonu
- Firebase Console’da `stajyerpro-app` projesini aç; Android ve iOS uygulamaları ekle.
- Android için `google-services.json`, iOS için `GoogleService-Info.plist` dosyalarını `stajyerpro_app/android/app` ve `ios/Runner` içine yerleştir.
- `flutterfire configure` komutunu çalıştırarak `firebase_options.dart` üret.

## 3. Auth (FR-01/FR-02)
- Firebase Auth’ta Email/Password + Google Sign-In aktif et.
- Onboarding sırasında hedef rol, sınav tarihi ve çalışma yoğunluğu Firestore’daki `users/{{uid}}` dokümanına yazılacak.

## 4. Firestore & Storage
- Koleksiyonlar: `users`, `subjects`, `topics`, `questions`, `exam_attempts`, `daily_stats`, `ai_sessions`.
- `lib/core/firebase/firestore_paths.dart` dosyasında koleksiyon sabitlerini tanımla.
- Storage’da ileride PDF/video içeriği için `content/` klasörü aç.

## 5. Ortam Değişkenleri
- `.env` benzeri dosyada API anahtarları tutulacak; Flutter tarafında `flutter_dotenv` ile kullan.
- `README.md` içinden Firebase proje ID, App ID, `firebase_options.dart` üretim talimatları paylaş.

Bu dosya script_runner tarafından {current_timestamp()} tarihinde üretildi.
"""
    write_text_file(plan_path, plan_content)
    append_log("Flutter + Firebase setup planı dev_notes/flutter_firebase_setup.md içerisinde güncellendi.")
    return True


def slugify(text: str) -> str:
    slug = re.sub(r"[^a-z0-9]+", "_", text.lower())
    slug = slug.strip("_")
    return slug or "task"


def generic_task_plan(task_text: str) -> bool:
    ensure_dir(NOTES_DIR)
    slug = slugify(task_text)[:80]
    note_path = NOTES_DIR / f"{slug}_plan.md"
    content = f"""# Görev Planı: {task_text}

Bu belge, PRD ve Workflow notlarına göre \"{task_text}\" başlığındaki çalışmayı planlamak için script tarafından üretildi.

## Yapılacaklar
- PRD’de ilgili FR/NFR maddelerini kontrol et.
- Gerekli veri modelleri, UI bileşenleri ve backend süreçlerini listele.
- Tamamlandığında bu planı güncelle.

Oluşturulma zamanı: {current_timestamp()}
"""
    write_text_file(note_path, content)
    append_log(f"Genel görev planı oluşturuldu: dev_notes/{note_path.name}")
    return True


TASK_HANDLERS = [
    ("Flutter projesini oluşturup Firebase", setup_flutter_firebase),
]


def resolve_handler(task_text: str):
    for keyword, handler in TASK_HANDLERS:
        if keyword in task_text:
            return handler
    return generic_task_plan


def mark_task(content: str, task_line: str) -> str:
    completed_line = task_line.replace("[ ]", "[x]", 1)
    return content.replace(task_line, completed_line, 1)


def mark_task_by_text(content: str, task_text: str):
    pattern = re.compile(rf"^- \[ \] {re.escape(task_text)}$", re.MULTILINE)
    match = pattern.search(content)
    if not match:
        return content, False
    replaced_line = match.group(0).replace("[ ]", "[x]", 1)
    updated = content[:match.start()] + replaced_line + content[match.end():]
    return updated, True





def main() -> None:
    user_prompt = " ".join(sys.argv[1:]).strip()
    watching = user_prompt.lower().startswith("script")
    if not watching:
        print("Script izleme modunda çalışmadı (komut 'script' ile başlamıyor).")
        return

    print("0) Script izleme modunda başlatıldı.")

    prd_content = read_file(PRD_PATH)
    prd_todos = TODO_PATTERN.findall(prd_content)
    if not prd_todos:
        print("Görev bulunamadı; `yapilan_islemler.md` değişimlerini izlemeye geçiliyor.")
        watch_log_and_trigger()
        return
    current_task_line = prd_todos[0]
    task_text = current_task_line.split("] ", 1)[1]
    print(f"1) PRD'den görev alındı: {safe_display(task_text)}")

    # Görevi işaretle
    updated_prd = mark_task(prd_content, current_task_line)
    write_file(PRD_PATH, updated_prd)
    print("2) PRD'deki görev [x] olarak işaretlendi.")

    # Workflow raporunda eşleşen satırı işaretle
    workflow_content = read_file(REPORT_PATH)
    updated_workflow, found = mark_task_by_text(workflow_content, task_text)
    if found:
        write_file(REPORT_PATH, updated_workflow)
        print("3) Workflow raporundaki eş görev de [x] oldu.")
    else:
        print("3) Workflow raporunda eşleşen satır bulunamadı.")

    # Yapılan işlemi logla
    append_log(f"Görev tamamlandı: {task_text}")
    print("4) Yapılan işlemler kaydedildi.")

    print("5) Script tamamlandı. Yeni görev eklenirse tekrar çalıştırılabilir.")


def process_next_task(initial_run: bool = False) -> bool:
    prd_content = read_file(PRD_PATH)
    prd_todos = TODO_PATTERN.findall(prd_content)

    if not prd_todos:
        if initial_run:
            print("1) PRD içinde tamamlanmamış görev bulunmadı.")
        return False

    current_task_line = prd_todos[0]
    task_text = current_task_line.split("] ", 1)[1]
    print(f"1) PRD görevi ele alındı: {safe_display(task_text)}")

    handler = resolve_handler(task_text)
    print("2) Görev için tanımlanan plan/handler çalıştırılıyor...")
    handler_success = handler(task_text)
    if not handler_success:
        print("   - Handler başarısız oldu, script durduruluyor.")
        append_log(f"Görev handler hatası nedeniyle durdu: {task_text}")
        return False

    updated_prd = mark_task(prd_content, current_task_line)
    write_file(PRD_PATH, updated_prd)
    print("3) PRD üzerindeki görev [x] olarak işaretlendi.")

    workflow_content = read_file(REPORT_PATH)
    updated_workflow, found = mark_task_by_text(workflow_content, task_text)
    if found:
        write_file(REPORT_PATH, updated_workflow)
        print("4) Workflow raporundaki eş görev de [x] oldu.")
    else:
        print("4) Workflow raporunda eşleşen satır bulunamadı.")

    append_log(f"Görev tamamlandı: {task_text}")
    print("5) Yapılan işlemler kaydedildi.")

    print("6) Sonraki görev için script_runner döngüsü devam ediyor...")
    return True


def watch_log_and_trigger():
    try:
        last_seen = LOG_PATH.stat().st_mtime
    except FileNotFoundError:
        last_seen = 0.0

    print("İzleme modu aktif. `yapilan_islemler.md` güncellendiğinde görev listesi tekrar çalışacak.")
    while True:
        time.sleep(2)
        try:
            current = LOG_PATH.stat().st_mtime
        except FileNotFoundError:
            continue
        if current <= last_seen:
            continue
        last_seen = current
        if current <= LAST_LOG_WRITE_MTIME:
            continue
        print("Log dosyası güncellendi; görev listesi yeniden kontrol ediliyor.")
        while process_next_task():
            pass
        print("Aktif görev kalmadı; izleme moduna geri dönüldü.")


if __name__ == "__main__":
    main()
