"""
9. Yargı Paketi Güncellemelerini Müfredata Ekleme
17 kanunda yapılan değişiklikleri ilgili derslere ekler
"""
import firebase_admin
from firebase_admin import credentials, firestore
from pathlib import Path

BASE_DIR = Path(r'c:\Users\HP\Desktop\StajyerPro')
SERVICE_ACCOUNT_PATH = BASE_DIR / 'service-account.json'

if not firebase_admin._apps:
    cred = credentials.Certificate(str(SERVICE_ACCOUNT_PATH))
    firebase_admin.initialize_app(cred)

db = firestore.client()

# 9. Yargı Paketi (7499 sayılı Kanun - 12 Mart 2024)
# 17 kanunda değişiklik yapan kapsamlı düzenleme
# Her ders için yeni ana başlık ve alt konular

YARGI_PAKETI_9 = {
    "ceza_muhakemesi": {
        "root_name": "9. Yargı Paketi (CMK Değişiklikleri)",
        "order": 100,
        "children": [
            "Tutukluluk Süreleri (CMK m.102)",
            "Adli Kontrol Tedbirleri (CMK m.109)",
            "Arama ve Elkoyma Değişiklikleri",
            "Seri Muhakeme Usulü (CMK m.250)",
            "Basit Yargılama Usulü (CMK m.251-252)",
            "İstinaf ve Temyiz Süreleri",
            "Duruşmada Ses ve Görüntü Kaydı"
        ]
    },
    "ceza_hukuku": {
        "root_name": "9. Yargı Paketi (TCK ve İnfaz Değişiklikleri)",
        "order": 100,
        "children": [
            "Koşullu Salıverilme Oranları (5275 s.K.)",
            "Denetimli Serbestlik Süreleri",
            "Açık Ceza İnfaz Kurumuna Ayrılma",
            "Kapalı Görüş ve Telefon Hakkı",
            "Hükümlülerin Nakil İşlemleri"
        ]
    },
    "icra_iflas": {
        "root_name": "9. Yargı Paketi (İİK Değişiklikleri)",
        "order": 100,
        "children": [
            "Sürelerin Hesaplanması (İİK m.19)",
            "Konkordato Mühlet Kararı (İİK m.289)",
            "Konkordato Tasdik Şartları (İİK m.305)",
            "İflas Erteleme Kaldırılması",
            "Elektronik Ortamda Satış"
        ]
    },
    "idari_yargilama": {
        "root_name": "9. Yargı Paketi (İYUK Değişiklikleri)",
        "order": 100,
        "children": [
            "İvedi Yargılama Usulü (İYUK m.20/A)",
            "Yürütmenin Durdurulması (İYUK m.27)",
            "Temyiz Sınırı Değişikliği"
        ]
    },
    "avukatlik_hukuku": {
        "root_name": "9. Yargı Paketi (Avukatlık Kanunu Değişiklikleri)",
        "order": 100,
        "children": [
            "Avukat-Müvekkil Görüşmesi (m.59)",
            "Tutuklu ile Görüşme Hakkı",
            "Staj Döneminde Duruşmaya Katılım"
        ]
    },
    "ticaret_hukuku": {
        "root_name": "9. Yargı Paketi (TTK Değişiklikleri)",
        "order": 100,
        "children": [
            "Elektronik Genel Kurul",
            "Şirketlerde Uzaktan Toplantı"
        ]
    },
    "medeni_hukuk": {
        "root_name": "9. Yargı Paketi (TMK Değişiklikleri)",
        "order": 100,
        "children": [
            "Kayyım Atanması Değişiklikleri",
            "Vesayet Makamı Kararları"
        ]
    }
}


def add_yargi_paketi_topics():
    """Add 9th Judicial Package topics to relevant subjects"""
    print("9. Yargı Paketi konuları ekleniyor...")
    
    total_added = 0
    
    for subj_id, data in YARGI_PAKETI_9.items():
        # Check if subject exists
        subj_ref = db.collection('subjects').document(subj_id)
        subj_doc = subj_ref.get()
        
        if not subj_doc.exists:
            print(f"  ⚠ {subj_id} bulunamadı, atlanıyor...")
            continue
        
        subj_name = subj_doc.to_dict().get('name', subj_id)
        
        # Create root topic (ana başlık)
        root_ref = db.collection('topics').document()
        root_ref.set({
            'name': data['root_name'],
            'subjectId': subj_id,
            'parentId': None,
            'order': data['order'],
            'isActive': True,
            'createdAt': firestore.SERVER_TIMESTAMP,
            'updatedAt': firestore.SERVER_TIMESTAMP
        })
        
        # Create child topics (alt konular)
        for i, child_name in enumerate(data['children'], 1):
            child_ref = db.collection('topics').document()
            child_ref.set({
                'name': child_name,
                'subjectId': subj_id,
                'parentId': root_ref.id,
                'order': i,
                'isActive': True,
                'createdAt': firestore.SERVER_TIMESTAMP,
                'updatedAt': firestore.SERVER_TIMESTAMP
            })
        
        child_count = len(data['children'])
        total_added += 1 + child_count
        print(f"  ✓ {subj_name}: +1 başlık, +{child_count} alt konu")
    
    print(f"\n✅ Toplam {total_added} yeni konu eklendi (9. Yargı Paketi)")
    return total_added


def main():
    print("=" * 60)
    print("9. YARGI PAKETİ KONU EKLEMESİ")
    print("=" * 60)
    
    added = add_yargi_paketi_topics()
    
    # Count total topics now
    topics = list(db.collection('topics').stream())
    
    print("\n" + "=" * 60)
    print(f"✅ 9. Yargı Paketi müfredata eklendi!")
    print(f"   - 5 derse yeni başlık eklendi")
    print(f"   - {added} yeni konu")
    print(f"   - Toplam konu sayısı: {len(topics)}")
    print("=" * 60)


if __name__ == '__main__':
    main()
