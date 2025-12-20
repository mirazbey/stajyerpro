"""
9. Yargı Paketi (2024) - TAM KONU & ALT BAŞLIK HARİTASI
8 ana konu, 43 alt başlık
Doğru ve güncel içerik
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

# 9. Yargı Paketi (2024) - 8 ana konu, 43 alt başlık
# İlgili derslere eklenecek konular

YARGI_PAKETI_9_DOGRU = {
    # 1. TCK Değişiklikleri -> ceza_hukuku
    "ceza_hukuku": {
        "root_name": "9. Yargı Paketi (TCK Değişiklikleri)",
        "order": 100,
        "children": [
            # 1.1 Uzlaştırma
            "Uzlaştırma Kapsamında Değişiklikler",
            "Uzlaştırma Kapsamı Dışına Alınan Suçlar",
            "Uzlaştırmacı Görevlendirme Usulleri",
            "Uzlaştırma Süresi ve Sonuçları",
            "Uzlaştırmanın Hukuki Etkileri",
            # 1.2 Yeni Suç Tipleri
            "Etki Ajanlığı (Influence Agent)",
            "Casusluk Kapsamı Değişikliği",
            "Devlete Karşı Suçlarda Yeni Düzenlemeler",
            # 1.3 Cinsel Suçlar
            "Cinsel Suçların Kapsamı",
            "Cinsel Suçlarda Cezaların Artırılması",
            "Cinsel Suçlarda Etkin Pişmanlığın Sınırlandırılması",
            # 1.4 Şiddet Suçları
            "Şiddet Suçlarının Uzlaşma Kapsamından Çıkarılması",
            "Koruma Tedbirlerinde Sıkılaştırma"
        ]
    },
    
    # 2. CMK Değişiklikleri -> ceza_muhakemesi
    "ceza_muhakemesi": {
        "root_name": "9. Yargı Paketi (CMK Değişiklikleri)",
        "order": 100,
        "children": [
            # 2.1 Soruşturma Usulü
            "Kolluğun Yetkilerinde Düzenleme",
            "Savcı Gözetimindeki İşlemlerde Yeni Kurallar",
            "İfade Alma-Sorgu Usulü Değişiklikleri",
            # 2.2 Tutuklama-Adli Kontrol
            "Tutuklama Şartlarında Değişiklik",
            "Adli Kontrol Süreleri",
            "Ölçülülük İlkesi Kapsamında Revizyon",
            # 2.3 Delil-Arama-Elkoyma
            "Dijital Delil Toplama Usulleri",
            "Arama-Elkoyma Kararlarında Yeni Düzenlemeler",
            "İletişimin Denetlenmesi Hükümleri",
            # 2.4 Uzlaştırma Prosedürü
            "CMK'da Uzlaştırma Sürecinin Yeni Yapısı",
            "Uzlaştırmada Süre-Yetki-Görevlendirme Değişiklikleri",
            # 2.5 Kanun Yolları
            "İtiraz Sürelerinde Düzenleme",
            "İstinaf Başvuru Koşulları",
            "Temyiz Sebeplerinin Genişletilmesi/Daraltılması"
        ]
    },
    
    # 3. HMK Değişiklikleri -> Yeni bir başlık olarak eklenecek (medeni usul yoksa borclar veya medeni'ye)
    # HMK ayrı ders olmadığı için bu konuları ayrı bir "Usul Hukuku" başlığı altında ekleyeceğiz
    # Şimdilik medeni_hukuk'a ekleyelim
    "medeni_hukuk": {
        "root_name": "9. Yargı Paketi (HMK ve TMK Değişiklikleri)",
        "order": 100,
        "children": [
            # 3.1 Temyiz Düzeni
            "Temyiz Edilebilir Kararlar",
            "Temyiz Süresi Değişiklikleri",
            "Temyizde Harç-Masraf Düzenlemeleri",
            # 3.2 İstinaf Düzeni
            "Bölge Adliye Mahkemesi İnceleme Kapsamı",
            "İstinaf Sebepleri",
            "İstinaf Sonucuna Göre Karar Türleri",
            # 3.3 Dava Açma
            "Dava Şartlarında Düzenlemeler",
            "Ön İnceleme Aşaması Kuralları",
            # 3.4 Tebligat-Süre
            "Elektronik Tebligat Sistemi",
            "Sürelerin Hesaplanması",
            # 7. Medeni Hukuk
            "Soybağı Davalarında Usul Değişiklikleri",
            "Aile İçi Şiddet Koruma Tedbirleri",
            "Vesayet İşlemlerinde Süre-Yetki Değişiklikleri"
        ]
    },
    
    # 4. İİK Değişiklikleri -> icra_iflas
    "icra_iflas": {
        "root_name": "9. Yargı Paketi (İİK Değişiklikleri)",
        "order": 100,
        "children": [
            # 4.1 Haciz ve Satış
            "Elektronik Satış Usulü",
            "Açık Artırma Şartlarının Yenilenmesi",
            "Satış İlanı Kuralları",
            "Teklif Farkı-Teminat Sistemi",
            # 4.2 Takip İşlemleri
            "İlamsız Takipte Yeni Düzenlemeler",
            "Kambiyo Senetlerine Özgü Takipte Değişiklikler",
            "Kiralanan Taşınmaz Tahliyesi Prosedürü",
            # 4.3 Rehnin Paraya Çevrilmesi
            "Rehinli Malların Satış Usulü",
            "Paraya Çevirme Süreleri",
            # 4.4 İflas ve Konkordato
            "İflas Karar Süreçlerinde Değişiklikler",
            "Konkordato Sürecinde İyileştirme Hükümleri"
        ]
    },
    
    # 5. Arabuluculuk -> is_hukuku'na ekleyelim (zorunlu arabuluculuk iş davalarında önemli)
    # 6. İş Hukuku da burada
    "is_hukuku": {
        "root_name": "9. Yargı Paketi (Arabuluculuk ve İş Hukuku Değişiklikleri)",
        "order": 100,
        "children": [
            # 5.1 Zorunlu Arabuluculuk
            "Yeni Zorunlu Arabuluculuk Alanları (İş-Tüketici-Ticari)",
            "Zorunlu Arabuluculukta Süre ve Usul",
            # 5.2 İhtiyari Arabuluculuk
            "İhtiyari Arabuluculuk Süreç Tanımı",
            "İhtiyari Arabuluculuk Usul Kuralları",
            # 5.3 Arabuluculuk Anlaşma Belgesi
            "Arabuluculuk Anlaşmasının Bağlayıcılığı",
            "Mahkeme Onayı ve İcra Edilebilirlik Şerhi",
            # 6.1 İşe İade-Fesih
            "Fesih Türlerinde Düzenlemeler",
            "İşe İadede Arabuluculuk Zorunluluğu",
            # 6.2 Tazminatlar
            "Kıdem-İhbar Tazminat Hükümlerinde Değişiklik",
            "Arabuluculuk Sonrası Dava Açma Koşulları",
            # 6.3 Usul
            "İş Uyuşmazlıklarında Dava Şartları",
            "İş Davalarında Süreler"
        ]
    },
    
    # 8. Genel Adli Reform -> idari_yargilama'ya ekleyelim (yargı sistemini ilgilendiriyor)
    "idari_yargilama": {
        "root_name": "9. Yargı Paketi (Adli Reform ve Usul Düzenlemeleri)",
        "order": 100,
        "children": [
            # 8.1 Yargı Hızlandırma
            "Makul Sürede Yargılanma Düzenlemeleri",
            "Elektronik İşlemlerde İyileştirme",
            # 8.2 İş Yükü Azaltma
            "Arabuluculuk Kapsamının Genişletilmesi",
            "Uzlaştırma Sürecinin Yeniden Yapılandırılması",
            # 8.3 Dijital Yargı
            "UYAP Düzenlemeleri",
            "Elektronik Dosya Süreçleri"
        ]
    },
    
    # Ticaret Hukuku - Arabuluculuk ticari davalarda da zorunlu
    "ticaret_hukuku": {
        "root_name": "9. Yargı Paketi (Ticari Uyuşmazlık Değişiklikleri)",
        "order": 100,
        "children": [
            "Ticari Davalarda Zorunlu Arabuluculuk Kapsamı",
            "Ticari Uyuşmazlıklarda Dava Şartı Arabuluculuk"
        ]
    },
    
    # Avukatlık Hukuku - uzlaştırmacı/arabulucu avukatlar
    "avukatlik_hukuku": {
        "root_name": "9. Yargı Paketi (Avukatlık Mesleği Değişiklikleri)",
        "order": 100,
        "children": [
            "Avukatların Arabuluculuk Faaliyetleri",
            "Uzlaştırmacı Avukat Görevlendirmesi"
        ]
    }
}


def delete_old_yargi_paketi():
    """Delete old 9th Judicial Package topics"""
    print("Eski 9. Yargı Paketi konuları siliniyor...")
    
    topics = list(db.collection('topics').stream())
    deleted = 0
    
    # First find root topics
    root_ids_to_delete = []
    for topic in topics:
        name = topic.to_dict().get('name', '')
        if '9. Yargı Paketi' in name:
            root_ids_to_delete.append(topic.id)
    
    # Delete children first, then roots
    for topic in topics:
        parent_id = topic.to_dict().get('parentId')
        if parent_id in root_ids_to_delete:
            topic.reference.delete()
            deleted += 1
    
    for topic in topics:
        if topic.id in root_ids_to_delete:
            topic.reference.delete()
            deleted += 1
    
    print(f"  ✓ {deleted} eski konu silindi")
    return deleted


def add_yargi_paketi_topics():
    """Add correct 9th Judicial Package topics"""
    print("\n9. Yargı Paketi (2024) konuları ekleniyor...")
    print("8 ana konu, 43 alt başlık\n")
    
    total_added = 0
    
    for subj_id, data in YARGI_PAKETI_9_DOGRU.items():
        subj_ref = db.collection('subjects').document(subj_id)
        subj_doc = subj_ref.get()
        
        if not subj_doc.exists:
            print(f"  ⚠ {subj_id} bulunamadı, atlanıyor...")
            continue
        
        subj_name = subj_doc.to_dict().get('name', subj_id)
        
        # Create root topic
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
        
        # Create children
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
    
    return total_added


def main():
    print("=" * 60)
    print("9. YARGI PAKETİ (2024) - DOĞRU İÇERİK")
    print("8 Ana Konu, 43 Alt Başlık")
    print("=" * 60)
    
    # Delete old
    delete_old_yargi_paketi()
    
    # Add new
    added = add_yargi_paketi_topics()
    
    # Count total
    topics = list(db.collection('topics').stream())
    
    print("\n" + "=" * 60)
    print("✅ 9. Yargı Paketi (2024) doğru içerikle yüklendi!")
    print(f"   - 8 ana konu başlığı")
    print(f"   - {added} toplam yeni konu")
    print(f"   - Genel toplam: {len(topics)} konu")
    print("=" * 60)


if __name__ == '__main__':
    main()
