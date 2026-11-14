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

  /// Configures realistic high-fidelity device viewport and guarantees clean teardown
  void setAdversarialViewport(WidgetTester tester, {Size size = const Size(1080, 2400)}) {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  /// Helper to safely switch navigation tabs in KashmirZoologyApp
  Future<void> switchTab(WidgetTester tester, int tabIndex) async {
    final keyName = tabIndex == 0
        ? 'discoverTab'
        : tabIndex == 1
            ? 'journalTab'
            : 'guideTab';
    final destinationFinder = find.byKey(Key(keyName));
    await tester.ensureVisible(destinationFinder);
    await tester.tap(destinationFinder);
    await tester.pumpAndSettle();
  }

  /// Helper to rapidly cycle tabs without settling between taps
  Future<void> rapidTabCycle(WidgetTester tester, List<int> tabSequence) async {
    for (final tab in tabSequence) {
      final keyName = tab == 0
          ? 'discoverTab'
          : tab == 1
              ? 'journalTab'
              : 'guideTab';
      final destinationFinder = find.byKey(Key(keyName));
      await tester.ensureVisible(destinationFinder);
      await tester.tap(destinationFinder);
      await tester.pump();
    }
    await tester.pumpAndSettle();
  }

  /// Helper to safely tap an element ensuring it is scrolled into view
  Future<void> tapVisible(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  /// Helper to identify which question from the bank is currently displayed
  FaunaQuizQuestion? findCurrentQuestion() {
    for (final q in kFaunaQuizQuestions) {
      if (find.text(q.prompt).evaluate().isNotEmpty) {
        return q;
      }
    }
    return null;
  }

  group('Adversarial Persistence Suite 1: Unanswered Question State Under Rapid Switching', () {
    testWidgets('APS1.1: Unanswered Question 1 survives rapid multi-tab switching', (tester) async {
      setAdversarialViewport(tester);
      await tester.pumpWidget(const KashmirZoologyApp());
      await tester.pumpAndSettle();

      // Initial state on Discover tab: Question 1
      expect(find.textContaining('Question 1/'), findsOneWidget);
      expect(find.text('Score: 0 / 37'), findsOneWidget);
      expect(find.byIcon(Icons.radio_button_unchecked), findsNWidgets(4));
      expect(find.text('Next Question'), findsNothing);

      // Rapidly cycle tabs: 0 -> 1 -> 2 -> 1 -> 0
      await rapidTabCycle(tester, [1, 2, 1, 0]);

      // Verify intact state on Discover tab
      expect(find.textContaining('Question 1/'), findsOneWidget);
      expect(find.text('Score: 0 / 37'), findsOneWidget);
      expect(find.byIcon(Icons.radio_button_unchecked), findsNWidgets(4));
      expect(find.text('Next Question'), findsNothing);
      expect(findCurrentQuestion()?.id, 'q-mammal-hangul-01');
      expect(tester.takeException(), isNull);
    });

    testWidgets('APS1.2: Unanswered mid-quiz question survives erratic tab navigation', (tester) async {
      setAdversarialViewport(tester);
      await tester.pumpWidget(const KashmirZoologyApp());
      await tester.pumpAndSettle();

      // Answer Q1 correctly and advance to Q2
      await tapVisible(tester, find.text('Kashmir Stag (Hangul)'));
      await tapVisible(tester, find.text('Next Question'));

      // Verify on Q2, unanswered
      expect(find.textContaining('Question 2/'), findsOneWidget);
      expect(find.text('Score: 1 / 37'), findsOneWidget);
      expect(find.byIcon(Icons.radio_button_unchecked), findsNWidgets(4));
      expect(find.text('Next Question'), findsNothing);

      // Erratic tab hopping: 0 -> 2 -> 0 -> 1 -> 2 -> 0 -> 1 -> 0
      await rapidTabCycle(tester, [2, 0, 1, 2, 0, 1, 0]);

      // Must strictly remain on Question 2 with Score 1 and 4 neutral options
      expect(find.textContaining('Question 2/'), findsOneWidget);
      expect(find.text('Score: 1 / 37'), findsOneWidget);
      expect(find.byIcon(Icons.radio_button_unchecked), findsNWidgets(4));
      expect(find.text('Next Question'), findsNothing);
      expect(findCurrentQuestion()?.id, 'q-mammal-snow-leopard-01');
    });
  });

  group('Adversarial Persistence Suite 2: Answered Question & Visual Feedback Persistence', () {
    testWidgets('APS2.1: Correctly answered question preserves selection, explanation, and advance button', (tester) async {
      setAdversarialViewport(tester);
      await tester.pumpWidget(const KashmirZoologyApp());
      await tester.pumpAndSettle();

      // Select correct answer on Question 1
      await tapVisible(tester, find.text('Kashmir Stag (Hangul)'));

      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
      expect(find.textContaining('Dachigam National Park'), findsOneWidget);
      expect(find.text('Next Question'), findsOneWidget);
      expect(find.text('Score: 1 / 37'), findsOneWidget);

      // Switch away through multiple tabs: Discover -> Guide -> Journal -> Discover
      await switchTab(tester, 2);
      expect(find.byKey(const Key('speciesSearchField')), findsOneWidget);

      await switchTab(tester, 1);
      expect(find.text('Field notebook'), findsOneWidget);

      await switchTab(tester, 0);

      // Verify exact question state is restored
      expect(find.textContaining('Question 1/'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
      expect(find.textContaining('Dachigam National Park'), findsOneWidget);
      expect(find.text('Next Question'), findsOneWidget);
      expect(find.text('Score: 1 / 37'), findsOneWidget);

      // Verify tapping Next Question after returning advances smoothly without stall
      await tapVisible(tester, find.text('Next Question'));

      expect(find.textContaining('Question 2/'), findsOneWidget);
      expect(find.text('Next Question'), findsNothing);
      expect(find.byIcon(Icons.radio_button_unchecked), findsNWidgets(4));
    });

    testWidgets('APS2.2: Incorrectly answered question preserves error state and revealed correct answer', (tester) async {
      setAdversarialViewport(tester);
      await tester.pumpWidget(const KashmirZoologyApp());
      await tester.pumpAndSettle();

      // Select incorrect answer on Question 1
      await tapVisible(tester, find.text('Kashmir Musk Deer'));

      expect(find.byIcon(Icons.cancel_rounded), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
      expect(find.textContaining('Dachigam National Park'), findsOneWidget);
      expect(find.text('Score: 0 / 37'), findsOneWidget);
      expect(find.text('Next Question'), findsOneWidget);

      // Rapidly cycle tabs back and forth
      await rapidTabCycle(tester, [1, 2, 0]);

      // Both incorrect red indicator and correct green indicator must persist
      expect(find.textContaining('Question 1/'), findsOneWidget);
      expect(find.byIcon(Icons.cancel_rounded), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
      expect(find.textContaining('Dachigam National Park'), findsOneWidget);
      expect(find.text('Score: 0 / 37'), findsOneWidget);
      expect(find.text('Next Question'), findsOneWidget);

      // Proceed to Question 2
      await tapVisible(tester, find.text('Next Question'));

      expect(find.textContaining('Question 2/'), findsOneWidget);
      expect(find.text('Score: 0 / 37'), findsOneWidget);
    });
  });

  group('Adversarial Persistence Suite 3: 5 Questions Answered & 10x Repetitive Tab Switch Stress', () {
    testWidgets('APS3.1: Answer 5 questions (Score=5), switch tabs 10 times, verify score and question invariant', (tester) async {
      setAdversarialViewport(tester);
      await tester.pumpWidget(const KashmirZoologyApp());
      await tester.pumpAndSettle();

      // Correct answers for the first 5 questions:
      final answers = [
        'Kashmir Stag (Hangul)',    // Q0
        'Snow Leopard',             // Q1
        'Himalayan Monal',          // Q2
        'Himalayan Marmot',         // Q3
        'Kashmiri Snow Trout',      // Q4
      ];

      for (int i = 0; i < answers.length; i++) {
        expect(find.textContaining('Question ${i + 1}/'), findsOneWidget);
        await tapVisible(tester, find.text(answers[i]));
        expect(find.text('Score: ${i + 1} / 37'), findsOneWidget);
        await tapVisible(tester, find.text('Next Question'));
      }

      // We should now be at Question 6 with score 5
      expect(find.textContaining('Question 6/37'), findsOneWidget);
      expect(find.text('Score: 5 / 37'), findsOneWidget);
      expect(findCurrentQuestion()?.id, 'q-mammal-markhor-01');

      // Stress: Switch tabs 10 times consecutively
      final tabSwitchSequence = [1, 2, 0, 1, 2, 1, 0, 2, 1, 0];
      expect(tabSwitchSequence.length, 10);

      for (int i = 0; i < tabSwitchSequence.length; i++) {
        await switchTab(tester, tabSwitchSequence[i]);
      }

      // Verify we are back on Discover tab
      expect(find.textContaining('Question 6/37'), findsOneWidget);
      expect(find.text('Score: 5 / 37'), findsOneWidget);
      expect(findCurrentQuestion()?.id, 'q-mammal-markhor-01');
      expect(find.byIcon(Icons.radio_button_unchecked), findsNWidgets(4));
      expect(find.text('Next Question'), findsNothing);

      // Now answer Question 6 correctly: Markhor
      await tapVisible(tester, find.text('Markhor (Pir Panjal Markhor)'));

      // Verify score increments to 6 / 37
      expect(find.text('Score: 6 / 37'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);

      // Advance to Question 7
      await tapVisible(tester, find.text('Next Question'));

      expect(find.textContaining('Question 7/37'), findsOneWidget);
      expect(find.text('Score: 6 / 37'), findsOneWidget);
      expect(findCurrentQuestion()?.id, 'q-mammal-tibetan-antelope-01');
    });
  });

  group('Adversarial Persistence Suite 4: Full App Completion Screen Persistence', () {
    testWidgets('APS4.1: Answering all 37 questions to completion persists across tab navigation', (tester) async {
      setAdversarialViewport(tester);
      await tester.pumpWidget(const KashmirZoologyApp());
      await tester.pumpAndSettle();

      // Advance through all 37 questions answering correctly
      for (int i = 0; i < kFaunaQuizQuestions.length; i++) {
        final q = kFaunaQuizQuestions[i];
        final correctOptionText = q.options[q.correctIndex];

        expect(find.textContaining('Question ${i + 1}/${kFaunaQuizQuestions.length}'), findsOneWidget);
        await tapVisible(tester, find.text(correctOptionText));
        await tapVisible(tester, find.text('Next Question'));
      }

      // Must be on Completion Screen
      expect(find.text('Fauna Challenge Complete!'), findsOneWidget);
      expect(find.text('Final Score: 37 / 37 (100%)'), findsOneWidget);
      expect(find.text('🏆 Himalayan Master Naturalist'), findsOneWidget);
      expect(find.text('Restart Quiz'), findsOneWidget);
      expect(find.text('Shuffle Questions'), findsOneWidget);

      // Switch to Journal tab
      await switchTab(tester, 1);
      expect(find.text('Field notebook'), findsOneWidget);
      expect(find.text('Fauna Challenge Complete!'), findsNothing);

      // Switch to Guide tab
      await switchTab(tester, 2);
      expect(find.byKey(const Key('speciesSearchField')), findsOneWidget);

      // Switch back to Discover tab
      await switchTab(tester, 0);

      // Completion screen MUST strictly persist!
      expect(find.text('Fauna Challenge Complete!'), findsOneWidget);
      expect(find.text('Final Score: 37 / 37 (100%)'), findsOneWidget);
      expect(find.text('🏆 Himalayan Master Naturalist'), findsOneWidget);
      expect(find.text('Restart Quiz'), findsOneWidget);
      expect(find.text('Shuffle Questions'), findsOneWidget);
    });

    testWidgets('APS4.2: Completion screen with non-100% score preserves exact percentage and rank across tabs', (tester) async {
      // Use custom 4-question bank with controller to test specific score breakdown
      final customQuestions = [
        kFaunaQuizQuestions[0],
        kFaunaQuizQuestions[1],
        kFaunaQuizQuestions[2],
        kFaunaQuizQuestions[3],
      ];
      final controller = FaunaQuizController(questions: customQuestions);

      // Answer 3 correct, 1 wrong -> 3 / 4 (75%)
      controller.selectAnswer(customQuestions[0].correctIndex); // Correct
      controller.nextQuestion();
      controller.selectAnswer(customQuestions[1].correctIndex); // Correct
      controller.nextQuestion();
      controller.selectAnswer(customQuestions[2].correctIndex); // Correct
      controller.nextQuestion();
      controller.selectAnswer((customQuestions[3].correctIndex + 1) % 4); // Wrong
      controller.nextQuestion();

      expect(controller.isCompleted, isTrue);
      expect(controller.score, 3);
      expect(controller.totalQuestions, 4);

      // Pump into test scaffold simulating tab-like mount/unmount
      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) {
              return Scaffold(
                body: SingleChildScrollView(
                  child: InteractiveFaunaChallengeCard(controller: controller),
                ),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Fauna Challenge Complete!'), findsOneWidget);
      expect(find.text('Final Score: 3 / 4 (75%)'), findsOneWidget);
      expect(find.text('🌲 Apprentice Ranger'), findsOneWidget);

      // Rebuild widget tree (simulating tab switch disposal and recreation)
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Container(key: const Key('dummyOtherTab')),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('dummyOtherTab')), findsOneWidget);

      // Re-mount Discover tab with same controller
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

      expect(find.text('Fauna Challenge Complete!'), findsOneWidget);
      expect(find.text('Final Score: 3 / 4 (75%)'), findsOneWidget);
      expect(find.text('🌲 Apprentice Ranger'), findsOneWidget);
      expect(find.text('Restart Quiz'), findsOneWidget);
      expect(find.text('Shuffle Questions'), findsOneWidget);
    });
  });

  group('Adversarial Persistence Suite 5: Restart & Shuffle After Tab Switches', () {
    testWidgets('APS5.1: Restarting quiz after tab switch resets to Question 1 with zero score and persists', (tester) async {
      setAdversarialViewport(tester);
      await tester.pumpWidget(const KashmirZoologyApp());
      await tester.pumpAndSettle();

      // Answer Q0 and advance
      await tapVisible(tester, find.text('Kashmir Stag (Hangul)'));
      await tapVisible(tester, find.text('Next Question'));

      // Switch tabs
      await switchTab(tester, 1);
      await switchTab(tester, 0);

      // Answer Q1 incorrectly and advance
      expect(find.textContaining('Question 2/'), findsOneWidget);
      await tapVisible(tester, find.text('Himalayan Brown Bear'));
      await tapVisible(tester, find.text('Next Question'));

      expect(find.textContaining('Question 3/'), findsOneWidget);

      // Fast-forward to completion by answering remaining questions
      for (int i = 2; i < kFaunaQuizQuestions.length; i++) {
        final q = kFaunaQuizQuestions[i];
        await tapVisible(tester, find.text(q.options[q.correctIndex]));
        await tapVisible(tester, find.text('Next Question'));
      }

      expect(find.text('Fauna Challenge Complete!'), findsOneWidget);

      // Switch tabs while in completion view
      await switchTab(tester, 2);
      await switchTab(tester, 0);

      expect(find.text('Fauna Challenge Complete!'), findsOneWidget);

      // Tap 'Restart Quiz'
      await tapVisible(tester, find.text('Restart Quiz'));

      // Must be back at Question 1 with Score 0 and neutral options
      expect(find.textContaining('Question 1/37'), findsOneWidget);
      expect(find.text('Score: 0 / 37'), findsOneWidget);
      expect(find.byIcon(Icons.radio_button_unchecked), findsNWidgets(4));
      expect(findCurrentQuestion()?.id, 'q-mammal-hangul-01');

      // Tab switch after restart: state must still be Question 1 with score 0
      await switchTab(tester, 1);
      await switchTab(tester, 0);

      expect(find.textContaining('Question 1/37'), findsOneWidget);
      expect(find.text('Score: 0 / 37'), findsOneWidget);
      expect(findCurrentQuestion()?.id, 'q-mammal-hangul-01');
    });

    testWidgets('APS5.2: Tapping Shuffle Questions randomizes questions and shuffled order persists across tab switches', (tester) async {
      setAdversarialViewport(tester);
      await tester.pumpWidget(const KashmirZoologyApp());
      await tester.pumpAndSettle();

      // Quickly reach completion screen
      for (int i = 0; i < kFaunaQuizQuestions.length; i++) {
        final q = kFaunaQuizQuestions[i];
        await tapVisible(tester, find.text(q.options[q.correctIndex]));
        await tapVisible(tester, find.text('Next Question'));
      }

      expect(find.text('Fauna Challenge Complete!'), findsOneWidget);

      // Tap 'Shuffle Questions'
      await tapVisible(tester, find.text('Shuffle Questions'));

      // Quiz must restart at Question 1 with Score 0
      expect(find.textContaining('Question 1/37'), findsOneWidget);
      expect(find.text('Score: 0 / 37'), findsOneWidget);

      // Identify the new first question
      final firstShuffledQuestion = findCurrentQuestion();
      expect(firstShuffledQuestion, isNotNull);

      // Switch tabs back and forth
      await rapidTabCycle(tester, [1, 2, 0]);

      // Verify the EXACT SAME shuffled question is still displayed
      expect(find.textContaining('Question 1/37'), findsOneWidget);
      expect(find.text('Score: 0 / 37'), findsOneWidget);
      expect(findCurrentQuestion()?.id, firstShuffledQuestion!.id);
      expect(find.text(firstShuffledQuestion.prompt), findsOneWidget);
    });
  });

  group('Adversarial Persistence Suite 6: Widget Lifecycle & Adverse Interruption Invariants', () {
    testWidgets('APS6.1: Simulated AppLifecycleState transitions while answering do not corrupt quiz state', (tester) async {
      setAdversarialViewport(tester);
      await tester.pumpWidget(const KashmirZoologyApp());
      await tester.pumpAndSettle();

      // Select an answer
      await tapVisible(tester, find.text('Kashmir Stag (Hangul)'));
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);

      // Simulate app being minimized (inactive/hidden/paused) then resumed
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pump();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();

      // State must be completely intact
      expect(find.textContaining('Question 1/'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
      expect(find.textContaining('Dachigam National Park'), findsOneWidget);
      expect(find.text('Next Question'), findsOneWidget);
      expect(find.text('Score: 1 / 37'), findsOneWidget);

      // Tab switch after resume
      await switchTab(tester, 1);
      await switchTab(tester, 0);

      expect(find.textContaining('Question 1/'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
      expect(find.text('Next Question'), findsOneWidget);
    });

    testWidgets('APS6.2: Mid-tap immediate tab switch without frame settling does not throw unmounted exceptions', (tester) async {
      setAdversarialViewport(tester);
      await tester.pumpWidget(const KashmirZoologyApp());
      await tester.pumpAndSettle();

      // Tap option and immediately switch tab without pumpAndSettle
      await tapVisible(tester, find.text('Kashmir Stag (Hangul)'));
      final guideTabFinder = find.byKey(const Key('guideTab'));
      await tester.ensureVisible(guideTabFinder);
      await tester.tap(guideTabFinder);

      // Single tick pump while transition is happening
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);

      // Return to Discover
      await switchTab(tester, 0);
      expect(find.textContaining('Question 1/'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
