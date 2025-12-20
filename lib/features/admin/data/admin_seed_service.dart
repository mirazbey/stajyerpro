import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Admin/seed hizmeti: ders, konu ve ornek soru eklemek icin kullanilir.
final adminSeedServiceProvider = Provider<AdminSeedService>((ref) {
  return AdminSeedService(firestore: FirebaseFirestore.instance);
});

class AdminSeedService {
  final FirebaseFirestore firestore;

  AdminSeedService({required this.firestore});

  /// Koleksiyonlarin temel sayimlarini dondurur.
  Future<Map<String, int>> fetchCounts() async {
    final subjects = await firestore.collection('subjects').get();
    final topics = await firestore.collection('topics').get();
    final questions = await firestore.collection('questions').get();

    return {
      'subjects': subjects.size,
      'topics': topics.size,
      'questions': questions.size,
    };
  }

  /// Ornek ders ve konu seed'i (idempotent).
  Future<void> seedSubjectsAndTopics() async {
    final now = Timestamp.fromDate(DateTime.now());
    final batch = firestore.batch();

    for (final subject in _subjectsSeed) {
      final ref = firestore.collection('subjects').doc(subject['id']!);
      batch.set(ref, {
        'name': subject['name'],
        'order': int.parse(subject['order']!),
        'isActive': true,
        'createdAt': now,
        'updatedAt': now,
      }, SetOptions(merge: true));
    }

    for (final topic in _topicsSeed) {
      final ref = firestore.collection('topics').doc(topic['id']!);
      batch.set(ref, {
        'name': topic['name'],
        'subjectId': topic['subjectId'],
        'order': int.parse(topic['order']!),
        'isActive': true,
        'createdAt': now,
        'updatedAt': now,
      }, SetOptions(merge: true));
    }

    await batch.commit();
  }

  /// Ornek soru seed'i (idempotent). Mevcut subject/topic id'lerini kullanir.
  Future<void> seedSampleQuestions() async {
    final now = Timestamp.fromDate(DateTime.now());
    final batch = firestore.batch();

    for (final question in _questionsSeed) {
      final ref = firestore.collection('questions').doc(question['id']!);
      batch.set(ref, {
        'stem': question['stem'],
        'options': question['options'],
        'correctIndex': question['correctIndex'],
        'explanation': question['explanation'],
        'source': question['source'],
        'subjectId': question['subjectId'],
        'topicIds': question['topicIds'],
        'difficulty': question['difficulty'],
        'targetRoles': question['targetRoles'],
        'createdAt': now,
        'updatedAt': now,
      }, SetOptions(merge: true));
    }

    await batch.commit();
  }
}

// Seed veri seti (kucuk ve idempotent olacak sekilde tasarlandi)
const List<Map<String, String>> _subjectsSeed = [
  {'id': 'anayasa', 'name': 'Anayasa Hukuku', 'order': '1'},
  {'id': 'idare', 'name': 'Idare Hukuku', 'order': '2'},
  {'id': 'ceza-genel', 'name': 'Ceza Hukuku Genel', 'order': '3'},
  {'id': 'ceza-ozel', 'name': 'Ceza Hukuku Ozel', 'order': '4'},
];

const List<Map<String, String>> _topicsSeed = [
  {'id': 'anayasa-devlet', 'subjectId': 'anayasa', 'name': 'Devletin Temel Nitelikleri', 'order': '1'},
  {'id': 'anayasa-yasama', 'subjectId': 'anayasa', 'name': 'Yasama Yetkisi', 'order': '2'},
  {'id': 'idare-idariislem', 'subjectId': 'idare', 'name': 'Idari Islemler', 'order': '1'},
  {'id': 'ceza-genel-suc', 'subjectId': 'ceza-genel', 'name': 'Sucun Unsurlari', 'order': '1'},
  {'id': 'ceza-ozel-hakaret', 'subjectId': 'ceza-ozel', 'name': 'Hakaret Suclari', 'order': '1'},
];

final List<Map<String, dynamic>> _questionsSeed = [
  {
    'id': 'q-anayasa-001',
    'stem': '1982 Anayasasina gore yasama yetkisi kime aittir ve devredilebilir mi?',
    'options': [
      'Cumhurbaskanina aittir, OHAL durumunda devredilebilir.',
      'TBMM\'ye aittir, devredilemez.',
      'Bakanlar Kuruluna aittir, kanunla devredilebilir.',
      'TBMM ve Cumhurbaskani birlikte kullanir, kanunla genisletilebilir.',
      'Anayasa Mahkemesi dogrular, yasama organi uygular.'
    ],
    'correctIndex': 1,
    'explanation': 'Anayasa madde 7: Yasama yetkisi Turk Milleti adina TBMM\'ye aittir ve bu yetki devredilemez.',
    'source': 'TC Anayasasi m.7',
    'subjectId': 'anayasa',
    'topicIds': ['anayasa-yasama'],
    'difficulty': 'medium',
    'targetRoles': ['judge', 'prosecutor'],
  },
  {
    'id': 'q-idare-001',
    'stem': 'Idari islemlerin hukuka uygunluk karinesi hangi sonucu dogurur?',
    'options': [
      'Islem iptal davasina konu olamaz.',
      'Islemin hukuka aykiri oldugu kabul edilir.',
      'Islem yurutulurken idare tazminat odemek zorundadir.',
      'Islem yurutulmeye devam eder, iptal edilene kadar hukuken gecerlidir.',
      'Islem sadece Parlamento onayi ile uygulanabilir.'
    ],
    'correctIndex': 3,
    'explanation': 'Hukuka uygunluk karinesi geregi idari islem iptal edilene kadar gecerlidir ve uygulanir.',
    'source': 'Idare hukukunun genel prensibi',
    'subjectId': 'idare',
    'topicIds': ['idare-idariislem'],
    'difficulty': 'easy',
    'targetRoles': ['judge', 'lawyer'],
  },
  {
    'id': 'q-ceza-001',
    'stem': 'Ceza hukukunda kanunilik ilkesi asagidakilerden hangisini zorunlu kilar?',
    'options': [
      'Hakim, toplum vicdanina gore suclari belirleyebilir.',
      'Sadece yazili kanunlarda yer alan fiiller suc sayilabilir.',
      'Idarenin genelgeleriyle suc tanimi yapilabilir.',
      'Cumhurbaskani kararnamesiyle ceza arttirilabilir.',
      'Hakimin takdir yetkisiyle bosluklar doldurulur.'
    ],
    'correctIndex': 1,
    'explanation': 'Kanunilik ilkesi, ancak yazili kanunla suc ve ceza konulabilecegini ifade eder.',
    'source': 'TCK temel ilkeler',
    'subjectId': 'ceza-genel',
    'topicIds': ['ceza-genel-suc'],
    'difficulty': 'medium',
    'targetRoles': ['judge', 'prosecutor'],
  },
];
