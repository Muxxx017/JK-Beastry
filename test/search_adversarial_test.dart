import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zoology_app/data/species_data.dart';
import 'package:zoology_app/main.dart';
import 'package:zoology_app/models/zoology_species.dart';
import 'package:zoology_app/screens/online_species_page.dart';
import 'package:zoology_app/services/inat_service.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  // ---------------------------------------------------------------------------
  // Comprehensive collection of adversarial strings
  // ---------------------------------------------------------------------------
  final extremeQueries = <String>[
    // Empty & whitespace variations
    '',
    ' ',
    '     ',
    '\t',
    '\n',
    '\r\n',
    '\t  \r\n \t',
    '\u00A0', // Non-breaking space
    '\u200B', // Zero-width space
    '\uFEFF', // Zero-width non-breaking space (BOM)

    // Pure punctuation & repeated separators
    '-',
    '--',
    '---',
    '------',
    '___',
    '- - -',
    '_ _ _',
    '.',
    '..',
    '...',
    ',',
    ',,,',
    ':',
    ';',
    '!',
    '!!!',
    '?',
    '???',
    '!@#\$%^&*()_+-=[]{}|;\':",./<>?',
    '//\\\\',
    '/',
    '\\',
    '\'',
    '\'\'\'',
    '"',
    '"""',
    '()',
    '(())',
    '[]',
    '[[]]',
    '{}',
    '{{}}',
    '<script>',
    '</script>',
    '<!-- comment -->',

    // Regex metacharacters & ReDoS candidates
    '.*',
    '^.*\$',
    '+',
    '++',
    '+++',
    '*',
    '**',
    '?',
    '??',
    '(',
    ')',
    '(?',
    '(?=',
    '(?!',
    '[',
    ']',
    '[^a-z0-9]',
    '\\d+',
    '\\w+',
    '\\s+',
    '\\b',
    '\\b\\b\\b',
    '|',
    '|||',
    '^',
    '\$',
    '\$\$\$',
    'a{1,1000}',
    '(a+)+',
    '([a-zA-Z]+)*',
    '((a*)*)*',

    // Injection & format strings
    '\' OR \'1\'=\'1',
    '\' OR 1=1 --',
    '<script>alert("xss")</script>',
    '\x00',
    '\x00snow',
    'snow\x00leopard',
    '%s%d%n%x',
    '{{7*7}}',
    '\${7*7}',

    // Emojis & multi-byte unicode
    '🐆',
    '🦌',
    '❄️🐆',
    '🐻',
    '🦅',
    '🦗🕷️🐍',
    '👨‍👩‍👧‍👦',

    // RTL & non-Latin scripts
    'پلنگ برفی',
    'ہنگل',
    'हिम तेंदुआ',
    'हंगुल',
    '雪豹',
    'Тигр',

    // Accented / diacritics
    'héron',
    'café',
    'naïve',
    'fauna señor',

    // Extreme length strings
    'a' * 100,
    'a' * 500,
    'snow leopard ' * 30,
    'cervus-hanglu-hanglu-' * 25,
    '-' * 150,
    '?' * 150,
    'a-b c_d. ' * 50,
  ];

  // ===========================================================================
  // GROUP 1: computeSpeciesRelevanceTier Robustness on Extreme Queries
  // ===========================================================================
  group('Adversarial Group 1: computeSpeciesRelevanceTier under extreme inputs', () {
    test('computeSpeciesRelevanceTier never throws and returns valid tier [0, 4] across all extreme queries for all catalog species', () {
      final sampleSpecies = [
        kSpeciesCatalog.firstWhere((s) => s.id == 'snow-leopard'),
        kSpeciesCatalog.firstWhere((s) => s.id == 'hangul'),
        kSpeciesCatalog.firstWhere((s) => s.id == 'himalayan-brown-bear'),
        kSpeciesCatalog.firstWhere((s) => s.id == 'western-tragopan'),
        kSpeciesCatalog.firstWhere((s) => s.id == 'ladybird'),
      ];

      for (final species in sampleSpecies) {
        for (final query in extremeQueries) {
          final tier = computeSpeciesRelevanceTier(species, query);
          expect(tier, inInclusiveRange(0, 4),
              reason: 'Query "$query" on species "${species.id}" produced invalid tier $tier');
        }
      }
    });

    test('All 144 catalog species evaluate safely against core adversarial inputs', () {
      final coreAdversarial = [
        '',
        '   ',
        '---',
        '__',
        '.*',
        '(?=',
        '\\b',
        '\'',
        '"',
        '\\',
        '[a-z]',
        '🐆',
        'a' * 200,
      ];

      for (final species in kSpeciesCatalog) {
        for (final query in coreAdversarial) {
          final tier = computeSpeciesRelevanceTier(species, query);
          expect(tier, inInclusiveRange(0, 4),
              reason: 'Species ${species.id} failed on query "$query" with tier $tier');
        }
      }
    });

    test('computeSpeciesRelevanceTier handles synthetic edge-case species safely', () {
      final syntheticSpecies = ZoologySpecies(
        id: 'synthetic-edge-case',
        commonName: '',
        scientificName: '',
        category: 'Mammal',
        status: 'Rare',
        region: 'Ladakh',
        habitat: '',
        size: '',
        conservation: '',
        feature: '',
        funFact: '',
        audioAsset: null,
        isVocal: false,
        vocalization: '',
        ecologicalRole: '',
        threats: '',
        taxonomy: {},
        searchTerms: [],
        imageUrl: '',
      );

      for (final query in extremeQueries) {
        expect(() => computeSpeciesRelevanceTier(syntheticSpecies, query), returnsNormally);
        final tier = computeSpeciesRelevanceTier(syntheticSpecies, query);
        expect(tier, inInclusiveRange(0, 4));
      }
    });
  });

  // ===========================================================================
  // GROUP 2: matchCuratedSpecies Robustness on Extreme Queries
  // ===========================================================================
  group('Adversarial Group 2: matchCuratedSpecies under extreme inputs', () {
    test('matchCuratedSpecies returns valid List<ZoologySpecies> without throwing for all extreme queries', () {
      for (final query in extremeQueries) {
        expect(() => matchCuratedSpecies(query), returnsNormally,
            reason: 'Query "$query" threw an exception');
        final matches = matchCuratedSpecies(query);
        expect(matches, isA<List<ZoologySpecies>>());
      }
    });

    test('matchCuratedSpecies returns empty list for queries with no alphanumeric content', () {
      final nonAlphanumeric = [
        '',
        ' ',
        '   \t\n  ',
        '---',
        '------',
        '___',
        '???',
        '!!!',
        '!@#\$%^&*()',
        '//\\\\',
        '\'\'\'',
        '"""',
        '🐆',
        '🦌',
        'پلنگ', // Arabic script has no a-z0-9 tokens
      ];

      for (final query in nonAlphanumeric) {
        final matches = matchCuratedSpecies(query);
        expect(matches, isEmpty,
            reason: 'Expected empty curated matches for non-alphanumeric query "$query", got ${matches.length}');
      }
    });

    test('matchCuratedSpecies never returns plant species even with adversarial queries', () {
      for (final query in ['flora', 'plant', 'tree', 'pine', 'cedar', 'moss', 'grass']) {
        final matches = matchCuratedSpecies(query);
        for (final m in matches) {
          expect(m.category, isNot(equals('Plant')),
              reason: 'Curated match ${m.commonName} has category Plant');
        }
      }
    });
  });

  // ===========================================================================
  // GROUP 3: Punctuation, Hyphenation & Casing Combinations
  // ===========================================================================
  group('Adversarial Group 3: Punctuation, Hyphenation & Casing combinations', () {
    test('Chaotic casing and hyphenation combinations match intended fauna', () {
      final snowLeopard = kSpeciesCatalog.firstWhere((s) => s.id == 'snow-leopard');

      final snowLeopardQueries = [
        'sNoW-lEoPaRd',
        'SNOW--LEOPARD',
        'snow---leopard',
        '  sNoW   lEoPaRd  ',
        'sNoW_lEoPaRd',
        'snow-leopard!',
        '--snow-leopard--',
        '(snow leopard)',
        '"snow leopard"',
        '\'snow-leopard\'',
      ];

      for (final q in snowLeopardQueries) {
        final tier = computeSpeciesRelevanceTier(snowLeopard, q);
        expect(tier, lessThanOrEqualTo(1),
            reason: 'Query "$q" on snow leopard failed to reach Tier 0 or 1, got tier $tier');

        final matches = matchCuratedSpecies(q);
        expect(matches.map((s) => s.id), contains('snow-leopard'),
            reason: 'matchCuratedSpecies failed to find snow-leopard for query "$q"');
      }
    });

    test('Hangul casing and double hyphenation combinations match Hangul', () {
      final hangul = kSpeciesCatalog.firstWhere((s) => s.id == 'hangul');

      final hangulQueries = [
        'cervus--hanglu',
        'CeRvUs-HaNgLu',
        'CERVUS--HANGLU--HANGLU',
        'cervus - - hanglu',
        'cervus-hanglu!',
        'kashmir--stag',
        'KASHMIR-STAG',
        'HaNgUl',
        '"hangul"',
        'hangul!',
      ];

      for (final q in hangulQueries) {
        final tier = computeSpeciesRelevanceTier(hangul, q);
        expect(tier, lessThanOrEqualTo(1),
            reason: 'Query "$q" on hangul failed to reach Tier 0 or 1, got tier $tier');

        final matches = matchCuratedSpecies(q);
        expect(matches.map((s) => s.id), contains('hangul'),
            reason: 'matchCuratedSpecies failed to find hangul for query "$q"');
      }
    });

    test('Pallas cat apostrophe, hyphens, and punctuation variations', () {
      final pallasCat = kSpeciesCatalog.firstWhere((s) => s.id == 'pallas-cat');

      final pallasQueries = [
        "pallas's cat",
        'pallas\'s cat',
        "PALLAS'S CAT",
        "pallas-cat",
        "pallas--cat",
        "pallas's--cat",
        "pallas  cat",
        "pallas's cat!",
      ];

      for (final q in pallasQueries) {
        final tier = computeSpeciesRelevanceTier(pallasCat, q);
        expect(tier, lessThanOrEqualTo(2),
            reason: 'Query "$q" on pallas cat failed to reach name tier (<= 2), got tier $tier');

        final matches = matchCuratedSpecies(q);
        expect(matches.map((s) => s.id), contains('pallas-cat'),
            reason: 'matchCuratedSpecies failed to find pallas-cat for query "$q"');
      }
    });

    test('Seven-spot ladybird exclamation, hyphens, and whitespace variations', () {
      final ladybird = kSpeciesCatalog.firstWhere((s) => s.id == 'ladybird');

      final ladybirdQueries = [
        'seven-spot ladybird!',
        'SEVEN-SPOT LADYBIRD',
        'seven--spot--ladybird',
        'seven  spot  ladybird',
        'seven-spot-ladybird!',
        'seven-spot',
        'seven spot ladybird?',
      ];

      for (final q in ladybirdQueries) {
        final tier = computeSpeciesRelevanceTier(ladybird, q);
        expect(tier, lessThanOrEqualTo(1),
            reason: 'Query "$q" on ladybird failed to reach Tier 0 or 1, got tier $tier');

        final matches = matchCuratedSpecies(q);
        expect(matches.map((s) => s.id), contains('ladybird'),
            reason: 'matchCuratedSpecies failed to find ladybird for query "$q"');
      }
    });
  });

  // ===========================================================================
  // GROUP 4: High-Throughput Fuzzing & Performance
  // ===========================================================================
  group('Adversarial Group 4: High-throughput fuzzing & performance', () {
    test('1,000 rapid randomized adversarial queries execute without crash or ReDoS', () {
      final rng = Random(42);
      final charPool = 'abcdefghijklmnopqrstuvwxyz0123456789 -_.,!?:;\'"()[]{}+*^%#@\$~`/\t\n🐆';

      final stopwatch = Stopwatch()..start();

      for (int i = 0; i < 1000; i++) {
        final length = rng.nextInt(35);
        final buffer = StringBuffer();
        for (int j = 0; j < length; j++) {
          buffer.write(charPool[rng.nextInt(charPool.length)]);
        }
        final randomQuery = buffer.toString();

        final species = kSpeciesCatalog[rng.nextInt(kSpeciesCatalog.length)];
        final tier = computeSpeciesRelevanceTier(species, randomQuery);
        expect(tier, inInclusiveRange(0, 4));
      }

      stopwatch.stop();
      // Ensure 1000 tier calculations finish in under 1 second (linear O(N) performance)
      expect(stopwatch.elapsedMilliseconds, lessThan(1000),
          reason: '1000 tier computations took too long: ${stopwatch.elapsedMilliseconds}ms');
    });

    test('100 randomized queries against full-catalog matchCuratedSpecies complete efficiently', () {
      final rng = Random(123);
      final charPool = 'abcdefghijklmnopqrstuvwxyz0123456789 -_.,!?';

      final stopwatch = Stopwatch()..start();

      for (int i = 0; i < 100; i++) {
        final length = rng.nextInt(20);
        final buffer = StringBuffer();
        for (int j = 0; j < length; j++) {
          buffer.write(charPool[rng.nextInt(charPool.length)]);
        }
        final randomQuery = buffer.toString();

        final matches = matchCuratedSpecies(randomQuery);
        expect(matches, isNotNull);
      }

      stopwatch.stop();
      // 100 full catalog searches (14,400 tokenizations) must complete in under 5 seconds
      expect(stopwatch.elapsedMilliseconds, lessThan(5000),
          reason: '100 catalog searches took too long: ${stopwatch.elapsedMilliseconds}ms');
    });
  });

  // ===========================================================================
  // GROUP 5: Widget UI Adversarial Input Stress Test
  // ===========================================================================
  group('Adversarial Group 5: Widget UI Adversarial Input Stress Test', () {
    testWidgets('Entering extreme and adversarial queries into UI search field does not crash',
        (WidgetTester tester) async {
      await tester.pumpWidget(const KashmirZoologyApp());
      await tester.pumpAndSettle();

      // Navigate to Guide tab
      await tester.tap(find.byKey(const Key('guideTab')));
      await tester.pumpAndSettle();

      final searchFinder = find.byKey(const Key('speciesSearchField'));
      expect(searchFinder, findsOneWidget);

      final testInputs = [
        '---',
        '   ',
        '.*',
        '(?=',
        '\\b',
        '<script>alert("hack")</script>',
        '\' OR 1=1 --',
        '🐆🦌🐻',
        'a' * 120,
        'sNoW-lEoPaRd',
        'cervus--hanglu',
        'pallas\'s cat',
        'seven-spot ladybird!',
        '',
      ];

      for (final input in testInputs) {
        await tester.enterText(searchFinder, input);
        await tester.pumpAndSettle();

        // Either species list or empty-state text must render without crash
        final hasList = find.byType(SliverList).evaluate().isNotEmpty ||
            find.text('No matching species found.').evaluate().isNotEmpty;
        expect(hasList, isTrue, reason: 'Failed UI render for query "$input"');
      }

      // Verify targeted query displays intended species
      await tester.enterText(searchFinder, 'sNoW-lEoPaRd');
      await tester.pumpAndSettle();
      expect(find.text('Snow Leopard'), findsAtLeast(1));

      // Verify clear / reset
      await tester.enterText(searchFinder, '');
      await tester.pumpAndSettle();
      expect(find.text('Snow Leopard'), findsAtLeast(1));
    });

    testWidgets('OnlineSpeciesPage search handles adversarial inputs gracefully',
        (WidgetTester tester) async {
      final fakeService = InatService();
      addTearDown(fakeService.close);

      await tester.pumpWidget(
        MaterialApp(
          home: OnlineSpeciesPage(service: fakeService),
        ),
      );
      await tester.pumpAndSettle();

      final searchFinder = find.byKey(const Key('onlineSpeciesSearchField'));
      expect(searchFinder, findsOneWidget);

      for (final input in ['---', '.*', '(a+)+', '🐆', 'sNoW-lEoPaRd']) {
        await tester.enterText(searchFinder, input);
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pumpAndSettle();
      }

      // Curated card for snow leopard should appear
      expect(find.text('Snow Leopard'), findsAtLeast(1));
    });
  });
}
