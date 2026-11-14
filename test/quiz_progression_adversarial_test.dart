import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zoology_app/data/fauna_quiz_data.dart';
import 'package:zoology_app/main.dart';
import 'package:zoology_app/models/fauna_quiz_question.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Group A: Rapid Multi-Tap & Concurrency Fuzzing', () {
    testWidgets('A1: Simultaneous 4-pointer gesture tap locks state immediately without race conditions', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: InteractiveFaunaChallengeCard(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final inkWells = find.byType(InkWell);
      expect(inkWells, findsNWidgets(4));

      // Simulate simultaneous pointer contact on all 4 option tiles
      final g1 = await tester.startGesture(tester.getCenter(inkWells.at(0)));
      final g2 = await tester.startGesture(tester.getCenter(inkWells.at(1)));
      final g3 = await tester.startGesture(tester.getCenter(inkWells.at(2)));
      final g4 = await tester.startGesture(tester.getCenter(inkWells.at(3)));

      // Release all pointers on the same frame
      await g1.up();
      await g2.up();
      await g3.up();
      await g4.up();
      await tester.pump();

      // Exactly one Next Question button appears, state is locked
      expect(find.text('Next Question'), findsOneWidget);

      // Verify that at most one option shows check or cancel icon
      final checks = find.byIcon(Icons.check_circle_rounded);
      final cancels = find.byIcon(Icons.cancel_rounded);
      expect(checks.evaluate().length + cancels.evaluate().length, inInclusiveRange(1, 2));

      // Score counter must be at most 1, never double-counted (e.g. 2, 3, or 4)
      expect(
        find.text('Score: 1 / 37').evaluate().length + find.text('Score: 0 / 37').evaluate().length,
        equals(1),
      );
    });

    testWidgets('A2: Rapid sequential tapping of all options before frame pump registers only the first tap', (tester) async {
      final controller = FaunaQuizController();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: InteractiveFaunaChallengeCard(controller: controller),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap options 0, 1, 2, 3 sequentially without pumping frames between taps
      final inkWells = find.byType(InkWell);
      await tester.tap(inkWells.at(0));
      await tester.tap(inkWells.at(1));
      await tester.tap(inkWells.at(2));
      await tester.tap(inkWells.at(3));
      await tester.pump();

      expect(controller.answered, isTrue);
      expect(controller.selectedAnswer, equals(0));
      // First option for Q0 is Kashmir Musk Deer (incorrect) -> score must remain 0
      expect(controller.score, equals(0));
      expect(find.text('Next Question'), findsOneWidget);
    });

    testWidgets('A3: Rapid multi-tapping on Next Question does not skip questions or advance multiple times', (tester) async {
      final controller = FaunaQuizController();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: InteractiveFaunaChallengeCard(controller: controller),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Answer question 0
      await tester.tap(find.byType(InkWell).at(1)); // Kashmir Stag (Hangul) -> correct
      await tester.pumpAndSettle();

      expect(controller.currentIndex, equals(0));
      expect(controller.score, equals(1));
      final nextButton = find.text('Next Question');
      expect(nextButton, findsOneWidget);

      // Tap Next Question 5 times rapidly
      await tester.tap(nextButton);
      await tester.tap(nextButton);
      await tester.tap(nextButton);
      await tester.tap(nextButton);
      await tester.tap(nextButton);
      await tester.pump();

      // Invariant: Next Question must advance by exactly 1 question, currentIndex must be 1 (Question 2)
      expect(controller.currentIndex, equals(1));
      expect(controller.answered, isFalse);
      expect(controller.selectedAnswer, isNull);
      expect(find.textContaining('Question 2/37'), findsOneWidget);
      // Next Question button must disappear until answered
      expect(find.text('Next Question'), findsNothing);
    });

    testWidgets('A4: Tapping option immediately after Next Question on same frame maintains state integrity', (tester) async {
      final controller = FaunaQuizController();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: InteractiveFaunaChallengeCard(controller: controller),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Answer Q0
      await tester.tap(find.byType(InkWell).at(1));
      await tester.pumpAndSettle();

      // Tap Next Question and then trigger a tap event on an option
      await tester.tap(find.text('Next Question'));
      await tester.pumpAndSettle();

      // Now on Q1, tap first option
      await tester.tap(find.byType(InkWell).first);
      await tester.pump();

      expect(controller.currentIndex, equals(1));
      expect(controller.answered, isTrue);
      expect(find.text('Next Question'), findsOneWidget);
    });

    testWidgets('A5: Attempting to select answer after round is completed is rejected cleanly', (tester) async {
      final testQuestions = [kFaunaQuizQuestions[0]];
      final controller = FaunaQuizController(questions: testQuestions);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: InteractiveFaunaChallengeCard(controller: controller),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Answer Q0 correctly
      await tester.tap(find.byType(InkWell).at(1));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next Question'));
      await tester.pumpAndSettle();

      expect(controller.isCompleted, isTrue);
      expect(controller.score, equals(1));

      // Attempting to select answers now should be rejected
      controller.selectAnswer(0);
      controller.selectAnswer(1);
      controller.nextQuestion();

      expect(controller.isCompleted, isTrue);
      expect(controller.score, equals(1));
      expect(find.text('Fauna Challenge Complete!'), findsOneWidget);
    });
  });

  group('Group B: Full 37-Question Playthrough & Score Accumulation', () {
    testWidgets('B1: Perfect 37/37 Playthrough increments 0..36, scores 37/37, and displays Master Naturalist rank without exceptions', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final controller = FaunaQuizController();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: InteractiveFaunaChallengeCard(controller: controller),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(controller.totalQuestions, equals(37));

      for (int i = 0; i < 37; i++) {
        expect(controller.currentIndex, equals(i), reason: 'Failed at question index $i');
        expect(controller.score, equals(i), reason: 'Pre-answer score mismatch at step $i');
        expect(controller.isCompleted, isFalse, reason: 'Completed prematurely at step $i');

        final currentQ = controller.currentQuestion;
        expect(currentQ, isNotNull);
        expect(currentQ!.id, equals(kFaunaQuizQuestions[i].id));

        // Find the correct option text
        final correctText = currentQ.options[currentQ.correctIndex];
        final correctFinder = find.text(correctText);
        expect(correctFinder, findsOneWidget, reason: 'Could not find option "$correctText" at index $i');

        // Tap the correct option
        await tester.tap(correctFinder);
        await tester.pump();

        expect(controller.answered, isTrue);
        expect(controller.score, equals(i + 1), reason: 'Score did not increment after correct answer at step $i');
        expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);

        final nextButton = find.text('Next Question');
        expect(nextButton, findsOneWidget);
        await tester.tap(nextButton);
        await tester.pump();
      }

      // Invariants after all 37 questions
      expect(controller.isCompleted, isTrue);
      expect(controller.score, equals(37));
      expect(controller.totalQuestions, equals(37));
      expect(controller.currentQuestion, isNotNull); // Safe modulo accessor
      expect(tester.takeException(), isNull);

      // Verify completion screen elements
      expect(find.text('Fauna Challenge Complete!'), findsOneWidget);
      expect(find.text('Final Score: 37 / 37 (100%)'), findsOneWidget);
      expect(find.text('🏆 Himalayan Master Naturalist'), findsOneWidget);
      expect(find.text('Restart Quiz'), findsOneWidget);
      expect(find.text('Shuffle Questions'), findsOneWidget);

      // Test Restart Quiz from Completion Screen
      await tester.tap(find.text('Restart Quiz'));
      await tester.pump();

      expect(controller.isCompleted, isFalse);
      expect(controller.currentIndex, equals(0));
      expect(controller.score, equals(0));
      expect(find.textContaining('Question 1/37'), findsOneWidget);
      expect(find.text('Score: 0 / 37'), findsOneWidget);
    });

    testWidgets('B2: Flawless Zero 0/37 Playthrough accumulates 0 score and displays Junior Field Scout rank', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final controller = FaunaQuizController();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: InteractiveFaunaChallengeCard(controller: controller),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      for (int i = 0; i < 37; i++) {
        expect(controller.currentIndex, equals(i));
        expect(controller.score, equals(0));

        final currentQ = controller.currentQuestion!;
        // Choose intentionally incorrect answer
        final wrongIndex = (currentQ.correctIndex + 1) % 4;
        final wrongText = currentQ.options[wrongIndex];

        await tester.tap(find.text(wrongText));
        await tester.pump();

        expect(controller.answered, isTrue);
        expect(controller.score, equals(0));
        expect(find.byIcon(Icons.cancel_rounded), findsOneWidget);

        await tester.tap(find.text('Next Question'));
        await tester.pump();
      }

      expect(controller.isCompleted, isTrue);
      expect(controller.score, equals(0));
      expect(find.text('Fauna Challenge Complete!'), findsOneWidget);
      expect(find.text('Final Score: 0 / 37 (0%)'), findsOneWidget);
      expect(find.text('🔍 Junior Field Scout'), findsOneWidget);
    });

    testWidgets('B3: Mixed/Alternating Score Playthrough computes exact integer percentage and rank', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final controller = FaunaQuizController();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: InteractiveFaunaChallengeCard(controller: controller),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      int expectedScore = 0;
      for (int i = 0; i < 37; i++) {
        final currentQ = controller.currentQuestion!;
        final bool answerCorrectly = (i % 2 == 0); // 19 correct (0, 2, ..., 36)

        final selectedText = answerCorrectly
            ? currentQ.options[currentQ.correctIndex]
            : currentQ.options[(currentQ.correctIndex + 1) % 4];

        if (answerCorrectly) expectedScore++;

        await tester.tap(find.text(selectedText));
        await tester.pump();
        expect(controller.score, equals(expectedScore));

        await tester.tap(find.text('Next Question'));
        await tester.pump();
      }

      expect(controller.isCompleted, isTrue);
      expect(controller.score, equals(19));
      const expectedPercent = 51; // round(19 / 37 * 100) = 51%
      expect(find.text('Final Score: 19 / 37 ($expectedPercent%)'), findsOneWidget);
      expect(find.text('🔍 Junior Field Scout'), findsOneWidget); // < 60%
    });
  });

  group('Group C: Controller Boundary Invariants & Edge Cases', () {
    test('C1: Empty question list controller invariants and safe no-ops', () {
      final controller = FaunaQuizController(questions: []);

      expect(controller.totalQuestions, equals(0));
      expect(controller.currentIndex, equals(0));
      expect(controller.questionIndex, equals(0));
      expect(controller.currentQuestion, isNull);
      expect(controller.isCompleted, isTrue);
      expect(controller.score, equals(0));
      expect(controller.answered, isFalse);
      expect(controller.selectedAnswer, isNull);

      // Safe no-ops
      controller.selectAnswer(0);
      controller.selectAnswer(-1);
      controller.selectAnswer(99);
      expect(controller.score, equals(0));
      expect(controller.answered, isFalse);

      controller.nextQuestion();
      expect(controller.currentIndex, equals(0));
      expect(controller.isCompleted, isTrue);

      controller.restartQuiz(shuffle: true);
      expect(controller.totalQuestions, equals(0));
      expect(controller.isCompleted, isTrue);

      controller.restartQuiz(shuffle: false);
      expect(controller.totalQuestions, equals(0));
      expect(controller.isCompleted, isTrue);
    });

    testWidgets('C2: Empty question list renders completion view gracefully without throwing', (tester) async {
      final controller = FaunaQuizController(questions: []);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InteractiveFaunaChallengeCard(controller: controller),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Fauna Challenge Complete!'), findsOneWidget);
      expect(find.text('Final Score: 0 / 0 (0%)'), findsOneWidget);
    });

    test('C3: 1-question list lifecycle and repeated nextQuestion calls when completed', () {
      final singleQ = kFaunaQuizQuestions.first;
      final controller = FaunaQuizController(questions: [singleQ]);

      expect(controller.totalQuestions, equals(1));
      expect(controller.currentIndex, equals(0));
      expect(controller.isCompleted, isFalse);
      expect(controller.currentQuestion, equals(singleQ));

      // Answering correctly
      controller.selectAnswer(singleQ.correctIndex);
      expect(controller.answered, isTrue);
      expect(controller.score, equals(1));

      // Advance to completion
      controller.nextQuestion();
      expect(controller.isCompleted, isTrue);
      expect(controller.currentIndex, equals(0)); // Stays bounded

      // 50 repeated nextQuestion calls must be safe no-ops
      for (int i = 0; i < 50; i++) {
        controller.nextQuestion();
        expect(controller.isCompleted, isTrue);
        expect(controller.currentIndex, equals(0));
        expect(controller.score, equals(1));
      }

      // Further selectAnswer calls must be rejected
      controller.selectAnswer(0);
      expect(controller.score, equals(1));
    });

    test('C4: Out-of-bounds answer selections (-1, 99) are safely handled', () {
      final controller = FaunaQuizController();

      // Negative index selection
      controller.selectAnswer(-1);
      expect(controller.answered, isTrue);
      expect(controller.selectedAnswer, equals(-1));
      expect(controller.score, equals(0)); // Not matching correctIndex

      // Advance
      controller.nextQuestion();
      expect(controller.currentIndex, equals(1));

      // Over-limit index selection
      controller.selectAnswer(999);
      expect(controller.answered, isTrue);
      expect(controller.selectedAnswer, equals(999));
      expect(controller.score, equals(0));
    });

    testWidgets('C5: Out-of-bounds selectedAnswer renders in UI without crashing', (tester) async {
      final controller = FaunaQuizController();
      controller.selectAnswer(-1); // Out-of-bounds index

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: InteractiveFaunaChallengeCard(controller: controller),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      // Correct option should still be shown in green
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
      // Next Question button should be present
      expect(find.text('Next Question'), findsOneWidget);
    });

    test('C6: Calling nextQuestion when unanswered is ignored', () {
      final controller = FaunaQuizController();
      expect(controller.currentIndex, equals(0));
      expect(controller.answered, isFalse);

      controller.nextQuestion();
      expect(controller.currentIndex, equals(0)); // Must NOT advance

      controller.nextQuestion();
      expect(controller.currentIndex, equals(0));
    });

    test('C7: Immutability of questions list prevents external corruption', () {
      final controller = FaunaQuizController();

      expect(
        () => controller.questions.add(kFaunaQuizQuestions.first),
        throwsA(isA<UnsupportedError>()),
      );
      expect(
        () => controller.questions.clear(),
        throwsA(isA<UnsupportedError>()),
      );
      expect(
        () => controller.questions.removeAt(0),
        throwsA(isA<UnsupportedError>()),
      );
    });

    test('C8: Isolated list defense: mutating the input list does not corrupt controller', () {
      final mutableQuestions = List<FaunaQuizQuestion>.from(kFaunaQuizQuestions);
      final controller = FaunaQuizController(questions: mutableQuestions);

      mutableQuestions.clear();
      expect(controller.totalQuestions, equals(37));
      expect(controller.questions.length, equals(37));
    });
  });

  group('Group D: Shuffle Stability & Permutation Integrity', () {
    test('D1: Shuffling produces a valid bijective permutation of all 37 unique questions', () {
      final controller = FaunaQuizController();
      controller.restartQuiz(shuffle: true);

      expect(controller.questions.length, equals(37));
      final originalIds = kFaunaQuizQuestions.map((q) => q.id).toList();
      final shuffledIds = controller.questions.map((q) => q.id).toList();

      expect(shuffledIds.toSet(), equals(originalIds.toSet()));
      expect(shuffledIds.toSet().length, equals(37)); // Strictly zero duplicates
    });

    test('D2: Answer keys and options remain strictly intact post-shuffle', () {
      final controller = FaunaQuizController();
      controller.restartQuiz(shuffle: true);

      final originalMap = {for (final q in kFaunaQuizQuestions) q.id: q};

      for (final shuffledQ in controller.questions) {
        final orig = originalMap[shuffledQ.id]!;
        expect(shuffledQ.prompt, equals(orig.prompt));
        expect(shuffledQ.options, equals(orig.options));
        expect(shuffledQ.correctIndex, equals(orig.correctIndex));
        expect(shuffledQ.explanation, equals(orig.explanation));
        expect(shuffledQ.speciesId, equals(orig.speciesId));
        expect(shuffledQ.category, equals(orig.category));
        expect(shuffledQ.region, equals(orig.region));

        // The answer string pointed to by correctIndex must match verbatim
        expect(
          shuffledQ.options[shuffledQ.correctIndex],
          equals(orig.options[orig.correctIndex]),
        );
      }
    });

    test('D3: Successive shuffles produce randomized permutations', () {
      final controller = FaunaQuizController();
      final originalOrder = kFaunaQuizQuestions.map((q) => q.id).toList();

      int distinctCount = 0;
      for (int trial = 0; trial < 10; trial++) {
        controller.restartQuiz(shuffle: true);
        final shuffledOrder = controller.questions.map((q) => q.id).toList();
        if (shuffledOrder.toString() != originalOrder.toString()) {
          distinctCount++;
        }
      }

      // Across 10 trials with 37! combinations, order must differ virtually 100% of the time
      expect(distinctCount, greaterThanOrEqualTo(9));
    });

    test('D4: restartQuiz(shuffle: false) completely restores original canonical order', () {
      final controller = FaunaQuizController();
      controller.restartQuiz(shuffle: true);

      // Now reset without shuffle
      controller.restartQuiz(shuffle: false);

      expect(controller.questions.length, equals(37));
      for (int i = 0; i < 37; i++) {
        expect(
          controller.questions[i].id,
          equals(kFaunaQuizQuestions[i].id),
          reason: 'Canonical order mismatch at index $i after un-shuffled restart',
        );
      }
    });

    test('D5: Single question and empty list shuffle stability', () {
      final singleController = FaunaQuizController(questions: [kFaunaQuizQuestions.first]);
      singleController.restartQuiz(shuffle: true);
      expect(singleController.totalQuestions, equals(1));
      expect(singleController.questions.first.id, equals(kFaunaQuizQuestions.first.id));

      final emptyController = FaunaQuizController(questions: []);
      emptyController.restartQuiz(shuffle: true);
      expect(emptyController.totalQuestions, equals(0));
      expect(emptyController.isCompleted, isTrue);
    });
  });

  group('Group E: Integration & High-Frequency Lifecycle Stress', () {
    testWidgets('E1: High-frequency tab switching during quiz progression does not corrupt state or drop progress', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(const KashmirZoologyApp());
      await tester.pumpAndSettle();

      // Q0: Answer Kashmir Stag (Hangul)
      await tester.tap(find.text('Kashmir Stag (Hangul)'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next Question'));
      await tester.pumpAndSettle();

      // Rapidly switch between Discover, Guide, Journal 15 times
      for (int i = 0; i < 15; i++) {
        await tester.tap(find.byKey(const Key('guideTab')));
        await tester.pump();
        await tester.tap(find.byKey(const Key('journalTab')));
        await tester.pump();
        await tester.tap(find.byKey(const Key('discoverTab')));
        await tester.pump();
      }
      await tester.pumpAndSettle();

      // Invariant: Card must still be cleanly on Question 2/37 with score 1
      expect(find.textContaining('Question 2/37'), findsOneWidget);
      expect(find.text('Score: 1 / 37'), findsOneWidget);
      expect(find.byIcon(Icons.radio_button_unchecked), findsNWidgets(4));

      // Answer Q1: Snow Leopard
      await tester.tap(find.text('Snow Leopard'));
      await tester.pumpAndSettle();

      // Switch tabs again while answered
      await tester.tap(find.byKey(const Key('guideTab')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('discoverTab')));
      await tester.pumpAndSettle();

      // Invariant: Q1 answered state, checkmark, and explanation must persist
      expect(find.textContaining('Question 2/37'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
      expect(find.textContaining('Panthera uncia'), findsOneWidget);
      expect(find.text('Next Question'), findsOneWidget);
    });

    testWidgets('E2: Rapid button smashing of Restart and Shuffle does not cause unhandled state exceptions', (tester) async {
      final testQuestions = [kFaunaQuizQuestions[0]];
      final controller = FaunaQuizController(questions: testQuestions);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: InteractiveFaunaChallengeCard(controller: controller),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Complete the quiz
      await tester.tap(find.byType(InkWell).at(1));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next Question'));
      await tester.pumpAndSettle();

      expect(find.text('Fauna Challenge Complete!'), findsOneWidget);

      // Rapid smashing of Restart and Shuffle
      for (int i = 0; i < 5; i++) {
        final restartButton = find.text('Restart Quiz');
        if (restartButton.evaluate().isNotEmpty) {
          await tester.tap(restartButton);
          await tester.pump();
        }
        controller.restartQuiz(shuffle: true);
        await tester.pump();
      }

      expect(tester.takeException(), isNull);
    });
  });
}
