{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "title": "StajyerProQuestion",
  "description": "HMGS sınavı için soru şeması. topic_path müfredattaki konu adlarıyla eşleşmeli.",
  "type": "object",
  "required": [
    "id",
    "subject_code",
    "topic_path",
    "difficulty",
    "stem",
    "options",
    "correct_option",
    "static_explanation"
  ],
  "properties": {
    "id": {
      "type": "string",
      "description": "Benzersiz soru ID'si. Format: DERSKODU-001",
      "examples": ["MEDENI-001", "CEZA-042", "ANAYASA-015"]
    },
    "subject_code": {
      "type": "string",
      "description": "Ders kodu - import sırasında Firestore subject ID'sine dönüştürülür",
      "enum": [
        "CIVIL", "MEDENI",
        "OBLIGATIONS", "BORCLAR",
        "CRIMINAL", "CEZA", "TCK",
        "CRIM_PROC", "CMK",
        "COMMERCIAL", "TTK",
        "ADMIN", "IDARE",
        "IYUK",
        "CONSTITUTION", "ANAYASA",
        "HMK",
        "ICRA", "IIK",
        "VERGI", "TAX",
        "IS", "LABOR",
        "ATTORNEY", "AVUKATLIK",
        "FELSEFE", "PHILOSOPHY",
        "INTERNATIONAL",
        "MOHUK"
      ]
    },
    "topic_path": {
      "type": "array",
      "minItems": 1,
      "maxItems": 2,
      "items": { "type": "string" },
      "description": "Konu yolu: [Ana Grup, Alt Konu]. Müfredattaki konu adlarıyla BİREBİR eşleşmeli!",
      "examples": [
        ["Suçun Genel Teorisi", "Teşebbüs"],
        ["Aile Hukuku", "Boşanma"],
        ["Soruşturma", "Tutuklama"],
        ["Temel Hak ve Özgürlükler"]
      ]
    },
    "difficulty": {
      "type": "integer",
      "minimum": 1,
      "maximum": 3,
      "description": "Zorluk: 1=Kolay, 2=Orta, 3=Zor"
    },
    "exam_weight_tag": {
      "type": "string",
      "enum": ["core", "supporting", "longtail"],
      "default": "core",
      "description": "core=Sınavda sık çıkar, supporting=Ara sıra, longtail=Nadir"
    },
    "target_roles": {
      "type": "array",
      "items": {
        "type": "string",
        "enum": ["avukat", "hakim", "savci", "noter", "genel"]
      },
      "default": ["genel"],
      "description": "Hangi meslek grubu için önemli"
    },
    "stem": {
      "type": "string",
      "minLength": 20,
      "description": "Soru metni - en az 20 karakter olmalı"
    },
    "options": {
      "type": "array",
      "minItems": 4,
      "maxItems": 5,
      "items": {
        "type": "object",
        "required": ["label", "text"],
        "properties": {
          "label": {
            "type": "string",
            "enum": ["A", "B", "C", "D", "E"]
          },
          "text": {
            "type": "string",
            "minLength": 1,
            "description": "Şık metni - boş olamaz"
          }
        }
      },
      "description": "4-5 şık (A, B, C, D, E)"
    },
    "correct_option": {
      "type": "string",
      "enum": ["A", "B", "C", "D", "E"],
      "description": "Doğru cevabın harfi"
    },
    "static_explanation": {
      "type": "string",
      "minLength": 20,
      "description": "Doğru cevabın açıklaması - öğretici olmalı"
    },
    "ai_hint": {
      "type": "string",
      "description": "Öğrenciye kısa ipucu (ezber tekniği, dikkat noktası)"
    },
    "related_statute": {
      "type": "string",
      "description": "İlgili kanun maddesi. Örnek: TMK m.12, TCK m.35",
      "examples": ["TMK m.12", "TCK m.35/1", "CMK m.100", "AY m.125/5"]
    },
    "learning_objective": {
      "type": "string",
      "description": "Bu soruyla kazanılacak öğrenme hedefi"
    },
    "source_pdf": {
      "type": "string",
      "description": "Kaynak PDF dosya adı (opsiyonel)"
    },
    "source_page": {
      "type": "integer",
      "minimum": 1,
      "description": "Kaynak sayfa numarası (opsiyonel)"
    },
    "tags": {
      "type": "array",
      "items": { "type": "string" },
      "description": "Arama için etiketler",
      "examples": [["teşebbüs", "eksik kalkışma", "gönüllü vazgeçme"]]
    },
    "created_at": {
      "type": "string",
      "format": "date-time",
      "description": "Oluşturulma tarihi ISO 8601 formatında"
    },
    "status": {
      "type": "string",
      "enum": ["draft", "approved"],
      "default": "draft",
      "description": "draft=Taslak, approved=Onaylandı"
    }
  },
  "examples": [
    {
      "id": "CEZA-001",
      "subject_code": "CEZA",
      "topic_path": ["Suçun Özel Görünüş Şekilleri", "Teşebbüs"],
      "difficulty": 2,
      "exam_weight_tag": "core",
      "target_roles": ["avukat", "hakim"],
      "stem": "TCK'ya göre, failin elinde olmayan nedenlerle icra hareketlerini tamamlayamaması halinde aşağıdakilerden hangisi söz konusu olur?",
      "options": [
        {"label": "A", "text": "Tam teşebbüs"},
        {"label": "B", "text": "Eksik teşebbüs"},
        {"label": "C", "text": "İşlenemez suç"},
        {"label": "D", "text": "Gönüllü vazgeçme"},
        {"label": "E", "text": "Etkin pişmanlık"}
      ],
      "correct_option": "B",
      "static_explanation": "İcra hareketlerinin tamamlanamaması 'eksik teşebbüs' olarak adlandırılır. TCK m.35'e göre teşebbüs, suçun icrasına elverişli hareketlerle doğrudan doğruya başlanıp da elde olmayan nedenlerle tamamlanamamasıdır.",
      "ai_hint": "Teşebbüste fail icra hareketlerini tamamlayamadıysa EKSİK, tamamladıysa ama netice gerçekleşmediyse TAM teşebbüs.",
      "related_statute": "TCK m.35",
      "learning_objective": "Eksik ve tam teşebbüs ayrımını yapabilmek",
      "tags": ["teşebbüs", "eksik teşebbüs", "icra hareketleri"],
      "status": "approved"
    },
    {
      "id": "MEDENI-015",
      "subject_code": "MEDENI",
      "topic_path": ["Aile Hukuku", "Boşanma"],
      "difficulty": 1,
      "exam_weight_tag": "core",
      "target_roles": ["genel"],
      "stem": "TMK'ya göre evlilik birliğinin temelinden sarsılması nedeniyle açılan boşanma davasında, davacının kusuru daha ağır ise davalı ne yapabilir?",
      "options": [
        {"label": "A", "text": "Davayı kabul etmek zorundadır"},
        {"label": "B", "text": "Davaya itiraz edebilir"},
        {"label": "C", "text": "Karşı dava açmak zorundadır"},
        {"label": "D", "text": "Mahkemeye itiraz edemez"},
        {"label": "E", "text": "Dava reddedilir"}
      ],
      "correct_option": "B",
      "static_explanation": "TMK m.166/2'ye göre, davacının kusuru daha ağır ise, davalının davaya itiraz hakkı vardır. İtiraz hakkının kötüye kullanılması ve evlilik birliğinin devamında korunmaya değer bir yarar kalmaması halinde boşanmaya karar verilebilir.",
      "ai_hint": "Ağır kusurlu eş boşanma davası açabilir ama karşı tarafın İTİRAZ HAKKI var!",
      "related_statute": "TMK m.166/2",
      "learning_objective": "Evlilik birliğinin temelinden sarsılmasında kusur değerlendirmesini anlayabilmek",
      "tags": ["boşanma", "kusur", "itiraz hakkı"],
      "status": "approved"
    }
  ]
}
