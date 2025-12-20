import 'package:cloud_firestore/cloud_firestore.dart';

class WrongAnswerModel {
  final String id;
  final String userId;
  final String questionId;
  final DateTime addedAt;
  final int attemptCount; // Kaç kez tekrar çözüldü
  final DateTime? lastAttempt; // Son deneme tarihi
  final bool? lastResult; // Son denemede doğru mu yanlış mı

  WrongAnswerModel({
    required this.id,
    required this.userId,
    required this.questionId,
    required this.addedAt,
    this.attemptCount = 0,
    this.lastAttempt,
    this.lastResult,
  });

  factory WrongAnswerModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return WrongAnswerModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      questionId: data['questionId'] ?? '',
      addedAt: (data['addedAt'] as Timestamp).toDate(),
      attemptCount: data['attemptCount'] ?? 0,
      lastAttempt: data['lastAttempt'] != null
          ? (data['lastAttempt'] as Timestamp).toDate()
          : null,
      lastResult: data['lastResult'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'questionId': questionId,
      'addedAt': Timestamp.fromDate(addedAt),
      'attemptCount': attemptCount,
      'lastAttempt': lastAttempt != null
          ? Timestamp.fromDate(lastAttempt!)
          : null,
      'lastResult': lastResult,
    };
  }
}
