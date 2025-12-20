import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stajyerpro_app/features/exam/presentation/widgets/question_detail_sheet.dart';
import 'package:stajyerpro_app/shared/models/question_model.dart';

void main() {
  testWidgets('QuestionDetailSheet displays question stem and options', (
    WidgetTester tester,
  ) async {
    final question = QuestionModel(
      id: 'q1',
      stem: 'What is the capital of Turkey?',
      options: ['Istanbul', 'Ankara', 'Izmir', 'Bursa', 'Adana'],
      correctIndex: 1,
      subjectId: 'geo',
      topicIds: ['cities'],
      difficulty: 'easy',
      lawArticle: 'Madde 1',
      detailedExplanation: 'Ankara is the capital.',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: QuestionDetailSheet(
            question: question,
            userAnswerIndex: 0,
            onAddToWrongPool: () async {},
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify stem is displayed
    expect(find.text('What is the capital of Turkey?'), findsOneWidget);

    // Verify options are displayed
    expect(find.text('A)', skipOffstage: false), findsOneWidget);
    expect(find.text('Istanbul', skipOffstage: false), findsOneWidget);
    expect(find.text('B)', skipOffstage: false), findsOneWidget);
    expect(find.text('Ankara', skipOffstage: false), findsOneWidget);

    // Verify explanation is displayed
    expect(find.text('Ankara is the capital.'), findsOneWidget);

    // Verify Law Article is displayed
    expect(find.text('Madde 1'), findsOneWidget);
  });
}
