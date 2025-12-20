"""
HMGS Hiyerarşik Müfredat - Ana Başlıklar + Alt Konular
Önce mevcut topics temizlenir, sonra hiyerarşik yapıda yüklenir.
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

# Hiyerarşik Müfredat: Ana Başlık -> Alt Konular
HIERARCHICAL_CURRICULUM = {
    'anayasa_hukuku': {
        'name': 'Anayasa Hukuku',
        'order': 1,
        'groups': [
            {
                'name': 'Anayasa Hukukuna Giriş',
                'order': 1,
                'topics': [
                    'Anayasa Kavramı ve Türleri',
                    'Anayasa Yapımı ve Değiştirilmesi',
                    'Devlet Kavramı ve Unsurları',
                    'Egemenlik ve Kaynağı',
                    'Hükümet Sistemleri',
                ]
            },
            {
                'name': 'Temel Hak ve Özgürlükler',
                'order': 2,
                'topics': [
                    'Temel Hakların Sınırlandırılması',
                    'Kişi Hakları ve Ödevleri',
                    'Sosyal ve Ekonomik Haklar',
                    'Siyasi Haklar ve Ödevler',
                ]
            },
            {
                'name': 'Yasama',
                'order': 3,
                'topics': [
                    'TBMM Yapısı ve İşleyişi',
                    'Milletvekilliği',
                    'Kanun Yapım Süreci',
                    'Meclis Denetimi',
                ]
            },
            {
                'name': 'Yürütme',
                'order': 4,
                'topics': [
                    'Cumhurbaşkanlığı Sistemi',
                    'Cumhurbaşkanlığı Kararnamesi',
                    'Olağanüstü Hal Yönetimi',
                ]
            },
            {
                'name': 'Yargı',
                'order': 5,
                'topics': [
                    'Yargı Organı Genel',
                    'Anayasa Mahkemesi',
                    'İptal Davası',
                    'İtiraz Yolu',
                    'Bireysel Başvuru',
                ]
            },
        ]
    },
    
    'medeni_hukuk': {
        'name': 'Medeni Hukuk',
        'order': 2,
        'groups': [
            {
                'name': 'Başlangıç Hükümleri',
                'order': 1,
                'topics': [
                    'Hukukun Uygulanması',
                    'Dürüstlük Kuralı ve İyiniyet',
                    'İspat Yükü',
                ]
            },
            {
                'name': 'Kişiler Hukuku',
                'order': 2,
                'topics': [
                    'Gerçek Kişiler',
                    'Kişiliğin Başlangıcı ve Sonu',
                    'Hak Ehliyeti',
                    'Fiil Ehliyeti',
                    'Kısıtlılık ve Vesayet',
                    'Kişiliğin Korunması',
                    'Ad ve Yerleşim Yeri',
                ]
            },
            {
                'name': 'Tüzel Kişiler',
                'order': 3,
                'topics': [
                    'Tüzel Kişi Genel',
                    'Dernekler',
                    'Vakıflar',
                ]
            },
            {
                'name': 'Aile Hukuku',
                'order': 4,
                'topics': [
                    'Nişanlanma',
                    'Evlenme ve Evlenme Engelleri',
                    'Boşanma ve Sebepleri',
                    'Mal Rejimleri',
                    'Edinilmiş Mallara Katılma',
                    'Soybağı',
                    'Evlat Edinme',
                    'Velayet',
                    'Nafaka',
                ]
            },
            {
                'name': 'Miras Hukuku',
                'order': 5,
                'topics': [
                    'Miras Hukuku Genel',
                    'Yasal Mirasçılar',
                    'Saklı Pay',
                    'Vasiyetname',
                    'Miras Sözleşmesi',
                    'Mirasın Geçişi',
                ]
            },
            {
                'name': 'Eşya Hukuku',
                'order': 6,
                'topics': [
                    'Eşya Hukuku Genel',
                    'Zilyetlik',
                    'Tapu Sicili',
                    'Mülkiyet',
                    'Taşınmaz Mülkiyeti',
                    'Kat Mülkiyeti',
                    'Sınırlı Ayni Haklar',
                    'İrtifak Hakları',
                    'Rehin Hakları ve İpotek',
                ]
            },
        ]
    },
    
    'borclar_hukuku': {
        'name': 'Borçlar Hukuku',
        'order': 3,
        'groups': [
            {
                'name': 'Borç İlişkisi Genel',
                'order': 1,
                'topics': [
                    'Borç İlişkisinin Kaynakları',
                    'Sözleşmeden Doğan Borçlar',
                    'Sözleşmenin Kurulması',
                    'İrade Bozuklukları',
                    'Temsil',
                ]
            },
            {
                'name': 'Haksız Fiil',
                'order': 2,
                'topics': [
                    'Haksız Fiil Genel',
                    'Kusur Sorumluluğu',
                    'Kusursuz Sorumluluk',
                    'Tazminat',
                ]
            },
            {
                'name': 'Sebepsiz Zenginleşme',
                'order': 3,
                'topics': [
                    'Sebepsiz Zenginleşme Şartları',
                    'İade Borcu',
                ]
            },
            {
                'name': 'Borcun İfası',
                'order': 4,
                'topics': [
                    'İfa Genel',
                    'İfa Yeri ve Zamanı',
                    'Alacaklı Temerrüdü',
                    'Borçlu Temerrüdü',
                ]
            },
            {
                'name': 'Borç İlişkisinin Sona Ermesi',
                'order': 5,
                'topics': [
                    'İfa ile Sona Erme',
                    'İbra',
                    'Yenileme',
                    'Takas',
                    'Zamanaşımı',
                ]
            },
            {
                'name': 'Özel Borç İlişkileri',
                'order': 6,
                'topics': [
                    'Satış Sözleşmesi',
                    'Kira Sözleşmesi',
                    'Eser Sözleşmesi',
                    'Vekalet Sözleşmesi',
                    'Hizmet Sözleşmesi',
                    'Kefalet Sözleşmesi',
                ]
            },
        ]
    },
    
    'ceza_hukuku': {
        'name': 'Ceza Hukuku',
        'order': 4,
        'groups': [
            {
                'name': 'Ceza Hukukuna Giriş',
                'order': 1,
                'topics': [
                    'Ceza Hukukunun Temel İlkeleri',
                    'Suçta ve Cezada Kanunilik',
                    'Ceza Kanununun Uygulanması',
                ]
            },
            {
                'name': 'Suç Genel Teorisi',
                'order': 2,
                'topics': [
                    'Suçun Unsurları',
                    'Maddi Unsur (Fiil)',
                    'Manevi Unsur (Kast ve Taksir)',
                    'Hukuka Aykırılık',
                    'Kusur',
                ]
            },
            {
                'name': 'Suça İştirak',
                'order': 3,
                'topics': [
                    'Faillik Türleri',
                    'Azmettirme',
                    'Yardım Etme',
                ]
            },
            {
                'name': 'Suçun Özel Görünüş Biçimleri',
                'order': 4,
                'topics': [
                    'Teşebbüs',
                    'İçtima',
                    'Zincirleme Suç',
                ]
            },
            {
                'name': 'Yaptırımlar',
                'order': 5,
                'topics': [
                    'Ceza Türleri',
                    'Güvenlik Tedbirleri',
                    'Cezanın Belirlenmesi',
                    'Erteleme ve Hükmün Açıklanmasının Geri Bırakılması',
                ]
            },
            {
                'name': 'Hayata Karşı Suçlar',
                'order': 6,
                'topics': [
                    'Kasten Öldürme',
                    'Taksirle Öldürme',
                    'İntihara Yönlendirme',
                ]
            },
            {
                'name': 'Vücut Dokunulmazlığına Karşı Suçlar',
                'order': 7,
                'topics': [
                    'Kasten Yaralama',
                    'Taksirle Yaralama',
                    'İşkence ve Eziyet',
                ]
            },
            {
                'name': 'Cinsel Dokunulmazlığa Karşı Suçlar',
                'order': 8,
                'topics': [
                    'Cinsel Saldırı',
                    'Çocukların Cinsel İstismarı',
                    'Cinsel Taciz',
                ]
            },
            {
                'name': 'Hürriyete Karşı Suçlar',
                'order': 9,
                'topics': [
                    'Tehdit',
                    'Şantaj',
                    'Cebir',
                    'Kişiyi Hürriyetinden Yoksun Kılma',
                    'Konut Dokunulmazlığını İhlal',
                ]
            },
            {
                'name': 'Malvarlığına Karşı Suçlar',
                'order': 10,
                'topics': [
                    'Hırsızlık',
                    'Yağma',
                    'Mala Zarar Verme',
                    'Güveni Kötüye Kullanma',
                    'Dolandırıcılık',
                ]
            },
            {
                'name': 'Kamu İdaresine Karşı Suçlar',
                'order': 11,
                'topics': [
                    'Zimmet',
                    'Rüşvet',
                    'Görevi Kötüye Kullanma',
                    'İrtikap',
                    'Resmi Belgede Sahtecilik',
                ]
            },
        ]
    },
    
    'ceza_muhakemesi': {
        'name': 'Ceza Muhakemesi Hukuku',
        'order': 5,
        'groups': [
            {
                'name': 'Ceza Muhakemesine Giriş',
                'order': 1,
                'topics': [
                    'Ceza Muhakemesinin Temel İlkeleri',
                    'Muhakeme Süjeleri',
                    'Yetki Kuralları',
                ]
            },
            {
                'name': 'Soruşturma',
                'order': 2,
                'topics': [
                    'Soruşturmanın Başlaması',
                    'Cumhuriyet Savcısının Görevleri',
                    'İfade Alma ve Sorgu',
                    'Gözaltı',
                    'Tutuklama',
                    'Adli Kontrol',
                ]
            },
            {
                'name': 'Deliller',
                'order': 3,
                'topics': [
                    'Delil Genel',
                    'Arama ve Elkoyma',
                    'İletişimin Denetlenmesi',
                    'Gizli Soruşturmacı',
                    'Tanık ve Bilirkişi',
                ]
            },
            {
                'name': 'Kovuşturma',
                'order': 4,
                'topics': [
                    'İddianame',
                    'Duruşma',
                    'Delillerin Tartışılması',
                    'Hüküm',
                ]
            },
            {
                'name': 'Kanun Yolları',
                'order': 5,
                'topics': [
                    'İtiraz',
                    'İstinaf',
                    'Temyiz',
                    'Yargılamanın Yenilenmesi',
                ]
            },
        ]
    },
    
    'idare_hukuku': {
        'name': 'İdare Hukuku',
        'order': 6,
        'groups': [
            {
                'name': 'İdare Hukukuna Giriş',
                'order': 1,
                'topics': [
                    'İdare Kavramı',
                    'İdare Hukukunun Kaynakları',
                    'İdarenin Bütünlüğü İlkesi',
                ]
            },
            {
                'name': 'İdari Teşkilat',
                'order': 2,
                'topics': [
                    'Merkezi İdare',
                    'Yerinden Yönetim',
                    'Mahalli İdareler',
                    'Hizmet Yerinden Yönetim',
                    'Kamu Tüzel Kişileri',
                ]
            },
            {
                'name': 'İdari İşlemler',
                'order': 3,
                'topics': [
                    'İdari İşlem Kavramı',
                    'Düzenleyici İşlemler',
                    'Bireysel İşlemler',
                    'İdari İşlemin Unsurları',
                    'İdari İşlemin Sona Ermesi',
                ]
            },
            {
                'name': 'İdari Sözleşmeler',
                'order': 4,
                'topics': [
                    'İdari Sözleşme Türleri',
                    'Kamu İhale Kanunu',
                    'İmtiyaz Sözleşmeleri',
                ]
            },
            {
                'name': 'Kamu Görevlileri',
                'order': 5,
                'topics': [
                    'Memur Kavramı',
                    'Memurluğa Giriş',
                    'Memurun Hakları ve Yükümlülükleri',
                    'Disiplin Hukuku',
                ]
            },
            {
                'name': 'Kolluk',
                'order': 6,
                'topics': [
                    'Kolluk Kavramı',
                    'İdari Kolluk ve Adli Kolluk',
                    'Kolluk Yetkileri',
                ]
            },
            {
                'name': 'Kamu Malları',
                'order': 7,
                'topics': [
                    'Kamu Malı Kavramı',
                    'Kamulaştırma',
                    'İstimval',
                ]
            },
            {
                'name': 'İdarenin Sorumluluğu',
                'order': 8,
                'topics': [
                    'Hizmet Kusuru',
                    'Kusursuz Sorumluluk',
                    'Risk İlkesi',
                    'Fedakarlığın Denkleştirilmesi',
                ]
            },
        ]
    },
    
    'idari_yargilama': {
        'name': 'İdari Yargılama Hukuku',
        'order': 7,
        'groups': [
            {
                'name': 'İdari Yargı Teşkilatı',
                'order': 1,
                'topics': [
                    'İdare Mahkemeleri',
                    'Bölge İdare Mahkemeleri',
                    'Danıştay',
                ]
            },
            {
                'name': 'İdari Davalar',
                'order': 2,
                'topics': [
                    'İptal Davası',
                    'Tam Yargı Davası',
                    'İdari Sözleşme Davaları',
                ]
            },
            {
                'name': 'Dava Açma Koşulları',
                'order': 3,
                'topics': [
                    'Ehliyet',
                    'Süre',
                    'İdari Merci Tecavüzü',
                    'Yürütmenin Durdurulması',
                ]
            },
            {
                'name': 'Yargılama Usulü',
                'order': 4,
                'topics': [
                    'Yargılama İlkeleri',
                    'Duruşma',
                    'Karar',
                    'Kanun Yolları',
                ]
            },
        ]
    },
    
    'hmk': {
        'name': 'Hukuk Muhakemeleri Kanunu',
        'order': 8,
        'groups': [
            {
                'name': 'Temel İlkeler',
                'order': 1,
                'topics': [
                    'Medeni Yargının Amacı',
                    'Hukuki Dinlenilme Hakkı',
                    'Tasarruf ve Taraflarca Getirilme',
                    'Taleple Bağlılık',
                ]
            },
            {
                'name': 'Görev ve Yetki',
                'order': 2,
                'topics': [
                    'Görev Kuralları',
                    'Yetki Kuralları',
                    'Yetki Sözleşmesi',
                ]
            },
            {
                'name': 'Dava',
                'order': 3,
                'topics': [
                    'Dava Şartları',
                    'Dava Çeşitleri',
                    'Dava Açılması',
                    'Davaya Cevap',
                    'Islah',
                ]
            },
            {
                'name': 'Taraflar',
                'order': 4,
                'topics': [
                    'Taraf Ehliyeti',
                    'Dava Ehliyeti',
                    'Davaya Vekalet',
                    'Dava Arkadaşlığı',
                    'Fer\'i Müdahale',
                    'Asli Müdahale',
                ]
            },
            {
                'name': 'İspat',
                'order': 5,
                'topics': [
                    'İspat Yükü',
                    'Delil Sistemi',
                    'Senet',
                    'Yemin',
                    'Tanık',
                    'Bilirkişi',
                    'Keşif',
                ]
            },
            {
                'name': 'Yargılama',
                'order': 6,
                'topics': [
                    'Ön İnceleme',
                    'Tahkikat',
                    'Sözlü Yargılama',
                    'Hüküm',
                ]
            },
            {
                'name': 'Kanun Yolları',
                'order': 7,
                'topics': [
                    'İstinaf',
                    'Temyiz',
                    'Yargılamanın İadesi',
                ]
            },
            {
                'name': 'Geçici Hukuki Koruma',
                'order': 8,
                'topics': [
                    'İhtiyati Tedbir',
                    'İhtiyati Haciz',
                    'Delil Tespiti',
                ]
            },
        ]
    },
    
    'ticaret_hukuku': {
        'name': 'Ticaret Hukuku',
        'order': 9,
        'groups': [
            {
                'name': 'Ticari İşletme',
                'order': 1,
                'topics': [
                    'Ticari İşletme Kavramı',
                    'Tacir',
                    'Ticaret Sicili',
                    'Ticaret Unvanı',
                    'Haksız Rekabet',
                ]
            },
            {
                'name': 'Şirketler Hukuku Genel',
                'order': 2,
                'topics': [
                    'Şirket Kavramı ve Türleri',
                    'Adi Şirket',
                    'Kollektif Şirket',
                    'Komandit Şirket',
                ]
            },
            {
                'name': 'Sermaye Şirketleri',
                'order': 3,
                'topics': [
                    'Anonim Şirket Kuruluşu',
                    'Anonim Şirket Organları',
                    'Yönetim Kurulu',
                    'Genel Kurul',
                    'Limited Şirket',
                ]
            },
            {
                'name': 'Kıymetli Evrak',
                'order': 4,
                'topics': [
                    'Kıymetli Evrak Genel',
                    'Poliçe',
                    'Bono',
                    'Çek',
                ]
            },
        ]
    },
    
    'icra_iflas': {
        'name': 'İcra ve İflas Hukuku',
        'order': 10,
        'groups': [
            {
                'name': 'İcra Hukuku Genel',
                'order': 1,
                'topics': [
                    'İcra Teşkilatı',
                    'İcra Takibinin Tarafları',
                    'Şikayet',
                ]
            },
            {
                'name': 'İlamsız İcra',
                'order': 2,
                'topics': [
                    'Genel Haciz Yolu',
                    'Ödeme Emri',
                    'İtiraz',
                    'İtirazın Kaldırılması',
                    'İtirazın İptali',
                ]
            },
            {
                'name': 'İlamlı İcra',
                'order': 3,
                'topics': [
                    'İlamlı İcra Genel',
                    'İcra Emri',
                    'İlamın İcrası',
                ]
            },
            {
                'name': 'Haciz',
                'order': 4,
                'topics': [
                    'Haciz İşlemi',
                    'Haczi Caiz Olmayan Mallar',
                    'Üçüncü Kişinin İstihkak İddiası',
                    'Haczedilen Malların Satışı',
                    'Paraların Paylaştırılması',
                ]
            },
            {
                'name': 'İflas Hukuku',
                'order': 5,
                'topics': [
                    'İflas Sebepleri',
                    'İflasın Açılması',
                    'İflas Masası',
                    'İflas Tasfiyesi',
                    'Konkordato',
                ]
            },
        ]
    },
    
    'is_hukuku': {
        'name': 'İş ve Sosyal Güvenlik Hukuku',
        'order': 11,
        'groups': [
            {
                'name': 'Bireysel İş Hukuku',
                'order': 1,
                'topics': [
                    'İş Hukukunun Kaynakları',
                    'İşçi ve İşveren Kavramı',
                    'İş Sözleşmesi Türleri',
                    'İş Sözleşmesinin Kurulması',
                ]
            },
            {
                'name': 'İş Sözleşmesinin Hükümleri',
                'order': 2,
                'topics': [
                    'İşçinin Borçları',
                    'İşverenin Borçları',
                    'Ücret',
                    'Çalışma Süreleri',
                    'Dinlenme Süreleri',
                ]
            },
            {
                'name': 'İş Sözleşmesinin Sona Ermesi',
                'order': 3,
                'topics': [
                    'Fesih Genel',
                    'Bildirimli Fesih',
                    'Haklı Nedenle Fesih',
                    'İş Güvencesi',
                    'Kıdem Tazminatı',
                ]
            },
            {
                'name': 'Toplu İş Hukuku',
                'order': 4,
                'topics': [
                    'Sendikalar',
                    'Toplu İş Sözleşmesi',
                    'Grev ve Lokavt',
                ]
            },
            {
                'name': 'Sosyal Güvenlik',
                'order': 5,
                'topics': [
                    'Sosyal Güvenlik Kavramı',
                    'Sosyal Sigortalar',
                    'Emeklilik',
                ]
            },
        ]
    },
    
    'vergi_hukuku': {
        'name': 'Vergi Hukuku',
        'order': 12,
        'groups': [
            {
                'name': 'Vergi Hukuku Genel',
                'order': 1,
                'topics': [
                    'Vergi Kavramı',
                    'Verginin Unsurları',
                    'Vergilendirme İlkeleri',
                    'Vergi Kanunlarının Uygulanması',
                ]
            },
            {
                'name': 'Vergi Borcu',
                'order': 2,
                'topics': [
                    'Vergiyi Doğuran Olay',
                    'Mükellef ve Vergi Sorumlusu',
                    'Vergi Borcunun Sona Ermesi',
                    'Zamanaşımı',
                ]
            },
            {
                'name': 'Vergi Türleri',
                'order': 3,
                'topics': [
                    'Gelir Vergisi',
                    'Kurumlar Vergisi',
                    'Katma Değer Vergisi',
                    'Özel Tüketim Vergisi',
                    'Veraset ve İntikal Vergisi',
                ]
            },
            {
                'name': 'Vergi Yargısı',
                'order': 4,
                'topics': [
                    'Vergi Uyuşmazlıkları',
                    'Vergi Davaları',
                    'Uzlaşma',
                ]
            },
        ]
    },
    
    'milletlerarasi_hukuk': {
        'name': 'Milletlerarası Hukuk',
        'order': 13,
        'groups': [
            {
                'name': 'Devletler Genel Hukuku',
                'order': 1,
                'topics': [
                    'Uluslararası Hukukun Kaynakları',
                    'Devlet ve Tanıma',
                    'Uluslararası Andlaşmalar',
                    'Uluslararası Örgütler',
                ]
            },
            {
                'name': 'Devletler Özel Hukuku',
                'order': 2,
                'topics': [
                    'Yabancılar Hukuku',
                    'Vatandaşlık',
                    'Kanunlar İhtilafı',
                    'Milletlerarası Usul Hukuku',
                ]
            },
        ]
    },
    
    'avukatlik_hukuku': {
        'name': 'Avukatlık Hukuku',
        'order': 14,
        'groups': [
            {
                'name': 'Avukatlık Mesleği',
                'order': 1,
                'topics': [
                    'Avukatlık Mesleğine Giriş',
                    'Avukatın Hak ve Yükümlülükleri',
                    'Avukatlık Sözleşmesi',
                    'Avukatlık Ücreti',
                ]
            },
            {
                'name': 'Baro',
                'order': 2,
                'topics': [
                    'Baro Teşkilatı',
                    'Türkiye Barolar Birliği',
                    'Disiplin İşlemleri',
                ]
            },
        ]
    },
    
    'hukuk_felsefesi': {
        'name': 'Hukuk Felsefesi ve Sosyolojisi',
        'order': 15,
        'groups': [
            {
                'name': 'Hukuk Felsefesi',
                'order': 1,
                'topics': [
                    'Hukuk Kavramı',
                    'Doğal Hukuk',
                    'Hukuki Pozitivizm',
                    'Tarihçi Hukuk Okulu',
                ]
            },
            {
                'name': 'Hukuk Sosyolojisi',
                'order': 2,
                'topics': [
                    'Hukuk ve Toplum',
                    'Hukukun Sosyal İşlevleri',
                ]
            },
        ]
    },
}


def clear_topics():
    """Mevcut tüm topics'i sil"""
    print("🗑️  Mevcut topics temizleniyor...")
    
    topics_ref = db.collection('topics')
    docs = topics_ref.stream()
    
    batch = db.batch()
    count = 0
    
    for doc in docs:
        batch.delete(doc.reference)
        count += 1
        
        if count % 400 == 0:
            batch.commit()
            batch = db.batch()
            print(f"   {count} topic silindi...")
    
    if count % 400 != 0:
        batch.commit()
    
    print(f"✅ {count} topic silindi")
    return count


