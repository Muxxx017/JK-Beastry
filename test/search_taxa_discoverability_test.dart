import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zoology_app/data/species_data.dart';
import 'package:zoology_app/models/zoology_species.dart';
import 'package:zoology_app/main.dart';
import 'package:zoology_app/screens/online_species_page.dart';

/// Helper that reproduces the exact search matching logic in lib/main.dart
/// to test discoverability independently of widget pumping.
List<ZoologySpecies> executeSearch({
  required String query,
  String selectedCategory = 'All',
  String selectedRegion = 'All',
}) {
  final rawQuery = query.trim().toLowerCase();

  final queryTokens = rawQuery
      .split(RegExp(r'[^a-z0-9]+'))
      .where((t) => t.isNotEmpty)
      .toList();

  final qSpaced = rawQuery
      .replaceAll(RegExp(r'[\-_]+'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  final speciesList = kSpeciesCatalog.where((species) {
    final matchesCategory =
        selectedCategory == 'All' ||
        species.category == selectedCategory ||
        (selectedCategory == 'Not recorded' &&
            species.status == 'Not currently recorded');

    final matchesRegion =
        selectedRegion == 'All' ||
        species.region.toLowerCase().contains(selectedRegion.toLowerCase()) ||
        species.region
            .toLowerCase()
            .replaceAll('-', ' ')
            .contains(selectedRegion.toLowerCase().replaceAll('-', ' ')) ||
        species.region == selectedRegion;

    if (!matchesCategory || !matchesRegion) return false;

    if (queryTokens.isEmpty) return true;

    final searchDoc = [
      species.id,
      species.id.replaceAll('-', ' '),
      species.commonName,
      species.commonName.replaceAll('-', ' '),
      species.scientificName,
      ...species.searchTerms,
      ...species.searchTerms.map((t) => t.replaceAll('-', ' ')),
      ...species.taxonomy.values,
      species.searchableText,
      species.searchableText.replaceAll('-', ' '),
    ].join(' ').toLowerCase();

    return queryTokens.every((token) => searchDoc.contains(token));
  }).toList();

  if (queryTokens.isNotEmpty) {
    speciesList.sort((a, b) {
      final tierA = computeSpeciesRelevanceTier(a, rawQuery);
      final tierB = computeSpeciesRelevanceTier(b, rawQuery);

      if (tierA != tierB) {
        return tierA.compareTo(tierB);
      }

      final aWords = a.commonName.toLowerCase().split(RegExp(r'[^a-z0-9]+'));
      final bWords = b.commonName.toLowerCase().split(RegExp(r'[^a-z0-9]+'));
      final aExactWord = aWords.contains(rawQuery) || aWords.contains(qSpaced);
      final bExactWord = bWords.contains(rawQuery) || bWords.contains(qSpaced);
      if (aExactWord != bExactWord) {
        return aExactWord ? -1 : 1;
      }

      final lengthComp = a.commonName.length.compareTo(b.commonName.length);
      if (lengthComp != 0) return lengthComp;

      return a.commonName.compareTo(b.commonName);
    });
  }

  return speciesList;
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Milestone 4 Challenger Suite: 100% Taxa Discoverability Across Catalog', () {
    test('Catalog contains exactly 144 curated species', () {
      expect(kSpeciesCatalog.length, equals(144));
    });

    test('Property Test: EVERY ONE of the 144 species yields Tier 0 or Tier 1 for commonName', () {
      final failureList = <String>[];
      for (final species in kSpeciesCatalog) {
        final tier = computeSpeciesRelevanceTier(species, species.commonName);
        if (tier > 1) {
          failureList.add(
            '${species.id}: commonName "${species.commonName}" evaluated to Tier $tier (expected <= 1)',
          );
        }
      }
      expect(
        failureList,
        isEmpty,
        reason: 'All 144 species must return Tier 0 or 1 for their common name:\n${failureList.join('\n')}',
      );
    });

    test('Property Test: EVERY ONE of the 144 species yields Tier 0 or Tier 1 for scientificName', () {
      final failureList = <String>[];
      for (final species in kSpeciesCatalog) {
        final tier = computeSpeciesRelevanceTier(species, species.scientificName);
        if (tier > 1) {
          failureList.add(
            '${species.id}: scientificName "${species.scientificName}" evaluated to Tier $tier (expected <= 1)',
          );
        }
      }
      expect(
        failureList,
        isEmpty,
        reason: 'All 144 species must return Tier 0 or 1 for their scientific name:\n${failureList.join('\n')}',
      );
    });

    test('Property Test: EVERY ONE of the 144 species yields Tier 0 or Tier 1 for id', () {
      final failureList = <String>[];
      for (final species in kSpeciesCatalog) {
        final tier = computeSpeciesRelevanceTier(species, species.id);
        if (tier > 1) {
          failureList.add(
            '${species.id}: id "${species.id}" evaluated to Tier $tier (expected <= 1)',
          );
        }
      }
      expect(
        failureList,
        isEmpty,
        reason: 'All 144 species must return Tier 0 or 1 for their id:\n${failureList.join('\n')}',
      );
    });

    test('Property Test: primary common name (before parentheses) yields Tier 0 or Tier 1 for all species', () {
      final failureList = <String>[];
      for (final species in kSpeciesCatalog) {
        final primary = species.commonName.split('(').first.trim();
        final tier = computeSpeciesRelevanceTier(species, primary);
        if (tier > 1) {
          failureList.add(
            '${species.id}: primary name "$primary" evaluated to Tier $tier (expected <= 1)',
          );
        }
      }
      expect(
        failureList,
        isEmpty,
        reason: 'All 144 species must return Tier 0 or 1 for their primary common name:\n${failureList.join('\n')}',
      );
    });

    test('Property Test: parenthetical common names yield Tier 0 or Tier 1 for applicable species', () {
      final failureList = <String>[];
      for (final species in kSpeciesCatalog) {
        if (!species.commonName.contains('(')) continue;
        final parenthetical = species.commonName.split('(')[1].replaceAll(')', '').trim();
        final tier = computeSpeciesRelevanceTier(species, parenthetical);
        if (tier > 1) {
          failureList.add(
            '${species.id}: parenthetical name "$parenthetical" evaluated to Tier $tier (expected <= 1)',
          );
        }
      }
      expect(
        failureList,
        isEmpty,
        reason: 'All species with parenthetical names must return Tier 0 or 1 for their parenthetical name:\n${failureList.join('\n')}',
      );
    });

    test('Apostrophe & possessive name variations match at Tier 0', () {
      final pallas = kSpeciesCatalog.firstWhere((s) => s.id == 'pallas-cat');
      final russell = kSpeciesCatalog.firstWhere((s) => s.id == 'russell-viper');
      final stoliczka = kSpeciesCatalog.firstWhere((s) => s.id == 'stoliczka-gecko');

      expect(computeSpeciesRelevanceTier(pallas, "Pallas's Cat"), equals(0));
      expect(computeSpeciesRelevanceTier(pallas, "pallas's cat"), equals(0));
      expect(computeSpeciesRelevanceTier(pallas, "pallas cat"), equals(0));
      expect(computeSpeciesRelevanceTier(pallas, "Pallas's Cat (Manul)"), equals(0));

      expect(computeSpeciesRelevanceTier(russell, "Russell's Viper"), equals(0));
      expect(computeSpeciesRelevanceTier(russell, "russell's viper"), equals(0));
      expect(computeSpeciesRelevanceTier(russell, "russell viper"), equals(0));

      expect(computeSpeciesRelevanceTier(stoliczka, "Stoliczka's Mountain Gecko"), equals(0));
      expect(computeSpeciesRelevanceTier(stoliczka, "stoliczka's mountain gecko"), equals(0));
    });

    test('End-to-End Search Pipeline: Searching commonName returns target species for ALL 144 species', () {
      final failureList = <String>[];
      for (final species in kSpeciesCatalog) {
        final results = executeSearch(query: species.commonName);
        if (!results.any((s) => s.id == species.id)) {
          failureList.add(
            'Searching commonName "${species.commonName}" did not include species ${species.id}',
          );
        }
      }
      expect(
        failureList,
        isEmpty,
        reason: 'All 144 species must be returned when searching by their commonName:\n${failureList.join('\n')}',
      );
    });

    test('End-to-End Search Pipeline: Searching scientificName returns target species for ALL 144 species', () {
      final failureList = <String>[];
      for (final species in kSpeciesCatalog) {
        final results = executeSearch(query: species.scientificName);
        if (!results.any((s) => s.id == species.id)) {
          failureList.add(
            'Searching scientificName "${species.scientificName}" did not include species ${species.id}',
          );
        }
      }
      expect(
        failureList,
        isEmpty,
        reason: 'All 144 species must be returned when searching by their scientificName:\n${failureList.join('\n')}',
      );
    });

    test('End-to-End Search Pipeline: Searching id returns target species for ALL 144 species', () {
      final failureList = <String>[];
      for (final species in kSpeciesCatalog) {
        final results = executeSearch(query: species.id);
        if (!results.any((s) => s.id == species.id)) {
          failureList.add(
            'Searching id "${species.id}" did not include species ${species.id}',
          );
        }
      }
      expect(
        failureList,
        isEmpty,
        reason: 'All 144 species must be returned when searching by their id:\n${failureList.join('\n')}',
      );
    });

    test('Top-Rank Invariant: Exact commonName search places target species at index 0 or tied at Tier 0', () {
      final failureList = <String>[];
      for (final species in kSpeciesCatalog) {
        final results = executeSearch(query: species.commonName);
        if (results.isEmpty) {
          failureList.add('${species.id}: 0 results found');
          continue;
        }
        final targetTier = computeSpeciesRelevanceTier(species, species.commonName);
        final topResultTier = computeSpeciesRelevanceTier(results.first, species.commonName);
        if (targetTier > topResultTier) {
          failureList.add(
            '${species.id}: target tier ($targetTier) is worse than top result ${results.first.id} tier ($topResultTier)',
          );
        }
      }
      expect(
        failureList,
        isEmpty,
        reason: 'Exact commonName must place target species at top relevance tier:\n${failureList.join('\n')}',
      );
    });
  });

  group('Milestone 4 Challenger Suite: Vernacular Alias & Synonym Matching', () {
    test('Every species in catalog has non-empty searchTerms', () {
      final emptyTerms = kSpeciesCatalog.where((s) => s.searchTerms.isEmpty).toList();
      expect(
        emptyTerms,
        isEmpty,
        reason: 'All species should have curated searchTerms/aliases',
      );
    });

    test('Property Test: Searching EVERY searchTerm finds the target species in the catalog', () {
      final failureList = <String>[];
      int totalTermsTested = 0;

      for (final species in kSpeciesCatalog) {
        for (final term in species.searchTerms) {
          totalTermsTested++;
          final results = executeSearch(query: term);
          if (!results.any((s) => s.id == species.id)) {
            failureList.add(
              'Species ${species.id} missing when searching searchTerm "$term"',
            );
          }
        }
      }

      expect(totalTermsTested, greaterThan(300), reason: 'Should test hundreds of vernacular aliases');
      expect(
        failureList,
        isEmpty,
        reason: 'Every searchTerm must successfully return its owning species:\n${failureList.take(20).join('\n')}',
      );
    });

    test('Property Test: computeSpeciesRelevanceTier returns Tier 0, 1, or 2 for every searchTerm', () {
      final failureList = <String>[];
      for (final species in kSpeciesCatalog) {
        for (final term in species.searchTerms) {
          final tier = computeSpeciesRelevanceTier(species, term);
          if (tier > 2) {
            failureList.add(
              '${species.id} searchTerm "$term" evaluated to Tier $tier (expected <= 2)',
            );
          }
        }
      }
      expect(
        failureList,
        isEmpty,
        reason: 'All searchTerms must evaluate to Tier <= 2:\n${failureList.take(20).join('\n')}',
      );
    });

    test('High-Value Vernacular Terms Match Iconic Species', () {
      final testCases = <String, String>{
        'hangul': 'hangul',
        'hongul': 'hangul',
        'kashmir stag': 'hangul',
        'shan': 'snow-leopard',
        'barfani cheeta': 'snow-leopard',
        'drenmo': 'himalayan-brown-bear',
        'lal bhalu': 'himalayan-brown-bear',
        'haaputh': 'himalayan-black-bear',
        'habuth': 'himalayan-brown-bear',
        'chiru': 'tibetan-antelope',
        'shahtoosh': 'tibetan-antelope',
        'markhor': 'markhor',
        'pir panjal markhor': 'markhor',
        'ibex': 'himalayan-ibex',
        'skyin': 'himalayan-ibex',
        'bharal': 'bharal',
        'blue sheep': 'bharal',
        'monal': 'monal',
        'shangku': 'himalayan-wolf',
      };

      testCases.forEach((term, expectedId) {
        final results = executeSearch(query: term);
        expect(
          results.any((s) => s.id == expectedId),
          isTrue,
          reason: 'Searching "$term" must find species "$expectedId"',
        );
      });
    });
  });

  group('Milestone 4 Challenger Suite: Regional Invariants', () {
    const regionalKeys = [
      'Jammu',
      'Kashmir',
      'Ladakh',
      'Trans-Himalaya',
      'Pir Panjal',
    ];

    for (final region in regionalKeys) {
      test('Filtering by region "$region" yields non-empty results and matches region invariant', () {
        final results = executeSearch(query: '', selectedRegion: region);

        expect(
          results,
          isNotEmpty,
          reason: 'Region filter "$region" must produce non-empty fauna results',
        );

        final nonMatching = results.where((species) {
          final regLower = species.region.toLowerCase();
          final regSpaced = regLower.replaceAll('-', ' ');
          final filterLower = region.toLowerCase();
          final filterSpaced = filterLower.replaceAll('-', ' ');

          return !regLower.contains(filterLower) &&
              !regSpaced.contains(filterSpaced) &&
              species.region != region;
        }).toList();

        expect(
          nonMatching,
          isEmpty,
          reason: 'All species returned for region "$region" must have matching region field',
        );
      });
    }

    test('Regional filter combined with search query narrows results correctly', () {
      final ladakhOnly = executeSearch(query: 'leopard', selectedRegion: 'Ladakh');
      expect(ladakhOnly.any((s) => s.id == 'snow-leopard'), isTrue);
      expect(ladakhOnly.any((s) => s.id == 'common-leopard'), isFalse);

      final kashmirOnly = executeSearch(query: 'leopard', selectedRegion: 'Kashmir');
      expect(kashmirOnly.any((s) => s.id == 'common-leopard'), isTrue);
    });
  });

  group('Milestone 4 Challenger Suite: False-Positive Ranking Verification', () {
    test('Query "toad" ranks true toads ahead of narrative mentions (Himalayan Marmot, Checkered Keelback)', () {
      final results = executeSearch(query: 'toad');
      expect(results, isNotEmpty);

      // True toads (species with "toad" in commonName)
      final toadSpecies = results.where((s) => s.commonName.toLowerCase().contains('toad')).toList();
      expect(toadSpecies, isNotEmpty);

      // Marmot & Keelback mention toad in diet / ecological role
      final marmotIndex = results.indexWhere((s) => s.id == 'himalayan-marmot');
      final keelbackIndex = results.indexWhere((s) => s.id == 'checkered-keelback');

      for (final toad in toadSpecies) {
        final toadIndex = results.indexOf(toad);
        if (marmotIndex != -1) {
          expect(
            toadIndex,
            lessThan(marmotIndex),
            reason: '${toad.commonName} ($toadIndex) must rank ahead of Himalayan Marmot ($marmotIndex)',
          );
        }
        if (keelbackIndex != -1) {
          expect(
            toadIndex,
            lessThan(keelbackIndex),
            reason: '${toad.commonName} ($toadIndex) must rank ahead of Checkered Keelback ($keelbackIndex)',
          );
        }
      }
    });

    test('Query "snow leopard" ranks Snow Leopard ahead of prey animals (Ibex, Bharal, Marmot)', () {
      final results = executeSearch(query: 'snow leopard');
      expect(results, isNotEmpty);
      expect(results.first.id, equals('snow-leopard'));

      final snowLeopardIndex = results.indexWhere((s) => s.id == 'snow-leopard');
      expect(snowLeopardIndex, equals(0));

      final preyIds = ['himalayan-ibex', 'bharal', 'markhor', 'himalayan-marmot'];
      for (final preyId in preyIds) {
        final preyIndex = results.indexWhere((s) => s.id == preyId);
        if (preyIndex != -1) {
          expect(
            snowLeopardIndex,
            lessThan(preyIndex),
            reason: 'Snow Leopard (index 0) must rank ahead of prey $preyId (index $preyIndex)',
          );
        }
      }
    });

    test('Query "bear" ranks Brown Bear and Black Bear ahead of competitors or incidental mentions', () {
      final results = executeSearch(query: 'bear');
      expect(results, isNotEmpty);

      final topTwoIds = results.take(2).map((s) => s.id).toSet();
      expect(
        topTwoIds.contains('himalayan-brown-bear') || topTwoIds.contains('himalayan-black-bear'),
        isTrue,
        reason: 'True bear species must occupy top rankings for "bear"',
      );
    });

    test('Query "hangul" strictly ranks Kashmir Stag as #1 result', () {
      final results = executeSearch(query: 'hangul');
      expect(results, isNotEmpty);
      expect(results.first.id, equals('hangul'));
      expect(computeSpeciesRelevanceTier(results.first, 'hangul'), equals(0));
    });
  });

  group('Milestone 4 Challenger Suite: Online Atlas Curated Matching Discoverability', () {
    test('matchCuratedSpecies finds species for prefix queries', () {
      final queries = ['panth', 'cerv', 'monal', 'leop', 'bhalu', 'trag'];
      for (final q in queries) {
        final matches = matchCuratedSpecies(q);
        expect(matches, isNotEmpty, reason: 'Prefix "$q" should find matches in online curated search');
      }
    });

    test('matchCuratedSpecies returns zero plant taxa', () {
      final allCurated = matchCuratedSpecies('a');
      final plants = allCurated.where(
        (s) => s.category.toLowerCase() == 'plant' || s.category.toLowerCase() == 'flora',
      ).toList();
      expect(plants, isEmpty);
    });

    test('matchCuratedSpecies handles hyphenated strings', () {
      final matches = matchCuratedSpecies('snow-leopard');
      expect(matches, isNotEmpty);
      expect(matches.first.id, equals('snow-leopard'));
    });
  });

  group('Milestone 4 Challenger Suite: Boundary & Adversarial Robustness', () {
    test('Query with excessive tabs, newlines, and spaces does not fail', () {
      final results = executeSearch(query: '  \n\t  snow   \t  leopard  \n ');
      expect(results, isNotEmpty);
      expect(results.first.id, equals('snow-leopard'));
    });

    test('Query with punctuation only returns all species (acts as blank query)', () {
      final results = executeSearch(query: '!@#\$%^&*()');
      expect(results.length, equals(144));
    });

    test('Query with mixed punctuation and text locates target species', () {
      final results = executeSearch(query: 'hangul!! (deer)');
      expect(results.any((s) => s.id == 'hangul'), isTrue);
    });

    test('Case-insensitivity property across all 144 species', () {
      for (final species in kSpeciesCatalog) {
        final upperQuery = species.commonName.toUpperCase();
        final lowerQuery = species.commonName.toLowerCase();

        final tierUpper = computeSpeciesRelevanceTier(species, upperQuery);
        final tierLower = computeSpeciesRelevanceTier(species, lowerQuery);

        expect(
          tierUpper,
          equals(tierLower),
          reason: '${species.id}: upper ($tierUpper) and lower ($tierLower) tiers must match',
        );
      }
    });
  });

  group('Milestone 4 Challenger Suite: Widget UI Regional & Search Integration', () {
    testWidgets('Entering search query updates displayed list in KashmirZoologyApp', (tester) async {
      await tester.pumpWidget(const KashmirZoologyApp());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('guideTab')));
      await tester.pumpAndSettle();

      final searchField = find.byKey(const Key('speciesSearchField'));
      expect(searchField, findsOneWidget);

      await tester.enterText(searchField, 'Hangul');
      await tester.pumpAndSettle();

      expect(find.text('Kashmir Stag'), findsWidgets);

      await tester.enterText(searchField, '');
      await tester.pumpAndSettle();
    });

    testWidgets('Tapping Regional Chip filters visible species cards', (tester) async {
      await tester.pumpWidget(const KashmirZoologyApp());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('guideTab')));
      await tester.pumpAndSettle();

      final regionalBar = find.byKey(const Key('regionalFilterBar'));
      expect(regionalBar, findsOneWidget);

      final ladakhChip = find.byKey(const Key('regionChip-Ladakh'));
      expect(ladakhChip, findsOneWidget);

      await tester.tap(ladakhChip);
      await tester.pumpAndSettle();

      expect(find.text('Snow Leopard'), findsWidgets);

      final jammuChip = find.byKey(const Key('regionChip-Jammu'));
      expect(jammuChip, findsOneWidget);

      await tester.tap(jammuChip);
      await tester.pumpAndSettle();

      final allChip = find.byKey(const Key('regionChip-All'));
      await tester.tap(allChip);
      await tester.pumpAndSettle();
    });
  });
}
