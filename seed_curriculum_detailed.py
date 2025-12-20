"""
HMGS Detaylı Müfredat - BÖLÜM 1 (8 Ders)
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

CURRICULUM_PART1 = {
    'anayasa_hukuku': {
        'name': 'Anayasa Hukuku',
        'order': 1,
        'topics': [
            {'id': 'ay_giris', 'name': 'Anayasa Hukukuna Giriş', 'order': 1},
            {'id': 'ay_kavrami', 'name': 'Anayasa Kavramı ve Türleri', 'order': 2},
            {'id': 'ay_yapim', 'name': 'Anayasa Yapımı ve Değiştirilmesi', 'order': 3},
            {'id': 'ay_devlet', 'name': 'Devlet Kavramı ve Unsurları', 'order': 4},
            {'id': 'ay_egemenlik', 'name': 'Egemenlik ve Kaynağı', 'order': 5},
            {'id': 'ay_hukumet', 'name': 'Hükümet Sistemleri', 'order': 6},
            {'id': 'ay_temel_haklar', 'name': 'Temel Hak ve Özgürlükler', 'order': 7},
            {'id': 'ay_sinirlandirma', 'name': 'Temel Hakların Sınırlandırılması', 'order': 8},
            {'id': 'ay_kisi_haklari', 'name': 'Kişi Hakları ve Ödevleri', 'order': 9},
            {'id': 'ay_sosyal_haklar', 'name': 'Sosyal ve Ekonomik Haklar', 'order': 10},
            {'id': 'ay_siyasi_haklar', 'name': 'Siyasi Haklar ve Ödevler', 'order': 11},
            {'id': 'ay_yasama', 'name': 'Yasama (TBMM)', 'order': 12},
            {'id': 'ay_milletvekilligi', 'name': 'Milletvekilliği', 'order': 13},
            {'id': 'ay_kanun_yapimi', 'name': 'Kanun Yapım Süreci', 'order': 14},
            {'id': 'ay_meclis_denetim', 'name': 'Meclis Denetimi', 'order': 15},
            {'id': 'ay_yurutme', 'name': 'Yürütme (Cumhurbaşkanlığı)', 'order': 16},
            {'id': 'ay_cbk', 'name': 'Cumhurbaşkanlığı Kararnamesi', 'order': 17},
            {'id': 'ay_ohal', 'name': 'Olağanüstü Hal Yönetimi', 'order': 18},
            {'id': 'ay_yargi', 'name': 'Yargı Organı', 'order': 19},
            {'id': 'ay_aym', 'name': 'Anayasa Mahkemesi', 'order': 20},
            {'id': 'ay_iptal', 'name': 'İptal Davası', 'order': 21},
            {'id': 'ay_itiraz', 'name': 'İtiraz Yolu', 'order': 22},
            {'id': 'ay_bireysel', 'name': 'Bireysel Başvuru', 'order': 23},
        ]
    },
    
    'medeni_hukuk': {
        'name': 'Medeni Hukuk',
        'order': 2,
        'topics': [
            {'id': 'mh_baslangic', 'name': 'Başlangıç Hükümleri', 'order': 1},
            {'id': 'mh_hukuk_uyg', 'name': 'Hukukun Uygulanması', 'order': 2},
            {'id': 'mh_iyiniyet', 'name': 'Dürüstlük Kuralı ve İyiniyet', 'order': 3},
            {'id': 'mh_ispat', 'name': 'İspat Yükü', 'order': 4},
            {'id': 'mh_gercek_kisi', 'name': 'Gerçek Kişiler', 'order': 5},
            {'id': 'mh_kisilik_baslangic', 'name': 'Kişiliğin Başlangıcı ve Sonu', 'order': 6},
            {'id': 'mh_hak_ehliyeti', 'name': 'Hak Ehliyeti', 'order': 7},
            {'id': 'mh_fiil_ehliyeti', 'name': 'Fiil Ehliyeti', 'order': 8},
            {'id': 'mh_kisitlilik', 'name': 'Kısıtlılık', 'order': 9},
            {'id': 'mh_vesayet', 'name': 'Vesayet', 'order': 10},
            {'id': 'mh_kisilik_koruma', 'name': 'Kişiliğin Korunması', 'order': 11},
            {'id': 'mh_ad', 'name': 'Ad', 'order': 12},
            {'id': 'mh_yerlesim', 'name': 'Yerleşim Yeri', 'order': 13},
            {'id': 'mh_tuzel_kisi', 'name': 'Tüzel Kişiler', 'order': 14},
            {'id': 'mh_dernekler', 'name': 'Dernekler', 'order': 15},
            {'id': 'mh_vakiflar', 'name': 'Vakıflar', 'order': 16},
            {'id': 'mh_nisanlanma', 'name': 'Nişanlanma', 'order': 17},
            {'id': 'mh_evlenme', 'name': 'Evlenme', 'order': 18},
            {'id': 'mh_evlenme_engel', 'name': 'Evlenme Engelleri', 'order': 19},
            {'id': 'mh_bosanma', 'name': 'Boşanma', 'order': 20},
            {'id': 'mh_bosanma_sebep', 'name': 'Boşanma Sebepleri', 'order': 21},
            {'id': 'mh_mal_rejimi', 'name': 'Mal Rejimleri', 'order': 22},
            {'id': 'mh_edinilmis_mal', 'name': 'Edinilmiş Mallara Katılma', 'order': 23},
            {'id': 'mh_soybagi', 'name': 'Soybağı', 'order': 24},
            {'id': 'mh_evlat_edinme', 'name': 'Evlat Edinme', 'order': 25},
            {'id': 'mh_velayet', 'name': 'Velayet', 'order': 26},
            {'id': 'mh_nafaka', 'name': 'Nafaka', 'order': 27},
            {'id': 'mh_miras_genel', 'name': 'Miras Hukuku Genel', 'order': 28},
            {'id': 'mh_yasal_miras', 'name': 'Yasal Mirasçılar', 'order': 29},
            {'id': 'mh_sakli_pay', 'name': 'Saklı Pay', 'order': 30},
            {'id': 'mh_olume_bagli', 'name': 'Ölüme Bağlı Tasarruflar', 'order': 31},
            {'id': 'mh_vasiyetname', 'name': 'Vasiyetname', 'order': 32},
            {'id': 'mh_miras_sozlesme', 'name': 'Miras Sözleşmesi', 'order': 33},
            {'id': 'mh_miras_gecis', 'name': 'Mirasın Geçişi', 'order': 34},
            {'id': 'mh_esya_genel', 'name': 'Eşya Hukuku Genel', 'order': 35},
            {'id': 'mh_zilyetlik', 'name': 'Zilyetlik', 'order': 36},
            {'id': 'mh_tapu_sicil', 'name': 'Tapu Sicili', 'order': 37},
            {'id': 'mh_mulkiyet', 'name': 'Mülkiyet', 'order': 38},
            {'id': 'mh_tasinmaz_mulk', 'name': 'Taşınmaz Mülkiyeti', 'order': 39},
            {'id': 'mh_kat_mulkiyeti', 'name': 'Kat Mülkiyeti', 'order': 40},
            {'id': 'mh_sinirli_ayni', 'name': 'Sınırlı Ayni Haklar', 'order': 41},
            {'id': 'mh_irtifak', 'name': 'İrtifak Hakları', 'order': 42},
            {'id': 'mh_rehin', 'name': 'Rehin Hakları', 'order': 43},
            {'id': 'mh_ipotek', 'name': 'İpotek', 'order': 44},
        ]
    },
    
    'borclar_hukuku': {
        'name': 'Borçlar Hukuku',
        'order': 3,
        'topics': [
            {'id': 'bh_giris', 'name': 'Borçlar Hukukuna Giriş', 'order': 1},
            {'id': 'bh_borc_kaynagi', 'name': 'Borcun Kaynakları', 'order': 2},
            {'id': 'bh_sozlesme_genel', 'name': 'Sözleşmeden Doğan Borç', 'order': 3},
            {'id': 'bh_sozlesme_kurulus', 'name': 'Sözleşmenin Kurulması', 'order': 4},
            {'id': 'bh_icap_kabul', 'name': 'İcap ve Kabul', 'order': 5},
            {'id': 'bh_irade_beyan', 'name': 'İrade Beyanı', 'order': 6},
            {'id': 'bh_sekil', 'name': 'Şekil', 'order': 7},
            {'id': 'bh_temsil', 'name': 'Temsil', 'order': 8},
            {'id': 'bh_hukumsuzluk', 'name': 'Hukuki İşlemin Hükümsüzlüğü', 'order': 9},
            {'id': 'bh_irade_sakatligi', 'name': 'İrade Sakatlıkları', 'order': 10},
            {'id': 'bh_gabin', 'name': 'Aşırı Yararlanma (Gabin)', 'order': 11},
            {'id': 'bh_haksiz_fiil', 'name': 'Haksız Fiil', 'order': 12},
            {'id': 'bh_kusur_sorumluluk', 'name': 'Kusur Sorumluluğu', 'order': 13},
            {'id': 'bh_kusursuz_sorumluluk', 'name': 'Kusursuz Sorumluluk', 'order': 14},
            {'id': 'bh_sebepsiz_zengin', 'name': 'Sebepsiz Zenginleşme', 'order': 15},
            {'id': 'bh_borc_iliskisi', 'name': 'Borç İlişkisinin Hükümleri', 'order': 16},
            {'id': 'bh_ifa', 'name': 'Borcun İfası', 'order': 17},
            {'id': 'bh_ifa_yeri_zamani', 'name': 'İfa Yeri ve Zamanı', 'order': 18},
            {'id': 'bh_borclu_temerrud', 'name': 'Borçlu Temerrüdü', 'order': 19},
            {'id': 'bh_alacakli_temerrud', 'name': 'Alacaklı Temerrüdü', 'order': 20},
            {'id': 'bh_imkansizlik', 'name': 'İfa İmkansızlığı', 'order': 21},
            {'id': 'bh_zarar', 'name': 'Zarar ve Tazminat', 'order': 22},
            {'id': 'bh_cezai_sart', 'name': 'Cezai Şart', 'order': 23},
            {'id': 'bh_alacak_devri', 'name': 'Alacağın Devri', 'order': 24},
            {'id': 'bh_borc_ustlenme', 'name': 'Borcun Üstlenilmesi', 'order': 25},
            {'id': 'bh_sona_erme', 'name': 'Borcun Sona Ermesi', 'order': 26},
            {'id': 'bh_takas', 'name': 'Takas', 'order': 27},
            {'id': 'bh_zamanasimi', 'name': 'Zamanaşımı', 'order': 28},
            {'id': 'bh_satis', 'name': 'Satış Sözleşmesi', 'order': 29},
            {'id': 'bh_tasinir_satis', 'name': 'Taşınır Satışı', 'order': 30},
            {'id': 'bh_tasinmaz_satis', 'name': 'Taşınmaz Satışı', 'order': 31},
            {'id': 'bh_bagislama', 'name': 'Bağışlama', 'order': 32},
            {'id': 'bh_kira', 'name': 'Kira Sözleşmesi', 'order': 33},
            {'id': 'bh_konut_kira', 'name': 'Konut ve Çatılı İşyeri Kirası', 'order': 34},
            {'id': 'bh_eser', 'name': 'Eser Sözleşmesi', 'order': 35},
            {'id': 'bh_vekalet', 'name': 'Vekalet Sözleşmesi', 'order': 36},
            {'id': 'bh_hizmet', 'name': 'Hizmet Sözleşmesi', 'order': 37},
            {'id': 'bh_kefalet', 'name': 'Kefalet Sözleşmesi', 'order': 38},
        ]
    },
    
    'ceza_hukuku': {
        'name': 'Ceza Hukuku',
        'order': 4,
        'topics': [
            {'id': 'ch_giris', 'name': 'Ceza Hukukuna Giriş', 'order': 1},
            {'id': 'ch_temel_ilke', 'name': 'Temel İlkeler', 'order': 2},
            {'id': 'ch_kanunun_uyg', 'name': 'Ceza Kanununun Uygulanması', 'order': 3},
            {'id': 'ch_zaman_uyg', 'name': 'Zaman Bakımından Uygulama', 'order': 4},
            {'id': 'ch_yer_uyg', 'name': 'Yer Bakımından Uygulama', 'order': 5},
            {'id': 'ch_kisi_uyg', 'name': 'Kişi Bakımından Uygulama', 'order': 6},
            {'id': 'ch_suc_genel', 'name': 'Suç Genel Teorisi', 'order': 7},
            {'id': 'ch_maddi_unsur', 'name': 'Maddi Unsur (Fiil)', 'order': 8},
            {'id': 'ch_hareket', 'name': 'Hareket', 'order': 9},
            {'id': 'ch_netice', 'name': 'Netice', 'order': 10},
            {'id': 'ch_nedensellik', 'name': 'Nedensellik Bağı', 'order': 11},
            {'id': 'ch_manevi_unsur', 'name': 'Manevi Unsur', 'order': 12},
            {'id': 'ch_kast', 'name': 'Kast', 'order': 13},
            {'id': 'ch_taksir', 'name': 'Taksir', 'order': 14},
            {'id': 'ch_hukuka_aykiri', 'name': 'Hukuka Aykırılık', 'order': 15},
            {'id': 'ch_hukuka_uygunluk', 'name': 'Hukuka Uygunluk Nedenleri', 'order': 16},
            {'id': 'ch_mesru_mudafaa', 'name': 'Meşru Müdafaa', 'order': 17},
            {'id': 'ch_zorunluluk', 'name': 'Zorunluluk Hali', 'order': 18},
            {'id': 'ch_kusur', 'name': 'Kusurluluk', 'order': 19},
            {'id': 'ch_kusuru_kaldiran', 'name': 'Kusuru Kaldıran Nedenler', 'order': 20},
            {'id': 'ch_tesebbüs', 'name': 'Suça Teşebbüs', 'order': 21},
            {'id': 'ch_gonullu_vazgecme', 'name': 'Gönüllü Vazgeçme', 'order': 22},
            {'id': 'ch_istirak', 'name': 'Suça İştirak', 'order': 23},
            {'id': 'ch_faillik', 'name': 'Faillik Türleri', 'order': 24},
            {'id': 'ch_seriklik', 'name': 'Şeriklik', 'order': 25},
            {'id': 'ch_ictima', 'name': 'Suçların İçtimaı', 'order': 26},
            {'id': 'ch_yaptirimlar', 'name': 'Yaptırımlar', 'order': 27},
            {'id': 'ch_hapis', 'name': 'Hapis Cezası', 'order': 28},
            {'id': 'ch_adli_para', 'name': 'Adli Para Cezası', 'order': 29},
            {'id': 'ch_guvenlik_ted', 'name': 'Güvenlik Tedbirleri', 'order': 30},
            {'id': 'ch_erteleme', 'name': 'Cezanın Ertelenmesi', 'order': 31},
            {'id': 'ch_hagb', 'name': 'HAGB', 'order': 32},
            {'id': 'ch_hayata_karsi', 'name': 'Hayata Karşı Suçlar', 'order': 33},
            {'id': 'ch_oldurmne', 'name': 'Kasten Öldürme', 'order': 34},
            {'id': 'ch_taksirle_oldurme', 'name': 'Taksirle Öldürme', 'order': 35},
            {'id': 'ch_vucuda_karsi', 'name': 'Vücut Bütünlüğüne Karşı Suçlar', 'order': 36},
            {'id': 'ch_yaralama', 'name': 'Kasten Yaralama', 'order': 37},
            {'id': 'ch_cinsel_dokunulmazlik', 'name': 'Cinsel Dokunulmazlığa Karşı Suçlar', 'order': 38},
            {'id': 'ch_hurriyet', 'name': 'Hürriyete Karşı Suçlar', 'order': 39},
            {'id': 'ch_konut_dokunulmazligi', 'name': 'Konut Dokunulmazlığı', 'order': 40},
            {'id': 'ch_mala_karsi', 'name': 'Malvarlığına Karşı Suçlar', 'order': 41},
            {'id': 'ch_hirsizlik', 'name': 'Hırsızlık', 'order': 42},
            {'id': 'ch_yagma', 'name': 'Yağma', 'order': 43},
            {'id': 'ch_dolandiricilik', 'name': 'Dolandırıcılık', 'order': 44},
            {'id': 'ch_guven_kotu', 'name': 'Güveni Kötüye Kullanma', 'order': 45},
            {'id': 'ch_kamu_guveni', 'name': 'Kamu Güvenine Karşı Suçlar', 'order': 46},
            {'id': 'ch_sahtecilik', 'name': 'Belgede Sahtecilik', 'order': 47},
            {'id': 'ch_kamu_idaresi', 'name': 'Kamu İdaresine Karşı Suçlar', 'order': 48},
            {'id': 'ch_irtikap', 'name': 'İrtikap', 'order': 49},
            {'id': 'ch_ruşvet', 'name': 'Rüşvet', 'order': 50},
            {'id': 'ch_zimmet', 'name': 'Zimmet', 'order': 51},
            {'id': 'ch_gorev_kotuye', 'name': 'Görevi Kötüye Kullanma', 'order': 52},
        ]
    },
}


def seed_part1():
    print("🚀 HMGS Detaylı Müfredat BÖLÜM 1 yükleniyor...\n")
    
    batch = db.batch()
    count = 0
    total_topics = 0
    
    for subject_id, data in CURRICULUM_PART1.items():
        # Subject
        ref = db.collection('subjects').document(subject_id)
        batch.set(ref, {
            'id': subject_id,
            'name': data['name'],
            'order': data['order'],
            'isActive': True,
            'topicCount': len(data['topics']),
            'updatedAt': firestore.SERVER_TIMESTAMP
        }, merge=True)
        count += 1
        
        print(f"📚 {data['name']} ({len(data['topics'])} konu)")
        
        # Topics
        for topic in data['topics']:
            t_ref = db.collection('topics').document(topic['id'])
            batch.set(t_ref, {
                'id': topic['id'],
                'name': topic['name'],
                'subjectId': subject_id,
                'order': topic['order'],
                'isActive': True,
                'questionCount': 0,
                'updatedAt': firestore.SERVER_TIMESTAMP
            }, merge=True)
            count += 1
            total_topics += 1
            
            if count >= 450:
                batch.commit()
                batch = db.batch()
                count = 0
    
    if count > 0:
        batch.commit()
    
    print(f"\n✅ Bölüm 1 tamamlandı! {total_topics} konu yüklendi.")


if __name__ == '__main__':
    seed_part1()
