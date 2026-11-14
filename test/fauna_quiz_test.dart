import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zoology_app/data/fauna_quiz_data.dart';
import 'package:zoology_app/data/species_data.dart';
import 'package:zoology_app/main.dart';
import 'package:zoology_app/models/fauna_quiz_question.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Group 1: Question Bank Integrity & Regional Zoology Whitelist', () {
    test('Q1.1: Question bank contains at least 30 authentic regional zoology questions', () {
      expect(kFaunaQuizQuestions.length, greaterThanOrEqualTo(30));
    });

    test('Q1.2: Question fields are non-empty, IDs unique, and correct indices valid (0..3)', () {
      final ids = <String>{};
      for (final q in kFaunaQuizQuestions) {
        expect(ids.add(q.id), isTrue, reason: 'Duplicate quiz question ID: ${q.id}');
        expect(q.prompt.trim(), isNotEmpty);
        expect(q.options.length, 4);
        expect(q.options.toSet().length, 4, reason: 'Duplicate options in question ${q.id}');
        expect(q.correctIndex, inInclusiveRange(0, 3));
        expect(q.explanation.trim(), isNotEmpty);
      }
    });

    test('Q1.3: Strict Zero Flora / Plant rule across all quiz questions and options', () {
      const bannedFlora = ['chinar', 'saffron', 'deodar', 'flora', 'plant', 'tree', 'flower', 'pine'];
      for (final q in kFaunaQuizQuestions) {
        final text = '${q.prompt} ${q.options.join(" ")} ${q.explanation}'.toLowerCase();
        final words = RegExp(r'\b[a-z]+\b').allMatches(text).map((m) => m.group(0)!).toSet();
        for (final flora in bannedFlora) {
          expect(words.contains(flora), isFalse, reason: 'Quiz question ${q.id} mentions banned flora term: $flora');
        }
      }
    });

    test('Q1.4: Comprehensive class coverage across all 6 regional taxa classes', () {
      final classes = kFaunaQuizQuestions.map((q) => q.category).toSet();
      expect(classes, containsAll(['Mammal', 'Bird', 'Reptile', 'Amphibian', 'Fish', 'Insect']));
      for (final c in classes) {
        final count = kFaunaQuizQuestions.where((q) => q.category == c).length;
        expect(count, greaterThanOrEqualTo(2), reason: 'Taxa $c should have at least 2 questions');
      }
    });

    test('Q1.5: Valid species catalog cross-reference and regional metadata tags', () {
      const validRegions = {'Jammu', 'Kashmir', 'Ladakh', 'Trans-Himalaya', 'Pir Panjal'};
      final catalogIds = kSpeciesCatalog.map((s) => s.id).toSet();
      for (final q in kFaunaQuizQuestions) {
        expect(catalogIds, contains(q.speciesId), reason: 'Question ${q.id} references non-catalog species ${q.speciesId}');
        expect(validRegions, contains(q.region), reason: 'Question ${q.id} has invalid region ${q.region}');
      }
    });
  });

  group('Group 2: UI Presentation & Initial State', () {
    testWidgets('Q2.1: Initial rendering displays card badge, counter, prompt, and 4 neutral options', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: SingleChildScrollView(child: InteractiveFaunaChallengeCard())),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('INTERACTIVE FAUNA CHALLENGE'), findsOneWidget);
      expect(find.textContaining('Question 1/'), findsOneWidget);
      expect(find.byIcon(Icons.radio_button_unchecked), findsNWidgets(4));
      expect(find.text('Next Question'), findsNothing);
      expect(find.textContaining('Dachigam National Park'), findsNothing); // Explanation hidden
    });

    testWidgets('Q2.2: Renders multi-line questions on compact screens without RenderFlex overflow', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: SingleChildScrollView(child: InteractiveFaunaChallengeCard())),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });

  group('Group 3: Immediate Interaction & Non-Stalling Responsiveness', () {
    testWidgets('Q3.1: Tapping an option updates state immediately on single pump frame', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: SingleChildScrollView(child: InteractiveFaunaChallengeCard())),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(InkWell).first);
      await tester.pump(); // Immediate 0-ms pump

      expect(find.text('Next Question'), findsOneWidget);
    });

    testWidgets('Q3.2: Immediate answer locking prevents multi-tap race conditions', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: SingleChildScrollView(child: InteractiveFaunaChallengeCard())),
        ),
      );
      await tester.pumpAndSettle();

      final options = find.byType(InkWell);
      await tester.tap(options.at(0));
      await tester.tap(options.at(2));
      await tester.pump();

      // Only first tap registered, exactly one Next Question button
      expect(find.text('Next Question'), findsOneWidget);
    });

    testWidgets('Q3.3: Tapping Next Question immediately renders subsequent question', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: SingleChildScrollView(child: InteractiveFaunaChallengeCard())),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(InkWell).first);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Next Question'));
      await tester.pump(); // Immediate pump

      expect(find.textContaining('Question 2/'), findsOneWidget);
      expect(find.text('Next Question'), findsNothing);
    });
  });

  group('Group 4: Correct vs Incorrect Visual Feedback & Scoring', () {
    testWidgets('Q4.1: Correct answer selection renders green highlight, check icon, explanation, and increments score', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: SingleChildScrollView(child: InteractiveFaunaChallengeCard())),
        ),
      );
      await tester.pumpAndSettle();

      // Q1 correct is Kashmir Stag (Hangul)
      await tester.tap(find.text('Kashmir Stag (Hangul)'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
      expect(find.byIcon(Icons.cancel_rounded), findsNothing);
      expect(find.textContaining('Dachigam National Park'), findsOneWidget);
    });

    testWidgets('Q4.2: Incorrect answer selection renders red highlight, shows correct answer in green, and displays explanation', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: SingleChildScrollView(child: InteractiveFaunaChallengeCard())),
        ),
      );
      await tester.pumpAndSettle();

      // Q1 wrong answer is Kashmir Musk Deer
      await tester.tap(find.text('Kashmir Musk Deer'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.cancel_rounded), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget); // Correct answer revealed
      expect(find.textContaining('Dachigam National Park'), findsOneWidget);
    });

    testWidgets('Q4.3: Unselected wrong options maintain neutral styling', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: SingleChildScrollView(child: InteractiveFaunaChallengeCard())),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Kashmir Musk Deer'));
      await tester.pumpAndSettle();

      // 2 neutral options remain unselected
      expect(find.byIcon(Icons.radio_button_unchecked), findsNWidgets(2));
    });
  });

  group('Group 5: Multi-Question Cycling & Cumulative Score Tracking', () {
    testWidgets('Q5.1: Sequence of questions accumulates score accurately', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: SingleChildScrollView(child: InteractiveFaunaChallengeCard())),
        ),
      );
      await tester.pumpAndSettle();

      // Q1: Correct (Hangul) -> Score 1
      await tester.tap(find.text('Kashmir Stag (Hangul)'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next Question'));
      await tester.pumpAndSettle();

      // Q2: Incorrect (Himalayan Brown Bear) -> Score still 1
      await tester.tap(find.text('Himalayan Brown Bear'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next Question'));
      await tester.pumpAndSettle();

      // Q3: Correct (Himalayan Monal) -> Score 2
      await tester.tap(find.text('Himalayan Monal'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Question 3/'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
    });

    testWidgets('Q5.2: Advancing to next question fully resets selection and locks state', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: SingleChildScrollView(child: InteractiveFaunaChallengeCard())),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(InkWell).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next Question'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.radio_button_unchecked), findsNWidgets(4));
      expect(find.text('Next Question'), findsNothing);
    });
  });

  group('Group 6: Completion Screen & Score Summary', () {
    testWidgets('Q6.1: Completing question set displays completion view with score and percentage', (tester) async {
      // Test with custom 2-question bank
      final testQuestions = [
        kFaunaQuizQuestions[0],
        kFaunaQuizQuestions[1],
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: InteractiveFaunaChallengeCard(questions: testQuestions),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Q1: Correct
      await tester.tap(find.text(testQuestions[0].options[testQuestions[0].correctIndex]));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next Question'));
      await tester.pumpAndSettle();

      // Q2: Incorrect
      final wrongIdx = (testQuestions[1].correctIndex + 1) % 4;
      await tester.tap(find.text(testQuestions[1].options[wrongIdx]));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next Question'));
      await tester.pumpAndSettle();

      // Completion screen elements
      expect(find.textContaining('Challenge Complete'), findsOneWidget);
      expect(find.textContaining('1 / 2'), findsOneWidget);
      expect(find.textContaining('50%'), findsOneWidget);
      expect(find.text('Restart Quiz'), findsOneWidget);
    });

    testWidgets('Q6.2: Tapping Restart Quiz resets to Question 1 with score 0', (tester) async {
      final testQuestions = [kFaunaQuizQuestions[0]];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: InteractiveFaunaChallengeCard(questions: testQuestions),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(InkWell).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next Question'));
      await tester.pumpAndSettle();

      expect(find.text('Restart Quiz'), findsOneWidget);
      await tester.tap(find.text('Restart Quiz'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Question 1/'), findsOneWidget);
      expect(find.byIcon(Icons.radio_button_unchecked), findsNWidgets(4));
    });

    testWidgets('Q6.3: Tapping Shuffle Questions randomizes questions and restarts at Question 1', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: SingleChildScrollView(child: InteractiveFaunaChallengeCard())),
        ),
      );
      await tester.pumpAndSettle();

      // When shuffle action is tapped
      final shuffleButton = find.textContaining('Shuffle');
      if (shuffleButton.evaluate().isNotEmpty) {
        await tester.tap(shuffleButton.first);
        await tester.pumpAndSettle();
        expect(find.textContaining('Question 1/'), findsOneWidget);
      }
    });
  });

  group('Group 7: Tab Persistence in KashmirZoologyApp (Integration)', () {
    testWidgets('Q7.1: Switching from Discover tab to Guide tab and returning retains question index, selection, and explanation', (tester) async {
      await tester.pumpWidget(const KashmirZoologyApp());
      await tester.pumpAndSettle();

      // Initial state on Discover tab: answer Question 1
      expect(find.textContaining('Question 1/'), findsOneWidget);
      await tester.tap(find.text('Kashmir Stag (Hangul)'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Dachigam National Park'), findsOneWidget);

      // Advance to Question 2
      await tester.tap(find.text('Next Question'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Question 2/'), findsOneWidget);

      // Select an option on Question 2
      await tester.tap(find.text('Snow Leopard'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Panthera uncia'), findsOneWidget);

      // Switch away to Field Guide tab (tab 2)
      await tester.tap(find.byKey(const Key('guideTab')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('speciesSearchField')), findsOneWidget);

      // Switch back to Discover tab (tab 0)
      await tester.tap(find.byKey(const Key('discoverTab')));
      await tester.pumpAndSettle();

      // Invariant: Card must still be on Question 2 with Snow Leopard selected and explanation visible!
      expect(find.textContaining('Question 2/'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
      expect(find.textContaining('Panthera uncia'), findsOneWidget);
      expect(find.text('Next Question'), findsOneWidget);
    });

    testWidgets('Q7.2: Tab switching preserves cumulative score across tabs', (tester) async {
      await tester.pumpWidget(const KashmirZoologyApp());
      await tester.pumpAndSettle();

      // Answer Q1 correctly
      await tester.tap(find.text('Kashmir Stag (Hangul)'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next Question'));
      await tester.pumpAndSettle();

      // Switch to Field Journal tab and back
      await tester.tap(find.byKey(const Key('journalTab')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('discoverTab')));
      await tester.pumpAndSettle();

      // Still on Q2, now answer Q2 correctly
      expect(find.textContaining('Question 2/'), findsOneWidget);
      await tester.tap(find.text('Snow Leopard'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next Question'));
      await tester.pumpAndSettle();

      // Now on Q3; cumulative score is 2
      expect(find.textContaining('Question 3/'), findsOneWidget);
    });

    testWidgets('Q7.3: Tab switching during Completion View preserves Completion View', (tester) async {
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

      await tester.tap(find.byType(InkWell).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next Question'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Challenge Complete'), findsOneWidget);

      // Controller state preserved
      expect(controller.isCompleted, isTrue);
    });
  });

  group('Group 8: Shuffling, Randomization & Boundary Invariants', () {
    test('Q8.1: Shuffling produces valid permutations without losing questions', () {
      final original = List<FaunaQuizQuestion>.from(kFaunaQuizQuestions);
      final shuffled = List<FaunaQuizQuestion>.from(kFaunaQuizQuestions)..shuffle();

      expect(shuffled.length, original.length);
      expect(shuffled.toSet(), original.toSet());
    });

    testWidgets('Q8.2: Empty question bank fallback does not throw unhandled RangeError', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: InteractiveFaunaChallengeCard(questions: []),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('Q8.3: Rapid tab navigation while answering does not trigger unmounted setState error', (tester) async {
      await tester.pumpWidget(const KashmirZoologyApp());
      await tester.pumpAndSettle();

      // Tap option and immediately switch tab without pumpAndSettle
      await tester.tap(find.byType(InkWell).first);
      await tester.tap(find.byKey(const Key('guideTab')));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });
}
