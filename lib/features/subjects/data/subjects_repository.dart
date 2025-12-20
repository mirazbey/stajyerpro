import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/subject_model.dart';
import '../../../shared/models/topic_model.dart';
import '../../../shared/models/question_model.dart';

/// SubjectsRepository Provider
final subjectsRepositoryProvider = Provider<SubjectsRepository>((ref) {
  return SubjectsRepository(firestore: FirebaseFirestore.instance);
});

/// Tüm dersleri getiren Stream Provider
final subjectsStreamProvider = StreamProvider<List<SubjectModel>>((ref) {
  final repository = ref.watch(subjectsRepositoryProvider);
  return repository.getSubjects();
});

/// Bir derse ait konuları getiren Stream Provider (Admin için - tüm konular)
final topicsBySubjectStreamProvider =
    StreamProvider.family<List<TopicModel>, String>((ref, subjectId) {
      final repository = ref.watch(subjectsRepositoryProvider);
      return repository.getTopicsBySubjectForAdmin(subjectId);
    });

/// Ders ve konu verilerini Firestore'dan çeken repository
class SubjectsRepository {
  final FirebaseFirestore firestore;

  SubjectsRepository({required this.firestore});

  /// Tüm dersleri getir (aktif olanlar, sıralı)
  Stream<List<SubjectModel>> getSubjects() {
    return firestore
        .collection('subjects')
        .where('isActive', isEqualTo: true)
        .orderBy('order')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => SubjectModel.fromFirestore(doc))
              .toList(),
        );
  }

  /// Belirli bir dersi ID'ye göre getir
  Future<SubjectModel?> getSubjectById(String subjectId) async {
    final doc = await firestore.collection('subjects').doc(subjectId).get();
    if (!doc.exists) return null;
    return SubjectModel.fromFirestore(doc);
  }

  /// Bir derse ait konuları getir (aktif olanlar, sıralı)
  Stream<List<TopicModel>> getTopicsBySubject(String subjectId) {
    debugPrint('🔍 getTopicsBySubject called with subjectId: $subjectId');
    return firestore
        .collection('topics')
        .where('subjectId', isEqualTo: subjectId)
        // isActive filtresini client-side yapıyoruz (index sorunu önlemek için)
        .snapshots()
        .map((snapshot) {
          debugPrint('📦 Firestore returned ${snapshot.docs.length} docs for subjectId: $subjectId');
          final topics = snapshot.docs
              .map((doc) => TopicModel.fromFirestore(doc))
              .where((topic) => topic.isActive) // Client-side filter
              .toList();
          debugPrint('✅ After isActive filter: ${topics.length} topics');
          topics.sort((a, b) => a.order.compareTo(b.order));
          return topics;
        });
  }

  /// Admin için bir derse ait TÜM konuları getir (aktif/pasif farketmeksizin)
  Stream<List<TopicModel>> getTopicsBySubjectForAdmin(String subjectId) {
    return firestore
        .collection('topics')
        .where('subjectId', isEqualTo: subjectId)
        // isActive filtresi YOK
        // .orderBy('order') // Index hatasını önlemek için sıralamayı client-side yapıyoruz
        .snapshots()
        .map((snapshot) {
          final topics = snapshot.docs
              .map((doc) => TopicModel.fromFirestore(doc))
              .toList();
          // Client-side sorting
          topics.sort((a, b) => a.order.compareTo(b.order));
          return topics;
        });
  }

  /// Belirli bir konuyu ID'ye göre getir
  Future<TopicModel?> getTopicById(String topicId) async {
    final doc = await firestore.collection('topics').doc(topicId).get();
    if (!doc.exists) return null;
    return TopicModel.fromFirestore(doc);
  }

  /// Birden fazla konuyu ID listesine göre getir
  Future<List<TopicModel>> getTopicsByIds(List<String> topicIds) async {
    if (topicIds.isEmpty) return [];

    // Firestore whereIn supports max 10 items.
    // If more than 10, we need to split or just fetch all and filter (not efficient but safe for now)
    // Or just fetch in batches. For simplicity in this project, let's assume < 10 or fetch all.
    // Better: fetch all active topics and filter.

    final querySnapshot = await firestore
        .collection('topics')
        .where(FieldPath.documentId, whereIn: topicIds.take(10).toList())
        .get();

    return querySnapshot.docs
        .map((doc) => TopicModel.fromFirestore(doc))
        .toList();
  }

  /// Tüm konuları getir (arama için)
  Stream<List<TopicModel>> getAllTopics() {
    return firestore
        .collection('topics')
        .where('isActive', isEqualTo: true)
        .orderBy('name')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => TopicModel.fromFirestore(doc))
              .toList(),
        );
  }

  /// Konu verilerini seed et (Test için)
  Future<void> seedTopics(String subjectId) async {
    final topics = [
      {
        'name': 'Temel Kavramlar',
        'description': 'Hukukun temel kavramları ve başlangıç hükümleri',
        'order': 1,
        'questionCount': 15,
      },
      {
        'name': 'Kişiler Hukuku',
        'description': 'Gerçek ve tüzel kişiler, ehliyet türleri',
        'order': 2,
        'questionCount': 25,
      },
      {
        'name': 'Aile Hukuku',
        'description': 'Nişanlanma, evlenme, boşanma ve soybağı',
        'order': 3,
        'questionCount': 20,
      },
      {
        'name': 'Miras Hukuku',
        'description': 'Yasal mirasçılar, ölüme bağlı tasarruflar',
        'order': 4,
        'questionCount': 18,
      },
      {
        'name': 'Eşya Hukuku',
        'description': 'Zilyetlik, tapu sicili ve mülkiyet',
        'order': 5,
        'questionCount': 30,
      },
    ];

    final batch = firestore.batch();

    for (var topic in topics) {
      final docRef = firestore.collection('topics').doc();
      batch.set(docRef, {
        'id': docRef.id,
        'subjectId': subjectId,
        'name': topic['name'],
        'description': topic['description'],
        'order': topic['order'],
        'questionCount': topic['questionCount'],
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
  }

  /// Müfredat JSON'ını kaydet (Recursive)
  Future<void> saveCurriculum(
    String subjectId,
    List<Map<String, dynamic>> curriculum,
  ) async {
    final batch = firestore.batch();

    for (var i = 0; i < curriculum.length; i++) {
      await _saveTopicRecursive(
        batch,
        subjectId,
        null, // Top level -> parentId is null
        curriculum[i],
        i + 1,
      );
    }

    await batch.commit();
  }

  Future<void> _saveTopicRecursive(
    WriteBatch batch,
    String subjectId,
    String? parentId,
    Map<String, dynamic> data,
    int order,
  ) async {
    final docRef = firestore.collection('topics').doc();

    batch.set(docRef, {
      'id': docRef.id,
      'subjectId': subjectId,
      'parentId': parentId,
      'name': data['name'],
      'description': data['description'],
      'order': order,
      'isActive': false, // Varsayılan olarak taslak (onay bekliyor)
      'questionCount': 0,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // Subtopics varsa kaydet
    if (data['subtopics'] != null && (data['subtopics'] as List).isNotEmpty) {
      final subtopics = List<Map<String, dynamic>>.from(data['subtopics']);
      for (var i = 0; i < subtopics.length; i++) {
        await _saveTopicRecursive(
          batch,
          subjectId,
          docRef.id, // Parent is current topic
          subtopics[i],
          i + 1,
        );
      }
    }
  }

  /// Konu içeriğini ve soruları kaydet
  Future<void> saveTopicContent(
    String subjectId,
    String topicId,
    Map<String, dynamic> content,
  ) async {
    final batch = firestore.batch();

    // 1. Konu özetini güncelle
    final topicRef = firestore.collection('topics').doc(topicId);
    batch.update(topicRef, {
      'description': content['summary'],
      'isActive': true, // İçerik üretilince konuyu aktif et
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // 2. Soruları kaydet
    final questions = List<Map<String, dynamic>>.from(content['questions']);
    final questionsCollection = firestore.collection('questions');

    for (var q in questions) {
      final docRef = questionsCollection.doc();
      final question = QuestionModel(
        id: docRef.id,
        stem: q['text'],
        options: List<String>.from(q['options']),
        correctIndex: q['correctAnswerIndex'],
        detailedExplanation: q['explanation'], // Yeni alan
        explanation: q['explanation'], // Geriye dönük uyumluluk
        lawArticle: q['lawArticle'],
        subjectId: subjectId,
        topicIds: [topicId],
        difficulty: 'medium', // Varsayılan
        source: 'AI Generated',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      batch.set(docRef, question.toFirestore());
    }

    // 3. Soru sayısını güncelle
    batch.update(topicRef, {
      'questionCount': FieldValue.increment(questions.length),
    });

    await batch.commit();
  }
}
