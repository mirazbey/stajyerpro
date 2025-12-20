# NotebookLLM Prompt & Şablon Örneği
## 1. Örnek Prompt Metni

Aşağıdaki prompt, `TC Anayasası.pdf`, `Anayasa Hukukunun Temel Esasları - Kemal Gözler.pdf` ve `genel kamu hukuku ders notları.pdf` dosyalarıyla 10 soru üretmek için hazırlanmıştır. Farklı dersler için yalnızca kaynak listesini ve konu kapsamını gerektiği gibi değiştir.

```
You are an HMGS question-writer bot. Use ONLY the attached PDFs (TC Anayasası.pdf, Anayasa Hukukunun Temel Esasları - Kemal Gözler.pdf, genel kamu hukuku ders notları.pdf) plus the instructions below to create EXACTLY 10 Turkish multiple-choice questions.

Formatting rules:
1. Follow the [QUESTION] block template shown later in this prompt. Write each field on a single line (`SubjectCode: ...` etc.).
2. After the 10 blocks, output a JSON array that matches the provided schema exactly. Use the same data from the blocks.
3. Cite PDF name + page in both `SourceReference` (block) and `source_pdf`/`source_page` (JSON). Use at least two different PDFs across the set.
4. `topic_path` must be an array like `["Genel Esaslar","Cumhuriyetin Nitelikleri"]`. `target_roles` must be an array using these exact lowercase values: `avukat`, `hakim`, `savci`, `noter`.
5. JSON property names must match the schema: `id`, `subject_code`, `topic_path`, `difficulty`, `exam_weight_tag`, `target_roles`, `stem`, `options`, `correct_option`, `static_explanation`, `ai_hint`, `related_statute`, `learning_objective`, `source_pdf`, `source_page`, `created_at`, `status`.
6. `options` must be an array of objects `{ "label": "A", "text": "..." }`. `status` must be `"draft"` or `"approved"`.
7. Use ISO 8601 timestamps for `created_at` (e.g. `2024-05-01T10:00:00Z`).

Include the template and schema snippets below directly inside the prompt when sending to NotebookLLM.
```

---

## 2. [QUESTION] Blok Şablonu

```
[QUESTION]
SubjectCode: <code>
TopicPath: <Ana > Alt > Mikro>
Difficulty: <1|2|3>
ExamWeightTag: <core|supporting|longtail>
TargetRoles: <avukat|hakim|savci|noter, virgülle ayr>
SourceReference: <pdf_adı, s.xx>
Stem: <Soru metni>
Options:
A) <Şık>
B) <Şık>
C) <Şık>
D) <Şık>
E) <Şık>
CorrectOption: <A|B|C|D|E>
StaticExplanation: <Kısa açıklama>
AIHint: <AI koça ipucu>
RelatedStatute: <Kanun + madde>
LearningObjective: <Öğrenme amacı>
```

Her soru için bu bloğu doldur.

---

## 3. JSON Şema Parçası (Promptta Gösterilecek Versiyon)

```
Example JSON object:
{
  "id": "uuid-1234",
  "subject_code": "CONSTITUTION",
  "topic_path": ["Genel Esaslar","Cumhuriyetin Nitelikleri"],
  "difficulty": 2,
  "exam_weight_tag": "core",
  "target_roles": ["hakim"],
  "stem": "Türkiye Cumhuriyeti Anayasası'nın 2. maddesinde yer alan ...?",
  "options": [
    {"label": "A", "text": "Demokratik"},
    {"label": "B", "text": "Laik"},
    {"label": "C", "text": "Sosyal"},
    {"label": "D", "text": "Federal"}
  ],
  "correct_option": "D",
  "static_explanation": "Madde 2'de federal devlet sayılmaz.",
  "ai_hint": "Madde 2'de sayılan nitelikler...",
  "related_statute": "Anayasa m.2",
  "learning_objective": "Cumhuriyetin niteliklerini hatırlama",
  "source_pdf": "TC Anayasası.pdf",
  "source_page": 19,
  "created_at": "2024-05-01T10:00:00Z",
  "status": "approved"
}
```

NotebookLLM’e “JSON çıktısını bu yapıya sadık kalarak üret” demen yeterli. Bu dosyayı güncelleyerek her ders için uyarlayabilirsin.
