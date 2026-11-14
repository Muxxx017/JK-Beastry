import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zoology_app/data/observation_store.dart';
import 'package:zoology_app/data/offline_taxa_store.dart';
import 'package:zoology_app/data/species_data.dart';
import 'package:zoology_app/main.dart';
import 'package:zoology_app/models/field_observation.dart';
import 'package:zoology_app/models/inat_taxon.dart';
import 'package:zoology_app/models/zoology_species.dart';
import 'package:zoology_app/screens/species_detail_page.dart';
import 'package:zoology_app/widgets/species_reference_photo.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await ObservationStore().save([]);
  });

  group('Tier 4 - Real-World Zoological Scenarios', () {
    testWidgets('Scenario 1: Field Explorer Dachigam Expedition', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const KashmirZoologyApp());
      await tester.pumpAndSettle();

      // 1. Navigate to Guide tab
      await tester.tap(find.byKey(const Key('guideTab')));
      await tester.pumpAndSettle();

      // 2. Search Hangul by vernacular name "hangul"
      await tester.enterText(find.byKey(const Key('speciesSearchField')), 'hangul');
      await tester.pumpAndSettle();

      expect(find.text('Kashmir Stag'), findsAtLeast(1));

      // 3. Open detail page
      await tester.tap(find.text('Kashmir Stag').first);
      await tester.pumpAndSettle();

      // 4. Verify Dachigam habitat notes and critically endangered status
      expect(find.textContaining('Dachigam'), findsAtLeast(1));
      expect(find.text('Critically Endangered'), findsAtLeast(1));
      expect(find.byType(SpeciesReferencePhoto), findsOneWidget);

      // 5. Scroll to and trigger vocalization player
      await tester.scrollUntilVisible(
        find.byType(InteractiveVocalizationWidget),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      final playBtn = find.descendant(
        of: find.byType(InteractiveVocalizationWidget),
        matching: find.byType(IconButton),
      );
      await tester.tap(playBtn);
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byIcon(Icons.pause_rounded), findsOneWidget);

      // Stop simulation
      await tester.tap(playBtn);
      await tester.pump(const Duration(milliseconds: 50));

      // 6. Log sighting
      await tester.scrollUntilVisible(
        find.text('Log Sighting'),
        -300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Log Sighting'));
      await tester.pumpAndSettle();

      final store = ObservationStore();
      final observation = FieldObservation(
        id: 'dachigam-hangul-001',
        speciesName: 'Kashmir Stag (Hangul)',
        location: 'Dachigam National Park, Upper Dagwan River',
        notes: 'Heard resonant autumn bugles from ridge line.',
        photoBase64: null,
        observedAt: DateTime.now(),
      );
      await store.save([observation]);

      final saved = await store.load();
      expect(saved.any((o) => o.id == 'dachigam-hangul-001'), isTrue);
    });

    test('Scenario 2: High-Altitude Ladakh Snow Leopard Survey', () {
      // 1. Survey Ladakh mammals
      final ladakhMammals = kSpeciesCatalog.where(
        (s) => s.category == 'Mammal' && s.region.toLowerCase().contains('ladakh'),
      ).toList();

      expect(ladakhMammals, isNotEmpty);

      // 2. Verify Snow Leopard details
      final snowLeopard = ladakhMammals.firstWhere((s) => s.id == 'snow-leopard');
      expect(snowLeopard.scientificName, equals('Panthera uncia'));
      expect(snowLeopard.conservation, equals('Vulnerable'));
      expect(snowLeopard.habitat.toLowerCase(), contains('alpine'));
      expect(snowLeopard.funFact.toLowerCase(), contains('tail'));

      // 3. Verify co-occurring Ladakh predators and ungulates
      final mammalIds = ladakhMammals.map((s) => s.id).toSet();
      expect(mammalIds, contains('himalayan-wolf'));
      expect(mammalIds, contains('pallas-cat'));
      expect(mammalIds, contains('bharal'));
      expect(mammalIds, contains('tibetan-wild-ass'));
    });

    testWidgets('Scenario 3: Wildlife Quiz Master Session', (tester) async {
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

      // Question 1: Hangul bugle in Dachigam
      expect(find.textContaining('Question 1/'), findsOneWidget);
      await tester.tap(find.text('Kashmir Stag (Hangul)'));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
      expect(find.textContaining('Dachigam National Park'), findsOneWidget);
      await tester.tap(find.text('Next Question'));
      await tester.pumpAndSettle();

      // Question 2: Ghost of the Mountains (Snow Leopard)
      expect(find.textContaining('Question 2/'), findsOneWidget);
      await tester.tap(find.text('Snow Leopard'));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
      expect(find.textContaining('Panthera uncia'), findsOneWidget);
      await tester.tap(find.text('Next Question'));
      await tester.pumpAndSettle();

      // Question 3: Iridescent pheasant (Himalayan Monal)
      expect(find.textContaining('Question 3/'), findsOneWidget);
      await tester.tap(find.text('Himalayan Monal'));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
      await tester.tap(find.text('Next Question'));
      await tester.pumpAndSettle();

      // Question 4: Talus slope sentry whistles (Himalayan Marmot)
      expect(find.textContaining('Question 4/'), findsOneWidget);
      await tester.tap(find.text('Himalayan Marmot'));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
      await tester.tap(find.text('Next Question'));
      await tester.pumpAndSettle();

      // Question 5: Khont river fish (Kashmiri Snow Trout)
      expect(find.textContaining('Question 5/'), findsOneWidget);
      await tester.tap(find.text('Kashmiri Snow Trout'));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
      await tester.tap(find.text('Next Question'));
      await tester.pumpAndSettle();

      // Advances smoothly to question 6 without stalling
      expect(find.textContaining('Question 6/'), findsOneWidget);
    });

    test('Scenario 4: Multi-Taxa Field Guide Discovery', () {
      const taxaCategories = ['Mammal', 'Bird', 'Reptile', 'Amphibian', 'Fish', 'Insect'];

      for (final category in taxaCategories) {
        final speciesInTaxa = kSpeciesCatalog.where((s) => s.category == category).toList();

        // 1. Must contain entries
        expect(speciesInTaxa, isNotEmpty, reason: 'Category $category has 0 entries');

        // 2. Strict zero flora check
        expect(
          speciesInTaxa.any((s) => s.category.toLowerCase() == 'plant'),
          isFalse,
          reason: 'Plant entry detected in $category',
        );

        // 3. Complete taxonomy
        for (final species in speciesInTaxa) {
          expect(species.taxonomy['Kingdom'], equals('Animalia'));
          expect(species.taxonomy['Phylum'], isNotEmpty);
          expect(species.taxonomy['Class'], isNotEmpty);
          expect(species.taxonomy['Order'], isNotEmpty);
          expect(species.taxonomy['Family'], isNotEmpty);
          expect(species.taxonomy['Genus'], isNotEmpty);
        }
      }

      // Check key regional representatives
      final ids = kSpeciesCatalog.map((s) => s.id).toSet();
      expect(ids, contains('western-tragopan')); // Bird
      expect(ids, contains('himalayan-pit-viper')); // Reptile
      expect(ids, contains('himalayan-toad')); // Amphibian
      expect(ids, contains('kashmir-snow-trout')); // Fish
      expect(ids, contains('ladybird')); // Insect
    });

    testWidgets('Scenario 5: Complete Offline Field Mode Simulation', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      // 1. Bundled species loads without network
      final hangul = kSpeciesCatalog.firstWhere((s) => s.id == 'hangul');
      await tester.pumpWidget(
        MaterialApp(
          home: SpeciesDetailPage(species: hangul),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(SpeciesReferencePhoto), findsOneWidget);

      // 2. Unbundled species renders fallback art plate cleanly
      const unbundledOffline = ZoologySpecies(
        id: 'remote-alpine-vole',
        commonName: 'Remote Alpine Vole',
        scientificName: 'Alticola roylei',
        category: 'Mammal',
        region: 'Pir Panjal',
        status: 'Present',
        habitat: 'Rocky screes',
        size: '12 cm',
        conservation: 'Least Concern',
        feature: 'Dense grey fur',
        funFact: 'Active under snowpack',
        imageUrl: 'https://unreachable.offline.host/vole.jpg',
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: SpeciesDetailPage(species: unbundledOffline),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(SpeciesReferencePhoto), findsOneWidget);
      expect(find.text('Remote Alpine Vole'), findsAtLeast(1));

      // 3. Offline observation persistence
      // Valid 1x1 transparent PNG in base64
      const validPngBase64 = 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=';
      final store = ObservationStore();
      final offlineObs = FieldObservation(
        id: 'offline-expedition-note',
        speciesName: 'Remote Alpine Vole',
        location: 'Sinthan Top, 3,800m',
        notes: 'Observed moving between scree crevices under sub-zero wind.',
        photoBase64: validPngBase64,
        observedAt: DateTime.now(),
      );

      await store.save([offlineObs]);
      final loaded = await store.load();

      expect(loaded.any((o) => o.id == 'offline-expedition-note'), isTrue);
      final retrieved = loaded.firstWhere((o) => o.id == 'offline-expedition-note');
      expect(retrieved.photoBytes, isNotEmpty);

      // Clean store for subsequent tests
      await store.save([]);

      // 4. Offline downloaded taxa lookup
      final taxaStore = OfflineTaxaStore();
      const cachedTaxon = InatTaxon(
        id: 55555,
        name: 'Alticola roylei',
        commonName: 'Royle\'s Mountain Vole',
        rank: 'species',
        regionalObservations: 5,
        totalObservations: 40,
        conservationStatus: 'Least Concern',
        photoUrl: null,
        photoAttribution: null,
        photoLicense: null,
        wikipediaUrl: null,
      );

      await taxaStore.save(cachedTaxon);
      final taxonResult = await taxaStore.findByScientificName('Alticola roylei');
      expect(taxonResult, isNotNull);
      expect(taxonResult!.id, equals(55555));

      await taxaStore.remove(55555);
    });

    testWidgets('Scenario 6: End-to-End Field Journal Observation Workflow', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const KashmirZoologyApp());
      await tester.pumpAndSettle();

      // Navigate to Journal tab
      await tester.tap(find.byKey(const Key('journalTab')));
      await tester.pumpAndSettle();

      // Open field notebook
      await tester.tap(find.byKey(const Key('fieldNotebookToggle')));
      await tester.pumpAndSettle();

      // Fill in sighting details
      await tester.ensureVisible(find.byKey(const Key('observationNotesField')));
      await tester.enterText(
        find.byKey(const Key('observationNotesField')),
        'Fresh tracks of Himalayan Brown Bear near the alpine stream.',
      );

      // Save observation
      await tester.ensureVisible(find.byKey(const Key('saveObservationButton')));
      await tester.tap(find.byKey(const Key('saveObservationButton')));
      await tester.pumpAndSettle();

      // Verify observation appears in field journal entries
      expect(find.textContaining('Fresh tracks of Himalayan Brown Bear'), findsOneWidget);
    });
  });
}
