import 'package:flutter_test/flutter_test.dart';
import 'package:zoology_app/data/species_data.dart';
import 'package:zoology_app/models/zoology_species.dart';

void main() {
  group('Milestone 1: Catalog & Zoology Data Expansion Tests', () {
    test('Catalog contains at least 130 native wildlife species (R5)', () {
      expect(kSpeciesCatalog.length, greaterThanOrEqualTo(130));
      expect(kSpeciesCatalog.length, 144);
    });

    test('Strict zero flora / plant rule is maintained (R5)', () {
      const plantKeywords = ['plant', 'flora', 'flower', 'tree', 'herb', 'shrub'];
      for (final species in kSpeciesCatalog) {
        expect(
          species.category.toLowerCase(),
          isNot('plant'),
          reason: 'Species ${species.id} must not have category Plant',
        );
        expect(
          species.taxonomy['Kingdom'],
          'Animalia',
          reason: 'Species ${species.id} must belong to Animalia kingdom',
        );
        for (final keyword in plantKeywords) {
          expect(
            species.category.toLowerCase(),
            isNot(keyword),
            reason: 'Species ${species.id} has plant-related category',
          );
        }
      }
    });

    test('All 6 major zoological classes are comprehensively represented', () {
      final counts = <String, int>{};
      for (final s in kSpeciesCatalog) {
        counts[s.category] = (counts[s.category] ?? 0) + 1;
      }

      expect(counts['Mammal'], greaterThanOrEqualTo(40));
      expect(counts['Bird'], greaterThanOrEqualTo(40));
      expect(counts['Reptile'], greaterThanOrEqualTo(12));
      expect(counts['Amphibian'], greaterThanOrEqualTo(8));
      expect(counts['Insect'], greaterThanOrEqualTo(10));
      expect(counts['Fish'], greaterThanOrEqualTo(6));

      expect(counts['Mammal'], 52);
      expect(counts['Bird'], 46);
      expect(counts['Reptile'], 15);
      expect(counts['Amphibian'], 10);
      expect(counts['Insect'], 13);
      expect(counts['Fish'], 8);
    });

    test('Every species ID is unique, non-empty, and valid kebab-case', () {
      final ids = <String>{};
      final kebabPattern = RegExp(r'^[a-z0-9]+(-[a-z0-9]+)*$');

      for (final species in kSpeciesCatalog) {
        expect(species.id, isNotEmpty);
        expect(
          kebabPattern.hasMatch(species.id),
          isTrue,
          reason: 'Species ID ${species.id} is not valid kebab-case',
        );
        expect(
          ids.add(species.id),
          isTrue,
          reason: 'Duplicate species ID found: ${species.id}',
        );
      }
    });

    test('Hangul taxonomy is corrected to authoritative Cervus hanglu hanglu', () {
      final hangul = kSpeciesCatalog.firstWhere((s) => s.id == 'hangul');

      expect(hangul.scientificName, 'Cervus hanglu hanglu');
      expect(hangul.taxonomy['Species'], 'Cervus hanglu');
      expect(hangul.taxonomy['Subspecies'], 'Cervus hanglu hanglu');
      expect(hangul.searchTerms, contains('cervus hanglu hanglu'));
      expect(hangul.searchTerms, contains('hangul'));
      expect(hangul.conservation, 'Critically Endangered');
      expect(hangul.audioAsset, 'assets/audio/hangul.mp3');
      expect(hangul.isVocal, isTrue);
      expect(hangul.vocalizationNote, isNotNull);
      expect(hangul.vocalizationNote, contains('bugle'));
    });

    test('Audio and vocalization metadata is populated across all catalog entries', () {
      for (final species in kSpeciesCatalog) {
        // isVocal must be boolean
        expect(species.isVocal, isA<bool>());

        // vocalizationNote must be informative non-empty string
        expect(
          species.vocalizationNote,
          isNotNull,
          reason: 'Species ${species.id} is missing vocalizationNote',
        );
        expect(
          species.vocalizationNote!.trim(),
          isNotEmpty,
          reason: 'Species ${species.id} has empty vocalizationNote',
        );

        // If audioAsset is provided, must point to assets/audio/ and end with .mp3
        if (species.audioAsset != null) {
          expect(
            species.audioAsset!,
            startsWith('assets/audio/'),
            reason: 'Species ${species.id} audioAsset path must start with assets/audio/',
          );
          expect(
            species.audioAsset!,
            endsWith('.mp3'),
            reason: 'Species ${species.id} audioAsset must be an MP3 file',
          );
        }

        // Non-vocal species should explain alternative acoustic or sensory communication
        if (!species.isVocal) {
          final note = species.vocalizationNote!.toLowerCase();
          final explainsAlternative = note.contains('non-vocal') ||
              note.contains('vibrat') ||
              note.contains('pheromone') ||
              note.contains('display') ||
              note.contains('pressure') ||
              note.contains('chemical') ||
              note.contains('lateral');
          expect(
            explainsAlternative,
            isTrue,
            reason: 'Non-vocal species ${species.id} note does not explain sensory mechanism',
          );
        }
      }
    });

    test('Focal species have valid assigned audio assets', () {
      final audioCatalog = kSpeciesCatalog.where((s) => s.audioAsset != null).toList();
      expect(audioCatalog.length, greaterThanOrEqualTo(10));

      final audioSpeciesIds = audioCatalog.map((s) => s.id).toSet();
      expect(audioSpeciesIds, contains('hangul'));
      expect(audioSpeciesIds, contains('snow-leopard'));
      expect(audioSpeciesIds, contains('himalayan-wolf'));
      expect(audioSpeciesIds, contains('monal'));
      expect(audioSpeciesIds, contains('western-tragopan'));
      expect(audioSpeciesIds, contains('kashmir-flycatcher'));
      expect(audioSpeciesIds, contains('blue-whistling-thrush'));
      expect(audioSpeciesIds, contains('black-necked-crane'));
      expect(audioSpeciesIds, contains('himalayan-pit-viper'));
      expect(audioSpeciesIds, contains('himalayan-toad'));
    });

    test('Added native Jammu & Kashmir fauna are present with verified data', () {
      final speciesMap = {for (var s in kSpeciesCatalog) s.id: s};

      // Keystone Mammals
      expect(speciesMap['himalayan-goral']?.scientificName, 'Naemorhedus goral');
      expect(speciesMap['himalayan-serow']?.scientificName, 'Capricornis thar');
      expect(speciesMap['barking-deer']?.scientificName, 'Muntiacus muntjak');
      expect(speciesMap['sambar']?.scientificName, 'Rusa unicolor');
      expect(speciesMap['ladakh-pika']?.scientificName, 'Ochotona ladacensis');
      expect(speciesMap['small-indian-mongoose']?.scientificName, 'Urva auropunctata');
      expect(speciesMap['asian-palm-civet']?.scientificName, 'Paradoxurus hermaphroditus');
      expect(speciesMap['smooth-coated-otter']?.scientificName, 'Lutrogale perspicillata');
      expect(speciesMap['jungle-cat']?.scientificName, 'Felis chaus');
      expect(speciesMap['indian-pangolin']?.scientificName, 'Manis crassicaudata');
      expect(speciesMap['five-striped-palm-squirrel']?.scientificName, 'Funambulus pennantii');
      expect(speciesMap['himalayan-weasel']?.scientificName, 'Mustela sibirica');
      expect(speciesMap['tibetan-gazelle']?.scientificName, 'Procapra picticaudata');
      expect(speciesMap['kashmir-cave-bat']?.scientificName, 'Myotis longipes');

      // Keystone Birds
      expect(speciesMap['cheer-pheasant']?.scientificName, 'Catreus wallichii');
      expect(speciesMap['kalij-pheasant']?.scientificName, 'Lophura leucomelanos');
      expect(speciesMap['common-kingfisher']?.scientificName, 'Alcedo atthis');
      expect(speciesMap['white-throated-kingfisher']?.scientificName, 'Halcyon smyrnensis');
      expect(speciesMap['pied-kingfisher']?.scientificName, 'Ceryle rudis');
      expect(speciesMap['common-moorhen']?.scientificName, 'Gallinula chloropus');
      expect(speciesMap['eurasian-coot']?.scientificName, 'Fulica atra');
      expect(speciesMap['grey-heron']?.scientificName, 'Ardea cinerea');
      expect(speciesMap['northern-pintail']?.scientificName, 'Anas acuta');
      expect(speciesMap['himalayan-woodpecker']?.scientificName, 'Dendrocopos himalayensis');
      expect(speciesMap['great-barbet']?.scientificName, 'Psilopogon virens');
      expect(speciesMap['slaty-headed-parakeet']?.scientificName, 'Psittacula himalayana');
      expect(speciesMap['kashmir-nuthatch']?.scientificName, 'Sitta cashmirensis');
      expect(speciesMap['yellow-billed-chough']?.scientificName, 'Pyrrhocorax graculus');
      expect(speciesMap['steppe-eagle']?.scientificName, 'Aquila nipalensis');
      expect(speciesMap['eurasian-eagle-owl']?.scientificName, 'Bubo bubo');

      // Keystone Herpetofauna
      expect(speciesMap['himalayan-keelback']?.scientificName, 'Herpetoreas platyceps');
      expect(speciesMap['checkered-keelback']?.scientificName, 'Fowlea piscator');
      expect(speciesMap['indian-cobra']?.scientificName, 'Naja naja');
      expect(speciesMap['common-krait']?.scientificName, 'Bungarus caeruleus');
      expect(speciesMap['russell-viper']?.scientificName, 'Daboia russelii');
      expect(speciesMap['cliff-racer']?.scientificName, 'Platyceps ladacensis');
      expect(speciesMap['common-wolf-snake']?.scientificName, 'Lycodon aulicus');
      expect(speciesMap['himalayan-ground-skink']?.scientificName, 'Asymblepharus himalayanus');
      expect(speciesMap['stoliczka-gecko']?.scientificName, 'Cyrtodactylus stoliczkai');
      expect(speciesMap['indian-flapshell-turtle']?.scientificName, 'Lissemys punctata');
      expect(speciesMap['kashmir-paa-frog']?.scientificName, 'Allopaa hazarensis');
      expect(speciesMap['indian-bullfrog']?.scientificName, 'Hoplobatrachus tigerinus');
      expect(speciesMap['ladakh-toad']?.scientificName, 'Bufotes latastii');
      expect(speciesMap['kashmir-cricket-frog']?.scientificName, 'Minervarya kashmiriensis');
      expect(speciesMap['common-asian-toad']?.scientificName, 'Duttaphrynus melanostictus');
      expect(speciesMap['burrowing-frog']?.scientificName, 'Sphaerotheca breviceps');
      expect(speciesMap['murree-hills-frog']?.scientificName, 'Nanorana vicina');
      expect(speciesMap['skardu-toad']?.scientificName, 'Bufotes pseudoraddei');

      // Keystone Invertebrates & Fishes
      expect(speciesMap['kashmir-swallowtail']?.scientificName, 'Papilio machaon asiatica');
      expect(speciesMap['common-peacock-butterfly']?.scientificName, 'Papilio polyctor');
      expect(speciesMap['noble-apollo']?.scientificName, 'Parnassius charltonius');
      expect(speciesMap['indian-tortoiseshell']?.scientificName, 'Aglais caschmirensis');
      expect(speciesMap['four-spotted-chaser']?.scientificName, 'Libellula quadrimaculata');
      expect(speciesMap['blue-emperor-dragonfly']?.scientificName, 'Anax imperator');
      expect(speciesMap['asian-giant-hornet']?.scientificName, 'Vespa mandarinia');
      expect(speciesMap['himalayan-rock-scorpion']?.scientificName, 'Scorpiops hardwickii');
      expect(speciesMap['kashmir-stone-loach']?.scientificName, 'Triplophysa kashmirensis');
      expect(speciesMap['kashmir-torrent-catfish']?.scientificName, 'Glyptothorax kashmirensis');
      expect(speciesMap['blunt-snout-snow-trout']?.scientificName, 'Schizothorax plagiostomus');
      expect(speciesMap['rainbow-trout']?.scientificName, 'Oncorhynchus mykiss');
    });

    test('Regional biogeography covers Kashmir, Jammu, Ladakh, and Pir Panjal', () {
      final regionsJoined = kSpeciesCatalog.map((s) => s.region.toLowerCase()).join(' ');

      expect(regionsJoined, contains('kashmir'));
      expect(regionsJoined, contains('jammu'));
      expect(regionsJoined, contains('ladakh'));
      expect(regionsJoined, contains('pir panjal'));

      for (final species in kSpeciesCatalog) {
        expect(species.region.trim(), isNotEmpty);
      }
    });

    test('ZoologySpecies model methods (copyWith, toJson, fromJson, searchableText) work correctly', () {
      final original = kSpeciesCatalog.firstWhere((s) => s.id == 'hangul');

      // copyWith
      final updated = original.copyWith(
        conservation: 'Vulnerable',
        isVocal: false,
        vocalizationNote: 'Test note',
      );
      expect(updated.id, original.id);
      expect(updated.conservation, 'Vulnerable');
      expect(updated.isVocal, isFalse);
      expect(updated.vocalizationNote, 'Test note');
      expect(updated.commonName, original.commonName);

      // toJson / fromJson roundtrip
      final json = original.toJson();
      expect(json['id'], 'hangul');
      expect(json['scientificName'], 'Cervus hanglu hanglu');
      expect(json['audioAsset'], 'assets/audio/hangul.mp3');
      expect(json['isVocal'], isTrue);

      final restored = ZoologySpecies.fromJson(json);
      expect(restored.id, original.id);
      expect(restored.scientificName, original.scientificName);
      expect(restored.audioAsset, original.audioAsset);
      expect(restored.isVocal, original.isVocal);
      expect(restored.vocalizationNote, original.vocalizationNote);

      // searchableText contains audio notes and taxonomy
      expect(original.searchableText, contains('cervus hanglu hanglu'));
      expect(original.searchableText, contains('bugle'));
    });
  });
}
