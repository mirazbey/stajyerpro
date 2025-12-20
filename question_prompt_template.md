# NotebookLLM Soru Taslak Şablonu

Bu şablon, NotebookLLM’den HMGS kapsamındaki çoktan seçmeli soruları üretirken kullanılacak standart girdiyi tanımlar. Akış, `Workflow_UI_Report.md`de anlatıldığı gibi ders/konu seçiminin ardından soru çözümü → doğru/yanlış geri bildirimi → AI açıklamasını içerdiği için, her sorunun aşağıdaki alanları doldurması zorunludur.

## 1. Meta Bilgiler
- **Subject Code**: PRD’deki ders kodu (örn. `CONSTITUTION`, `CIVIL`, `CMK`).
- **Topic Path**: Ders → alt konu → mikro konu (örn. `Medeni Hukuk > Kişiler Hukuku > Fiil Ehliyeti`).
- **Difficulty**: `1` (kolay), `2` (orta), `3` (zor).
- **Exam Weight Tag**: HMGS dağılımındaki ağırlıkla ilişkili kısa etiket (örn. `core`, `supporting`).
- **Target Role Emphasis**: (opsiyonel) Avukatlık / Hakimlik / Savcılık / Noterlik odaklıysa belirt.
- **Source Reference**: PDF dosya adı + sayfa numarası (örn. `ceza hukuku genel hükümler ders notları.pdf, s.45`).

## 2. Soru Gövdesi Alanları
```
[QUESTION]
Stem: <Soru metnini yazın; mevzuat atıfı gerekiyorsa kısaca belirtin.>
Options:
A) <Şık A>
B) <Şık B>
C) <Şık C>
D) <Şık D>
E) <Şık E> (opsiyonel ancak HMGS genelde 5 şıklı)
CorrectOption: <A/B/C/D/E>
StaticExplanation: <Kısa, kanun maddesine dayanan açıklama.>
AIHint: <AI koçun detaylı açıklama üretirken vurgulaması gereken noktalar (madde numarası, tipik tuzak vb.).>
RelatedStatute: <Kanun adı ve madde (örn. TMK m.9).>
LearningObjective: <Bu soruyla ölçülen kavram/beceri.>
```

NotebookLLM’e bu blok verilirken, ilgili PDF veya ders notunun kısa özeti ve kontext cümleleri eklenmelidir.

## 3. Örnek Girdi
```
[QUESTION]
SubjectCode: CMK
TopicPath: Ceza Muhakemesi Kanunu > Koruma Tedbirleri > Tutuklama Şartları
Difficulty: 2
ExamWeightTag: core
TargetRoleEmphasis: Hakimlik
SourceReference: ceza muhakemesi kanunu.pdf, s.108
Stem: Tutuklama kararı verilebilmesi için aranan “kuvvetli suç şüphesi”nin yanı sıra aşağıdaki koşullardan hangisinin bulunması gerekir?
Options:
A) Soruşturmanın cumhuriyet savcısı tarafından yürütülmesi
B) Şüphelinin kaçması veya delilleri karartma tehlikesi
C) Suçun yalnızca katalog suçlardan biri olması
D) Şüphelinin müdafi yardımından feragat etmesi
CorrectOption: B
StaticExplanation: CMK m.100’e göre tutuklama kararı için kuvvetli suç şüphesi yanında kaçma, saklanma veya delilleri karartma tehlikesi gibi nedenlerin varlığı aranır.
AIHint: CMK m.100’deki ek şartlar; katalog suç şartı tek başına yeterli değildir.
RelatedStatute: CMK m.100
LearningObjective: Tutuklama kararının şartlarını ayırt edebilme
```

## 4. NotebookLLM Çıktısının JSON’a Aktarımı
NotebookLLM’den gelen her soru yukarıdaki alanlara sahip olmalıdır. Doğrulama sonrası `question_bank/<subject>.json` dosyasına aktarılır. Ayrıntılı JSON şeması için `question_schema.json` dosyasına bakınız.
