import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zoology_app/data/species_data.dart';
import 'package:zoology_app/main.dart';
import 'package:zoology_app/screens/online_species_page.dart';
import 'package:zoology_app/services/inat_service.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Milestone 4 - Search Matching & Tiered Relevance: Exact Name Search', () {
    test('Exact common name search identifies target species at Tier 0', () {
      final focalSpecies = [
        'Snow Leopard',
        'Western Tragopan',
        'Himalayan Brown Bear',
        'Golden Mahseer',
        'Seven-Spot Ladybird',
        'Himalayan Toad',
      ];

      for (final name in focalSpecies) {
        final species = kSpeciesCatalog.firstWhere(
          (s) => s.commonName.toLowerCase() == name.toLowerCase(),
        );
        final tier = computeSpeciesRelevanceTier(species, name);
        expect(tier, equals(0), reason: '$name should match at Tier 0');
      }
    });

    test('Exact scientific name binomial and trinomial matches at Tier 0', () {
      final focalScientific = [
        'Panthera uncia',
        'Cervus hanglu hanglu',
        'Ursus arctos isabellinus',
        'Tragopan melanocephalus',
        'Tor putitora',
      ];

      for (final sciName in focalScientific) {
        final species = kSpeciesCatalog.firstWhere(
          (s) => s.scientificName.toLowerCase() == sciName.toLowerCase(),
        );
        final tier = computeSpeciesRelevanceTier(species, sciName);
        expect(tier, equals(0), reason: '$sciName should match at Tier 0');
      }
    });

    test('Exact ID kebab-case search matches at Tier 0', () {
      final focalIds = [
        'snow-leopard',
        'hangul',
        'western-tragopan',
        'golden-mahseer',
        'ladybird',
        'himalayan-toad',
      ];

      for (final id in focalIds) {
        final species = kSpeciesCatalog.firstWhere((s) => s.id == id);
        final tier = computeSpeciesRelevanceTier(species, id);
        expect(tier, equals(0), reason: '$id should match at Tier 0');
      }
    });

    test('Case-insensitivity across uppercase, lowercase, and mixed queries', () {
      final snowLeopard = kSpeciesCatalog.firstWhere((s) => s.id == 'snow-leopard');
      for (final query in ['SNOW LEOPARD', 'snow leopard', 'sNoW lEoPaRd']) {
        expect(computeSpeciesRelevanceTier(snowLeopard, query), equals(0));
      }

      final hangul = kSpeciesCatalog.firstWhere((s) => s.id == 'hangul');
      for (final query in ['CERVUS HANGLU HANGLU', 'cervus hanglu hanglu', 'CeRvUs HaNgLu']) {
        final tier = computeSpeciesRelevanceTier(hangul, query);
        expect(tier, lessThanOrEqualTo(1));
      }
    });
  });

  group('Milestone 4 - Search Matching & Tiered Relevance: Partial & Prefix Search', () {
    test('Prefix search on common name evaluates to Tier 1', () {
      final snowLeopard = kSpeciesCatalog.firstWhere((s) => s.id == 'snow-leopard');
      expect(computeSpeciesRelevanceTier(snowLeopard, 'snow'), equals(1));

      final brownBear = kSpeciesCatalog.firstWhere((s) => s.id == 'himalayan-brown-bear');
      expect(computeSpeciesRelevanceTier(brownBear, 'himalayan'), equals(1));
    });

    test('Prefix search on scientific name evaluates to Tier 1', () {
      final snowLeopard = kSpeciesCatalog.firstWhere((s) => s.id == 'snow-leopard');
      expect(computeSpeciesRelevanceTier(snowLeopard, 'panth'), equals(1));

      final hangul = kSpeciesCatalog.firstWhere((s) => s.id == 'hangul');
      expect(computeSpeciesRelevanceTier(hangul, 'cerv'), equals(1));
    });

    test('Prefix search on species id evaluates to Tier 1', () {
      final hangul = kSpeciesCatalog.firstWhere((s) => s.id == 'hangul');
      expect(computeSpeciesRelevanceTier(hangul, 'hang'), equals(1));
    });

    test('Partial word-boundary search within commonName evaluates to Tier 2', () {
      final snowLeopard = kSpeciesCatalog.firstWhere((s) => s.id == 'snow-leopard');
      // "leop" is a word-boundary match inside "Snow Leopard"
      expect(computeSpeciesRelevanceTier(snowLeopard, 'leop'), equals(2));
      expect(computeSpeciesRelevanceTier(snowLeopard, 'leopard'), equals(2));
    });

    test('Partial search across multiple bird and fish taxa', () {
      final monal = kSpeciesCatalog.firstWhere((s) => s.id == 'monal');
      expect(computeSpeciesRelevanceTier(monal, 'himalayan'), equals(1));
      expect(computeSpeciesRelevanceTier(monal, 'monal'), equals(0));

      final mahseer = kSpeciesCatalog.firstWhere((s) => s.id == 'golden-mahseer');
      expect(computeSpeciesRelevanceTier(mahseer, 'mahseer'), lessThanOrEqualTo(2));
    });
  });

  group('Milestone 4 - Hyphenated and Punctuation Query Normalization', () {
    test('Hyphenated query matches space-separated common names at Tier 0', () {
      final snowLeopard = kSpeciesCatalog.firstWhere((s) => s.id == 'snow-leopard');
      expect(computeSpeciesRelevanceTier(snowLeopard, 'snow-leopard'), equals(0));
    });

    test('Hyphenated query matches species with hyphenated common names', () {
      final crane = kSpeciesCatalog.firstWhere((s) => s.id == 'black-necked-crane');
      expect(computeSpeciesRelevanceTier(crane, 'black-necked'), equals(1));
      expect(computeSpeciesRelevanceTier(crane, 'black necked'), equals(1));
    });

    test('Pallas-cat hyphen and apostrophe variations match', () {
      final pallasCat = kSpeciesCatalog.firstWhere((s) => s.id == 'pallas-cat');
      expect(computeSpeciesRelevanceTier(pallasCat, 'pallas-cat'), equals(0));
      expect(computeSpeciesRelevanceTier(pallasCat, 'pallas cat'), equals(0));
    });

    test('Query with irregular and excess whitespace normalizes cleanly', () {
      final snowLeopard = kSpeciesCatalog.firstWhere((s) => s.id == 'snow-leopard');
      expect(computeSpeciesRelevanceTier(snowLeopard, '   snow     leopard   '), equals(0));
    });

    test('Query with punctuation characters does not crash matcher', () {
      final hangul = kSpeciesCatalog.firstWhere((s) => s.id == 'hangul');
      expect(computeSpeciesRelevanceTier(hangul, 'hangul!'), equals(0));
      expect(computeSpeciesRelevanceTier(hangul, 'hangul...'), equals(0));
      expect(() => computeSpeciesRelevanceTier(hangul, 'hangul, deer?'), returnsNormally);
      expect(() => computeSpeciesRelevanceTier(hangul, 'cervus+hanglu*?[]()'), returnsNormally);
    });
  });

  group('Milestone 4 - Vernacular and Regional Synonym Search', () {
    test('Kashmiri vernacular name "hangul" matches Kashmir Stag at Tier 0', () {
      final hangul = kSpeciesCatalog.firstWhere((s) => s.id == 'hangul');
      expect(computeSpeciesRelevanceTier(hangul, 'hangul'), equals(0));
    });

    test('Ladakhi vernacular name "shan" matches Snow Leopard at Tier 1', () {
      final snowLeopard = kSpeciesCatalog.firstWhere((s) => s.id == 'snow-leopard');
      expect(computeSpeciesRelevanceTier(snowLeopard, 'shan'), equals(1));
    });

    test('Vernacular name "drenmo" matches Himalayan Brown Bear at Tier 1', () {
      final brownBear = kSpeciesCatalog.firstWhere((s) => s.id == 'himalayan-brown-bear');
      expect(computeSpeciesRelevanceTier(brownBear, 'drenmo'), equals(1));
    });

    test('Vernacular name "haaputh" matches Asian Black Bear at Tier 1', () {
      final blackBear = kSpeciesCatalog.firstWhere((s) => s.id == 'himalayan-black-bear');
      expect(computeSpeciesRelevanceTier(blackBear, 'haaputh'), equals(1));
    });

    test('Vernacular name "barfani cheeta" matches Snow Leopard at Tier 1', () {
      final snowLeopard = kSpeciesCatalog.firstWhere((s) => s.id == 'snow-leopard');
      expect(computeSpeciesRelevanceTier(snowLeopard, 'barfani cheeta'), equals(1));
    });
  });

  group('Milestone 4 - Tiered Relevance & False-Positive Resistance', () {
    test('Query "toad" prioritizes actual toads in Tier 2 over narrative mentions in Tier 4', () {
      final toads = kSpeciesCatalog.where(
        (s) => s.commonName.toLowerCase().contains('toad'),
      ).toList();

      expect(toads, isNotEmpty);
      for (final toad in toads) {
        final tier = computeSpeciesRelevanceTier(toad, 'toad');
        expect(tier, equals(2), reason: '${toad.commonName} should be Tier 2');
      }

      // Himalayan Marmot mentions "toads" in its ecological role
      final marmot = kSpeciesCatalog.firstWhere((s) => s.id == 'himalayan-marmot');
      final marmotTier = computeSpeciesRelevanceTier(marmot, 'toad');
      expect(marmotTier, equals(4), reason: 'Marmot should rank in Tier 4 for toad query');

      // Checkered Keelback mentions "toads" in its diet
      final keelback = kSpeciesCatalog.firstWhere((s) => s.id == 'checkered-keelback');
      final keelbackTier = computeSpeciesRelevanceTier(keelback, 'toad');
      expect(keelbackTier, equals(4), reason: 'Keelback should rank in Tier 4 for toad query');

      // Verify all actual toads rank ahead of marmots and snakes
      for (final toad in toads) {
        expect(computeSpeciesRelevanceTier(toad, 'toad'), lessThan(marmotTier));
        expect(computeSpeciesRelevanceTier(toad, 'toad'), lessThan(keelbackTier));
      }
    });

    test('Query "snow leopard" returns Snow Leopard at Tier 0 ahead of prey animals at Tier 4', () {
      final snowLeopard = kSpeciesCatalog.firstWhere((s) => s.id == 'snow-leopard');
      expect(computeSpeciesRelevanceTier(snowLeopard, 'snow leopard'), equals(0));

      final preyAnimals = ['himalayan-marmot', 'himalayan-ibex', 'bharal', 'markhor'];
      for (final preyId in preyAnimals) {
        final prey = kSpeciesCatalog.firstWhere((s) => s.id == preyId);
        final preyTier = computeSpeciesRelevanceTier(prey, 'snow leopard');
        expect(preyTier, equals(4), reason: '$preyId should rank at Tier 4 for "snow leopard" query');
        expect(computeSpeciesRelevanceTier(snowLeopard, 'snow leopard'), lessThan(preyTier));
      }
    });

    test('Query "aphids" matches Seven-Spot Ladybird and "burrows" matches Marmot at Tier 4', () {
      final ladybird = kSpeciesCatalog.firstWhere((s) => s.id == 'ladybird');
      final tier = computeSpeciesRelevanceTier(ladybird, 'aphids');
      expect(tier, lessThanOrEqualTo(4));

      final marmot = kSpeciesCatalog.firstWhere((s) => s.id == 'himalayan-marmot');
      expect(computeSpeciesRelevanceTier(marmot, 'burrows'), equals(4));
    });

    test('Taxonomy Order/Family/Genus queries evaluate to Tier 3 when not matching name prefix', () {
      final snowLeopard = kSpeciesCatalog.firstWhere((s) => s.id == 'snow-leopard');
      // Felidae is in taxonomy values, not commonName or scientificName
      expect(computeSpeciesRelevanceTier(snowLeopard, 'felidae'), equals(3));
      // Carnivora is Order
      expect(computeSpeciesRelevanceTier(snowLeopard, 'carnivora'), equals(3));
    });
  });

  group('Milestone 4 - Category Filtering', () {
    const categories = ['Mammal', 'Bird', 'Reptile', 'Amphibian', 'Fish', 'Insect'];

    for (final cat in categories) {
      test('Filtering by category "$cat" returns all corresponding fauna entries', () {
        final filtered = kSpeciesCatalog.where((s) => s.category == cat).toList();
        expect(filtered, isNotEmpty, reason: 'Category $cat must have entries');
        expect(filtered.every((s) => s.category == cat), isTrue);
      });
    }

    test('Zero plants exist across all categories', () {
      final plants = kSpeciesCatalog.where(
        (s) => s.category.toLowerCase() == 'plant' || s.category.toLowerCase() == 'flora',
      ).toList();
      expect(plants, isEmpty);
    });

    test('Catalog contains exactly 144 species across all 6 classes', () {
      expect(kSpeciesCatalog.length, equals(144));
      final classes = kSpeciesCatalog.map((s) => s.category).toSet();
      expect(classes, containsAll(categories));
    });
  });

  group('Milestone 4 - Regional Filtering', () {
    final expectedRegions = {
      'Jammu': 30,
      'Kashmir': 50,
      'Ladakh': 20,
      'Pir Panjal': 10,
    };

    expectedRegions.forEach((region, minCount) {
      test('Filtering by region "$region" returns at least $minCount species', () {
        final filtered = kSpeciesCatalog.where(
          (s) =>
              s.region.toLowerCase().contains(region.toLowerCase()) ||
              s.region.toLowerCase().replaceAll('-', ' ').contains(
                    region.toLowerCase().replaceAll('-', ' '),
                  ),
        ).toList();

        expect(
          filtered.length,
          greaterThanOrEqualTo(minCount),
          reason: 'Region $region should have at least $minCount species',
        );
      });
    });

    test('Trans-Himalaya region filtering returns cold desert fauna', () {
      final transHimalaya = kSpeciesCatalog.where(
        (s) =>
            s.region.toLowerCase().contains('trans-himalaya') ||
            s.region.toLowerCase().contains('trans himalaya'),
      ).toList();

      expect(transHimalaya, isNotEmpty);
      expect(transHimalaya.any((s) => s.id == 'himalayan-wolf'), isTrue);
      expect(transHimalaya.any((s) => s.id == 'skardu-toad'), isTrue);
    });

    test('Combined Category (Mammal) and Region (Ladakh) filtering returns Ladakh mammals', () {
      final ladakhMammals = kSpeciesCatalog.where(
        (s) =>
            s.category == 'Mammal' &&
            (s.region.toLowerCase().contains('ladakh') ||
                s.region.toLowerCase().contains('trans-himalaya')),
      ).toList();

      expect(ladakhMammals, isNotEmpty);
      expect(ladakhMammals.any((s) => s.id == 'snow-leopard'), isTrue);
      expect(ladakhMammals.any((s) => s.id == 'pallas-cat'), isTrue);
      expect(ladakhMammals.any((s) => s.id == 'bharal'), isTrue);
    });
  });

  group('Milestone 4 - Curated Matches in OnlineSpeciesPage', () {
    test('matchCuratedSpecies finds species with partial/prefix "leop"', () {
      final matches = matchCuratedSpecies('leop');
      expect(matches, isNotEmpty);
      expect(matches.any((s) => s.id == 'snow-leopard'), isTrue);
      expect(matches.any((s) => s.id == 'common-leopard'), isTrue);
      expect(matches.any((s) => s.id == 'leopard-cat'), isTrue);
    });

    test('matchCuratedSpecies finds species with partial/prefix "panth"', () {
      final matches = matchCuratedSpecies('panth');
      expect(matches, isNotEmpty);
      expect(matches.any((s) => s.id == 'snow-leopard'), isTrue);
      expect(matches.any((s) => s.id == 'common-leopard'), isTrue);
    });

    test('matchCuratedSpecies finds Hangul with partial/prefix "cerv"', () {
      final matches = matchCuratedSpecies('cerv');
      expect(matches, isNotEmpty);
      expect(matches.any((s) => s.id == 'hangul'), isTrue);
    });

    test('matchCuratedSpecies finds Himalayan Monal with partial/prefix "monal"', () {
      final matches = matchCuratedSpecies('monal');
      expect(matches, isNotEmpty);
      expect(matches.any((s) => s.id == 'monal'), isTrue);
    });

    test('matchCuratedSpecies handles hyphenated "snow-leopard"', () {
      final matches = matchCuratedSpecies('snow-leopard');
      expect(matches, isNotEmpty);
      expect(matches.first.id, equals('snow-leopard'));
    });

    test('matchCuratedSpecies returns empty list for non-J&K fauna (e.g. lion)', () {
      final matches = matchCuratedSpecies('lion');
      expect(matches, isEmpty);
    });

    test('matchCuratedSpecies returns empty list for empty or whitespace query', () {
      expect(matchCuratedSpecies(''), isEmpty);
      expect(matchCuratedSpecies('   '), isEmpty);
    });
  });

  group('Milestone 4 - Flutter Widget UI Integration: Field Guide Search & Filters', () {
    testWidgets('Entering hyphenated query "snow-leopard" in guide search displays Snow Leopard', (
      tester,
    ) async {
      await tester.pumpWidget(const KashmirZoologyApp());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('guideTab')));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.byKey(const Key('speciesSearchField')));
      await tester.enterText(
        find.byKey(const Key('speciesSearchField')),
        'snow-leopard',
      );
      await tester.pumpAndSettle();

      expect(find.text('Snow Leopard'), findsAtLeast(1));
    });

    testWidgets('Tapping Category ChoiceChip filters the species guide list', (
      tester,
    ) async {
      await tester.pumpWidget(const KashmirZoologyApp());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('guideTab')));
      await tester.pumpAndSettle();

      // Tap Bird category chip
      await tester.tap(find.widgetWithText(ChoiceChip, 'Bird'));
      await tester.pumpAndSettle();

      // Verify bird species appears
      expect(find.text('Rock Pigeon (Blue Rock Pigeon)'), findsAtLeast(1));
    });

    testWidgets('Tapping Regional ChoiceChip filters the species guide list', (
      tester,
    ) async {
      await tester.pumpWidget(const KashmirZoologyApp());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('guideTab')));
      await tester.pumpAndSettle();

      // Regional filter bar exists
      expect(find.byKey(const Key('regionalFilterBar')), findsOneWidget);

      // Tap Ladakh regional chip
      await tester.tap(find.byKey(const Key('regionChip-Ladakh')));
      await tester.pumpAndSettle();

      // Verify Ladakh fauna is present
      expect(find.text('Snow Leopard'), findsAtLeast(1));
    });

    testWidgets('Empty search result state renders cleanly without crashing', (
      tester,
    ) async {
      await tester.pumpWidget(const KashmirZoologyApp());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('guideTab')));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('speciesSearchField')),
        'NonExistentCreatureXYZ',
      );
      await tester.pumpAndSettle();

      expect(find.text('No matching species found.'), findsOneWidget);
    });

    testWidgets('Online species page shows curated match card for partial query "monal"', (
      tester,
    ) async {
      final fakeService = InatService();
      addTearDown(fakeService.close);

      await tester.pumpWidget(
        MaterialApp(
          home: OnlineSpeciesPage(service: fakeService),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('onlineSpeciesSearchField')),
        'monal',
      );
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('curatedSpecies-monal')), findsOneWidget);
      expect(find.text('Himalayan Monal'), findsAtLeast(1));
    });
  });
}
