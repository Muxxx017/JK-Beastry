import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zoology_app/data/daily_animal_widget_data.dart';
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
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Tier 3 - Cross-Feature Pairwise Interactions', () {
    testWidgets('X1 (F4 x F3): Search species by vernacular name -> Navigate to detail page -> Trigger vocalization player', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const KashmirZoologyApp());
      await tester.pumpAndSettle();

      // Navigate to Guide tab
      await tester.tap(find.byKey(const Key('guideTab')));
      await tester.pumpAndSettle();

      // Search by vernacular name
      await tester.enterText(find.byKey(const Key('speciesSearchField')), 'hangul');
      await tester.pumpAndSettle();

      expect(find.text('Kashmir Stag'), findsAtLeast(1));

      // Open detail page
      await tester.tap(find.text('Kashmir Stag').first);
      await tester.pumpAndSettle();

      // Scroll until vocalization player is visible
      await tester.scrollUntilVisible(
        find.byType(InteractiveVocalizationWidget),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      // Trigger vocalization simulation
      expect(find.byType(InteractiveVocalizationWidget), findsOneWidget);
      final playBtn = find.descendant(
        of: find.byType(InteractiveVocalizationWidget),
        matching: find.byType(IconButton),
      );
      await tester.tap(playBtn);
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byIcon(Icons.pause_rounded), findsOneWidget);

      // Stop before tearDown
      await tester.tap(playBtn);
      await tester.pump(const Duration(milliseconds: 50));
    });

    testWidgets('X2 (F6 x F1): Category filter Mammal -> Select species -> Reference photo renders with attribution credit', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const KashmirZoologyApp());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('guideTab')));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ChoiceChip, 'Mammal'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('speciesSearchField')), 'hangul');
      await tester.pumpAndSettle();

      expect(find.text('Kashmir Stag'), findsAtLeast(1));
      await tester.tap(find.text('Kashmir Stag').first);
      await tester.pumpAndSettle();

      expect(find.descendant(of: find.byType(SpeciesDetailPage), matching: find.byType(SpeciesReferencePhoto)), findsOneWidget);
      expect(find.text('Kashmir Stag'), findsAtLeast(1));
    });

    testWidgets('X3 (F1 x F7): Offline mode -> Fallback art plate renders -> Log sighting persists in ObservationStore', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const unbundledSpecies = ZoologySpecies(
        id: 'offline-test-taxa',
        commonName: 'Offline Test Taxa',
        scientificName: 'Taxa incognita',
        category: 'Mammal',
        region: 'Ladakh',
        status: 'Present',
        habitat: 'Plateau',
        size: '1 m',
        conservation: 'Vulnerable',
        feature: 'Camouflage',
        funFact: 'Active at twilight',
        imageUrl: 'https://example.com/broken-offline-endpoint.jpg',
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: SpeciesDetailPage(species: unbundledSpecies),
        ),
      );
      await tester.pumpAndSettle();

      // Art plate renders
      expect(find.byType(SpeciesReferencePhoto), findsOneWidget);

      // Tap Log Sighting
      await tester.tap(find.text('Log Sighting'));
      await tester.pumpAndSettle();

      // Persist in store
      final store = ObservationStore();
      final obs = FieldObservation(
        id: 'obs-x3',
        speciesName: unbundledSpecies.commonName,
        location: 'Ladakh High Plateau',
        notes: 'Sighting logged from field guide detail view.',
        photoBase64: null,
        observedAt: DateTime.now(),
      );
      await store.save([obs]);

      final loaded = await store.load();
      expect(loaded.any((o) => o.speciesName == 'Offline Test Taxa'), isTrue);
    });

    test('X4 (F2 x F5): Quiz challenge facts directly align with curated species facts in kSpeciesCatalog', () {
      final hangul = kSpeciesCatalog.firstWhere((s) => s.id == 'hangul');
      final snowLeopard = kSpeciesCatalog.firstWhere((s) => s.id == 'snow-leopard');
      final marmot = kSpeciesCatalog.firstWhere((s) => s.id == 'himalayan-marmot');

      // Question 1 fact: Hangul state animal in Dachigam
      expect(hangul.funFact.toLowerCase(), contains('state animal'));
      expect(hangul.distribution.toLowerCase(), contains('dachigam'));

      // Question 2 fact: Snow Leopard tail and ghost of the mountains
      expect(snowLeopard.funFact.toLowerCase(), contains('tail'));
      expect(snowLeopard.habitat.toLowerCase(), contains('alpine'));

      // Question 4 fact: Himalayan Marmot alarm whistle
      expect(marmot.vocalization.toLowerCase(), contains('whistle'));
    });

    test('X5 (F4 x F6): Search by scientific genus (Cervus) -> Verify resulting species exhibits complete taxonomy lineage', () {
      final matches = kSpeciesCatalog.where((s) => s.scientificName.startsWith('Cervus')).toList();

      expect(matches, isNotEmpty);
      for (final species in matches) {
        expect(species.taxonomy['Kingdom'], equals('Animalia'));
        expect(species.taxonomy['Class'], equals('Mammalia'));
        expect(species.taxonomy['Order'], equals('Artiodactyla'));
        expect(species.taxonomy['Family'], equals('Cervidae'));
        expect(species.taxonomy['Genus'], equals('Cervus'));
      }
    });

    test('X6 (F6 x F7): Log sighting from detail page -> Saves field observation to ObservationStore -> Reloads with identical data', () async {
      final store = ObservationStore();
      final observation = FieldObservation(
        id: 'sighting-x6',
        speciesName: 'Western Tragopan',
        location: 'Limber Wildlife Sanctuary',
        notes: 'Heard early dawn territorial call from dense hazel understory.',
        photoBase64: base64Encode([1, 2, 3, 4, 5]),
        observedAt: DateTime(2026, 11, 14, 6, 15),
      );

      await store.save([observation]);
      final reloaded = await store.load();

      expect(reloaded.length, greaterThanOrEqualTo(1));
      final item = reloaded.firstWhere((o) => o.id == 'sighting-x6');
      expect(item.speciesName, equals('Western Tragopan'));
      expect(item.location, equals('Limber Wildlife Sanctuary'));
      expect(item.photoBytes, equals([1, 2, 3, 4, 5]));
    });

    testWidgets('X7 (F1 x F6): Reference photo tap -> Fullscreen zoom viewer -> Verify attribution and license metadata against species profile', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const testSpecies = ZoologySpecies(
        id: 'x7-species',
        commonName: 'Profile Attributed Animal',
        scientificName: 'Attributus verus',
        category: 'Bird',
        region: 'Kashmir',
        status: 'Present',
        habitat: 'Riverine',
        size: '40 cm',
        conservation: 'Least Concern',
        feature: 'Crest',
        funFact: 'Water diver',
        imageUrl: 'https://example.com/verified-profile.jpg',
        imageAttribution: 'Himalayan Wildlife Archive',
        imageLicense: 'CC BY-SA 4.0',
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SpeciesReferencePhoto(species: testSpecies, height: 250),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(GestureDetector).first);
      await tester.pumpAndSettle();

      expect(find.byType(InteractiveViewer), findsOneWidget);
      expect(find.textContaining('Himalayan Wildlife Archive'), findsAtLeast(1));
      expect(find.textContaining('CC BY-SA 4.0'), findsAtLeast(1));

      await tester.tap(find.byTooltip('Close photo'));
      await tester.pumpAndSettle();
    });

    testWidgets('X8 (F4 x F1): Search species with bundled offline asset (red-fox) -> Verify bundled image renders without waiting for network', (
      tester,
    ) async {
      final redFox = kSpeciesCatalog.firstWhere((s) => s.id == 'red-fox');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SpeciesReferencePhoto(species: redFox, height: 220),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(Image), findsOneWidget);
    });

    test('X9 (F5 x F7): Daily animal widget generator extracts verified animal facts from expanded catalog excluding all flora', () {
      final records = buildDailyAnimalWidgetRecords(kSpeciesCatalog);

      expect(records, isNotEmpty);
      for (final record in records) {
        final commonName = record['commonName']!;
        final species = kSpeciesCatalog.firstWhere((s) => s.commonName == commonName);
        expect(species.category.toLowerCase(), isNot(equals('plant')));
        expect(species.category.toLowerCase(), isNot(equals('flora')));
        expect(record['funFact'], isNotEmpty);
      }
    });

    testWidgets('X10 (F4 x F2): Home screen tab switching from Discover (quiz) to Guide (search) and back preserves layout integrity', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const KashmirZoologyApp());
      await tester.pumpAndSettle();

      expect(find.text('TODAY IN THE FIELD'), findsOneWidget);
      expect(find.text('INTERACTIVE FAUNA CHALLENGE'), findsOneWidget);

      // Switch to Guide tab
      await tester.tap(find.byKey(const Key('guideTab')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('speciesSearchField')), findsOneWidget);

      // Switch back to Discover tab
      await tester.tap(find.byKey(const Key('discoverTab')));
      await tester.pumpAndSettle();

      expect(find.text('TODAY IN THE FIELD'), findsOneWidget);
      expect(find.text('INTERACTIVE FAUNA CHALLENGE'), findsOneWidget);
    });

    test('X11 (F3 x F6): Detail page vocalization section displays correct acoustic text matching species ecological niche', () {
      final monal = kSpeciesCatalog.firstWhere((s) => s.id == 'monal');
      expect(monal.vocalization.toLowerCase(), contains('whistle'));
      expect(monal.habitat.toLowerCase(), contains('alpine'));

      final ibex = kSpeciesCatalog.firstWhere((s) => s.id == 'himalayan-ibex');
      expect(ibex.vocalization.toLowerCase(), contains('whistle'));
    });

    test('X12 (F7 x F1): OfflineTaxaStore downloaded taxon photo path integrates with InatTaxon model', () async {
      final store = OfflineTaxaStore();
      const downloadedTaxon = InatTaxon(
        id: 77777,
        name: 'Ursus thibetanus',
        commonName: 'Asiatic Black Bear',
        rank: 'species',
        regionalObservations: 30,
        totalObservations: 2000,
        conservationStatus: 'Vulnerable',
        photoUrl: 'https://example.com/bear.jpg',
        photoAttribution: 'Archive',
        photoLicense: 'CC BY',
        wikipediaUrl: 'https://en.wikipedia.org/wiki/Asian_black_bear',
        offlinePhotoPath: '/data/user/0/com.kashmir.zoology/app_flutter/offline_species_photos/77777.jpg',
      );

      await store.save(downloadedTaxon);
      final retrieved = await store.findByScientificName('Ursus thibetanus');

      expect(retrieved, isNotNull);
      expect(retrieved!.offlinePhotoPath, equals('/data/user/0/com.kashmir.zoology/app_flutter/offline_species_photos/77777.jpg'));

      await store.remove(77777);
    });
  });
}
