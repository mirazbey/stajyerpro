"""
HMGS Detaylı Müfredat - BÖLÜM 2 (Kalan Dersler)
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

CURRICULUM_PART2 = {
    'ceza_muhakemesi': {
        'name': 'Ceza Muhakemesi Hukuku',
        'order': 5,
        'topics': [
            {'id': 'cmk_giris', 'name': 'Ceza Muhakemesine Giriş', 'order': 1},
            {'id': 'cmk_ilkeler', 'name': 'Temel İlkeler', 'order': 2},
            {'id': 'cmk_sujeler', 'name': 'Muhakeme Süjeleri', 'order': 3},
            {'id': 'cmk_mahkemeler', 'name': 'Ceza Mahkemeleri', 'order': 4},
            {'id': 'cmk_gorev', 'name': 'Görev ve Yetki', 'order': 5},
            {'id': 'cmk_sureler', 'name': 'Süreler', 'order': 6},
            {'id': 'cmk_yakalama', 'name': 'Yakalama', 'order': 7},
            {'id': 'cmk_gozalti', 'name': 'Gözaltı', 'order': 8},
            {'id': 'cmk_tutuklama', 'name': 'Tutuklama', 'order': 9},
            {'id': 'cmk_adli_kontrol', 'name': 'Adli Kontrol', 'order': 10},
            {'id': 'cmk_arama', 'name': 'Arama', 'order': 11},
            {'id': 'cmk_elkoyma', 'name': 'Elkoyma', 'order': 12},
            {'id': 'cmk_iletisim', 'name': 'İletişimin Denetlenmesi', 'order': 13},
            {'id': 'cmk_gizli_sorusturma', 'name': 'Gizli Soruşturmacı', 'order': 14},
            {'id': 'cmk_sorusturma', 'name': 'Soruşturma Evresi', 'order': 15},
            {'id': 'cmk_delil', 'name': 'Delil ve İspat', 'order': 16},
            {'id': 'cmk_ifade', 'name': 'İfade Alma', 'order': 17},
            {'id': 'cmk_iddianame', 'name': 'İddianame', 'order': 18},
            {'id': 'cmk_kovusturma', 'name': 'Kovuşturma Evresi', 'order': 19},
            {'id': 'cmk_durusma', 'name': 'Duruşma', 'order': 20},
            {'id': 'cmk_hukum', 'name': 'Hüküm', 'order': 21},
            {'id': 'cmk_itiraz', 'name': 'İtiraz', 'order': 22},
            {'id': 'cmk_istinaf', 'name': 'İstinaf', 'order': 23},
            {'id': 'cmk_temyiz', 'name': 'Temyiz', 'order': 24},
            {'id': 'cmk_olaganustu', 'name': 'Olağanüstü Kanun Yolları', 'order': 25},
            {'id': 'cmk_uzlasma', 'name': 'Uzlaşma', 'order': 26},
            {'id': 'cmk_onyargılama', 'name': 'Ön Ödeme', 'order': 27},
            {'id': 'cmk_kamu_davası', 'name': 'Kamu Davasının Açılması Ertelenmesi', 'order': 28},
        ]
    },
    
    'idare_hukuku': {
        'name': 'İdare Hukuku',
        'order': 6,
        'topics': [
            {'id': 'ih_giris', 'name': 'İdare Hukukuna Giriş', 'order': 1},
            {'id': 'ih_ilkeler', 'name': 'İdare Hukukunun İlkeleri', 'order': 2},
            {'id': 'ih_hukuki_rejim', 'name': 'İdarenin Hukuki Rejimi', 'order': 3},
            {'id': 'ih_merkezi', 'name': 'Merkezi İdare', 'order': 4},
            {'id': 'ih_cumhurbaskanligi', 'name': 'Cumhurbaşkanlığı Teşkilatı', 'order': 5},
            {'id': 'ih_bakanlik', 'name': 'Bakanlıklar', 'order': 6},
            {'id': 'ih_tasra', 'name': 'Taşra Teşkilatı', 'order': 7},
            {'id': 'ih_yerinden', 'name': 'Yerinden Yönetim', 'order': 8},
            {'id': 'ih_belediye', 'name': 'Belediyeler', 'order': 9},
            {'id': 'ih_il_ozel', 'name': 'İl Özel İdaresi', 'order': 10},
            {'id': 'ih_koy', 'name': 'Köy İdaresi', 'order': 11},
            {'id': 'ih_hizmet_yerinden', 'name': 'Hizmet Yerinden Yönetim', 'order': 12},
            {'id': 'ih_kamu_tuzel', 'name': 'Kamu Tüzel Kişileri', 'order': 13},
            {'id': 'ih_idari_islem', 'name': 'İdari İşlem', 'order': 14},
            {'id': 'ih_islem_unsurlari', 'name': 'İdari İşlemin Unsurları', 'order': 15},
            {'id': 'ih_bireysel_islem', 'name': 'Bireysel İşlemler', 'order': 16},
            {'id': 'ih_duzenleyici', 'name': 'Düzenleyici İşlemler', 'order': 17},
            {'id': 'ih_yonetmelik', 'name': 'Yönetmelik', 'order': 18},
            {'id': 'ih_idari_eylem', 'name': 'İdari Eylem', 'order': 19},
            {'id': 'ih_idari_sozlesme', 'name': 'İdari Sözleşme', 'order': 20},
            {'id': 'ih_kamu_ihale', 'name': 'Kamu İhale Hukuku', 'order': 21},
            {'id': 'ih_kamu_gorevlisi', 'name': 'Kamu Görevlileri', 'order': 22},
            {'id': 'ih_memur', 'name': 'Memurlar', 'order': 23},
            {'id': 'ih_atama', 'name': 'Atama ve İlerleme', 'order': 24},
            {'id': 'ih_disiplin', 'name': 'Disiplin Hukuku', 'order': 25},
            {'id': 'ih_sorumluluk', 'name': 'İdarenin Sorumluluğu', 'order': 26},
            {'id': 'ih_hizmet_kusuru', 'name': 'Hizmet Kusuru', 'order': 27},
            {'id': 'ih_kusursuz', 'name': 'Kusursuz Sorumluluk', 'order': 28},
            {'id': 'ih_kamu_mallari', 'name': 'Kamu Malları', 'order': 29},
            {'id': 'ih_kamulastirma', 'name': 'Kamulaştırma', 'order': 30},
            {'id': 'ih_kolluk', 'name': 'İdari Kolluk', 'order': 31},
        ]
    },
    
    'idari_yargilama': {
        'name': 'İdari Yargılama Hukuku',
        'order': 7,
        'topics': [
            {'id': 'iy_giris', 'name': 'İdari Yargıya Giriş', 'order': 1},
            {'id': 'iy_teskilat', 'name': 'İdari Yargı Teşkilatı', 'order': 2},
            {'id': 'iy_danistay', 'name': 'Danıştay', 'order': 3},
            {'id': 'iy_bim', 'name': 'Bölge İdare Mahkemeleri', 'order': 4},
            {'id': 'iy_idare_mah', 'name': 'İdare Mahkemeleri', 'order': 5},
            {'id': 'iy_vergi_mah', 'name': 'Vergi Mahkemeleri', 'order': 6},
            {'id': 'iy_gorev', 'name': 'Görev ve Yetki', 'order': 7},
            {'id': 'iy_dava_turleri', 'name': 'Dava Türleri', 'order': 8},
            {'id': 'iy_iptal', 'name': 'İptal Davası', 'order': 9},
            {'id': 'iy_iptal_sartlari', 'name': 'İptal Davası Şartları', 'order': 10},
            {'id': 'iy_iptal_nedenleri', 'name': 'İptal Nedenleri', 'order': 11},
            {'id': 'iy_tam_yargi', 'name': 'Tam Yargı Davası', 'order': 12},
            {'id': 'iy_yargilama_usulu', 'name': 'Yargılama Usulü', 'order': 13},
            {'id': 'iy_dava_acma', 'name': 'Dava Açma Süresi', 'order': 14},
            {'id': 'iy_yurutme_durdurma', 'name': 'Yürütmenin Durdurulması', 'order': 15},
            {'id': 'iy_karar', 'name': 'Kararlar', 'order': 16},
            {'id': 'iy_istinaf_iy', 'name': 'İstinaf', 'order': 17},
            {'id': 'iy_temyiz_iy', 'name': 'Temyiz', 'order': 18},
        ]
    },
    
    'hukuk_muhakemeleri': {
        'name': 'Hukuk Muhakemeleri Kanunu',
        'order': 8,
        'topics': [
            {'id': 'hmk_giris', 'name': 'Medeni Usul Hukukuna Giriş', 'order': 1},
            {'id': 'hmk_ilkeler', 'name': 'Temel İlkeler', 'order': 2},
            {'id': 'hmk_mahkemeler', 'name': 'Hukuk Mahkemeleri', 'order': 3},
            {'id': 'hmk_gorev', 'name': 'Görev', 'order': 4},
            {'id': 'hmk_yetki', 'name': 'Yetki', 'order': 5},
            {'id': 'hmk_taraflar', 'name': 'Taraflar', 'order': 6},
            {'id': 'hmk_taraf_ehliyeti', 'name': 'Taraf Ehliyeti', 'order': 7},
            {'id': 'hmk_dava_ehliyeti', 'name': 'Dava Ehliyeti', 'order': 8},
            {'id': 'hmk_dava_arkadasligi', 'name': 'Dava Arkadaşlığı', 'order': 9},
            {'id': 'hmk_fer_i_mudahale', 'name': 'Fer\'i Müdahale', 'order': 10},
            {'id': 'hmk_asli_mudahale', 'name': 'Asli Müdahale', 'order': 11},
            {'id': 'hmk_dava_sartlari', 'name': 'Dava Şartları', 'order': 12},
            {'id': 'hmk_hukuki_yarar', 'name': 'Hukuki Yarar', 'order': 13},
            {'id': 'hmk_dava_cesitleri', 'name': 'Dava Çeşitleri', 'order': 14},
            {'id': 'hmk_eda_davasi', 'name': 'Eda Davası', 'order': 15},
            {'id': 'hmk_tespit_davasi', 'name': 'Tespit Davası', 'order': 16},
            {'id': 'hmk_belirsiz_alacak', 'name': 'Belirsiz Alacak Davası', 'order': 17},
            {'id': 'hmk_kismi_dava', 'name': 'Kısmi Dava', 'order': 18},
            {'id': 'hmk_dava_dilekce', 'name': 'Dava Dilekçesi', 'order': 19},
            {'id': 'hmk_cevap_dilekce', 'name': 'Cevap Dilekçesi', 'order': 20},
            {'id': 'hmk_on_inceleme', 'name': 'Ön İnceleme', 'order': 21},
            {'id': 'hmk_tahkikat', 'name': 'Tahkikat', 'order': 22},
            {'id': 'hmk_ispat', 'name': 'İspat ve Deliller', 'order': 23},
            {'id': 'hmk_ispat_yuku', 'name': 'İspat Yükü', 'order': 24},
            {'id': 'hmk_senet', 'name': 'Senet', 'order': 25},
            {'id': 'hmk_yemin', 'name': 'Yemin', 'order': 26},
            {'id': 'hmk_tanik', 'name': 'Tanık', 'order': 27},
            {'id': 'hmk_bilirkisi', 'name': 'Bilirkişi', 'order': 28},
            {'id': 'hmk_kesif', 'name': 'Keşif', 'order': 29},
            {'id': 'hmk_sozlu_yargilama', 'name': 'Sözlü Yargılama', 'order': 30},
            {'id': 'hmk_hukum', 'name': 'Hüküm', 'order': 31},
            {'id': 'hmk_basit_yargilama', 'name': 'Basit Yargılama', 'order': 32},
            {'id': 'hmk_istinaf_hmk', 'name': 'İstinaf', 'order': 33},
            {'id': 'hmk_temyiz_hmk', 'name': 'Temyiz', 'order': 34},
            {'id': 'hmk_yargilamanin_iadesi', 'name': 'Yargılamanın İadesi', 'order': 35},
            {'id': 'hmk_gecici_koruma', 'name': 'Geçici Hukuki Koruma', 'order': 36},
            {'id': 'hmk_ihtiyati_tedbir', 'name': 'İhtiyati Tedbir', 'order': 37},
        ]
    },
    
    'ticaret_hukuku': {
        'name': 'Ticaret Hukuku',
        'order': 9,
        'topics': [
            {'id': 'th_giris', 'name': 'Ticaret Hukukuna Giriş', 'order': 1},
            {'id': 'th_ticari_isletme', 'name': 'Ticari İşletme', 'order': 2},
            {'id': 'th_tacir', 'name': 'Tacir', 'order': 3},
            {'id': 'th_ticaret_sicili', 'name': 'Ticaret Sicili', 'order': 4},
            {'id': 'th_ticaret_unvani', 'name': 'Ticaret Unvanı', 'order': 5},
            {'id': 'th_haksiz_rekabet', 'name': 'Haksız Rekabet', 'order': 6},
            {'id': 'th_ticari_defterler', 'name': 'Ticari Defterler', 'order': 7},
            {'id': 'th_cari_hesap', 'name': 'Cari Hesap', 'order': 8},
            {'id': 'th_acente', 'name': 'Acentelik', 'order': 9},
            {'id': 'th_sirketler_genel', 'name': 'Şirketler Hukuku Genel', 'order': 10},
            {'id': 'th_kollektif', 'name': 'Kollektif Şirket', 'order': 11},
            {'id': 'th_komandit', 'name': 'Komandit Şirket', 'order': 12},
            {'id': 'th_anonim', 'name': 'Anonim Şirket', 'order': 13},
            {'id': 'th_as_kurulus', 'name': 'A.Ş. Kuruluşu', 'order': 14},
            {'id': 'th_as_yonetim', 'name': 'A.Ş. Yönetim Kurulu', 'order': 15},
            {'id': 'th_as_genel_kurul', 'name': 'A.Ş. Genel Kurul', 'order': 16},
            {'id': 'th_as_denetim', 'name': 'A.Ş. Denetim', 'order': 17},
            {'id': 'th_as_pay', 'name': 'A.Ş. Pay ve Pay Senedi', 'order': 18},
            {'id': 'th_limited', 'name': 'Limited Şirket', 'order': 19},
            {'id': 'th_kiymetli_evrak', 'name': 'Kıymetli Evrak Genel', 'order': 20},
            {'id': 'th_police', 'name': 'Poliçe', 'order': 21},
            {'id': 'th_bono', 'name': 'Bono', 'order': 22},
            {'id': 'th_cek', 'name': 'Çek', 'order': 23},
            {'id': 'th_cek_karsiliksiz', 'name': 'Karşılıksız Çek', 'order': 24},
        ]
    },
    
    'icra_iflas': {
        'name': 'İcra ve İflas Hukuku',
        'order': 10,
        'topics': [
            {'id': 'ii_giris', 'name': 'İcra Hukukuna Giriş', 'order': 1},
            {'id': 'ii_teskilat', 'name': 'İcra Teşkilatı', 'order': 2},
            {'id': 'ii_sikayet', 'name': 'Şikayet', 'order': 3},
            {'id': 'ii_ilamsiz_takip', 'name': 'İlamsız Takip', 'order': 4},
            {'id': 'ii_genel_haciz', 'name': 'Genel Haciz Yolu', 'order': 5},
            {'id': 'ii_odeme_emri', 'name': 'Ödeme Emri', 'order': 6},
            {'id': 'ii_itiraz', 'name': 'İtiraz', 'order': 7},
            {'id': 'ii_itirazin_kaldirilmasi', 'name': 'İtirazın Kaldırılması', 'order': 8},
            {'id': 'ii_itirazin_iptali', 'name': 'İtirazın İptali', 'order': 9},
            {'id': 'ii_kambiyo_takip', 'name': 'Kambiyo Senetlerine Özgü Takip', 'order': 10},
            {'id': 'ii_kiralanan_tahliye', 'name': 'Kiralanan Tahliyesi', 'order': 11},
            {'id': 'ii_ilamli_takip', 'name': 'İlamlı Takip', 'order': 12},
            {'id': 'ii_haciz', 'name': 'Haciz', 'order': 13},
            {'id': 'ii_haczedilmezlik', 'name': 'Haczedilmezlik', 'order': 14},
            {'id': 'ii_istihkak', 'name': 'İstihkak Davası', 'order': 15},
            {'id': 'ii_satis', 'name': 'Satış', 'order': 16},
            {'id': 'ii_paralarin_paylasimi', 'name': 'Paraların Paylaştırılması', 'order': 17},
            {'id': 'ii_rehnin_paraya', 'name': 'Rehnin Paraya Çevrilmesi', 'order': 18},
            {'id': 'ii_iflas_genel', 'name': 'İflas Hukuku Genel', 'order': 19},
            {'id': 'ii_takipli_iflas', 'name': 'Takipli İflas', 'order': 20},
            {'id': 'ii_dogrudan_iflas', 'name': 'Doğrudan İflas', 'order': 21},
            {'id': 'ii_iflas_idare', 'name': 'İflasın İdaresi', 'order': 22},
            {'id': 'ii_sira_cetveli', 'name': 'Sıra Cetveli', 'order': 23},
            {'id': 'ii_konkordato', 'name': 'Konkordato', 'order': 24},
            {'id': 'ii_tasarrufun_iptali', 'name': 'Tasarrufun İptali', 'order': 25},
        ]
    },
    
    'is_hukuku': {
        'name': 'İş ve Sosyal Güvenlik Hukuku',
        'order': 11,
        'topics': [
            {'id': 'ish_giris', 'name': 'İş Hukukuna Giriş', 'order': 1},
            {'id': 'ish_is_sozlesmesi', 'name': 'İş Sözleşmesi', 'order': 2},
            {'id': 'ish_is_sozl_turleri', 'name': 'İş Sözleşmesi Türleri', 'order': 3},
            {'id': 'ish_isci_borclari', 'name': 'İşçinin Borçları', 'order': 4},
            {'id': 'ish_isveren_borclari', 'name': 'İşverenin Borçları', 'order': 5},
            {'id': 'ish_ucret', 'name': 'Ücret', 'order': 6},
            {'id': 'ish_calisma_suresi', 'name': 'Çalışma Süreleri', 'order': 7},
            {'id': 'ish_fazla_calisma', 'name': 'Fazla Çalışma', 'order': 8},
            {'id': 'ish_yillik_izin', 'name': 'Yıllık İzin', 'order': 9},
            {'id': 'ish_fesih', 'name': 'İş Sözleşmesinin Feshi', 'order': 10},
            {'id': 'ish_sureli_fesih', 'name': 'Süreli Fesih (İhbar)', 'order': 11},
            {'id': 'ish_hakli_fesih', 'name': 'Haklı Nedenle Fesih', 'order': 12},
            {'id': 'ish_kidem_tazminati', 'name': 'Kıdem Tazminatı', 'order': 13},
            {'id': 'ish_is_guv', 'name': 'İş Güvencesi', 'order': 14},
            {'id': 'ish_ise_iade', 'name': 'İşe İade Davası', 'order': 15},
            {'id': 'ish_is_sagligi', 'name': 'İş Sağlığı ve Güvenliği', 'order': 16},
            {'id': 'ish_toplu_is', 'name': 'Toplu İş Hukuku', 'order': 17},
            {'id': 'ish_sendika', 'name': 'Sendika', 'order': 18},
            {'id': 'ish_tis', 'name': 'Toplu İş Sözleşmesi', 'order': 19},
            {'id': 'ish_grev_lokavt', 'name': 'Grev ve Lokavt', 'order': 20},
            {'id': 'sgh_giris', 'name': 'Sosyal Güvenlik Hukukuna Giriş', 'order': 21},
            {'id': 'sgh_sigorta_kollari', 'name': 'Sigorta Kolları', 'order': 22},
            {'id': 'sgh_is_kazasi', 'name': 'İş Kazası ve Meslek Hastalığı', 'order': 23},
            {'id': 'sgh_emeklilik', 'name': 'Emeklilik', 'order': 24},
            {'id': 'sgh_primler', 'name': 'Primler', 'order': 25},
        ]
    },
    
    'vergi_hukuku': {
        'name': 'Vergi Hukuku',
        'order': 12,
        'topics': [
            {'id': 'vh_giris', 'name': 'Vergi Hukukuna Giriş', 'order': 1},
            {'id': 'vh_vergilendirme', 'name': 'Vergilendirme İlkeleri', 'order': 2},
            {'id': 'vh_vergi_odevi', 'name': 'Vergi Ödevi', 'order': 3},
            {'id': 'vh_mukellef', 'name': 'Mükellef ve Vergi Sorumlusu', 'order': 4},
            {'id': 'vh_vergi_unsurlari', 'name': 'Verginin Unsurları', 'order': 5},
            {'id': 'vh_tarh', 'name': 'Verginin Tarhı', 'order': 6},
            {'id': 'vh_tahakkuk', 'name': 'Verginin Tahakkuku', 'order': 7},
            {'id': 'vh_tahsil', 'name': 'Verginin Tahsili', 'order': 8},
            {'id': 'vh_zamanasimi', 'name': 'Zamanaşımı', 'order': 9},
            {'id': 'vh_vergi_suclari', 'name': 'Vergi Suç ve Cezaları', 'order': 10},
            {'id': 'vh_gelir_vergisi', 'name': 'Gelir Vergisi', 'order': 11},
            {'id': 'vh_kurumlar', 'name': 'Kurumlar Vergisi', 'order': 12},
            {'id': 'vh_kdv', 'name': 'Katma Değer Vergisi', 'order': 13},
            {'id': 'vh_otv', 'name': 'Özel Tüketim Vergisi', 'order': 14},
            {'id': 'vh_vergi_yargisi', 'name': 'Vergi Yargısı', 'order': 15},
            {'id': 'vh_uzlasma', 'name': 'Uzlaşma', 'order': 16},
        ]
    },
    
    'milletlerarasi': {
        'name': 'Milletlerarası Hukuk',
        'order': 13,
        'topics': [
            {'id': 'mh_giris', 'name': 'Milletlerarası Hukuka Giriş', 'order': 1},
            {'id': 'mh_kaynaklar', 'name': 'Kaynaklar', 'order': 2},
            {'id': 'mh_devlet', 'name': 'Devlet', 'order': 3},
            {'id': 'mh_tanima', 'name': 'Tanıma', 'order': 4},
            {'id': 'mh_antlasma', 'name': 'Antlaşmalar Hukuku', 'order': 5},
            {'id': 'mh_diplomatik', 'name': 'Diplomatik İlişkiler', 'order': 6},
            {'id': 'mh_konsolosluk', 'name': 'Konsolosluk İlişkileri', 'order': 7},
            {'id': 'mh_insan_haklari', 'name': 'İnsan Hakları', 'order': 8},
            {'id': 'mh_bm', 'name': 'Birleşmiş Milletler', 'order': 9},
            {'id': 'mh_uyusmazlik', 'name': 'Uyuşmazlıkların Çözümü', 'order': 10},
            {'id': 'mh_uad', 'name': 'Uluslararası Adalet Divanı', 'order': 11},
        ]
    },
    
    'avukatlik_hukuku': {
        'name': 'Avukatlık Hukuku',
        'order': 14,
        'topics': [
            {'id': 'av_giris', 'name': 'Avukatlık Mesleğine Giriş', 'order': 1},
            {'id': 'av_kabul', 'name': 'Mesleğe Kabul Şartları', 'order': 2},
            {'id': 'av_staj', 'name': 'Avukatlık Stajı', 'order': 3},
            {'id': 'av_haklar', 'name': 'Avukatın Hakları', 'order': 4},
            {'id': 'av_yukumlulukler', 'name': 'Avukatın Yükümlülükleri', 'order': 5},
            {'id': 'av_yasaklar', 'name': 'Avukatlık Yasakları', 'order': 6},
            {'id': 'av_baro', 'name': 'Baro', 'order': 7},
            {'id': 'av_tbb', 'name': 'Türkiye Barolar Birliği', 'order': 8},
            {'id': 'av_disiplin', 'name': 'Disiplin Hukuku', 'order': 9},
            {'id': 'av_disiplin_ceza', 'name': 'Disiplin Cezaları', 'order': 10},
            {'id': 'av_sorumluluk', 'name': 'Avukatın Sorumluluğu', 'order': 11},
        ]
    },
    
    'hukuk_felsefesi': {
        'name': 'Hukuk Felsefesi ve Sosyolojisi',
        'order': 15,
        'topics': [
            {'id': 'hf_giris', 'name': 'Hukuk Felsefesine Giriş', 'order': 1},
            {'id': 'hf_dogal_hukuk', 'name': 'Doğal Hukuk', 'order': 2},
            {'id': 'hf_pozitivizm', 'name': 'Hukuki Pozitivizm', 'order': 3},
            {'id': 'hf_saf_hukuk', 'name': 'Saf Hukuk Teorisi', 'order': 4},
            {'id': 'hf_sosyolojik', 'name': 'Sosyolojik Hukuk Okulu', 'order': 5},
            {'id': 'hf_adalet', 'name': 'Adalet Kavramı', 'order': 6},
            {'id': 'hf_hukuk_sosyoloji', 'name': 'Hukuk Sosyolojisi', 'order': 7},
            {'id': 'hf_hukuk_toplum', 'name': 'Hukuk ve Toplum', 'order': 8},
        ]
    },
}


def seed_part2():
    print("🚀 HMGS Detaylı Müfredat BÖLÜM 2 yükleniyor...\n")
    
    batch = db.batch()
    count = 0
    total_topics = 0
    
    for subject_id, data in CURRICULUM_PART2.items():
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
    
    print(f"\n✅ Bölüm 2 tamamlandı! {total_topics} konu yüklendi.")


if __name__ == '__main__':
    seed_part2()
