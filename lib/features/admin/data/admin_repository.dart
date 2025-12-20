import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/question_model.dart';

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  return AdminRepository(firestore: FirebaseFirestore.instance);
});

class AdminRepository {
  final FirebaseFirestore firestore;

  AdminRepository({required this.firestore});

  /// Soru ekle
  Future<void> addQuestion(QuestionModel question) async {
    await firestore.collection('questions').add(question.toFirestore());
  }

  /// Soru güncelle
  Future<void> updateQuestion(QuestionModel question) async {
    await firestore
        .collection('questions')
        .doc(question.id)
        .update(question.toFirestore());
  }

  /// Soru sil
  Future<void> deleteQuestion(String questionId) async {
    await firestore.collection('questions').doc(questionId).delete();
  }

  /// Soruları getir (Sayfalandırma ile)
  Future<List<QuestionModel>> getQuestions({
    int limit = 20,
    DocumentSnapshot? startAfter,
    String? subjectId,
  }) async {
    Query query = firestore
        .collection('questions')
        .orderBy('createdAt', descending: true)
        .limit(limit);

    if (subjectId != null) {
      query = query.where('subjectId', isEqualTo: subjectId);
    }

    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    final snapshot = await query.get();
    return snapshot.docs
        .map((doc) => QuestionModel.fromFirestore(doc))
        .toList();
  }

  /// Toplam soru sayısını getir
  Future<int> getQuestionCount() async {
    final snapshot = await firestore.collection('questions').count().get();
    return snapshot.count ?? 0;
  }

  /// Toplam kullanıcı sayısını getir
  Future<int> getUserCount() async {
    final snapshot = await firestore.collection('users').count().get();
    return snapshot.count ?? 0;
  }

  /// Sistem istatistiklerini getir (Parallel execution)
  Future<Map<String, int>> getSystemStats() async {
    final results = await Future.wait([getQuestionCount(), getUserCount()]);

    return {'questions': results[0], 'users': results[1]};
  }
}
