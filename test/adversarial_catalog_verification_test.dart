import 'package:flutter_test/flutter_test.dart';
import 'package:zoology_app/data/species_data.dart';
import 'package:zoology_app/models/zoology_species.dart';

void main() {
  group('Milestone 1 Empirical Challenger Suite: Comprehensive Catalog Property Tests', () {
    test('P1: Exact catalog cardinality and zoological class balance', () {
      expect(kSpeciesCatalog.length, 144,
          reason: 'Catalog must contain exactly 144 verified species');

      final classCounts = <String, int>{};
      for (final species in kSpeciesCatalog) {
        classCounts[species.category] = (classCounts[species.category] ?? 0) + 1;
      }

      // Check representation across all 6 authentic zoological classes
      expect(classCounts['Mammal'], 52, reason: 'Expected 52 mammals');
      expect(classCounts['Bird'], 46, reason: 'Expected 46 birds');
      expect(classCounts['Reptile'], 15, reason: 'Expected 15 reptiles');
      expect(classCounts['Amphibian'], 10, reason: 'Expected 10 amphibians');
      expect(classCounts['Insect'], 13, reason: 'Expected 13 insects/invertebrates');
      expect(classCounts['Fish'], 8, reason: 'Expected 8 coldwater fishes');

      final sum = classCounts.values.fold<int>(0, (a, b) => a + b);
      expect(sum, 144, reason: 'Sum of all categories must match total catalog count');
    });

    test('P2: Strict zero flora / plant rule across all metadata fields', () {
      const forbiddenFloraTerms = [
        'plant', 'flora', 'tree', 'herb', 'shrub', 'flower', 'grass',
        'fern', 'moss', 'algae', 'fungus', 'fungi', 'lichen', 'angiosperm',
        'gymnosperm', 'conifer', 'deciduous tree', 'plantae'
      ];

      const forbiddenPlantFamilies = [
        'pinaceae', 'rosaceae', 'asteraceae', 'poaceae', 'fabaceae',
        'brassicaceae', 'solanaceae', 'orchidaceae', 'cupressaceae'
      ];

      for (final species in kSpeciesCatalog) {
        final catLower = species.category.toLowerCase().trim();
        for (final term in forbiddenFloraTerms) {
          expect(catLower, isNot(term),
              reason: 'Species ${species.id} category "$catLower" matches forbidden flora term "$term"');
        }

        // Kingdom must be Animalia strictly
        expect(species.taxonomy['Kingdom'], 'Animalia',
            reason: 'Species ${species.id} Kingdom must be strictly Animalia');

        // Phylum must be Chordata or Arthropoda
        final phylum = species.taxonomy['Phylum'];
        expect(phylum, anyOf('Chordata', 'Arthropoda'),
            reason: 'Species ${species.id} Phylum "$phylum" must be Chordata or Arthropoda');

        // Family check
        final family = species.taxonomy['Family']?.toLowerCase();
        if (family != null) {
          for (final plantFam in forbiddenPlantFamilies) {
            expect(family, isNot(plantFam),
                reason: 'Species ${species.id} family "$family" is a known plant family');
          }
        }

        // Common name must not be a pure plant name
        final nameLower = species.commonName.toLowerCase().trim();
        for (final term in ['pine', 'cedar', 'oak tree', 'willow tree', 'rose', 'orchid', 'lotus']) {
          if (nameLower == term) {
            fail('Species ${species.id} common name "$nameLower" is purely a plant name');
          }
        }
      }
    });

    test('P3: Scientific names follow strict binomial/trinomial format and taxonomy consistency', () {
      final binomenPattern = RegExp(r'^[A-Z][a-z]+ [a-z]+$');
      final trinomenPattern = RegExp(r'^[A-Z][a-z]+ [a-z]+ [a-z]+$');

      for (final species in kSpeciesCatalog) {
        final sciName = species.scientificName;
        expect(sciName, isNotEmpty,
            reason: 'Species ${species.id} has empty scientific name');
        expect(sciName, equals(sciName.trim()),
            reason: 'Species ${species.id} has leading/trailing whitespace in scientificName: "$sciName"');

        final isBinomial = binomenPattern.hasMatch(sciName);
        final isTrinomial = trinomenPattern.hasMatch(sciName);

        expect(isBinomial || isTrinomial, isTrue,
            reason: 'Species ${species.id} scientificName "$sciName" violates binomen/trinomen format');

        final parts = sciName.split(' ');
        final genus = parts[0];
        final speciesEpithet = parts[1];

        // Genus must start with uppercase, epithets strictly lowercase
        expect(genus[0], equals(genus[0].toUpperCase()),
            reason: 'Genus in "$sciName" must be capitalized');
        expect(speciesEpithet, equals(speciesEpithet.toLowerCase()),
            reason: 'Species epithet in "$sciName" must be lowercase');

        if (isTrinomial) {
          final subEpithet = parts[2];
          expect(subEpithet, equals(subEpithet.toLowerCase()),
              reason: 'Subspecies epithet in "$sciName" must be lowercase');
        }

        // Taxonomy Map Consistency
        expect(species.taxonomy['Genus'], equals(genus),
            reason: 'Species ${species.id}: taxonomy Genus "${species.taxonomy['Genus']}" does not match $genus');

        final expectedSpecies = '$genus $speciesEpithet';
        expect(species.taxonomy['Species'], equals(expectedSpecies),
            reason: 'Species ${species.id}: taxonomy Species "${species.taxonomy['Species']}" does not match $expectedSpecies');

        if (isTrinomial) {
          // Check if Subspecies is present; if not, flag as potential discrepancy
          final sub = species.taxonomy['Subspecies'];
          if (sub != null) {
            expect(sub, equals(sciName),
                reason: 'Species ${species.id}: taxonomy Subspecies "$sub" does not match $sciName');
          }
        }
      }
    });

    test('P4: ID values are unique, non-empty, and adhere to strict kebab-case', () {
      final seenIds = <String>{};
      final kebabRegex = RegExp(r'^[a-z0-9]+(-[a-z0-9]+)*$');

      for (final species in kSpeciesCatalog) {
        expect(species.id, isNotEmpty, reason: 'Encountered empty species ID');
        expect(species.id.length, greaterThanOrEqualTo(3),
            reason: 'Species ID "${species.id}" is abnormally short');
        expect(species.id.length, lessThanOrEqualTo(50),
            reason: 'Species ID "${species.id}" is abnormally long');

        expect(kebabRegex.hasMatch(species.id), isTrue,
            reason: 'Species ID "${species.id}" violates kebab-case rules (lowercase letters, digits, single hyphens)');

        final isUnique = seenIds.add(species.id);
        expect(isUnique, isTrue,
            reason: 'Collision detected: Duplicate species ID "${species.id}" found in catalog');
      }

      expect(seenIds.length, 144,
          reason: 'Expected exactly 144 unique species IDs');
    });

    test('P5: Hangul taxonomy is strictly Cervus hanglu hanglu with no obsolete trinomen as primary', () {
      final hangulMatches = kSpeciesCatalog.where((s) => s.id == 'hangul').toList();
      expect(hangulMatches.length, 1, reason: 'Expected exactly one Hangul entry');

      final hangul = hangulMatches.first;
      expect(hangul.scientificName, 'Cervus hanglu hanglu',
          reason: 'Hangul scientificName must be authoritative Cervus hanglu hanglu');
      expect(hangul.taxonomy['Species'], 'Cervus hanglu');
      expect(hangul.taxonomy['Subspecies'], 'Cervus hanglu hanglu');
      expect(hangul.category, 'Mammal');
      expect(hangul.region, contains('Kashmir'));
      expect(hangul.conservation, 'Critically Endangered');
      expect(hangul.status, 'Present');
      expect(hangul.isVocal, isTrue);
      expect(hangul.audioAsset, 'assets/audio/hangul.mp3');
      expect(hangul.vocalizationNote, contains('bugle'));

      // Check that no other species claims Cervus hanglu
      for (final s in kSpeciesCatalog) {
        if (s.id != 'hangul') {
          expect(s.scientificName, isNot('Cervus hanglu hanglu'));
          expect(s.scientificName, isNot('Cervus hanglu kashmiricus'));
        }
      }
    });

    test('P6: isVocal boolean contract and vocalization notes are complete and valid', () {
      int vocalCount = 0;
      int nonVocalCount = 0;
      int audioAssetCount = 0;

      for (final species in kSpeciesCatalog) {
        // isVocal must be boolean
        expect(species.isVocal, isA<bool>());

        // Both vocalization and vocalizationNote must be informative non-empty strings
        expect(species.vocalization.trim().length, greaterThanOrEqualTo(10),
            reason: 'Species ${species.id} vocalization field is too short or empty');

        expect(species.vocalizationNote, isNotNull,
            reason: 'Species ${species.id} vocalizationNote is null');
        expect(species.vocalizationNote!.trim().length, greaterThanOrEqualTo(10),
            reason: 'Species ${species.id} vocalizationNote is too short or empty');

        if (species.isVocal) {
          vocalCount++;
        } else {
          nonVocalCount++;
          // Non-vocal species should not have an audio asset assigned
          expect(species.audioAsset, isNull,
              reason: 'Non-vocal species ${species.id} should not have an audioAsset');

          // Non-vocal species note must explain sensory / acoustic mechanisms
          final note = species.vocalizationNote!.toLowerCase();
          final explainsAlternative = note.contains('non-vocal') ||
              note.contains('vibrat') ||
              note.contains('pheromone') ||
              note.contains('display') ||
              note.contains('pressure') ||
              note.contains('chemical') ||
              note.contains('lateral') ||
              note.contains('stridulat') ||
              note.contains('silent');
          expect(explainsAlternative, isTrue,
              reason: 'Non-vocal species ${species.id} vocalizationNote fails to explain sensory/acoustic mechanism: "${species.vocalizationNote}"');
        }

        // If audioAsset is set, must meet path convention
        if (species.audioAsset != null) {
          audioAssetCount++;
          expect(species.isVocal, isTrue,
              reason: 'Species ${species.id} with audioAsset must have isVocal=true');
          expect(species.audioAsset, startsWith('assets/audio/'),
              reason: 'Species ${species.id} audioAsset must start with assets/audio/');
          expect(species.audioAsset, endsWith('.mp3'),
              reason: 'Species ${species.id} audioAsset must end with .mp3');
        }
      }

      // Check distribution: both vocal and non-vocal fauna exist
      expect(vocalCount, greaterThan(80), reason: 'Majority of birds and mammals vocalize');
      expect(nonVocalCount, greaterThan(20), reason: 'Fishes, reptiles, and insects include non-vocal taxa');
      expect(audioAssetCount, greaterThanOrEqualTo(10), reason: 'Milestone 1 must specify audioAssets for key focal fauna');
    });

    test('P7: Category whitelist and regional distribution validity', () {
      const validCategories = {'Mammal', 'Bird', 'Reptile', 'Amphibian', 'Fish', 'Insect'};

      final regionalPresence = <String, int>{
        'kashmir': 0,
        'jammu': 0,
        'ladakh': 0,
        'pir panjal': 0,
      };

      for (final species in kSpeciesCatalog) {
        expect(validCategories.contains(species.category), isTrue,
            reason: 'Species ${species.id} has invalid category "${species.category}". Must be one of $validCategories');

        expect(species.region.trim(), isNotEmpty,
            reason: 'Species ${species.id} has empty region string');
        expect(species.region.length, greaterThanOrEqualTo(4),
            reason: 'Species ${species.id} region string "${species.region}" is too short');

        final regLower = species.region.toLowerCase();
        for (final key in regionalPresence.keys) {
          if (regLower.contains(key)) {
            regionalPresence[key] = regionalPresence[key]! + 1;
          }
        }
      }

      // Every primary biogeographical region must have significant coverage
      expect(regionalPresence['kashmir']!, greaterThanOrEqualTo(50),
          reason: 'Kashmir region must be represented by at least 50 species');
      expect(regionalPresence['jammu']!, greaterThanOrEqualTo(30),
          reason: 'Jammu region must be represented by at least 30 species');
      expect(regionalPresence['ladakh']!, greaterThanOrEqualTo(20),
          reason: 'Ladakh region must be represented by at least 20 species');
      expect(regionalPresence['pir panjal']!, greaterThanOrEqualTo(10),
          reason: 'Pir Panjal region must be represented by at least 10 species');
    });

    test('P8: Complete zoological field data integrity across all 144 entries', () {
      const validConservationStatuses = {
        'Critically Endangered',
        'Endangered',
        'Vulnerable',
        'Near Threatened',
        'Least Concern',
        'Data Deficient',
        'Not Evaluated'
      };

      for (final species in kSpeciesCatalog) {
        expect(species.commonName.trim().length, greaterThanOrEqualTo(3),
            reason: 'Species ${species.id} has invalid commonName');
        expect(species.habitat.trim().length, greaterThanOrEqualTo(10),
            reason: 'Species ${species.id} has invalid habitat');
        expect(species.size.trim().length, greaterThanOrEqualTo(3),
            reason: 'Species ${species.id} has invalid size');
        expect(validConservationStatuses.contains(species.conservation), isTrue,
            reason: 'Species ${species.id} has invalid conservation status "${species.conservation}"');
        expect(species.feature.trim().length, greaterThanOrEqualTo(10),
            reason: 'Species ${species.id} has invalid feature');
        expect(species.funFact.trim().length, greaterThanOrEqualTo(10),
            reason: 'Species ${species.id} has invalid funFact');
        expect(species.distribution.trim().length, greaterThanOrEqualTo(10),
            reason: 'Species ${species.id} has invalid distribution');
        expect(species.diet.trim().length, greaterThanOrEqualTo(5),
            reason: 'Species ${species.id} has invalid diet');
        expect(species.behavior.trim().length, greaterThanOrEqualTo(10),
            reason: 'Species ${species.id} has invalid behavior');
        expect(species.breeding.trim().length, greaterThanOrEqualTo(10),
            reason: 'Species ${species.id} has invalid breeding');
        expect(species.threats.trim().length, greaterThanOrEqualTo(10),
            reason: 'Species ${species.id} has invalid threats');
        expect(species.ecologicalRole.trim().length, greaterThanOrEqualTo(10),
            reason: 'Species ${species.id} has invalid ecologicalRole');
        expect(species.identification.trim().length, greaterThanOrEqualTo(10),
            reason: 'Species ${species.id} has invalid identification');

        // Search terms check
        expect(species.searchTerms, isNotEmpty,
            reason: 'Species ${species.id} has empty searchTerms list');
        final commonLower = species.commonName.toLowerCase();
        final commonNormalized = commonLower.replaceAll('-', ' ');
        final sciLower = species.scientificName.toLowerCase();

        final hasCommon = species.searchTerms.any((t) {
          final tNorm = t.replaceAll('-', ' ');
          return commonNormalized.contains(tNorm) || tNorm.contains(commonNormalized);
        });
        final hasSci = species.searchTerms.any((t) => sciLower.contains(t) || t.contains(sciLower));
        expect(hasCommon, isTrue,
            reason: 'Species ${species.id} searchTerms does not index common name "${species.commonName}"');
        expect(hasSci, isTrue,
            reason: 'Species ${species.id} searchTerms does not index scientific name "${species.scientificName}"');
      }
    });

    test('P9: Serialization roundtrip and model property invariants on all 144 species', () {
      for (final species in kSpeciesCatalog) {
        final json = species.toJson();
        final deserialized = ZoologySpecies.fromJson(json);

        expect(deserialized.id, equals(species.id));
        expect(deserialized.commonName, equals(species.commonName));
        expect(deserialized.scientificName, equals(species.scientificName));
        expect(deserialized.category, equals(species.category));
        expect(deserialized.region, equals(species.region));
        expect(deserialized.status, equals(species.status));
        expect(deserialized.habitat, equals(species.habitat));
        expect(deserialized.size, equals(species.size));
        expect(deserialized.conservation, equals(species.conservation));
        expect(deserialized.feature, equals(species.feature));
        expect(deserialized.funFact, equals(species.funFact));
        expect(deserialized.distribution, equals(species.distribution));
        expect(deserialized.diet, equals(species.diet));
        expect(deserialized.behavior, equals(species.behavior));
        expect(deserialized.breeding, equals(species.breeding));
        expect(deserialized.threats, equals(species.threats));
        expect(deserialized.ecologicalRole, equals(species.ecologicalRole));
        expect(deserialized.identification, equals(species.identification));
        expect(deserialized.vocalization, equals(species.vocalization));
        expect(deserialized.audioAsset, equals(species.audioAsset));
        expect(deserialized.isVocal, equals(species.isVocal));
        expect(deserialized.vocalizationNote, equals(species.vocalizationNote));
        expect(deserialized.taxonomy, equals(species.taxonomy));
        expect(deserialized.searchTerms, equals(species.searchTerms));

        // searchableText invariant
        final searchable = species.searchableText;
        expect(searchable, contains(species.commonName.toLowerCase()));
        expect(searchable, contains(species.scientificName.toLowerCase()));
        expect(searchable, contains(species.category.toLowerCase()));
        if (species.vocalizationNote != null) {
          expect(searchable, contains(species.vocalizationNote!.toLowerCase()));
        }

        // copyWith idempotence test
        final copied = species.copyWith();
        expect(copied.id, equals(species.id));
        expect(copied.commonName, equals(species.commonName));
        expect(copied.scientificName, equals(species.scientificName));
        expect(copied.isVocal, equals(species.isVocal));
      }
    });

    test('P10: Adversarial search queries & category filtering resilience', () {
      for (final species in kSpeciesCatalog) {
        // Query by exact common name
        final exactMatches = kSpeciesCatalog.where((s) =>
            s.commonName.toLowerCase() == species.commonName.toLowerCase()).toList();
        expect(exactMatches.length, 1,
            reason: 'Common name "${species.commonName}" should identify exactly one species');

        // Query by exact scientific name
        final sciMatches = kSpeciesCatalog.where((s) =>
            s.scientificName.toLowerCase() == species.scientificName.toLowerCase()).toList();
        expect(sciMatches.length, 1,
            reason: 'Scientific name "${species.scientificName}" should identify exactly one species');

        // Query by ID
        final idMatches = kSpeciesCatalog.where((s) => s.id == species.id).toList();
        expect(idMatches.length, 1);
      }

      // Filter by category integrity
      final categories = ['Mammal', 'Bird', 'Reptile', 'Amphibian', 'Fish', 'Insect'];
      for (final cat in categories) {
        final filtered = kSpeciesCatalog.where((s) => s.category == cat).toList();
        expect(filtered.isNotEmpty, isTrue);
        for (final s in filtered) {
          expect(s.category, equals(cat));
        }
      }
    });
  });
}
