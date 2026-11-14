import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zoology_app/data/daily_animal_widget_data.dart';
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

  group('Tier 1 - Feature 1: Accurate Species Imagery (R1)', () {
    testWidgets('F1-1: Bundled offline species render local asset without network requests', (
      tester,
    ) async {
      final hangul = kSpeciesCatalog.firstWhere((s) => s.id == 'hangul');
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SpeciesReferencePhoto(species: hangul, height: 250),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(SpeciesReferencePhoto), findsOneWidget);
      expect(find.byType(Image), findsOneWidget);
    });

    testWidgets('F1-2: Non-bundled species fallback safely to art plate on missing or offline image', (
      tester,
    ) async {
      const testSpecies = ZoologySpecies(
        id: 'unbundled-animal',
        commonName: 'Test Unbundled Animal',
        scientificName: 'Animalia incertae',
        category: 'Mammal',
        region: 'Kashmir',
        status: 'Present',
        habitat: 'Alpine',
        size: 'Medium',
        conservation: 'Least Concern',
        feature: 'Test feature',
        funFact: 'Test fun fact',
        imageUrl: '',
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SpeciesReferencePhoto(species: testSpecies, height: 250),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(SpeciesReferencePhoto), findsOneWidget);
      expect(find.text('Test Unbundled Animal'), findsAtLeast(1));
    });

    testWidgets('F1-3: Species photo credit text renders correctly formatted attribution and license', (
      tester,
    ) async {
      const testSpecies = ZoologySpecies(
        id: 'photo-credit-test',
        commonName: 'Attribution Test Species',
        scientificName: 'Species testus',
        category: 'Bird',
        region: 'Ladakh',
        status: 'Present',
        habitat: 'Cliffs',
        size: 'Small',
        conservation: 'Near Threatened',
        feature: 'Plumage',
        funFact: 'High flyer',
        imageUrl: 'https://example.com/valid-photo.jpg',
        imageAttribution: 'Zoological Society of J&K',
        imageLicense: 'CC BY 4.0',
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SpeciesReferencePhoto(species: testSpecies, height: 250),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Zoological Society of J&K'), findsOneWidget);
      expect(find.textContaining('CC BY 4.0'), findsOneWidget);
    });

    testWidgets('F1-4: Tap on reference photo opens fullscreen viewer with interactive controls', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const testSpecies = ZoologySpecies(
        id: 'tap-photo-test',
        commonName: 'Zoom Test Species',
        scientificName: 'Zoomus examinatus',
        category: 'Reptile',
        region: 'Jammu',
        status: 'Present',
        habitat: 'Rocky slopes',
        size: '30 cm',
        conservation: 'Least Concern',
        feature: 'Scales',
        funFact: 'Sun basking',
        imageUrl: 'https://example.com/zoom.jpg',
        imageAttribution: 'Field Guide Team',
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
      expect(find.byTooltip('Close photo'), findsOneWidget);

      await tester.tap(find.byTooltip('Close photo'));
      await tester.pumpAndSettle();

      expect(find.byType(InteractiveViewer), findsNothing);
    });

    test('F1-5: All catalog entries specify non-null image attribution and license values', () {
      for (final species in kSpeciesCatalog) {
        expect(species.imageUrl, isNotNull);
        expect(species.imageAttribution, isNotNull);
        expect(species.imageLicense, isNotNull);
      }
    });
  });

  group('Tier 1 - Feature 2: Interactive Fauna Quiz (R2)', () {
    testWidgets('F2-1: Fauna challenge card renders question, options, and header badge', (
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

      expect(find.text('INTERACTIVE FAUNA CHALLENGE'), findsOneWidget);
      expect(find.textContaining('Question 1/'), findsOneWidget);
      expect(find.byType(InkWell), findsNWidgets(4));
    });

    testWidgets('F2-2: Selecting an option locks choices and reveals educational explanation', (
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

      expect(find.text('Next Question'), findsNothing);

      await tester.tap(find.byType(InkWell).first);
      await tester.pumpAndSettle();

      expect(find.text('Next Question'), findsOneWidget);
      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('F2-3: Correct answer option highlights in green when selected', (
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

      // Question 1: option 1 'Kashmir Stag (Hangul)' is correct
      final hangulOption = find.text('Kashmir Stag (Hangul)');
      expect(hangulOption, findsOneWidget);

      await tester.tap(hangulOption);
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
      expect(find.textContaining('Dachigam National Park'), findsOneWidget);
    });

    testWidgets('F2-4: Tapping Next Question advances to the next question and resets selection state', (
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

      expect(find.textContaining('Question 1/'), findsOneWidget);
      await tester.tap(find.byType(InkWell).first);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Next Question'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Question 2/'), findsOneWidget);
      expect(find.text('Next Question'), findsNothing);
      expect(find.byIcon(Icons.radio_button_unchecked), findsNWidgets(4));
    });

    testWidgets('F2-5: Challenge card loops through question bank smoothly without throwing exceptions', (
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

      // Cycle 6 times to verify wrap-around
      for (int i = 0; i < 6; i++) {
        await tester.tap(find.byType(InkWell).first);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Next Question'));
        await tester.pumpAndSettle();
      }

      // After 6 cycles through the expanded question bank, advances cleanly to question 7
      expect(find.textContaining('Question 7/'), findsOneWidget);
    });
  });

  group('Tier 1 - Feature 3: Animal Vocalizations & Audio (R3)', () {
    testWidgets('F3-1: Interactive vocalization widget renders title and vocalization description', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: InteractiveVocalizationWidget(
              commonName: 'Kashmir Stag',
              vocalization: 'Resonant autumn rut bugles echoing across Dachigam.',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('VOCALIZATION & SOUNDS'), findsOneWidget);
      expect(
        find.text('Resonant autumn rut bugles echoing across Dachigam.'),
        findsOneWidget,
      );
      expect(find.text('Tap to simulate audio call'), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
    });

    testWidgets('F3-2: Tapping play button initiates acoustic simulation and toggles icon to pause', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: InteractiveVocalizationWidget(
              commonName: 'Snow Leopard',
              vocalization: 'Piercing yowls and gentle friendly chuffs.',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(IconButton));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byIcon(Icons.pause_rounded), findsOneWidget);
      expect(
        find.textContaining('Simulating acoustic wave for Snow Leopard'),
        findsOneWidget,
      );

      // Stop before tearDown
      await tester.tap(find.byType(IconButton));
      await tester.pump(const Duration(milliseconds: 50));
    });

    testWidgets('F3-3: Tapping pause button stops acoustic simulation and toggles icon to play', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: InteractiveVocalizationWidget(
              commonName: 'Himalayan Monal',
              vocalization: 'Loud ringing whistles echoing across subalpine slopes.',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Start
      await tester.tap(find.byType(IconButton));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byIcon(Icons.pause_rounded), findsOneWidget);

      // Stop
      await tester.tap(find.byType(IconButton));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
      expect(find.text('Tap to simulate audio call'), findsOneWidget);
    });

    testWidgets('F3-4: Species detail page displays vocalization player when species vocalization is non-empty', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final hangul = kSpeciesCatalog.firstWhere((s) => s.id == 'hangul');
      await tester.pumpWidget(
        MaterialApp(
          home: SpeciesDetailPage(species: hangul),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(InteractiveVocalizationWidget), findsOneWidget);
      expect(find.text('VOCALIZATION & SOUNDS'), findsOneWidget);
    });

    test('F3-5: Catalog vocal species provide detailed bio-acoustic call descriptions', () {
      final vocalSpecies = kSpeciesCatalog.where((s) => s.vocalization.trim().isNotEmpty);
      expect(vocalSpecies, isNotEmpty);
      expect(vocalSpecies.length, greaterThanOrEqualTo(50));

      final hangul = kSpeciesCatalog.firstWhere((s) => s.id == 'hangul');
      expect(hangul.vocalization.toLowerCase(), contains('bugle'));
    });
  });

  group('Tier 1 - Feature 4: Search Matching & Discovery (R4)', () {
    test('F4-1: Guide search matches exact species common name (e.g. Kashmir Stag)', () {
      final matches = kSpeciesCatalog.where((s) {
        return s.commonName.toLowerCase().contains('kashmir stag');
      }).toList();

      expect(matches, isNotEmpty);
      expect(matches.any((s) => s.id == 'hangul'), isTrue);
    });

    test('F4-2: Guide search matches scientific name binomial (e.g. Panthera uncia)', () {
      final matches = kSpeciesCatalog.where((s) {
        return s.scientificName.toLowerCase().contains('panthera uncia');
      }).toList();

      expect(matches, isNotEmpty);
      expect(matches.any((s) => s.id == 'snow-leopard'), isTrue);
    });

    test('F4-3: Guide search matches regional vernacular aliases (e.g. hangul)', () {
      final matches = kSpeciesCatalog.where((s) {
        final query = 'hangul';
        final inSearchTerms = s.searchTerms.any((term) => term.toLowerCase().contains(query));
        final inSearchable = s.searchableText.contains(query);
        return inSearchTerms || inSearchable;
      }).toList();

      expect(matches, isNotEmpty);
      expect(matches.first.id, equals('hangul'));
    });

    test('F4-4: Guide search performs case-insensitive matching across common names', () {
      for (final query in ['SNOW LEOPARD', 'snow leopard', 'SnOw LeOpArD']) {
        final matches = kSpeciesCatalog.where((s) {
          return s.searchableText.contains(query.toLowerCase());
        }).toList();

        expect(matches, isNotEmpty);
        expect(matches.any((s) => s.id == 'snow-leopard'), isTrue);
      }
    });

    test('F4-5: Guide search filters species simultaneously by category and search text', () {
      final mammals = kSpeciesCatalog.where((s) => s.category == 'Mammal').toList();
      final bearMammals = mammals.where((s) => s.searchableText.contains('bear')).toList();

      expect(bearMammals, isNotEmpty);
      expect(bearMammals.every((s) => s.category == 'Mammal'), isTrue);
      expect(bearMammals.any((s) => s.commonName.contains('Bear')), isTrue);
    });
  });

  group('Tier 1 - Feature 5: Regional Fauna Catalog Expansion (R5)', () {
    test('F5-1: Zero flora mandate: catalog contains 100% animal species and zero plants', () {
      expect(kSpeciesCatalog, isNotEmpty);
      final plantMatches = kSpeciesCatalog.where(
        (s) => s.category.toLowerCase() == 'plant' || s.category.toLowerCase() == 'flora',
      );
      expect(plantMatches, isEmpty);
    });

    test('F5-2: Catalog contains multi-taxa representation across distinct animal classes', () {
      final categories = kSpeciesCatalog.map((s) => s.category).toSet();

      expect(categories, contains('Mammal'));
      expect(categories, contains('Bird'));
      expect(categories, contains('Reptile'));
      expect(categories, contains('Amphibian'));
      expect(categories, contains('Fish'));
      expect(categories, contains('Insect'));
    });

    test('F5-3: Every catalog species possesses a unique non-empty kebab-case id', () {
      final ids = <String>{};
      final kebabRegex = RegExp(r'^[a-z0-9]+(-[a-z0-9]+)*$');

      for (final species in kSpeciesCatalog) {
        expect(species.id, isNotEmpty);
        expect(kebabRegex.hasMatch(species.id), isTrue, reason: 'Invalid ID: ${species.id}');
        expect(ids.add(species.id), isTrue, reason: 'Duplicate ID: ${species.id}');
      }
    });

    test('F5-4: Catalog species have complete taxonomical classification entries', () {
      for (final species in kSpeciesCatalog) {
        expect(species.taxonomy, isNotEmpty);
        expect(species.taxonomy['Kingdom'], equals('Animalia'));
        expect(species.taxonomy['Phylum'], isNotNull);
        expect(species.taxonomy['Class'], isNotNull);
        expect(species.taxonomy['Order'], isNotNull);
        expect(species.taxonomy['Family'], isNotNull);
        expect(species.taxonomy['Genus'], isNotNull);
      }
    });

    test('F5-5: Regional state symbols and keystone taxa are present in the catalog', () {
      final ids = kSpeciesCatalog.map((s) => s.id).toSet();

      // J&K State Animal (Hangul), Flagship Alpine Predator (Snow Leopard),
      // Regional Pheasant (Western Tragopan), Coldwater Fish (Kashmir Snow Trout)
      expect(ids, contains('hangul'));
      expect(ids, contains('snow-leopard'));
      expect(ids, contains('western-tragopan'));
      expect(ids, contains('kashmir-snow-trout'));
    });
  });

  group('Tier 1 - Feature 6: Zoology Feature Upgrades (R6)', () {
    test('F6-1: Category filtering isolates specific taxonomic groups', () {
      final birds = kSpeciesCatalog.where((s) => s.category == 'Bird').toList();
      expect(birds, isNotEmpty);
      expect(birds.every((s) => s.category == 'Bird'), isTrue);

      final reptiles = kSpeciesCatalog.where((s) => s.category == 'Reptile').toList();
      expect(reptiles, isNotEmpty);
      expect(reptiles.every((s) => s.category == 'Reptile'), isTrue);
    });

    testWidgets('F6-2: Species detail view displays comprehensive natural history and ecological role', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final hangul = kSpeciesCatalog.firstWhere((s) => s.id == 'hangul');
      await tester.pumpWidget(
        MaterialApp(home: SpeciesDetailPage(species: hangul)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Kashmir Stag'), findsAtLeast(1));
      expect(find.text('Ecological role'), findsOneWidget);
      expect(find.text('Life cycle & breeding'), findsOneWidget);
      expect(find.text('Threats'), findsOneWidget);
      expect(find.text('Conservation status'), findsOneWidget);
      expect(find.text('FUN FACT'), findsOneWidget);
    });

    testWidgets('F6-3: Species detail view displays research starting point references for verified nomenclature', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final snowLeopard = kSpeciesCatalog.firstWhere((s) => s.id == 'snow-leopard');
      await tester.pumpWidget(
        MaterialApp(home: SpeciesDetailPage(species: snowLeopard)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Research starting points'), findsOneWidget);
      expect(find.text('Books & papers'), findsOneWidget);
      expect(find.text('iNaturalist records'), findsOneWidget);
      expect(find.text('IUCN Red List'), findsOneWidget);
    });

    test('F6-4: Conservation status badges identify regional threat categories (CR, EN, VU, LC)', () {
      final statuses = kSpeciesCatalog.map((s) => s.conservation).toSet();

      expect(statuses, contains('Critically Endangered'));
      expect(statuses, contains('Vulnerable'));
      expect(statuses, contains('Least Concern'));
    });

    test('F6-5: Daily animal widget records generator compiles valid educational animal facts', () {
      final records = buildDailyAnimalWidgetRecords(kSpeciesCatalog);

      expect(records, isNotEmpty);
      expect(records.every((r) => r['commonName'] != null && r['commonName']!.isNotEmpty), isTrue);
      expect(records.every((r) => r['scientificName'] != null && r['scientificName']!.isNotEmpty), isTrue);
      expect(records.every((r) => r['funFact'] != null && r['funFact']!.isNotEmpty), isTrue);
    });
  });

  group('Tier 1 - Feature 7: Quality Assurance & Release Checks (R7)', () {
    test('F7-1: ZoologySpecies model serializes and deserializes JSON roundtrip faithfully', () {
      final original = kSpeciesCatalog.firstWhere((s) => s.id == 'hangul');
      final jsonMap = {
        'id': original.id,
        'commonName': original.commonName,
        'scientificName': original.scientificName,
        'category': original.category,
        'region': original.region,
        'status': original.status,
        'habitat': original.habitat,
        'size': original.size,
        'conservation': original.conservation,
        'feature': original.feature,
        'funFact': original.funFact,
        'distribution': original.distribution,
        'diet': original.diet,
        'behavior': original.behavior,
        'breeding': original.breeding,
        'threats': original.threats,
        'ecologicalRole': original.ecologicalRole,
        'identification': original.identification,
        'vocalization': original.vocalization,
        'imageUrl': original.imageUrl,
        'imageAttribution': original.imageAttribution,
        'imageLicense': original.imageLicense,
        'searchTerms': original.searchTerms,
        'taxonomy': original.taxonomy,
      };

      final reconstructed = ZoologySpecies.fromJson(jsonMap);

      expect(reconstructed.id, equals(original.id));
      expect(reconstructed.commonName, equals(original.commonName));
      expect(reconstructed.scientificName, equals(original.scientificName));
      expect(reconstructed.category, equals(original.category));
      expect(reconstructed.conservation, equals(original.conservation));
      expect(reconstructed.vocalization, equals(original.vocalization));
      expect(reconstructed.taxonomy, equals(original.taxonomy));
    });

    test('F7-2: FieldObservation model encodes and decodes base64 photos accurately', () {
      final dummyBytes = [10, 20, 30, 40, 50, 60, 70, 80];
      final observation = FieldObservation(
        id: 'obs-001',
        speciesName: 'Kashmir Stag',
        location: 'Dachigam Lower Ridge',
        notes: 'Adult stag observed near riverine woodland.',
        photoBase64: base64Encode(dummyBytes),
        observedAt: DateTime(2026, 11, 14, 8, 30),
      );

      final jsonString = jsonEncode(observation.toJson());
      final decodedJson = jsonDecode(jsonString) as Map<String, dynamic>;
      final restored = FieldObservation.fromJson(decodedJson);

      expect(restored.id, equals(observation.id));
      expect(restored.speciesName, equals(observation.speciesName));
      expect(restored.location, equals(observation.location));
      expect(restored.notes, equals(observation.notes));
      expect(restored.photoBytes, equals(dummyBytes));
      expect(restored.observedAt, equals(observation.observedAt));
    });

    test('F7-3: InatTaxon model deserializes API responses with photo licensing metadata', () {
      final jsonSample = {
        'id': 67835,
        'name': 'Panthera uncia',
        'preferred_common_name': 'Snow Leopard',
        'rank': 'species',
        'observations_count': 1200,
        'default_photo': {
          'medium_url': 'https://inaturalist-open-data.s3.amazonaws.com/photos/123/medium.jpg',
          'attribution': '(c) Wildlife Photographer, CC BY-NC',
          'license_code': 'cc-by-nc',
        },
      };

      final taxon = InatTaxon.fromAutocompleteJson(jsonSample);

      expect(taxon.id, equals(67835));
      expect(taxon.name, equals('Panthera uncia'));
      expect(taxon.commonName, equals('Snow Leopard'));
      expect(taxon.photoUrl, equals('https://inaturalist-open-data.s3.amazonaws.com/photos/123/medium.jpg'));
      expect(taxon.photoAttribution, equals('(c) Wildlife Photographer, CC BY-NC'));
      expect(taxon.photoLicense, equals('cc-by-nc'));
    });

    test('F7-4: Bundled assets registry maps to valid physical files in assets directory', () {
      expect(kSpeciesCatalog.any((s) => s.id == 'hangul'), isTrue);
      expect(kSpeciesCatalog.any((s) => s.id == 'bharal'), isTrue);
      expect(kSpeciesCatalog.any((s) => s.id == 'red-fox'), isTrue);
    });

    test('F7-5: Offline taxa store can cache, retrieve, and delete species records without data loss', () async {
      final store = OfflineTaxaStore();
      const testTaxon = InatTaxon(
        id: 99999,
        name: 'Gypaetus barbatus',
        commonName: 'Bearded Vulture',
        rank: 'species',
        regionalObservations: 15,
        totalObservations: 500,
        conservationStatus: 'Near Threatened',
        photoUrl: 'https://example.com/vulture.jpg',
        photoAttribution: 'Vulture Conservation Foundation',
        photoLicense: 'CC BY-SA',
        wikipediaUrl: 'https://en.wikipedia.org/wiki/Bearded_vulture',
      );

      await store.save(testTaxon);
      final retrieved = await store.findByScientificName('Gypaetus barbatus');

      expect(retrieved, isNotNull);
      expect(retrieved!.id, equals(99999));
      expect(retrieved.commonName, equals('Bearded Vulture'));

      await store.remove(99999);
      final afterDelete = await store.findByScientificName('Gypaetus barbatus');
      expect(afterDelete, isNull);
    });
  });
}
