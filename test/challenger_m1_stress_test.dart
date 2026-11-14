import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:zoology_app/data/species_data.dart';
import 'package:zoology_app/models/zoology_species.dart';

void main() {
  group('Empirical Challenge 1: ZoologySpecies Data Model Stress Testing', () {
    test('Round-trip serialization fidelity across all 144 catalog entries', () {
      expect(kSpeciesCatalog.length, 144);

      for (final original in kSpeciesCatalog) {
        final json = original.toJson();
        final restored = ZoologySpecies.fromJson(json);

        expect(restored.id, original.id, reason: 'Mismatch in id for ${original.id}');
        expect(restored.commonName, original.commonName, reason: 'Mismatch in commonName for ${original.id}');
        expect(restored.scientificName, original.scientificName, reason: 'Mismatch in scientificName for ${original.id}');
        expect(restored.category, original.category, reason: 'Mismatch in category for ${original.id}');
        expect(restored.region, original.region, reason: 'Mismatch in region for ${original.id}');
        expect(restored.status, original.status, reason: 'Mismatch in status for ${original.id}');
        expect(restored.habitat, original.habitat, reason: 'Mismatch in habitat for ${original.id}');
        expect(restored.size, original.size, reason: 'Mismatch in size for ${original.id}');
        expect(restored.conservation, original.conservation, reason: 'Mismatch in conservation for ${original.id}');
        expect(restored.feature, original.feature, reason: 'Mismatch in feature for ${original.id}');
        expect(restored.funFact, original.funFact, reason: 'Mismatch in funFact for ${original.id}');
        expect(restored.distribution, original.distribution, reason: 'Mismatch in distribution for ${original.id}');
        expect(restored.diet, original.diet, reason: 'Mismatch in diet for ${original.id}');
        expect(restored.behavior, original.behavior, reason: 'Mismatch in behavior for ${original.id}');
        expect(restored.breeding, original.breeding, reason: 'Mismatch in breeding for ${original.id}');
        expect(restored.threats, original.threats, reason: 'Mismatch in threats for ${original.id}');
        expect(restored.ecologicalRole, original.ecologicalRole, reason: 'Mismatch in ecologicalRole for ${original.id}');
        expect(restored.identification, original.identification, reason: 'Mismatch in identification for ${original.id}');
        expect(restored.vocalization, original.vocalization, reason: 'Mismatch in vocalization for ${original.id}');
        expect(restored.imageUrl, original.imageUrl, reason: 'Mismatch in imageUrl for ${original.id}');
        expect(restored.imageAttribution, original.imageAttribution, reason: 'Mismatch in imageAttribution for ${original.id}');
        expect(restored.imageLicense, original.imageLicense, reason: 'Mismatch in imageLicense for ${original.id}');
        expect(restored.searchTerms, original.searchTerms, reason: 'Mismatch in searchTerms for ${original.id}');
        expect(restored.taxonomy, original.taxonomy, reason: 'Mismatch in taxonomy for ${original.id}');
        expect(restored.audioAsset, original.audioAsset, reason: 'Mismatch in audioAsset for ${original.id}');
        expect(restored.isVocal, original.isVocal, reason: 'Mismatch in isVocal for ${original.id}');
        expect(restored.vocalizationNote, original.vocalizationNote, reason: 'Mismatch in vocalizationNote for ${original.id}');

        // Wire-format JSON encoding/decoding verification
        final encodedJsonString = jsonEncode(json);
        final decodedMap = jsonDecode(encodedJsonString) as Map<String, dynamic>;
        final wireRestored = ZoologySpecies.fromJson(decodedMap);
        expect(wireRestored.id, original.id);
        expect(wireRestored.commonName, original.commonName);
        expect(wireRestored.searchTerms, original.searchTerms);
        expect(wireRestored.taxonomy, original.taxonomy);
      }
    });

    test('copyWith field mutation completeness across all 26 model fields', () {
      final base = kSpeciesCatalog.firstWhere((s) => s.id == 'hangul');

      // Test mutating each of the 26 properties individually
      expect(base.copyWith(id: 'mut-1').id, 'mut-1');
      expect(base.copyWith(commonName: 'mut-2').commonName, 'mut-2');
      expect(base.copyWith(scientificName: 'mut-3').scientificName, 'mut-3');
      expect(base.copyWith(category: 'mut-4').category, 'mut-4');
      expect(base.copyWith(region: 'mut-5').region, 'mut-5');
      expect(base.copyWith(status: 'mut-6').status, 'mut-6');
      expect(base.copyWith(habitat: 'mut-7').habitat, 'mut-7');
      expect(base.copyWith(size: 'mut-8').size, 'mut-8');
      expect(base.copyWith(conservation: 'mut-9').conservation, 'mut-9');
      expect(base.copyWith(feature: 'mut-10').feature, 'mut-10');
      expect(base.copyWith(funFact: 'mut-11').funFact, 'mut-11');
      expect(base.copyWith(distribution: 'mut-12').distribution, 'mut-12');
      expect(base.copyWith(diet: 'mut-13').diet, 'mut-13');
      expect(base.copyWith(behavior: 'mut-14').behavior, 'mut-14');
      expect(base.copyWith(breeding: 'mut-15').breeding, 'mut-15');
      expect(base.copyWith(threats: 'mut-16').threats, 'mut-16');
      expect(base.copyWith(ecologicalRole: 'mut-17').ecologicalRole, 'mut-17');
      expect(base.copyWith(identification: 'mut-18').identification, 'mut-18');
      expect(base.copyWith(vocalization: 'mut-19').vocalization, 'mut-19');
      expect(base.copyWith(imageUrl: 'mut-20').imageUrl, 'mut-20');
      expect(base.copyWith(imageAttribution: 'mut-21').imageAttribution, 'mut-21');
      expect(base.copyWith(imageLicense: 'mut-22').imageLicense, 'mut-22');
      expect(base.copyWith(searchTerms: ['mut-23']).searchTerms, ['mut-23']);
      expect(base.copyWith(taxonomy: {'Rank': 'mut-24'}).taxonomy, {'Rank': 'mut-24'});
      expect(base.copyWith(audioAsset: 'assets/audio/mut-25.mp3').audioAsset, 'assets/audio/mut-25.mp3');
      expect(base.copyWith(isVocal: false).isVocal, isFalse);
      expect(base.copyWith(vocalizationNote: 'mut-26').vocalizationNote, 'mut-26');

      // 1. Zero mutation returns exact field equivalence
      final unchanged = base.copyWith();
      expect(unchanged.id, base.id);
      expect(unchanged.commonName, base.commonName);
      expect(unchanged.scientificName, base.scientificName);
      expect(unchanged.audioAsset, base.audioAsset);
      expect(unchanged.isVocal, base.isVocal);
      expect(unchanged.vocalizationNote, base.vocalizationNote);
      expect(unchanged.searchTerms, base.searchTerms);
      expect(unchanged.taxonomy, base.taxonomy);

      // 2. Individual mutations of audio/vocalization fields
      final silentHangul = base.copyWith(
        isVocal: false,
        vocalizationNote: 'Silent winter foraging mode',
        audioAsset: 'assets/audio/test_alt.mp3',
      );
      expect(silentHangul.isVocal, isFalse);
      expect(silentHangul.vocalizationNote, 'Silent winter foraging mode');
      expect(silentHangul.audioAsset, 'assets/audio/test_alt.mp3');
      expect(silentHangul.commonName, base.commonName); // Unchanged

      // 3. Taxonomy and searchTerms mutation
      final updatedTaxonomy = base.copyWith(
        searchTerms: ['custom-tag-1', 'custom-tag-2'],
        taxonomy: {'Kingdom': 'Animalia', 'Class': 'Mammalia', 'Clade': 'Ungulata'},
      );
      expect(updatedTaxonomy.searchTerms, ['custom-tag-1', 'custom-tag-2']);
      expect(updatedTaxonomy.taxonomy['Clade'], 'Ungulata');
      expect(base.searchTerms, isNot(contains('custom-tag-1'))); // Original untouched
    });

    test('fromJson resiliency against malformed, partial, and dirty payloads', () {
      // Missing non-required fields default safely
      final minimalJson = <String, dynamic>{
        'id': 'minimal-beast',
        'commonName': 'Minimal Beast',
        'scientificName': 'Bestia minima',
        'category': 'Mammal',
        'region': 'Jammu',
        'status': 'Present',
        'habitat': 'Highlands',
        'size': 'Small',
        'conservation': 'Least Concern',
        'feature': 'Compact body',
        'funFact': 'Fast runner',
      };

      final minimalSpecies = ZoologySpecies.fromJson(minimalJson);
      expect(minimalSpecies.id, 'minimal-beast');
      expect(minimalSpecies.distribution, '');
      expect(minimalSpecies.diet, '');
      expect(minimalSpecies.behavior, '');
      expect(minimalSpecies.searchTerms, isEmpty);
      expect(minimalSpecies.taxonomy, isEmpty);
      expect(minimalSpecies.audioAsset, isNull);
      expect(minimalSpecies.isVocal, isTrue); // default is true
      expect(minimalSpecies.vocalizationNote, isNull);

      // Dirty payload: non-string elements inside searchTerms, int in taxonomy, extra unknown fields
      final dirtyJson = <String, dynamic>{
        ...minimalJson,
        'searchTerms': ['valid_term', 42, null, true, 'another_term'],
        'taxonomy': {'Kingdom': 'Animalia', 'NumericRank': 100},
        'audioAsset': null,
        'isVocal': false,
        'vocalizationNote': 'Subterranean vibration only',
        'unknownExtraField': 'Ignored by parser',
      };

      final dirtySpecies = ZoologySpecies.fromJson(dirtyJson);
      expect(dirtySpecies.searchTerms, ['valid_term', 'another_term']);
      expect(dirtySpecies.taxonomy['NumericRank'], '100');
      expect(dirtySpecies.audioAsset, isNull);
      expect(dirtySpecies.isVocal, isFalse);
      expect(dirtySpecies.vocalizationNote, 'Subterranean vibration only');

      // Missing required field throws TypeError
      final brokenJson = <String, dynamic>{
        'commonName': 'No ID Beast',
      };
      expect(() => ZoologySpecies.fromJson(brokenJson), throwsA(isA<TypeError>()));
    });

    test('searchableText generation with extreme, unicode, and boundary inputs', () {
      // 1. Extreme string payload (10,000 characters)
      final hugeDesc = 'a' * 10000;
      final stressSpecies = ZoologySpecies(
        id: 'huge-beast',
        commonName: 'Huge Beast',
        scientificName: 'Megatherium gigas',
        category: 'Mammal',
        region: 'Ladakh',
        status: 'Present',
        habitat: 'Alpine',
        size: 'Huge',
        conservation: 'Vulnerable',
        feature: 'Massive build',
        funFact: 'Legendary',
        distribution: hugeDesc,
        searchTerms: ['giant', 'colossus'],
      );

      final searchableText = stressSpecies.searchableText;
      expect(searchableText.length, greaterThan(10000));
      expect(searchableText, contains('huge beast'));
      expect(searchableText, contains('megatherium gigas'));
      expect(searchableText, contains('colossus'));

      // 2. Unicode, multilingual vernacular scripts (Urdu, Kashmiri, Ladakhi), diacritics
      final unicodeSpecies = ZoologySpecies(
        id: 'unicode-test',
        commonName: 'Hangul Test',
        scientificName: 'Cervus hanglu',
        category: 'Mammal',
        region: 'Kashmir',
        status: 'Present',
        habitat: 'Dachigam',
        size: 'Medium',
        conservation: 'Critically Endangered',
        feature: 'Antlers',
        funFact: 'Iconic',
        searchTerms: [
          'ہانگل', // Urdu/Kashmiri Nastaliq
          'হাঁগুল',
          'červus', // Diacritic Latin
          'शान', // Hindi / Ladakhi devanagari
          '🦁🐾', // Emojis
        ],
        vocalizationNote: 'Rutting roar: 100 dB! (high-energy call)',
      );

      final unicodeSearchable = unicodeSpecies.searchableText;
      expect(unicodeSearchable, contains('ہانگل'));
      expect(unicodeSearchable, contains('červus'));
      expect(unicodeSearchable, contains('शान'));
      expect(unicodeSearchable, contains('🦁🐾'));
      expect(unicodeSearchable, contains('rutting roar'));

      // 3. Null vocalizationNote must not output "null" into searchableText
      final nullNoteSpecies = ZoologySpecies(
        id: 'null-note-beast',
        commonName: 'Quiet Beast',
        scientificName: 'Bestia tacita',
        category: 'Reptile',
        region: 'Jammu',
        status: 'Present',
        habitat: 'Rocks',
        size: 'Small',
        conservation: 'Least Concern',
        feature: 'Stealth',
        funFact: 'Never calls',
        vocalizationNote: null,
      );

      final terms = nullNoteSpecies.searchableText.split(' ');
      expect(terms, isNot(contains('null')));
    });
  });

  group('Empirical Challenge 2: Search Term Indexing & Vernacular Name Retrieval', () {
    test('Every species in kSpeciesCatalog has non-empty searchTerms and taxonomy', () {
      for (final species in kSpeciesCatalog) {
        expect(
          species.searchTerms,
          isNotEmpty,
          reason: 'Species ${species.id} has empty searchTerms list',
        );
        expect(
          species.taxonomy,
          isNotEmpty,
          reason: 'Species ${species.id} has empty taxonomy map',
        );
      }
    });

    test('Key iconic regional fauna vernacular names are indexed and searchable', () {
      final speciesMap = {for (var s in kSpeciesCatalog) s.id: s};

      // 1. Hangul (Cervus hanglu hanglu)
      final hangul = speciesMap['hangul']!;
      expect(hangul.searchableText, contains('hangul'));
      expect(hangul.searchableText, contains('kashmir stag'));
      expect(hangul.searchableText, contains('cervus hanglu hanglu'));
      expect(hangul.searchableText, contains('hongul'));

      // 2. Markhor (Capra falconeri cashmiriensis)
      final markhor = speciesMap['markhor']!;
      expect(markhor.searchableText, contains('markhor'));
      expect(markhor.searchableText, contains('pir panjal markhor'));
      expect(markhor.searchableText, contains('kashmir markhor'));
      expect(markhor.searchableText, contains('snake eater'));

      // 3. Snow Leopard (Panthera uncia)
      final snowLeopard = speciesMap['snow-leopard']!;
      expect(snowLeopard.searchableText, contains('snow leopard'));
      expect(snowLeopard.searchableText, contains('panthera uncia'));
      expect(snowLeopard.searchableText, contains('shan'));
      expect(snowLeopard.searchableText, contains('barfani cheeta'));

      // 4. Himalayan Monal (Lophophorus impejanus)
      final monal = speciesMap['monal']!;
      expect(monal.searchableText, contains('monal'));
      expect(monal.searchableText, contains('himalayan monal'));
      expect(monal.searchableText, contains('lophophorus impejanus'));

      // 5. Western Tragopan (Tragopan melanocephalus)
      final tragopan = speciesMap['western-tragopan']!;
      expect(tragopan.searchableText, contains('western tragopan'));
      expect(tragopan.searchableText, contains('daner'));

      // 6. Kashmir Musk Deer (Moschus cupreus)
      final muskDeer = speciesMap['musk-deer']!;
      expect(muskDeer.searchableText, contains('musk deer'));
      expect(muskDeer.searchableText, contains('moschus cupreus'));
      expect(muskDeer.searchableText, contains('kasturi'));

      // 7. Black-necked Crane (Grus nigricollis)
      final crane = speciesMap['black-necked-crane']!;
      expect(crane.searchableText, contains('black-necked crane'));
      expect(crane.searchableText, contains('grus nigricollis'));

      // 8. Himalayan Wolf (Canis lupus chanco)
      final wolf = speciesMap['himalayan-wolf']!;
      expect(wolf.searchableText, contains('himalayan wolf'));
      expect(wolf.searchableText, contains('shangku'));

      // 9. Himalayan Ibex (Capra sibirica)
      final ibex = speciesMap['himalayan-ibex']!;
      expect(ibex.searchableText, contains('ibex'));
      expect(ibex.searchableText, contains('skyin'));
      expect(ibex.searchableText, contains('tangrol'));

      // 10. Ladakh Pika (Ochotona ladacensis)
      final pika = speciesMap['ladakh-pika']!;
      expect(pika.searchableText, contains('pika'));
      expect(pika.searchableText, contains('ochotona ladacensis'));
    });

    test('Search matching algorithm simulation reproduces multi-token query matches', () {
      List<ZoologySpecies> simulateSearch(String query) {
        final normalizedQuery = query.trim().toLowerCase();
        if (normalizedQuery.isEmpty) return kSpeciesCatalog;

        final queryTerms = normalizedQuery
            .split(RegExp(r'\s+'))
            .where((term) => term.isNotEmpty)
            .toList();

        return kSpeciesCatalog.where((species) {
          final searchableText = species.searchableText;
          return queryTerms.every(searchableText.contains);
        }).toList();
      }

      // Exact single term
      expect(simulateSearch('hangul').map((s) => s.id), contains('hangul'));
      expect(simulateSearch('markhor').map((s) => s.id), contains('markhor'));
      expect(simulateSearch('shan').map((s) => s.id), contains('snow-leopard'));
      expect(simulateSearch('daner').map((s) => s.id), contains('western-tragopan'));
      expect(simulateSearch('kasturi').map((s) => s.id), contains('musk-deer'));

      // Multi-token combinations
      final kashmirStagResults = simulateSearch('kashmir stag dachigam');
      expect(kashmirStagResults.map((s) => s.id), contains('hangul'));

      final pirPanjalResults = simulateSearch('pir panjal markhor');
      expect(pirPanjalResults.map((s) => s.id), contains('markhor'));

      final ladakhApexResults = simulateSearch('snow leopard ladakh');
      expect(ladakhApexResults.map((s) => s.id), contains('snow-leopard'));

      // Case-insensitivity stress
      expect(simulateSearch('HANGUL').map((s) => s.id), contains('hangul'));
      expect(simulateSearch('mArKhOr').map((s) => s.id), contains('markhor'));
      expect(simulateSearch('  sNoW   LeOpArD  ').map((s) => s.id), contains('snow-leopard'));
    });
  });

  group('Empirical Challenge 3: Residual Flora Exclusion Audit', () {
    test('Zero plant or flora taxa in kSpeciesCatalog across all 144 entries (R5)', () {
      final prohibitedCategories = {'plant', 'flora', 'tree', 'herb', 'shrub', 'botany', 'vegetation'};

      for (final species in kSpeciesCatalog) {
        // 1. Category must strictly be an animal group
        expect(
          prohibitedCategories.contains(species.category.toLowerCase()),
          isFalse,
          reason: 'Species ${species.id} has plant category: ${species.category}',
        );

        // 2. Kingdom must strictly be Animalia
        expect(
          species.taxonomy['Kingdom'],
          'Animalia',
          reason: 'Species ${species.id} has non-animalia kingdom: ${species.taxonomy['Kingdom']}',
        );

        // 3. Phylum must be animal phyla
        final validAnimalPhyla = {'Chordata', 'Arthropoda', 'Mollusca', 'Annelida'};
        final phylum = species.taxonomy['Phylum'];
        expect(
          validAnimalPhyla.contains(phylum),
          isTrue,
          reason: 'Species ${species.id} has non-animal phylum: $phylum',
        );
      }
    });

    test('Verify all 144 species belong to valid zoological classes', () {
      final validClasses = {
        'Mammalia',
        'Aves',
        'Reptilia',
        'Amphibia',
        'Insecta',
        'Actinopterygii',
        'Arachnida',
      };

      for (final species in kSpeciesCatalog) {
        final speciesClass = species.taxonomy['Class'];
        expect(
          validClasses.contains(speciesClass),
          isTrue,
          reason: 'Species ${species.id} has invalid animal class: $speciesClass',
        );
      }
    });
  });
}
