"""
HMGS Müfredat Seed Script
- Tüm dersleri ve alt konularını Firestore'a yükler
- Her konu için özet ve açıklama içerir
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

# ============================================================
# HMGS MÜFREDATI - TÜM DERSLER VE ALT KONULAR
# ============================================================

CURRICULUM = {
    'anayasa_hukuku': {
        'name': 'Anayasa Hukuku',
        'description': 'Devletin temel yapısı, temel hak ve özgürlükler, anayasal kurumlar',
        'order': 1,
        'icon': 'gavel',
        'topics': [
            {
                'id': 'anayasa_genel',
                'name': 'Anayasa Hukukuna Giriş',
                'description': 'Anayasa kavramı, anayasacılık hareketleri, anayasa türleri',
                'summary': 'Anayasa, devletin temel yapısını ve işleyişini düzenleyen en üst hukuk normudur. Yazılı/yazısız, sert/yumuşak anayasa ayrımları önemlidir.',
                'order': 1
            },
            {
                'id': 'temel_haklar',
                'name': 'Temel Hak ve Özgürlükler',
                'description': 'Kişi hakları, sosyal haklar, siyasi haklar ve sınırlandırma rejimi',
                'summary': 'AY m.13: Temel haklar özlerine dokunulmaksızın, kanunla, ölçülülük ilkesine uygun olarak sınırlanabilir. Çekirdek alan dokunulmazdır.',
                'order': 2
            },
            {
                'id': 'yasama',
                'name': 'Yasama Organı',
                'description': 'TBMM yapısı, milletvekilliği, kanun yapım süreci, meclis denetimi',
                'summary': 'TBMM 600 milletvekilinden oluşur. Kanunlar cumhurbaşkanına 15 gün içinde gönderilir. Cumhurbaşkanı geri gönderirse meclis salt çoğunlukla aynen kabul edebilir.',
                'order': 3
            },
            {
                'id': 'yurutme',
                'name': 'Yürütme Organı',
                'description': 'Cumhurbaşkanlığı, Cumhurbaşkanlığı kararnameleri, olağanüstü hal',
                'summary': 'Cumhurbaşkanlığı hükümet sistemi: Cumhurbaşkanı hem devlet başkanı hem hükümet başkanı. CBK ile düzenleme yetkisi var ancak temel haklar kanunla düzenlenir.',
                'order': 4
            },
            {
                'id': 'yargi',
                'name': 'Yargı Organı',
                'description': 'Mahkemeler, yüksek yargı organları, hakimlik teminatı',
                'summary': 'Yargı bağımsızlığı ve hakim teminatı esastır. Anayasa Mahkemesi, Yargıtay, Danıştay, Uyuşmazlık Mahkemesi yüksek yargı organlarıdır.',
                'order': 5
            },
            {
                'id': 'anayasa_yargisi',
                'name': 'Anayasa Yargısı',
                'description': 'Anayasa Mahkemesi, norm denetimi, bireysel başvuru',
                'summary': 'İptal davası: Cumhurbaşkanı, TBMM üye tamsayısının 1/5i, iktidar ve anamuhalefet grupları. İtiraz yolu: Görülmekte olan davada mahkemeler başvurabilir.',
                'order': 6
            }
        ]
    },
    
    'medeni_hukuk': {
        'name': 'Medeni Hukuk',
        'description': 'Kişiler, aile, miras ve eşya hukuku',
        'order': 2,
        'icon': 'family_restroom',
        'topics': [
            {
                'id': 'kisiler_hukuku',
                'name': 'Kişiler Hukuku',
                'description': 'Gerçek kişiler, tüzel kişiler, ehliyet, kişilik hakları',
                'summary': 'Hak ehliyeti doğumla başlar ölümle sona erer. Fiil ehliyeti için ayırt etme gücü, erginlik ve kısıtlı olmamak gerekir. TMK m.8-50.',
                'order': 1
            },
            {
                'id': 'aile_hukuku',
                'name': 'Aile Hukuku',
                'description': 'Nişanlanma, evlenme, boşanma, soybağı, velayet, nafaka',
                'summary': 'Evlenme yaşı 18, hakim izniyle 17. Boşanma sebepleri: özel (zina, hayata kast, pek kötü muamele, suç, terk, akıl hastalığı) ve genel (evlilik birliğinin sarsılması).',
                'order': 2
            },
            {
                'id': 'miras_hukuku',
                'name': 'Miras Hukuku',
                'description': 'Yasal mirasçılar, ölüme bağlı tasarruflar, saklı pay, mirasın geçişi',
                'summary': 'Yasal mirasçılar: Altsoy, anne-baba, büyükanne-büyükbaba zümreleri ve sağ kalan eş. Saklı pay oranları: Altsoy 1/2, anne-baba 1/4, eş zümreye göre değişir.',
                'order': 3
            },
            {
                'id': 'esya_hukuku',
                'name': 'Eşya Hukuku',
                'description': 'Zilyetlik, tapu sicili, mülkiyet, sınırlı ayni haklar',
                'summary': 'Mülkiyet taşınmazlarda tescille, taşınırlarda teslimle kazanılır. Tapu sicili: Ana sicil (kütük) + yardımcı siciller. İyiniyetli üçüncü kişi sicile güvenerek hak kazanır.',
                'order': 4
            }
        ]
    },
    
    'borclar_hukuku': {
        'name': 'Borçlar Hukuku',
        'description': 'Borç ilişkisinin kaynakları, hükümleri ve sona ermesi',
        'order': 3,
        'icon': 'handshake',
        'topics': [
            {
                'id': 'borcun_kaynaklari',
                'name': 'Borcun Kaynakları',
                'description': 'Sözleşme, haksız fiil, sebepsiz zenginleşme',
                'summary': 'Borç kaynakları: Hukuki işlem (sözleşme, tek taraflı), haksız fiil (TBK m.49+), sebepsiz zenginleşme (TBK m.77+), kanun.',
                'order': 1
            },
            {
                'id': 'sozlesme_hukuku',
                'name': 'Sözleşme Hukuku',
                'description': 'Sözleşmenin kurulması, geçerliliği, hükümsüzlüğü',
                'summary': 'Sözleşme icap + kabul ile kurulur. Şekil serbestisi esastır. Kesin hükümsüzlük (butlan), iptal edilebilirlik, eksiklik halleri.',
                'order': 2
            },
            {
                'id': 'borcun_ifasi',
                'name': 'Borcun İfası ve Sona Ermesi',
                'description': 'İfa, ifa engelleri, temerrüt, zamanaşımı',
                'summary': 'İfa borcu sona erdirir. Borçlu temerrüdü: İfa zamanı gelmiş, muaccel, ihtar yapılmış. Alacaklı temerrüdü: Haklı neden olmaksızın ifayı reddetme.',
                'order': 3
            },
            {
                'id': 'ozel_borc_iliskileri',
                'name': 'Özel Borç İlişkileri',
                'description': 'Satış, kira, eser, vekalet, hizmet sözleşmeleri',
                'summary': 'Satış sözleşmesi: Taşınır/taşınmaz ayrımı. Kira: Konut ve çatılı işyeri kirası özel düzenleme. Eser sözleşmesi: Sonuç taahhüdü.',
                'order': 4
            }
        ]
    },
    
    'ceza_hukuku': {
        'name': 'Ceza Hukuku',
        'description': 'Suç teorisi, yaptırımlar, suç türleri',
        'order': 4,
        'icon': 'security',
        'topics': [
            {
                'id': 'ceza_genel',
                'name': 'Ceza Hukuku Genel Hükümler',
                'description': 'Suçun unsurları, kusurluluk, teşebbüs, iştirak, içtima',
                'summary': 'Suçun unsurları: Maddi unsur (hareket, netice, nedensellik), manevi unsur (kast, taksir), hukuka aykırılık. TCK m.20-75.',
                'order': 1
            },
            {
                'id': 'ceza_ozel',
                'name': 'Ceza Hukuku Özel Hükümler',
                'description': 'Hayata, vücut bütünlüğüne, mala karşı suçlar',
                'summary': 'Önemli suçlar: Kasten öldürme (m.81), yaralama (m.86), hırsızlık (m.141), dolandırıcılık (m.157), güveni kötüye kullanma (m.155).',
                'order': 2
            },
            {
                'id': 'yaptirimlar',
                'name': 'Yaptırımlar',
                'description': 'Cezalar, güvenlik tedbirleri, erteleme, hükmün açıklanmasının geri bırakılması',
                'summary': 'Hapis cezası türleri: Ağırlaştırılmış müebbet, müebbet, süreli. Adli para cezası gün karşılığı hesaplanır. HAGB için 2 yıl veya daha az ceza şartı.',
                'order': 3
            }
        ]
    },
    
    'ceza_muhakemesi': {
        'name': 'Ceza Muhakemesi Hukuku',
        'description': 'Ceza yargılama usulü, deliller, koruma tedbirleri, kanun yolları',
        'order': 5,
        'icon': 'balance',
        'topics': [
            {
                'id': 'cmk_genel',
                'name': 'Temel İlkeler ve Kavramlar',
                'description': 'Muhakeme süjeleri, görev ve yetki, süreler',
                'summary': 'CMK ilkeleri: Masumiyet karinesi, şüpheden sanık yararlanır, delil serbestisi, doğrudan doğruyalık, sözlülük.',
                'order': 1
            },
            {
                'id': 'koruma_tedbirleri',
                'name': 'Koruma Tedbirleri',
                'description': 'Yakalama, gözaltı, tutuklama, arama, elkoyma',
                'summary': 'Tutuklama: Kuvvetli suç şüphesi + tutuklama nedeni (kaçma, delil karartma şüphesi). Azami süreler: Ağır ceza 2+3 yıl, diğer 1+6 ay.',
                'order': 2
            },
            {
                'id': 'yargilama',
                'name': 'Yargılama Aşaması',
                'description': 'Soruşturma, kovuşturma, duruşma, deliller',
                'summary': 'Soruşturma: Savcılık yürütür, şüpheli. Kovuşturma: İddianameyle başlar, sanık. Delil değerlendirmesi hakime aittir.',
                'order': 3
            },
            {
                'id': 'kanun_yollari',
                'name': 'Kanun Yolları',
                'description': 'İtiraz, istinaf, temyiz, yargılamanın yenilenmesi',
                'summary': 'İstinaf: BAM incelemesi, hem maddi hem hukuki. Temyiz: Yargıtay, sadece hukuki denetim. Olağanüstü: Kanun yararına bozma, yargılamanın yenilenmesi.',
                'order': 4
            }
        ]
    },
    
    'idare_hukuku': {
        'name': 'İdare Hukuku',
        'description': 'İdarenin örgütlenmesi, işlemleri, sözleşmeleri ve sorumluluğu',
        'order': 6,
        'icon': 'account_balance',
        'topics': [
            {
                'id': 'idare_teskilat',
                'name': 'İdari Teşkilat',
                'description': 'Merkezi idare, yerinden yönetim, kamu tüzel kişileri',
                'summary': 'Merkezi idare: Cumhurbaşkanlığı, bakanlıklar, taşra teşkilatı. Yerinden yönetim: Mahalli idareler (belediye, il özel idaresi, köy), hizmet yerinden yönetim.',
                'order': 1
            },
            {
                'id': 'idari_islemler',
                'name': 'İdari İşlemler',
                'description': 'Bireysel işlemler, düzenleyici işlemler, idari sözleşmeler',
                'summary': 'İdari işlem unsurları: Yetki, şekil, sebep, konu, amaç. Düzenleyici işlemler: Tüzük, yönetmelik, CBK. Hukuka aykırılık yaptırımı: Yokluk veya iptal.',
                'order': 2
            },
            {
                'id': 'kamu_gorevlileri',
                'name': 'Kamu Görevlileri',
                'description': 'Memurlar, sözleşmeli personel, disiplin hukuku',
                'summary': 'Memur: Kariyer, liyakat, sınıflandırma ilkeleri. Atama, ilerleme, disiplin cezaları. 657 sayılı DMK temel düzenleme.',
                'order': 3
            },
            {
                'id': 'idari_sorumluluk',
                'name': 'İdarenin Sorumluluğu',
                'description': 'Hizmet kusuru, kusursuz sorumluluk, tam yargı davası',
                'summary': 'Hizmet kusuru: Hizmetin kötü, geç veya hiç işlememesi. Kusursuz sorumluluk: Risk, kamu külfetleri karşısında eşitlik, fedakarlığın denkleştirilmesi.',
                'order': 4
            }
        ]
    },
    
    'idari_yargilama': {
        'name': 'İdari Yargılama Hukuku',
        'description': 'İdari yargı teşkilatı, dava türleri, yargılama usulü',
        'order': 7,
        'icon': 'gavel',
        'topics': [
            {
                'id': 'idari_yargi_teskilat',
                'name': 'İdari Yargı Teşkilatı',
                'description': 'Danıştay, bölge idare mahkemeleri, idare ve vergi mahkemeleri',
                'summary': 'İdare mahkemeleri: Genel görevli. Vergi mahkemeleri: Vergi uyuşmazlıkları. Danıştay: Temyiz + ilk derece (bazı işlemler).',
                'order': 1
            },
            {
                'id': 'iptal_davasi',
                'name': 'İptal Davası',
                'description': 'Dava şartları, iptal nedenleri, kararın etkileri',
                'summary': 'İptal davası şartları: Kesin ve yürütülebilir işlem, menfaat ihlali, 60 gün süre. İptal nedenleri: Yetki, şekil, sebep, konu, amaç sakatlıkları.',
                'order': 2
            },
            {
                'id': 'tam_yargi',
                'name': 'Tam Yargı Davası',
                'description': 'Tazminat davaları, idari sözleşme uyuşmazlıkları',
                'summary': 'Tam yargı davası: İdarenin eylem ve işlemlerinden doğan zararların tazmini. İptal davasıyla birlikte veya sonra açılabilir.',
                'order': 3
            }
        ]
    },
    
    'hukuk_muhakemeleri': {
        'name': 'Hukuk Muhakemeleri Kanunu',
        'description': 'Medeni yargılama usulü, davalar, deliller, kanun yolları',
        'order': 8,
        'icon': 'description',
        'topics': [
            {
                'id': 'hmk_genel',
                'name': 'Temel İlkeler ve Kavramlar',
                'description': 'Görev, yetki, taraflar, süreler, tebligat',
                'summary': 'Dava şartları: Görev, yetki, taraf ve dava ehliyeti, hukuki yarar, kesin hüküm bulunmaması. HMK m.114-115.',
                'order': 1
            },
            {
                'id': 'dava_cesitleri',
                'name': 'Dava Çeşitleri',
                'description': 'Eda, tespit, belirsiz alacak, kısmi dava, dava arkadaşlığı',
                'summary': 'Eda davası: Bir şeyin yapılması/verilmesi. Tespit davası: Hukuki ilişkinin varlığı/yokluğu. Belirsiz alacak: Miktar belirlenemiyorsa.',
                'order': 2
            },
            {
                'id': 'ispat_delil',
                'name': 'İspat ve Deliller',
                'description': 'İspat yükü, delil türleri, delil sözleşmesi',
                'summary': 'İspat yükü: İddia eden ispatlar (HMK m.190). Kesin deliller: Senet, yemin, kesin hüküm. Takdiri deliller: Tanık, bilirkişi, keşif.',
                'order': 3
            },
            {
                'id': 'kanun_yollari_hmk',
                'name': 'Kanun Yolları',
                'description': 'İstinaf, temyiz, yargılamanın iadesi',
                'summary': 'İstinaf: 2 hafta içinde BAM. Temyiz: 2 hafta içinde Yargıtay. Parasal sınırlar her yıl güncellenir.',
                'order': 4
            }
        ]
    },
    
    'ticaret_hukuku': {
        'name': 'Ticaret Hukuku',
        'description': 'Ticari işletme, şirketler, kıymetli evrak',
        'order': 9,
        'icon': 'business',
        'topics': [
            {
                'id': 'ticari_isletme',
                'name': 'Ticari İşletme Hukuku',
                'description': 'Ticari işletme, tacir, ticaret sicili, ticaret unvanı',
                'summary': 'Ticari işletme: Esnaf sınırını aşan, gelir hedefli, devamlı, bağımsız faaliyet. Tacir: Ticari işletmeyi işleten gerçek/tüzel kişi.',
                'order': 1
            },
            {
                'id': 'sirketler',
                'name': 'Şirketler Hukuku',
                'description': 'Anonim, limited, kollektif, komandit şirketler',
                'summary': 'A.Ş.: Sermaye 250.000 TL (kayıtlı 500.000). Yönetim kurulu, genel kurul. Limited: 10.000 TL, 50 ortağa kadar, müdürler.',
                'order': 2
            },
            {
                'id': 'kiymetli_evrak',
                'name': 'Kıymetli Evrak Hukuku',
                'description': 'Poliçe, bono, çek, emtia senetleri',
                'summary': 'Çek: Görüldüğünde ödenir, ibraz süreleri (10 gün aynı yer, 1 ay farklı yer, 3 ay farklı ülke). Karşılıksız çek: Hapis + çek düzenleme yasağı.',
                'order': 3
            }
        ]
    },
    
    'icra_iflas': {
        'name': 'İcra ve İflas Hukuku',
        'description': 'Cebri icra, iflas, konkordato',
        'order': 10,
        'icon': 'account_balance_wallet',
        'topics': [
            {
                'id': 'icra_genel',
                'name': 'İcra Hukuku Genel',
                'description': 'İcra teşkilatı, takip türleri, şikayet, itiraz',
                'summary': 'Takip yolları: İlamlı icra, ilamsız icra (genel haciz, kambiyo, kiralanan tahliyesi). İtiraz: 7 gün içinde icra dairesine.',
                'order': 1
            },
            {
                'id': 'haciz',
                'name': 'Haciz ve Satış',
                'description': 'Haciz işlemleri, haczedilmezlik, satış usulü',
                'summary': 'Haciz: Borçlunun mallarına el koyma. Haczedilmezler: Lüzumlu eşya, meslek araçları, emekli maaşının 1/4ü hariç kısmı.',
                'order': 2
            },
            {
                'id': 'iflas',
                'name': 'İflas Hukuku',
                'description': 'İflas yolları, iflas masası, sıra cetveli',
                'summary': 'İflas yolları: Takipli iflas (genel, kambiyo), takipsiz (doğrudan, alacaklı talebi). İflas masası: Tüm malvarlığı tasfiye edilir.',
                'order': 3
            }
        ]
    },
    
    'is_hukuku': {
        'name': 'İş ve Sosyal Güvenlik Hukuku',
        'description': 'Bireysel iş hukuku, toplu iş hukuku, sosyal güvenlik',
        'order': 11,
        'icon': 'work',
        'topics': [
            {
                'id': 'is_sozlesmesi',
                'name': 'İş Sözleşmesi',
                'description': 'Sözleşme türleri, işçi-işveren borçları, çalışma süreleri',
                'summary': 'İş sözleşmesi: Bağımlılık + ücret. Belirli/belirsiz süreli, tam/kısmi zamanlı. Haftalık 45 saat, fazla çalışma %50 zamlı.',
                'order': 1
            },
            {
                'id': 'is_sozlesmesi_sona',
                'name': 'İş Sözleşmesinin Sona Ermesi',
                'description': 'Fesih, kıdem tazminatı, ihbar tazminatı, işe iade',
                'summary': 'İhbar süreleri: 0-6 ay: 2 hafta, 6-18 ay: 4 hafta, 18-36 ay: 6 hafta, 36+ ay: 8 hafta. Kıdem: Her yıl için 30 günlük brüt ücret.',
                'order': 2
            },
            {
                'id': 'sosyal_guvenlik',
                'name': 'Sosyal Güvenlik Hukuku',
                'description': 'SGK, primler, emeklilik, sağlık sigortası',
                'summary': 'Sigorta kolları: Kısa vadeli (iş kazası, hastalık, analık), uzun vadeli (malullük, yaşlılık, ölüm). Prim oranları işveren-işçi paylaşımlı.',
                'order': 3
            }
        ]
    },
    
    'vergi_hukuku': {
        'name': 'Vergi Hukuku',
        'description': 'Vergi hukukunun temel ilkeleri, vergi türleri, vergi yargısı',
        'order': 12,
        'icon': 'receipt_long',
        'topics': [
            {
                'id': 'vergi_genel',
                'name': 'Vergi Hukuku Genel',
                'description': 'Vergilendirme ilkeleri, vergi ödevi, mükellef hakları',
                'summary': 'Verginin yasallığı ilkesi: Vergi kanunla konulur. Vergilendirme unsurları: Konu, matrah, oran, mükellef, istisna, muafiyet.',
                'order': 1
            },
            {
                'id': 'vergi_turleri',
                'name': 'Vergi Türleri',
                'description': 'Gelir vergisi, kurumlar vergisi, KDV, ÖTV',
                'summary': 'Gelir vergisi: Gerçek kişi kazançları, artan oranlı. Kurumlar vergisi: Tüzel kişi kazançları, düz oranlı (%25). KDV: Tüketim vergisi.',
                'order': 2
            },
            {
                'id': 'vergi_yargi',
                'name': 'Vergi Yargısı',
                'description': 'Vergi mahkemeleri, vergi davası, uzlaşma',
                'summary': 'Vergi davası: 30 gün içinde vergi mahkemesine. Yürütmeyi durdurma talep edilebilir. İstinaf ve temyiz yolları açık.',
                'order': 3
            }
        ]
    },
    
    'milletlerarasi_hukuk': {
        'name': 'Milletlerarası Hukuk',
        'description': 'Devletler hukuku, uluslararası örgütler, insan hakları',
        'order': 13,
        'icon': 'public',
        'topics': [
            {
                'id': 'devletler_hukuku',
                'name': 'Devletler Genel Hukuku',
                'description': 'Uluslararası hukukun kaynakları, devlet, tanıma, antlaşmalar',
                'summary': 'Kaynaklar: Antlaşmalar, örf-adet, genel hukuk ilkeleri, içtihat, doktrin. Devletin unsurları: Ülke, insan topluluğu, egemenlik.',
                'order': 1
            },
            {
                'id': 'uluslararasi_orgutler',
                'name': 'Uluslararası Örgütler',
                'description': 'BM, AB, NATO, diğer örgütler',
                'summary': 'BM organları: Genel Kurul, Güvenlik Konseyi (5 daimi üye veto hakkı), Ekonomik Sosyal Konsey, Uluslararası Adalet Divanı.',
                'order': 2
            }
        ]
    },
    
    'avukatlik_hukuku': {
        'name': 'Avukatlık Hukuku',
        'description': 'Avukatlık mesleği, staj, baro, disiplin',
        'order': 14,
        'icon': 'person',
        'topics': [
            {
                'id': 'avukatlik_genel',
                'name': 'Avukatlık Mesleği',
                'description': 'Mesleğe kabul, staj, avukatın hak ve yükümlülükleri',
                'summary': 'Avukatlık şartları: TC vatandaşı, hukuk fakültesi, staj tamamlama, engel hal bulunmama. Staj süresi 1 yıl (6 ay mahkeme + 6 ay büro).',
                'order': 1
            },
            {
                'id': 'baro_disiplin',
                'name': 'Baro ve Disiplin',
                'description': 'Baro teşkilatı, disiplin cezaları, TBB',
                'summary': 'Disiplin cezaları: Uyarma, kınama, para cezası, işten yasaklama (3 ay-3 yıl), meslekten çıkarma. TBB en üst kuruluş.',
                'order': 2
            }
        ]
    },
    
    'hukuk_felsefesi': {
        'name': 'Hukuk Felsefesi ve Sosyolojisi',
        'description': 'Hukuk teorileri, adalet, hukuk sosyolojisi',
        'order': 15,
        'icon': 'psychology',
        'topics': [
            {
                'id': 'hukuk_teorileri',
                'name': 'Hukuk Teorileri',
                'description': 'Doğal hukuk, pozitivizm, sosyolojik hukuk',
                'summary': 'Doğal hukuk: Evrensel, değişmez, akıl/tanrı kaynaklı. Hukuki pozitivizm: Devlet iradesi, yaptırım. Saf hukuk teorisi (Kelsen): Norm hiyerarşisi.',
                'order': 1
            },
            {
                'id': 'hukuk_sosyoloji',
                'name': 'Hukuk Sosyolojisi',
                'description': 'Hukuk ve toplum ilişkisi, hukukun etkinliği',
                'summary': 'Hukuk sosyolojisi: Hukukun toplumsal işlevi, hukuk-toplum etkileşimi, hukukun etkinliği ve uygulanması.',
                'order': 2
            }
        ]
    }
}


def seed_curriculum():
    """Tüm müfredatı Firestore'a yükle"""
    print("🚀 HMGS Müfredat yükleniyor...\n")
    
    batch = db.batch()
    batch_count = 0
    
    total_subjects = 0
    total_topics = 0
    
    for subject_id, subject_data in CURRICULUM.items():
        # Subject dökümanını oluştur
        subject_ref = db.collection('subjects').document(subject_id)
        batch.set(subject_ref, {
            'id': subject_id,
            'name': subject_data['name'],
            'description': subject_data['description'],
            'order': subject_data['order'],
            'icon': subject_data.get('icon', 'book'),
            'isActive': True,
            'topicCount': len(subject_data['topics']),
            'createdAt': firestore.SERVER_TIMESTAMP,
            'updatedAt': firestore.SERVER_TIMESTAMP
        }, merge=True)
        batch_count += 1
        total_subjects += 1
        
        print(f"📚 {subject_data['name']}")
        
        # Topic dökümanlarını oluştur
        for topic in subject_data['topics']:
            topic_ref = db.collection('topics').document(topic['id'])
            batch.set(topic_ref, {
                'id': topic['id'],
                'name': topic['name'],
                'description': topic['description'],
                'summary': topic.get('summary', ''),
                'subjectId': subject_id,
                'order': topic['order'],
                'isActive': True,
                'questionCount': 0,  # Sonra güncellenecek
                'createdAt': firestore.SERVER_TIMESTAMP,
                'updatedAt': firestore.SERVER_TIMESTAMP
            }, merge=True)
            batch_count += 1
            total_topics += 1
            
            print(f"   └─ {topic['name']}")
        
        # Batch limit kontrolü
        if batch_count >= 450:
            batch.commit()
            batch = db.batch()
            batch_count = 0
    
    # Kalan batch'i commit et
    if batch_count > 0:
        batch.commit()
    
    print(f"\n{'='*50}")
    print(f"✅ Müfredat yüklendi!")
    print(f"   📚 Dersler: {total_subjects}")
    print(f"   📖 Konular: {total_topics}")
    print(f"{'='*50}")


