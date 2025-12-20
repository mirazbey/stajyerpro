import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/question_model.dart';
import '../domain/wrong_answer_model.dart';

final wrongAnswerRepositoryProvider = Provider((ref) {
  return WrongAnswerRepository(
    firestore: FirebaseFirestore.instance,
    auth: FirebaseAuth.instance,
  );
});

class WrongAnswerRepository {
  final FirebaseFirestore firestore;
  final FirebaseAuth auth;

  WrongAnswerRepository({required this.firestore, required this.auth});

  /// Soru yanlış havuzuna ekle
  Future<void> addToWrongPool(String questionId) async {
    final userId = auth.currentUser?.uid;
    if (userId == null) return;

    // Zaten ekli mi kontrol et
    final existing = await firestore
        .collection('wrong_answers')
        .where('userId', isEqualTo: userId)
        .where('questionId', isEqualTo: questionId)
        .get();

    if (existing.docs.isNotEmpty) {
      // Zaten varsa güncelle (tarihi yenile)
      await existing.docs.first.reference.update({
        'addedAt': FieldValue.serverTimestamp(),
        'attemptCount': FieldValue.increment(1),
      });
      return;
    }

    await firestore.collection('wrong_answers').add({
      'userId': userId,
      'questionId': questionId,
      'addedAt': FieldValue.serverTimestamp(),
      'attemptCount': 0,
      'lastAttempt': null,
      'lastResult': null,
    });
  }

  /// Yanlış havuzundaki soruları getir
  Stream<List<WrongAnswerModel>> getWrongAnswers() {
    final userId = auth.currentUser?.uid;
    if (userId == null) return Stream.value([]);

    return firestore
        .collection('wrong_answers')
        .where('userId', isEqualTo: userId)
        .orderBy('addedAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => WrongAnswerModel.fromFirestore(doc))
              .toList(),
        );
  }

  /// Yanlış havuzundan rastgele soru getir (Quiz için)
  Future<List<QuestionModel>> getRandomWrongQuestions(int count) async {
    final userId = auth.currentUser?.uid;
    if (userId == null) return [];

    // 1. Yanlış cevap ID'lerini çek
    final wrongAnswersSnapshot = await firestore
        .collection('wrong_answers')
        .where('userId', isEqualTo: userId)
        .get();

    if (wrongAnswersSnapshot.docs.isEmpty) return [];

    final wrongAnswers = wrongAnswersSnapshot.docs
        .map((doc) => WrongAnswerModel.fromFirestore(doc))
        .toList();

    // Karıştır ve limit uygula
    wrongAnswers.shuffle();
    final selectedWrongAnswers = wrongAnswers.take(count).toList();

    // 2. Soru detaylarını çek
    final questions = <QuestionModel>[];
    for (var wa in selectedWrongAnswers) {
      final qDoc = await firestore
          .collection('questions')
          .doc(wa.questionId)
          .get();
      if (qDoc.exists) {
        questions.add(QuestionModel.fromFirestore(qDoc));
      }
    }

    return questions;
  }

  /// Soruyu havuzdan çıkar (doğru bilince)
  Future<void> removeFromWrongPool(String questionId) async {
    final userId = auth.currentUser?.uid;
    if (userId == null) return;

    final snapshot = await firestore
        .collection('wrong_answers')
        .where('userId', isEqualTo: userId)
        .where('questionId', isEqualTo: questionId)
        .get();

    for (var doc in snapshot.docs) {
      await doc.reference.delete();
    }
  }
}
