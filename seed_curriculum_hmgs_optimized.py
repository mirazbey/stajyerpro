"""
HMGS Optimized Müfredat - Final Version
15 ders, ~230 alt konu
Daha sade ve HMGS sınavına uygun yapı
"""
import firebase_admin
from firebase_admin import credentials, firestore
from datetime import datetime
from pathlib import Path

BASE_DIR = Path(r'c:\Users\HP\Desktop\StajyerPro')
SERVICE_ACCOUNT_PATH = BASE_DIR / 'service-account.json'

if not firebase_admin._apps:
    cred = credentials.Certificate(str(SERVICE_ACCOUNT_PATH))
    firebase_admin.initialize_app(cred)

db = firestore.client()

# HMGS Optimized Curriculum - 15 ders, ~230 konu
HMGS_CURRICULUM = {
    "anayasa_hukuku": {
        "name": "Anayasa Hukuku",
        "order": 1,
        "topics": {
            "Anayasa Hukukuna Giriş": [
                "Anayasa Kavramı",
                "Devletin Unsurları",
                "Hükümet Sistemleri",
                "Egemenlik",
                "Kuvvetler Ayrılığı"
            ],
            "Temel Hak ve Özgürlükler": [
                "Temel Hakların Niteliği",
                "Sınırlandırma Rejimi",
                "Kişi Hakları",
                "Sosyal ve Ekonomik Haklar",
                "Siyasi Haklar"
            ],
            "Yasama": [
                "TBMM'nin Görevleri",
                "Milletvekilliği",
                "Kanun Yapım Süreci",
                "Denetim Yolları"
            ],
            "Yürütme": [
                "Cumhurbaşkanı'nın Görevleri",
                "Cumhurbaşkanlığı Kararnameleri",
                "Bakanlar",
                "Olağanüstü Hal"
            ],
            "Yargı": [
                "Hakimler ve Savcılar Kurulu",
                "Yargı Bağımsızlığı",
                "Anayasa Mahkemesi Görevleri",
                "İptal Davası ve İtiraz Yolu",
                "Bireysel Başvuru"
            ]
        }
    },
    "medeni_hukuk": {
        "name": "Medeni Hukuk",
        "order": 2,
        "topics": {
            "Başlangıç Hükümleri": [
                "Hukukun Uygulanması",
                "İyiniyet ve Dürüstlük Kuralı",
                "İspat Yükü"
            ],
            "Kişiler Hukuku": [
                "Gerçek Kişiler",
                "Kişiliğin Başlangıcı ve Sonu",
                "Hak ve Fiil Ehliyeti",
                "Kısıtlılık ve Vesayet",
                "Kişiliğin Korunması"
            ],
            "Tüzel Kişiler": [
                "Tüzel Kişi Kavramı",
                "Dernekler",
                "Vakıflar"
            ],
            "Aile Hukuku": [
                "Nişanlanma",
                "Evlenme",
                "Boşanma",
                "Mal Rejimleri",
                "Soybağı",
                "Velayet",
                "Nafaka"
            ],
            "Miras Hukuku": [
                "Yasal Mirasçılar",
                "Saklı Pay",
                "Ölüme Bağlı Tasarruflar",
                "Mirasın Geçişi"
            ],
            "Eşya Hukuku": [
                "Zilyetlik",
                "Tapu Sicili",
                "Mülkiyet",
                "Sınırlı Ayni Haklar",
                "Rehin ve İpotek"
            ]
        }
    },
    "borclar_hukuku": {
        "name": "Borçlar Hukuku",
        "order": 3,
        "topics": {
            "Borç İlişkisinin Kaynakları": [
                "Sözleşmeden Doğan Borçlar",
                "Sözleşmenin Kurulması",
                "Geçersizlik Halleri",
                "Temsil"
            ],
            "Haksız Fiil": [
                "Haksız Fiil Şartları",
                "Kusur Sorumluluğu",
                "Kusursuz Sorumluluk",
                "Tazminat"
            ],
            "Sebepsiz Zenginleşme": [
                "Sebepsiz Zenginleşme Şartları",
                "İade Borcu"
            ],
            "Borcun İfası ve Sona Ermesi": [
                "İfa",
                "Borçlu Temerrüdü",
                "Alacaklı Temerrüdü",
                "Zamanaşımı"
            ],
            "Özel Borç İlişkileri": [
                "Satış Sözleşmesi",
                "Kira Sözleşmesi",
                "Eser Sözleşmesi",
                "Vekalet Sözleşmesi",
                "Hizmet Sözleşmesi",
                "Kefalet Sözleşmesi"
            ]
        }
    },
    "ticaret_hukuku": {
        "name": "Ticaret Hukuku",
        "order": 4,
        "topics": {
            "Ticari İşletme": [
                "Ticari İşletme Kavramı",
                "Tacir",
                "Ticaret Unvanı",
                "Ticaret Sicili",
                "Haksız Rekabet"
            ],
            "Şirketler Hukuku": [
                "Şirket Kavramı",
                "Adi Şirket",
                "Kollektif ve Komandit Şirket",
                "Anonim Şirket Organları",
                "Limited Şirket"
            ],
            "Kıymetli Evrak": [
                "Kıymetli Evrak Temel Hükümler",
                "Poliçe",
                "Bono",
                "Çek"
            ]
        }
    },
    "ceza_hukuku": {
        "name": "Ceza Hukuku",
        "order": 5,
        "topics": {
            "Ceza Hukukuna Giriş": [
                "Ceza Hukukunun Temel İlkeleri",
                "Suçta ve Cezada Kanunilik",
                "Ceza Kanunlarının Uygulanması"
            ],
            "Suçun Genel Teorisi": [
                "Maddi Unsur",
                "Manevi Unsur",
                "Hukuka Aykırılık",
                "Kusur"
            ],
            "Suçun Özel Görünüş Şekilleri": [
                "Teşebbüs",
                "İştirak",
                "İçtima"
            ],
            "Yaptırımlar": [
                "Cezalar",
                "Güvenlik Tedbirleri"
            ],
            "Özel Suçlar": [
                "Hayata Karşı Suçlar",
                "Vücut Dokunulmazlığına Karşı Suçlar",
                "Malvarlığına Karşı Suçlar",
                "Kamu İdaresine Karşı Suçlar"
            ]
        }
    },
    "ceza_muhakemesi": {
        "name": "Ceza Muhakemesi Hukuku",
        "order": 6,
        "topics": {
            "Ceza Muhakemesine Giriş": [
                "CMK Temel İlkeleri",
                "Yetki Kuralları"
            ],
            "Soruşturma": [
                "Soruşturma Aşaması",
                "Gözaltı",
                "Tutuklama",
                "Adli Kontrol"
            ],
            "Deliller": [
                "Arama ve Elkoyma",
                "İletişimin Denetlenmesi",
                "Delil Değerlendirmesi"
            ],
            "Kovuşturma": [
                "İddianame",
                "Duruşma",
                "Hüküm"
            ],
            "Kanun Yolları": [
                "İtiraz",
                "İstinaf",
                "Temyiz"
            ]
        }
    },
    "idare_hukuku": {
        "name": "İdare Hukuku",
        "order": 7,
        "topics": {
            "İdarenin Kuruluşu": [
                "Merkezi İdare",
                "Yerinden Yönetim",
                "Kamu Tüzel Kişileri"
            ],
            "İdari İşlemler": [
                "Düzenleyici İşlemler",
                "Bireysel İşlemler",
                "İdari İşlemin Unsurları"
            ],
            "Kamu Görevlileri": [
                "Memur Kavramı",
                "Memurun Hakları",
                "Memurun Yükümlülükleri",
                "Disiplin"
            ],
            "Kolluk": [
                "Kolluk Kavramı",
                "Kolluk Yetkileri"
            ],
            "Kamu Malları": [
                "Kamu Malı Kavramı",
                "Kamulaştırma"
            ],
            "İdarenin Sorumluluğu": [
                "Hizmet Kusuru",
                "Kusursuz Sorumluluk"
            ]
        }
    },
    "idari_yargilama": {
        "name": "İdari Yargılama Usulü (İYUK)",
        "order": 8,
        "topics": {
            "Dava Türleri": [
                "İptal Davası",
                "Tam Yargı Davası"
            ],
            "Dava Şartları": [
                "Ehliyet",
                "Hak Düşürücü Süreler",
                "İdari Merci Tecavüzü"
            ],
            "Yargılama": [
                "Yürütmenin Durdurulması",
                "Yargılama Aşamaları",
                "Karar"
            ],
            "Kanun Yolları": [
                "İstinaf",
                "Temyiz"
            ]
        }
    },
    "vergi_hukuku": {
        "name": "Vergi Hukuku",
        "order": 9,
        "topics": {
            "Vergi Hukuku Genel": [
                "Vergi Kanunlarının Uygulanması",
                "Mükellefiyet",
                "Vergi Sorumluluğu"
            ],
            "Vergilendirme Süreci": [
                "Tarh",
                "Tebliğ",
                "Tahakkuk",
                "Tahsil"
            ],
            "Vergi Borcunun Sona Ermesi": [
                "Ödeme",
                "Zamanaşımı",
                "Terkin"
            ],
            "Vergi Suç ve Cezaları": [
                "Vergi Kabahatleri",
                "Vergi Suçları"
            ],
            "Vergi Uyuşmazlıkları": [
                "Uzlaşma",
                "Vergi Davaları"
            ]
        }
    },
    "icra_iflas": {
        "name": "İcra ve İflas Hukuku",
        "order": 10,
        "topics": {
            "İcra Takip Yolları": [
                "İlamsız Takip",
                "İlamlı Takip",
                "Kambiyo Senetlerine Özgü Takip",
                "Kiralanan Taşınmazların Tahliyesi"
            ],
            "Haciz": [
                "Haciz İşlemi",
                "Haczi Caiz Olmayan Mallar",
                "İstihkak"
            ],
            "Rehnin Paraya Çevrilmesi": [
                "Taşınır Rehni",
                "Taşınmaz Rehni"
            ],
            "İflas": [
                "İflas Sebepleri",
                "İflas Tasfiyesi"
            ],
            "Konkordato": [
                "Konkordato Şartları",
                "Konkordato Süreci"
            ]
        }
    },
    "is_hukuku": {
        "name": "İş Hukuku ve Sosyal Güvenlik",
        "order": 11,
        "topics": {
            "Bireysel İş Hukuku": [
                "İş Sözleşmesi Türleri",
                "Ücret",
                "Çalışma Süreleri"
            ],
            "Fesih": [
                "Bildirimli Fesih",
                "Haklı Nedenle Fesih",
                "İş Güvencesi"
            ],
            "Tazminatlar": [
                "Kıdem Tazminatı",
                "İhbar Tazminatı"
            ],
            "Sosyal Güvenlik": [
                "Sosyal Sigortalar",
                "Emeklilik"
            ],
            "Toplu İş Hukuku": [
                "Sendika",
                "Toplu İş Sözleşmesi",
                "Grev"
            ]
        }
    },
    "avukatlik_hukuku": {
        "name": "Avukatlık Hukuku",
        "order": 12,
        "topics": {
            "Avukatlık Mesleğine Giriş": [
                "Avukatlığa Kabul Şartları",
                "Staj Şartları",
                "Staj Süreci"
            ],
            "Avukatın Hak ve Yükümlülükleri": [
                "Avukatın Hakları",
                "Avukatın Yükümlülükleri",
                "Avukatlık Sözleşmesi",
                "Avukatlık Ücreti"
            ],
            "Baro ve Disiplin": [
                "Baro Teşkilatı",
                "Türkiye Barolar Birliği",
                "Disiplin İşlemleri"
            ]
        }
    },
    "hukuk_felsefesi": {
        "name": "Hukuk Felsefesi ve Sosyolojisi",
        "order": 13,
        "topics": {
            "Hukuk Felsefesi": [
                "Doğal Hukuk",
                "Hukuki Pozitivizm"
            ],
            "Hukuk Sosyolojisi": [
                "Hukuk ve Toplum İlişkisi",
                "Hukukun İşlevleri"
            ]
        }
    },
    "milletlerarasi_hukuk": {
        "name": "Milletlerarası Hukuk",
        "order": 14,
        "topics": {
            "Devletler Genel Hukuku": [
                "Uluslararası Hukuk Kaynakları",
                "Devlet ve Tanıma",
                "Uluslararası Örgütler",
                "Temel Anlaşmalar"
            ]
        }
    },
    "mohuk": {
        "name": "Milletlerarası Özel Hukuk (MÖHUK)",
        "order": 15,
        "topics": {
            "MÖHUK Genel": [
                "Kanunlar İhtilafı",
                "Uygulanacak Hukuk",
                "Yabancılar Hukuku",
                "Milletlerarası Usul Hukuku"
            ]
        }
    }
}