def update_question_topics():
    """Mevcut soruları yeni topic yapısına göre güncelle (opsiyonel)"""
    print("\n🔄 Soruları topic'lere eşleştirme...")
    
    # Bu aşamada sorular henüz topic'lere göre ayrılmadığı için
    # her dersin ilk topic'ine atayalım (geçici çözüm)
    
    questions = db.collection('questions').stream()
    
    batch = db.batch()
    count = 0
    updated = 0
    
    for doc in questions:
        data = doc.to_dict()
        subject_id = data.get('subjectId', '')
        
        # Subject'e göre ilk topic'i bul
        if subject_id in CURRICULUM:
            first_topic = CURRICULUM[subject_id]['topics'][0]['id']
            
            # topicIds'i güncelle
            batch.update(doc.reference, {
                'topicIds': [first_topic],
                'updatedAt': firestore.SERVER_TIMESTAMP
            })
            updated += 1
            count += 1
            
            if count >= 450:
                batch.commit()
                batch = db.batch()
                count = 0
    
    if count > 0:
        batch.commit()
    
    print(f"   ✅ {updated} soru güncellendi")


if __name__ == '__main__':
    seed_curriculum()
    
    # Opsiyonel: Mevcut soruları yeni topic'lere eşleştir
    # update_question_topics()
