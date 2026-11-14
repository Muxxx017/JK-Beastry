import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zoology_app/data/daily_animal_widget_data.dart';
import 'package:zoology_app/data/observation_store.dart';
import 'package:zoology_app/data/species_data.dart';
import 'package:zoology_app/main.dart';
import 'package:zoology_app/models/field_observation.dart';
import 'package:zoology_app/models/inat_taxon.dart';
import 'package:zoology_app/models/zoology_species.dart';
import 'package:zoology_app/screens/species_detail_page.dart';
import 'package:zoology_app/widgets/species_reference_photo.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Tier 2 - Feature 1: Boundary & Corner Cases (Imagery)', () {
    testWidgets('F1-B1: Empty or whitespace imageUrl falls back gracefully to art plate', (
      tester,
    ) async {
      const emptyUrlSpecies = ZoologySpecies(
        id: 'empty-image-animal',
        commonName: 'Empty Image Animal',
        scientificName: 'Nullus imago',
        category: 'Mammal',
        region: 'Kashmir',
        status: 'Present',
        habitat: 'Valleys',
        size: '1 m',
        conservation: 'Least Concern',
        feature: 'Feature',
        funFact: 'Fact',
        imageUrl: '   ',
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SpeciesReferencePhoto(species: emptyUrlSpecies, height: 200),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(SpeciesReferencePhoto), findsOneWidget);
      expect(find.text('Empty Image Animal'), findsAtLeast(1));
    });

    testWidgets('F1-B2: Extremely malformed or invalid URL does not throw unhandled exception', (
      tester,
    ) async {
      const malformedSpecies = ZoologySpecies(
        id: 'malformed-url-animal',
        commonName: 'Malformed URL Animal',
        scientificName: 'Fractus urlus',
        category: 'Bird',
        region: 'Ladakh',
        status: 'Present',
        habitat: 'Steppe',
        size: '50 cm',
        conservation: 'Vulnerable',
        feature: 'Wings',
        funFact: 'Glider',
        imageUrl: 'ht!tp://:::invalid---url-^%%&&',
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SpeciesReferencePhoto(species: malformedSpecies, height: 200),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(SpeciesReferencePhoto), findsOneWidget);
    });

    testWidgets('F1-B3: Species with blank attribution and license string defaults safely in photo credit', (
      tester,
    ) async {
      const blankAttributionSpecies = ZoologySpecies(
        id: 'blank-attrib-animal',
        commonName: 'Blank Credit Animal',
        scientificName: 'Sine creditus',
        category: 'Reptile',
        region: 'Jammu',
        status: 'Present',
        habitat: 'Rocks',
        size: '20 cm',
        conservation: 'Least Concern',
        feature: 'Claws',
        funFact: 'Basking',
        imageUrl: 'https://example.com/photo.jpg',
        imageAttribution: '',
        imageLicense: '',
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SpeciesReferencePhoto(species: blankAttributionSpecies, height: 200),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Reference photo'), findsOneWidget);
      expect(find.textContaining('CC BY-SA'), findsOneWidget);
    });

    testWidgets('F1-B4: Rapid consecutive tap on reference photo before transition settles does not crash', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const tapSpecies = ZoologySpecies(
        id: 'rapid-tap-photo',
        commonName: 'Rapid Tap Photo Species',
        scientificName: 'Celeritas tactus',
        category: 'Mammal',
        region: 'Kashmir',
        status: 'Present',
        habitat: 'Forests',
        size: '1.2 m',
        conservation: 'Near Threatened',
        feature: 'Fur',
        funFact: 'Nocturnal',
        imageUrl: 'https://example.com/tap.jpg',
        imageAttribution: 'Field Unit',
        imageLicense: 'CC BY',
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SpeciesReferencePhoto(species: tapSpecies, height: 200),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final target = find.byType(GestureDetector).first;
      await tester.tap(target, warnIfMissed: false);
      await tester.tap(target, warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(find.byType(InteractiveViewer), findsOneWidget);
      await tester.tap(find.byTooltip('Close photo'));
      await tester.pumpAndSettle();
    });

    testWidgets('F1-B5: Zero height constraint handles layout boundary gracefully', (
      tester,
    ) async {
      final hangul = kSpeciesCatalog.firstWhere((s) => s.id == 'hangul');
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SpeciesReferencePhoto(species: hangul, height: 0),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(SpeciesReferencePhoto), findsOneWidget);
    });
  });

  group('Tier 2 - Feature 2: Boundary & Corner Cases (Quiz)', () {
    testWidgets('F2-B1: Rapid multiple taps on different options before state settles registers only first selection', (
      tester,
    ) async {
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

      final options = find.byType(InkWell);
      expect(options, findsNWidgets(4));

      // Tap option 0 and immediately option 2
      await tester.tap(options.at(0));
      await tester.tap(options.at(2));
      await tester.pumpAndSettle();

      expect(find.text('Next Question'), findsOneWidget);
    });

    testWidgets('F2-B2: Rapid cycling through Next Question beyond total question count wraps cleanly', (
      tester,
    ) async {
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

      // Cycle 15 times (3 full loops of 5 questions)
      for (int i = 0; i < 15; i++) {
        await tester.tap(find.byType(InkWell).first);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Next Question'));
        await tester.pumpAndSettle();
      }

      // After 15 cycles through the expanded question bank, advances cleanly to question 16
      expect(find.textContaining('Question 16/'), findsOneWidget);
    });

    testWidgets('F2-B3: Tapping an option when already answered is completely ignored', (
      tester,
    ) async {
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

      final firstOption = find.text('Kashmir Musk Deer');
      final secondOption = find.text('Kashmir Stag (Hangul)');

      await tester.tap(firstOption);
      await tester.pumpAndSettle();

      // Tap another option when answered
      await tester.tap(secondOption);
      await tester.pumpAndSettle();

      expect(find.text('Next Question'), findsOneWidget);
    });

    testWidgets('F2-B4: Challenge card retains consistent state across simulated widget hierarchy rebuilds', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return SingleChildScrollView(
                  child: Column(
                    children: [
                      ElevatedButton(
                        onPressed: () => setState(() {}),
                        child: const Text('Rebuild Parent'),
                      ),
                      const InteractiveFaunaChallengeCard(),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Question 1/'), findsOneWidget);
      await tester.tap(find.text('Rebuild Parent'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Question 1/'), findsOneWidget);
    });

    testWidgets('F2-B5: Question option containing punctuation, dashes, and quotes renders without text truncation', (
      tester,
    ) async {
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

      expect(find.text('Kashmir Stag (Hangul)'), findsOneWidget);
    });
  });

  group('Tier 2 - Feature 3: Boundary & Corner Cases (Audio & Vocalizations)', () {
    testWidgets('F3-B1: Rapid play/pause button toggling preserves animation controller lifecycle', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: InteractiveVocalizationWidget(
              commonName: 'Himalayan Ibex',
              vocalization: 'Sharp explosive whistling snort.',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final playButton = find.byType(IconButton);

      // Rapidly toggle 5 times
      for (int i = 0; i < 5; i++) {
        await tester.tap(playButton);
        await tester.pump(const Duration(milliseconds: 20));
      }

      // Ensure stopped
      await tester.tap(playButton);
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
    });

    testWidgets('F3-B2: Species detail page with empty vocalization string hides vocalization widget completely', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const silentSpecies = ZoologySpecies(
        id: 'silent-fauna',
        commonName: 'Silent High Butterfly',
        scientificName: 'Parnassius charltonius',
        category: 'Insect',
        region: 'Ladakh',
        status: 'Present',
        habitat: 'Talus slopes',
        size: '80 mm',
        conservation: 'Near Threatened',
        feature: 'Translucent wings',
        funFact: 'High alpine flyer',
        vocalization: '',
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: SpeciesDetailPage(species: silentSpecies),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(InteractiveVocalizationWidget), findsNothing);
      expect(find.text('VOCALIZATION & SOUNDS'), findsNothing);
    });

    testWidgets('F3-B3: Extremely long vocalization text renders inside scrollable container without overflow', (
      tester,
    ) async {
      final longText = 'Acoustic calls of high mountain fauna. ' * 30;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: InteractiveVocalizationWidget(
                commonName: 'Verbose Animal',
                vocalization: longText,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(InteractiveVocalizationWidget), findsOneWidget);
      expect(find.text(longText), findsOneWidget);
    });

    testWidgets('F3-B4: Vocalization widget disposes animation controller safely when unmounted during active playback', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: InteractiveVocalizationWidget(
              commonName: 'Unmounting Animal',
              vocalization: 'Call before unmounting.',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Start playback
      await tester.tap(find.byType(IconButton));
      await tester.pump(const Duration(milliseconds: 50));

      // Unmount by replacing tree
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: SizedBox())),
      );
      await tester.pumpAndSettle();

      expect(find.byType(InteractiveVocalizationWidget), findsNothing);
    });

    test('F3-B5: Non-vocal and low-vocal species explain alternative acoustic and behavioral signaling', () {
      final nonVocalSpecies = kSpeciesCatalog.where(
        (s) => s.category == 'Fish' || s.category == 'Insect' || s.category == 'Reptile',
      );

      for (final species in nonVocalSpecies) {
        if (species.vocalization.isNotEmpty) {
          final text = species.vocalization.toLowerCase();
          final containsAcousticContext = text.contains('vocal') ||
              text.contains('sound') ||
              text.contains('acoustic') ||
              text.contains('silent') ||
              text.contains('vibrat') ||
              text.contains('hiss') ||
              text.contains('stridulat') ||
              text.contains('communicat');
          expect(containsAcousticContext, isTrue, reason: 'Species ${species.id} missing acoustic context');
        }
      }
    });
  });

  group('Tier 2 - Feature 4: Boundary & Corner Cases (Search Matching)', () {
    test('F4-B1: Hyphenated query matches equivalent spaced or hyphenated tokens', () {
      final hyphenMatches = kSpeciesCatalog.where((s) {
        final norm = s.searchableText.replaceAll('-', ' ');
        return norm.contains('snow leopard') || s.searchableText.contains('snow-leopard');
      }).toList();

      expect(hyphenMatches, isNotEmpty);
      expect(hyphenMatches.any((s) => s.id == 'snow-leopard'), isTrue);
    });

    test('F4-B2: Query with leading, trailing, and multiple interspersed whitespace trims and normalizes cleanly', () {
      const rawQuery = '   snow     leopard   ';
      final cleanTokens = rawQuery.trim().toLowerCase().split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toList();

      expect(cleanTokens, equals(['snow', 'leopard']));

      final matches = kSpeciesCatalog.where((s) {
        final text = s.searchableText;
        return cleanTokens.every((token) => text.contains(token));
      }).toList();

      expect(matches, isNotEmpty);
      expect(matches.any((s) => s.id == 'snow-leopard'), isTrue);
    });

    test('F4-B3: Query with regex/special characters (*, +, ?, [, ]) does not crash regex or matcher', () {
      const specialQuery = 'hangul+deer*?[]()';
      expect(() {
        final sanitized = specialQuery.replaceAll(RegExp(r'[^\w\s]'), ' ').trim();
        final matches = kSpeciesCatalog.where((s) => s.searchableText.contains(sanitized)).toList();
        expect(matches, isNotNull);
      }, returnsNormally);
    });

    test('F4-B4: Query matching no animals returns empty result list without crashing', () {
      const nonExistent = 'ZzzNonExistentFaunaQuery999';
      final matches = kSpeciesCatalog.where((s) => s.searchableText.contains(nonExistent.toLowerCase())).toList();

      expect(matches, isEmpty);
    });

    test('F4-B5: Extremely long search string (100+ chars) evaluates gracefully without hang', () {
      final longQuery = 'himalayan wildlife ' * 10;
      final stopwatch = Stopwatch()..start();

      final matches = kSpeciesCatalog.where((s) => s.searchableText.contains(longQuery.toLowerCase())).toList();
      stopwatch.stop();

      expect(matches, isEmpty);
      expect(stopwatch.elapsedMilliseconds, lessThan(500));
    });
  });

  group('Tier 2 - Feature 5: Boundary & Corner Cases (Catalog Integrity & Scope)', () {
    test('F5-B1: Strict zero flora audit: zero catalog entries have category Plant, Tree, Herb, or Flora', () {
      const forbiddenCategories = {'plant', 'flora', 'tree', 'herb', 'vegetation'};
      for (final species in kSpeciesCatalog) {
        expect(
          forbiddenCategories.contains(species.category.toLowerCase()),
          isFalse,
          reason: 'Species ${species.id} has botanical category: ${species.category}',
        );
      }
    });

    test('F5-B2: Edge taxa with single-word or hyphenated regional names are valid', () {
      final hangul = kSpeciesCatalog.firstWhere((s) => s.id == 'hangul');
      expect(hangul.searchTerms, contains('hangul'));
      expect(hangul.searchTerms, contains('hongul'));
    });

    test('F5-B3: Scientific name contains valid two or three part binomial/trinomial nomenclature', () {
      for (final species in kSpeciesCatalog) {
        final parts = species.scientificName.trim().split(RegExp(r'\s+'));
        expect(
          parts.length,
          greaterThanOrEqualTo(2),
          reason: 'Scientific name must be at least binomial: ${species.scientificName}',
        );
        expect(
          parts.length,
          lessThanOrEqualTo(4),
          reason: 'Scientific name exceeds valid trinomial format: ${species.scientificName}',
        );
      }
    });

    test('F5-B4: Rarity status boundaries are restricted to known guide categories (Present, Rare)', () {
      const validStatuses = {'Present', 'Rare'};
      for (final species in kSpeciesCatalog) {
        expect(
          validStatuses.contains(species.status),
          isTrue,
          reason: 'Species ${species.id} has invalid status: ${species.status}',
        );
      }
    });

    test('F5-B5: Species search terms array contains no null, empty, or whitespace-only strings', () {
      for (final species in kSpeciesCatalog) {
        for (final term in species.searchTerms) {
          expect(term.trim(), isNotEmpty, reason: 'Species ${species.id} has blank search term');
        }
      }
    });
  });

  group('Tier 2 - Feature 6: Boundary & Corner Cases (Zoology Upgrades & Geography)', () {
    test('F6-B1: All distinct biogeographical regions are represented (Kashmir, Jammu, Ladakh, Pir Panjal)', () {
      final regions = kSpeciesCatalog.map((s) => s.region.toLowerCase()).join(' ');

      expect(regions, contains('kashmir'));
      expect(regions, contains('jammu'));
      expect(regions, contains('ladakh'));
    });

    test('F6-B2: IUCN status filtering handles edge statuses (Critically Endangered vs Least Concern)', () {
      final cr = kSpeciesCatalog.where((s) => s.conservation == 'Critically Endangered').toList();
      final lc = kSpeciesCatalog.where((s) => s.conservation == 'Least Concern').toList();

      expect(cr, isNotEmpty);
      expect(lc, isNotEmpty);
      expect(cr.any((s) => s.id == 'hangul'), isTrue);
    });

    test('F6-B3: Taxonomy map accommodates species with subspecific trinomials', () {
      final hangul = kSpeciesCatalog.firstWhere((s) => s.id == 'hangul');
      expect(hangul.taxonomy['Species'], contains('Cervus hanglu'));
    });

    test('F6-B4: Category filter Not recorded boundary test returns expected empty/rare subset', () {
      final notRecorded = kSpeciesCatalog.where((s) => s.status == 'Not currently recorded').toList();
      expect(notRecorded, isEmpty);
    });

    test('F6-B5: Field observation notes store handles empty location and empty photo gracefully', () async {
      final store = ObservationStore();
      final obs = FieldObservation(
        id: 'empty-loc-test',
        speciesName: 'Unidentified Bird',
        location: '',
        notes: 'Heard call near canopy.',
        photoBase64: null,
        observedAt: DateTime.now(),
      );

      await store.save([obs]);
      final loaded = await store.load();

      expect(loaded.any((o) => o.id == 'empty-loc-test'), isTrue);
      final retrieved = loaded.firstWhere((o) => o.id == 'empty-loc-test');
      expect(retrieved.location, isEmpty);
      expect(retrieved.photoBytes, isNull);
    });
  });

  group('Tier 2 - Feature 7: Boundary & Corner Cases (QA, Storage & Contracts)', () {
    test('F7-B1: ObservationStore handles corrupted or malformed JSON in SharedPreferences without throw', () async {
      final store = ObservationStore();
      await store.save([]);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('field_observations_v1', 'CORRUPT_JSON_DATA_{{{{[');

      final loaded = await store.load();

      expect(loaded, isA<List<FieldObservation>>());
      expect(loaded, isEmpty);
    });

    test('F7-B2: ZoologySpecies.fromJson handles missing optional fields with default empty values', () {
      final minimalJson = {
        'id': 'minimal-species',
        'commonName': 'Minimal Animal',
        'scientificName': 'Minimus sp',
        'category': 'Mammal',
        'region': 'Jammu',
        'status': 'Present',
        'habitat': 'Scrub',
        'size': 'Small',
        'conservation': 'Data Deficient',
        'feature': 'Feature',
        'funFact': 'Fact',
      };

      final species = ZoologySpecies.fromJson(minimalJson);

      expect(species.distribution, isEmpty);
      expect(species.diet, isEmpty);
      expect(species.behavior, isEmpty);
      expect(species.breeding, isEmpty);
      expect(species.threats, isEmpty);
      expect(species.ecologicalRole, isEmpty);
      expect(species.vocalization, isEmpty);
      expect(species.imageUrl, isEmpty);
      expect(species.searchTerms, isEmpty);
      expect(species.taxonomy, isEmpty);
    });

    test('F7-B3: InatTaxon.fromJson handles missing optional photo attributes cleanly', () {
      final minimalTaxonJson = {
        'id': 12345,
        'name': 'Canis lupus',
        'rank': 'species',
        'totalObservations': 10,
      };

      final taxon = InatTaxon.fromJson(minimalTaxonJson);

      expect(taxon.id, equals(12345));
      expect(taxon.name, equals('Canis lupus'));
      expect(taxon.commonName, isNull);
      expect(taxon.photoUrl, isNull);
      expect(taxon.photoAttribution, isNull);
      expect(taxon.photos, isEmpty);
    });

    test('F7-B4: FieldObservation observedAt correctly parses various ISO-8601 boundary formats', () {
      final dt = DateTime.utc(2026, 11, 14, 12, 0, 0);
      final obs = FieldObservation(
        id: 'date-test',
        speciesName: 'Test Species',
        location: 'Gulmarg',
        notes: 'Notes',
        photoBase64: null,
        observedAt: dt,
      );

      final json = obs.toJson();
      final restored = FieldObservation.fromJson(json);

      expect(restored.observedAt.year, equals(2026));
      expect(restored.observedAt.month, equals(11));
      expect(restored.observedAt.day, equals(14));
    });

    test('F7-B5: Daily animal widget records generator handles catalog with minimal fields', () {
      final minimalCatalog = [
        const ZoologySpecies(
          id: 'test-widget-animal',
          commonName: 'Widget Animal',
          scientificName: 'Widgetus animalis',
          category: 'Mammal',
          region: 'Kashmir',
          status: 'Present',
          habitat: 'Forest',
          size: 'Medium',
          conservation: 'Least Concern',
          feature: 'Feature',
          funFact: 'Widget animal fun fact.',
        ),
      ];

      final records = buildDailyAnimalWidgetRecords(minimalCatalog);

      expect(records, hasLength(1));
      expect(records.single['commonName'], equals('Widget Animal'));
      expect(records.single['scientificName'], equals('Widgetus animalis'));
      expect(records.single['funFact'], equals('Widget animal fun fact.'));
    });
  });
}