def delete_all_topics():
    """Delete all existing topics"""
    print("Mevcut konular siliniyor...")
    topics = list(db.collection('topics').stream())
    count = 0
    batch = db.batch()
    batch_count = 0
    for topic in topics:
        batch.delete(topic.reference)
        count += 1
        batch_count += 1
        if batch_count >= 100:
            batch.commit()
            batch = db.batch()
            batch_count = 0
    if batch_count > 0:
        batch.commit()
    print(f"  ✓ {count} konu silindi")
    return count


def update_subjects():
    """Update subjects to match new curriculum"""
    print("\nDersler güncelleniyor...")
    
    # First deactivate all subjects
    subjects = db.collection('subjects').stream()
    for subj in subjects:
        subj.reference.update({'isActive': False})
    
    # Create/update subjects from curriculum
    for subj_id, subj_data in HMGS_CURRICULUM.items():
        doc_ref = db.collection('subjects').document(subj_id)
        doc_ref.set({
            'name': subj_data['name'],
            'order': subj_data['order'],
            'isActive': True,
            'createdAt': firestore.SERVER_TIMESTAMP,
            'updatedAt': firestore.SERVER_TIMESTAMP
        }, merge=True)
        print(f"  ✓ {subj_data['name']}")
    
    print(f"  Toplam: {len(HMGS_CURRICULUM)} ders aktif")