def get_subject_ids():
    """Mevcut subjects'lerin ID'lerini al"""
    subjects = {}
    docs = db.collection('subjects').stream()
    for doc in docs:
        data = doc.to_dict()
        name = data.get('name', '')
        subjects[name] = doc.id
    return subjects


def seed_hierarchical_curriculum():
    """Hiyerarşik müfredatı yükle"""
    print("\n📚 Hiyerarşik müfredat yükleniyor...")
    
    subject_ids = get_subject_ids()
    print(f"   Bulunan dersler: {list(subject_ids.keys())}")
    
    total_groups = 0
    total_topics = 0
    
    for subject_key, subject_data in HIERARCHICAL_CURRICULUM.items():
        subject_name = subject_data['name']
        
        # Subject ID'yi bul
        subject_id = subject_ids.get(subject_name)
        if not subject_id:
            print(f"⚠️  '{subject_name}' için subject bulunamadı, atlanıyor...")
            continue
        
        groups = subject_data['groups']
        group_count = 0
        topic_count = 0
        
        for group in groups:
            # Ana başlık (parent topic) oluştur
            parent_ref = db.collection('topics').document()
            parent_id = parent_ref.id
            
            parent_ref.set({
                'id': parent_id,
                'subjectId': subject_id,
                'parentId': None,  # Ana başlık
                'name': group['name'],
                'description': f"{subject_name} - {group['name']}",
                'order': group['order'],
                'isActive': True,
                'questionCount': 0,
                'createdAt': firestore.SERVER_TIMESTAMP,
                'updatedAt': firestore.SERVER_TIMESTAMP,
            })
            group_count += 1
            
            # Alt konuları oluştur
            for idx, topic_name in enumerate(group['topics'], 1):
                topic_ref = db.collection('topics').document()
                topic_id = topic_ref.id
                
                topic_ref.set({
                    'id': topic_id,
                    'subjectId': subject_id,
                    'parentId': parent_id,  # Ana başlığa bağlı
                    'name': topic_name,
                    'description': None,
                    'order': idx,
                    'isActive': True,
                    'questionCount': 0,
                    'createdAt': firestore.SERVER_TIMESTAMP,
                    'updatedAt': firestore.SERVER_TIMESTAMP,
                })
                topic_count += 1
        
        total_groups += group_count
        total_topics += topic_count
        print(f"📚 {subject_name}: {group_count} başlık, {topic_count} alt konu")
    
    return total_groups, total_topics


if __name__ == '__main__':
    print("=" * 60)
    print("HMGS HİYERARŞİK MÜFREDAT YÜKLEME")
    print("=" * 60)
    
    # 1. Mevcut topics'i temizle
    deleted = clear_topics()
    
    # 2. Hiyerarşik müfredatı yükle
    groups, topics = seed_hierarchical_curriculum()
    
    print("\n" + "=" * 60)
    print(f"✅ TAMAMLANDI!")
    print(f"   - Silinen eski topic: {deleted}")
    print(f"   - Yeni ana başlık: {groups}")
    print(f"   - Yeni alt konu: {topics}")
    print(f"   - TOPLAM: {groups + topics}")
    print("=" * 60)
