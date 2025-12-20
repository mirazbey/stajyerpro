import 'package:flutter_test/flutter_test.dart';
import 'package:stajyerpro_app/features/exam/domain/exam_distribution.dart';

void main() {
  group('Exam Distribution Tests', () {
    test('Total question count should be 120', () {
      int total = 0;
      for (var value in HMGS_DISTRIBUTION.values) {
        total += value;
      }

      expect(
        total,
        TOTAL_EXAM_QUESTIONS,
        reason: 'HMGS exam must have exactly 120 questions',
      );
      expect(total, 120);
    });

    test('Critical subjects should have correct question counts', () {
      expect(HMGS_DISTRIBUTION['anayasa'], 6);
      expect(HMGS_DISTRIBUTION['idare'], 6);
      expect(HMGS_DISTRIBUTION['medeni'], 15);
      expect(HMGS_DISTRIBUTION['ceza_genel'], 6);
      expect(HMGS_DISTRIBUTION['borclar'], 12);
    });

    test('All subject IDs should be valid strings', () {
      for (var key in HMGS_DISTRIBUTION.keys) {
        expect(key, isNotEmpty);
        expect(key, isA<String>());
      }
    });

    test('validateDistribution should return true', () {
      expect(validateDistribution(), isTrue);
    });
  });
}