def create_topics():
    """Create hierarchical topics"""
    print("\nKonular oluşturuluyor...")
    
    total_root = 0
    total_child = 0
    
    for subj_id, subj_data in HMGS_CURRICULUM.items():
        subj_root = 0
        subj_child = 0
        
        root_order = 0
        for root_name, children in subj_data['topics'].items():
            root_order += 1
            
            # Create root topic
            root_ref = db.collection('topics').document()
            root_ref.set({
                'name': root_name,
                'subjectId': subj_id,
                'parentId': None,
                'order': root_order,
                'isActive': True,
                'createdAt': firestore.SERVER_TIMESTAMP,
                'updatedAt': firestore.SERVER_TIMESTAMP
            })
            subj_root += 1
            
            # Create child topics
            child_order = 0
            for child_name in children:
                child_order += 1
                child_ref = db.collection('topics').document()
                child_ref.set({
                    'name': child_name,
                    'subjectId': subj_id,
                    'parentId': root_ref.id,
                    'order': child_order,
                    'isActive': True,
                    'createdAt': firestore.SERVER_TIMESTAMP,
                    'updatedAt': firestore.SERVER_TIMESTAMP
                })
                subj_child += 1
        
        print(f"  {subj_data['name']}: {subj_root} başlık, {subj_child} alt konu")
        total_root += subj_root
        total_child += subj_child
    
    print(f"\n✅ Toplam: {total_root} ana başlık + {total_child} alt konu = {total_root + total_child} konu")
    return total_root, total_child


def main():
    print("=" * 60)
    print("HMGS OPTİMİZE MÜFREDAT YÜKLEME")
    print("15 Ders - ~230 Konu")
    print("=" * 60)
    
    # Delete existing topics
    delete_all_topics()
    
    # Update subjects
    update_subjects()
    
    # Create new topics
    root, child = create_topics()
    
    print("\n" + "=" * 60)
    print("✅ HMGS müfredatı başarıyla yüklendi!")
    print(f"   - 15 ders")
    print(f"   - {root} ana başlık")
    print(f"   - {child} alt konu")
    print(f"   - Toplam: {root + child} konu")
    print("=" * 60)


if __name__ == '__main__':
    main()
