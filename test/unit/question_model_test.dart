import 'package:flutter_test/flutter_test.dart';
import 'package:stajyerpro_app/shared/models/question_model.dart';

void main() {
  group('QuestionModel Tests', () {
    test('should create QuestionModel from map', () {
      final question = QuestionModel(
        id: 'q1',
        stem: 'Test Question Stem',
        options: ['A', 'B', 'C', 'D', 'E'],
        correctIndex: 0,
        subjectId: 'sub1',
        topicIds: ['top1'],
        difficulty: 'medium',
        lawArticle: 'Madde 1',
        detailedExplanation: 'Explanation',
        wrongReasons: {1: 'Reason B'},
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(question.id, 'q1');
      expect(question.stem, 'Test Question Stem');
      expect(question.options.length, 5);
      expect(question.correctIndex, 0);
      expect(question.lawArticle, 'Madde 1');
    });

    test('toFirestore should return correct map', () {
      final question = QuestionModel(
        id: 'q1',
        stem: 'Test Question Stem',
        options: ['A', 'B', 'C', 'D', 'E'],
        correctIndex: 0,
        subjectId: 'sub1',
        topicIds: ['top1'],
        difficulty: 'medium',
        lawArticle: 'Madde 1',
        detailedExplanation: 'Explanation',
        wrongReasons: {1: 'Reason B'},
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final map = question.toFirestore();

      expect(map['stem'], 'Test Question Stem');
      expect(map['correctIndex'], 0);
      expect(map['lawArticle'], 'Madde 1');
      expect(map['wrongReasons'], {1: 'Reason B'});
    });
  });
}
