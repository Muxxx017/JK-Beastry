import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zoology_app/data/fauna_quiz_data.dart';
import 'package:zoology_app/data/observation_store.dart';
import 'package:zoology_app/data/offline_taxa_store.dart';
import 'package:zoology_app/data/species_data.dart';
import 'package:zoology_app/main.dart';
import 'package:zoology_app/models/fauna_quiz_question.dart';
import 'package:zoology_app/models/field_observation.dart';
import 'package:zoology_app/models/inat_taxon.dart';
import 'package:zoology_app/models/zoology_species.dart';
import 'package:zoology_app/screens/species_detail_page.dart';
import 'package:zoology_app/services/inat_service.dart';
import 'package:zoology_app/services/offline_species_service.dart';
import 'package:zoology_app/widgets/species_reference_photo.dart';

/// Mock HTTP client for injecting network faults, timeouts, and corrupted payloads
class _AdversarialMockClient extends http.BaseClient {
  final Future<http.StreamedResponse> Function(http.BaseRequest request) _handler;
  _AdversarialMockClient(this._handler);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) => _handler(request);
}

http.StreamedResponse _mockStreamedResponse({
  required String body,
  int statusCode = 200,
  Map<String, String>? headers,
}) {
  final encoded = utf8.encode(body);
  return http.StreamedResponse(
    Stream.value(encoded),
    statusCode,
    contentLength: encoded.length,
    headers: headers ?? {'content-type': 'application/json; charset=utf-8'},
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  // ===========================================================================
  // GROUP 1: DATA STORES ADVERSARIAL HARDENING
  // ===========================================================================
  group('Tier 5 - Group 1: Data Stores Adversarial Hardening', () {
    test('1.1: ObservationStore handles syntax-corrupted JSON by falling back to cache', () async {
      SharedPreferences.setMockInitialValues({
        'field_observations_v1': '{"corrupted": [unparseable JSON string',
      });
      final store = ObservationStore();
      final loaded = await store.load();

      expect(loaded, isNotNull);
      expect(loaded, isEmpty);
    });

    test('1.2: ObservationStore handles non-list JSON root values gracefully', () async {
      final invalidRoots = [
        '12345',
        '"A raw scalar string"',
        'true',
        '{"object": "not a list"}',
      ];

      for (final root in invalidRoots) {
        SharedPreferences.setMockInitialValues({'field_observations_v1': root});
        final store = ObservationStore();
        final loaded = await store.load();
        expect(loaded, isNotNull);
        expect(loaded, isEmpty, reason: 'Expected empty list for non-list JSON: $root');
      }
    });

    test('1.3: ObservationStore handles malformed items in list without unhandled crash', () async {
      SharedPreferences.setMockInitialValues({
        'field_observations_v1': jsonEncode([
          123, // not a map
          'string item',
          {
            'id': 'obs-1',
            // Missing speciesName, location, notes, observedAt
          },
          {
            'id': 'obs-2',
            'speciesName': 'Hangul',
            'location': 'Dachigam',
            'notes': 'Spotted near river',
            'photoBase64': null,
            'observedAt': 'invalid-date-format-xyz', // Invalid timestamp
          },
        ]),
      });

      final store = ObservationStore();
      final loaded = await store.load();
      expect(loaded, isNotNull);
      expect(loaded, isEmpty);
    });

    test('1.4: ObservationStore sorts observations strictly descending by observedAt', () async {
      final now = DateTime.now();
      final obsOld = FieldObservation(
        id: 'obs-old',
        speciesName: 'Snow Leopard',
        location: 'Hemis',
        notes: 'Old sighting',
        photoBase64: null,
        observedAt: now.subtract(const Duration(days: 10)),
      );
      final obsMid = FieldObservation(
        id: 'obs-mid',
        speciesName: 'Hangul',
        location: 'Dachigam',
        notes: 'Mid sighting',
        photoBase64: null,
        observedAt: now.subtract(const Duration(days: 2)),
      );
      final obsNew = FieldObservation(
        id: 'obs-new',
        speciesName: 'Himalayan Monal',
        location: 'Gulmarg',
        notes: 'Recent sighting',
        photoBase64: null,
        observedAt: now,
      );

      final store = ObservationStore();
      // Save in inverted order
      await store.save([obsOld, obsNew, obsMid]);

      final loaded = await store.load();
      expect(loaded.length, 3);
      expect(loaded[0].id, 'obs-new');
      expect(loaded[1].id, 'obs-mid');
      expect(loaded[2].id, 'obs-old');
    });

    test('1.5: ObservationStore in-memory cache survives save and reload cycles', () async {
      final store = ObservationStore();
      final observation = FieldObservation(
        id: 'obs-cache-test',
        speciesName: 'Kashmir Musk Deer',
        location: 'Overa-Aru',
        notes: 'Observed browsing on birch bark',
        photoBase64: null,
        observedAt: DateTime.now(),
      );

      await store.save([observation]);
      final loaded1 = await store.load();
      expect(loaded1.length, 1);
      expect(loaded1.single.id, 'obs-cache-test');

      // Now corrupt SharedPreferences to trigger load fallback
      SharedPreferences.setMockInitialValues({'field_observations_v1': '{bad_data'});
      final loaded2 = await store.load();
      // Must fall back to in-memory cache
      expect(loaded2.length, 1);
      expect(loaded2.single.id, 'obs-cache-test');
    });

    test('1.6: ObservationStore handles empty lists and null photoBase64 cleanly', () async {
      final store = ObservationStore();
      await store.save([]);
      final loaded = await store.load();
      expect(loaded, isEmpty);
    });

    test('1.7: FieldObservation serializes massive text notes without truncation', () async {
      final massiveNotes = 'Zoological observation data: ' * 2000; // ~60KB string
      final observation = FieldObservation(
        id: 'obs-massive-note',
        speciesName: 'Markhor',
        location: 'Kazinag National Park',
        notes: massiveNotes,
        photoBase64: null,
        observedAt: DateTime.parse('2026-11-14T10:00:00Z'),
      );

      final json = observation.toJson();
      final reconstituted = FieldObservation.fromJson(json);

      expect(reconstituted.notes.length, massiveNotes.length);
      expect(reconstituted.notes, massiveNotes);
      expect(reconstituted.photoBytes, isNull);
    });

    test('1.8: OfflineTaxaStore handles corrupted or malformed JSON in SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({
        'offline_taxa_v1': '{{{corrupted JSON payload',
      });
      final store = OfflineTaxaStore();
      final taxa = await store.load();
      expect(taxa, isNotNull);
      expect(taxa, isEmpty);
    });

    test('1.9: OfflineTaxaStore handles incomplete or corrupted taxon objects', () async {
      SharedPreferences.setMockInitialValues({
        'offline_taxa_v1': jsonEncode([
          {'id': 'not-an-int', 'name': 'Corrupted'},
          {'only': 'partial keys'},
        ]),
      });
      final store = OfflineTaxaStore();
      final taxa = await store.load();
      expect(taxa, isNotNull);
      expect(taxa, isEmpty);
    });

    test('1.10: OfflineTaxaStore.findByScientificName handles whitespace, case variations, and misses', () async {
      SharedPreferences.setMockInitialValues({});
      final store = OfflineTaxaStore();
      const testTaxon = InatTaxon(
        id: 101,
        name: 'Panthera uncia',
        commonName: 'Snow Leopard',
        rank: 'species',
        regionalObservations: 55,
        totalObservations: 1200,
        conservationStatus: 'Vulnerable',
        photoUrl: 'https://example.org/snow_leopard.jpg',
        photoAttribution: 'Naturalist',
        photoLicense: 'cc-by',
        wikipediaUrl: null,
      );

      await store.save(testTaxon);

      // Exact match
      final match1 = await store.findByScientificName('Panthera uncia');
      expect(match1, isNotNull);
      expect(match1!.id, 101);

      // Uppercase match
      final match2 = await store.findByScientificName('PANTHERA UNCIA');
      expect(match2, isNotNull);
      expect(match2!.id, 101);

      // Surrounding whitespace match
      final match3 = await store.findByScientificName('   Panthera uncia   ');
      expect(match3, isNotNull);
      expect(match3!.id, 101);

      // Non-existent species
      final miss = await store.findByScientificName('Nonexistent beast');
      expect(miss, isNull);
    });

    test('1.11: OfflineTaxaStore callbacks: photoWriter called on save, photoDeleter called on remove', () async {
      int? writtenTaxonId;
      Uint8List? writtenBytes;
      String? deletedPhotoPath;

      final store = OfflineTaxaStore(
        writePhoto: (id, bytes) async {
          writtenTaxonId = id;
          writtenBytes = bytes;
          return '/local/storage/photos/$id.jpg';
        },
        deletePhoto: (path) async {
          deletedPhotoPath = path;
        },
      );

      const taxon = InatTaxon(
        id: 202,
        name: 'Cervus hanglu',
        commonName: 'Hangul',
        rank: 'species',
        regionalObservations: 150,
        totalObservations: 200,
        conservationStatus: 'Critically Endangered',
        photoUrl: 'https://example.org/hangul.jpg',
        photoAttribution: 'Wildlife Warden',
        photoLicense: 'cc-by-sa',
        wikipediaUrl: null,
      );

      final dummyBytes = Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0, 0x01, 0x02]);
      await store.save(taxon, photoBytes: dummyBytes);

      expect(writtenTaxonId, 202);
      expect(writtenBytes, dummyBytes);

      final loaded = await store.load();
      expect(
        loaded.firstWhere((t) => t.id == 202).offlinePhotoPath,
        '/local/storage/photos/202.jpg',
      );

      // Now remove the taxon
      await store.remove(202);
      expect(deletedPhotoPath, '/local/storage/photos/202.jpg');

      final emptyLoaded = await store.load();
      expect(emptyLoaded.any((t) => t.id == 202), isFalse);
    });

    test('1.12: OfflineTaxaStore photoDeleter exception does not prevent record deletion', () async {
      final store = OfflineTaxaStore(
        writePhoto: (id, bytes) async => '/path/$id.jpg',
        deletePhoto: (path) async => throw Exception('Disk write protected'),
      );

      const taxon = InatTaxon(
        id: 303,
        name: 'Ursus thibetanus',
        commonName: 'Asiatic Black Bear',
        rank: 'species',
        regionalObservations: 80,
        totalObservations: 300,
        conservationStatus: 'Vulnerable',
        photoUrl: null,
        photoAttribution: null,
        photoLicense: null,
        wikipediaUrl: null,
        offlinePhotoPath: '/path/303.jpg',
      );

      await store.save(taxon);
      expect((await store.load()).any((t) => t.id == 303), isTrue);

      // Remove taxon even when deleter throws
      await store.remove(303);
      expect((await store.load()).any((t) => t.id == 303), isFalse);
    });

    test('1.13: OfflineTaxaStore updating existing taxon updates in-place without duplicating', () async {
      final store = OfflineTaxaStore();
      const initialTaxon = InatTaxon(
        id: 404,
        name: 'Gyps himalayensis',
        commonName: 'Himalayan Griffon',
        rank: 'species',
        regionalObservations: 30,
        totalObservations: 500,
        conservationStatus: 'Near Threatened',
        photoUrl: 'https://example.org/initial.jpg',
        photoAttribution: 'Birdwatcher A',
        photoLicense: 'cc-by',
        wikipediaUrl: null,
      );

      await store.save(initialTaxon);
      final matchingInitial = (await store.load()).where((t) => t.id == 404).toList();
      expect(matchingInitial, hasLength(1));

      final updatedTaxon = initialTaxon.copyWith(
        photoAttribution: 'Birdwatcher B (updated)',
      );
      await store.save(updatedTaxon);

      final matchingUpdated = (await store.load()).where((t) => t.id == 404).toList();
      expect(matchingUpdated, hasLength(1));
      expect(matchingUpdated.single.photoAttribution, 'Birdwatcher B (updated)');
    });
  });

  // ===========================================================================
  // GROUP 2: SERVICES ADVERSARIAL HARDENING
  // ===========================================================================
  group('Tier 5 - Group 2: Services Adversarial Hardening', () {
    test('2.1: InatService handles simulated network timeout by throwing TimeoutException', () async {
      final client = _AdversarialMockClient((request) async {
        throw TimeoutException('iNaturalist connection timed out');
      });
      final service = InatService(client: client);
      addTearDown(service.close);

      expect(
        () => service.searchRegionalSpecies(query: 'bear'),
        throwsA(isA<TimeoutException>()),
      );
    });

    test('2.2: InatService surfaces HTTP 500/502/503 server errors as ClientException', () async {
      final client = _AdversarialMockClient((request) async {
        return _mockStreamedResponse(
          body: '{"error": "Internal Server Error"}',
          statusCode: 500,
        );
      });
      final service = InatService(client: client);
      addTearDown(service.close);

      expect(
        () => service.searchRegionalSpecies(query: 'leopard'),
        throwsA(isA<http.ClientException>()),
      );
    });

    test('2.3: InatService throws FormatException when response is an HTML error page', () async {
      final client = _AdversarialMockClient((request) async {
        return _mockStreamedResponse(
          body: '<!DOCTYPE html><html><body>502 Bad Gateway</body></html>',
          statusCode: 200,
          headers: {'content-type': 'text/html'},
        );
      });
      final service = InatService(client: client);
      addTearDown(service.close);

      expect(
        () => service.searchRegionalSpecies(query: ''),
        throwsA(isA<FormatException>()),
      );
    });

    test('2.4: InatService throws FormatException when root JSON is a list instead of map', () async {
      final client = _AdversarialMockClient((request) async {
        return _mockStreamedResponse(body: '[{"id": 1}, {"id": 2}]', statusCode: 200);
      });
      final service = InatService(client: client);
      addTearDown(service.close);

      expect(
        () => service.searchRegionalSpecies(query: ''),
        throwsA(isA<FormatException>()),
      );
    });

    test('2.5: InatService falls back gracefully when secondary count query fails', () async {
      final client = _AdversarialMockClient((request) async {
        if (request.url.path.endsWith('/taxa/autocomplete')) {
          return _mockStreamedResponse(
            body: jsonEncode({
              'total_results': 1,
              'results': [
                {
                  'id': 505,
                  'name': 'Capra falconeri',
                  'preferred_common_name': 'Markhor',
                  'rank': 'species',
                  'observations_count': 40,
                },
              ],
            }),
          );
        }
        // Secondary species_counts call fails with 500
        return _mockStreamedResponse(body: 'Server Error', statusCode: 500);
      });

      final service = InatService(client: client);
      addTearDown(service.close);

      // Should fall back to matching taxa from autocomplete without throwing
      final result = await service.searchRegionalSpecies(query: 'Markhor');
      expect(result.taxa, hasLength(1));
      expect(result.taxa.single.displayName, 'Markhor');
      expect(result.hasMore, isFalse);
    });

    test('2.6: InatService name matching enforces whole-word token matching', () async {
      final client = _AdversarialMockClient((request) async {
        return _mockStreamedResponse(
          body: jsonEncode({
            'total_results': 1,
            'results': [
              {
                'id': 606,
                'name': 'Stagmomantis carolina',
                'preferred_common_name': 'Carolina Mantis',
                'rank': 'species',
              },
            ],
          }),
        );
      });

      final service = InatService(client: client);
      addTearDown(service.close);

      // 'stag' should NOT match 'Stagmomantis' because it is not a whole word
      final result = await service.searchRegionalSpecies(query: 'stag');
      expect(result.taxa, isEmpty);
    });

    test('2.7: InatService getTaxonDetails throws FormatException on empty result list', () async {
      final client = _AdversarialMockClient((request) async {
        return _mockStreamedResponse(
          body: jsonEncode({'total_results': 0, 'results': []}),
        );
      });
      final service = InatService(client: client);
      addTearDown(service.close);

      expect(
        () => service.getTaxonDetails(9999),
        throwsA(isA<FormatException>()),
      );
    });

    test('2.8: InatService findTaxonByScientificName supports trinomial fallback to binomial', () async {
      Uri? queriedUri;
      final client = _AdversarialMockClient((request) async {
        queriedUri = request.url;
        final q = request.url.queryParameters['q'];
        if (q == 'Cervus hanglu hanglu') {
          // No exact trinomial match
          return _mockStreamedResponse(body: jsonEncode({'results': []}));
        }
        if (q == 'cervus hanglu') {
          // Binomial fallback match succeeds
          return _mockStreamedResponse(
            body: jsonEncode({
              'results': [
                {
                  'id': 707,
                  'name': 'Cervus hanglu',
                  'preferred_common_name': 'Central Asian Red Deer',
                  'rank': 'species',
                },
              ],
            }),
          );
        }
        return _mockStreamedResponse(body: jsonEncode({'results': []}));
      });

      final service = InatService(client: client);
      addTearDown(service.close);

      final taxon = await service.findTaxonByScientificName(
        'Cervus hanglu hanglu',
        allowBinomialFallback: true,
      );

      expect(taxon, isNotNull);
      expect(taxon!.id, 707);
      expect(taxon.name, 'Cervus hanglu');
      expect(queriedUri, isNotNull);
    });

    test('2.9: InatService downloadPhoto security: rejects untrusted hosts and HTTP URLs', () async {
      final service = InatService();
      addTearDown(service.close);

      // Untrusted host
      const untrustedPhoto = InatTaxonPhoto(
        url: 'https://evil-hacker.com/malicious.jpg',
        attribution: 'Attacker',
        license: 'cc0',
      );
      expect(
        () => service.downloadPhoto(untrustedPhoto),
        throwsA(isA<FormatException>()),
      );

      // Insecure HTTP URL
      const insecurePhoto = InatTaxonPhoto(
        url: 'http://upload.wikimedia.org/photo.jpg',
        attribution: 'Artist',
        license: 'cc0',
      );
      expect(
        () => service.downloadPhoto(insecurePhoto),
        throwsA(isA<FormatException>()),
      );
    });

    test('2.10: InatService downloadPhoto payload constraints: non-2xx, oversized, non-image, 0-byte', () async {
      // Non-2xx
      final client404 = _AdversarialMockClient((req) async {
        return _mockStreamedResponse(body: 'Not found', statusCode: 404);
      });
      final service404 = InatService(client: client404);
      addTearDown(service404.close);

      const testPhoto = InatTaxonPhoto(
        url: 'https://upload.wikimedia.org/test.jpg',
        attribution: 'Author',
        license: 'cc-by',
      );
      expect(
        () => service404.downloadPhoto(testPhoto),
        throwsA(isA<http.ClientException>()),
      );

      // Non-image content type
      final clientHtml = _AdversarialMockClient((req) async {
        return _mockStreamedResponse(
          body: 'Not an image',
          statusCode: 200,
          headers: {'content-type': 'text/plain'},
        );
      });
      final serviceHtml = InatService(client: clientHtml);
      addTearDown(serviceHtml.close);
      expect(
        () => serviceHtml.downloadPhoto(testPhoto),
        throwsA(isA<FormatException>()),
      );

      // 0-byte stream
      final clientEmpty = _AdversarialMockClient((req) async {
        return http.StreamedResponse(
          const Stream<List<int>>.empty(),
          200,
          contentLength: 0,
          headers: {'content-type': 'image/jpeg'},
        );
      });
      final serviceEmpty = InatService(client: clientEmpty);
      addTearDown(serviceEmpty.close);
      expect(
        () => serviceEmpty.downloadPhoto(testPhoto),
        throwsA(isA<FormatException>()),
      );
    });

    test('2.11: InatService downloadReusablePhoto throws StateError for non-reusable licenses', () async {
      final service = InatService();
      addTearDown(service.close);

      const nonReusableTaxon = InatTaxon(
        id: 808,
        name: 'Panthera uncia',
        commonName: 'Snow Leopard',
        rank: 'species',
        regionalObservations: 10,
        totalObservations: 100,
        conservationStatus: 'Vulnerable',
        photoUrl: 'https://upload.wikimedia.org/photo.jpg',
        photoAttribution: 'Copyrighted Artist',
        photoLicense: 'all-rights-reserved', // Disallowed license
        wikipediaUrl: null,
      );

      expect(
        () => service.downloadReusablePhoto(nonReusableTaxon),
        throwsA(isA<StateError>()),
      );
    });

    test('2.12: InatService getTaxonomicClassification returns null on low confidence or NONE match', () async {
      final client = _AdversarialMockClient((req) async {
        return _mockStreamedResponse(
          body: jsonEncode({
            'usageKey': 1234,
            'scientificName': 'Unknown species',
            'matchType': 'NONE',
            'confidence': 30,
          }),
        );
      });
      final service = InatService(client: client);
      addTearDown(service.close);

      final classification = await service.getTaxonomicClassification('Unknown species');
      expect(classification, isNull);
    });

    test('2.13: OfflineSpeciesService download flow stores taxonomy, summary, and photo', () async {
      SharedPreferences.setMockInitialValues({});
      final client = _AdversarialMockClient((req) async {
        if (req.url.path.contains('/taxa/909')) {
          return _mockStreamedResponse(
            body: jsonEncode({
              'results': [
                {
                  'id': 909,
                  'name': 'Canis lupus chanco',
                  'preferred_common_name': 'Himalayan Wolf',
                  'rank': 'subspecies',
                  'observations_count': 45,
                  'default_photo': {
                    'medium_url': 'https://upload.wikimedia.org/himalayan_wolf.jpg',
                    'attribution': 'Photographer C',
                    'license_code': 'cc-by',
                  },
                  'wikipedia_url': 'https://en.wikipedia.org/wiki/Himalayan_wolf',
                },
              ],
            }),
          );
        }
        if (req.url.path.contains('/page/summary/Himalayan_wolf')) {
          return _mockStreamedResponse(
            body: jsonEncode({'extract': 'The Himalayan wolf is a canine of ancient lineage.'}),
          );
        }
        if (req.url.path.contains('/species/match')) {
          return _mockStreamedResponse(
            body: jsonEncode({
              'usageKey': 5219173,
              'scientificName': 'Canis lupus chanco',
              'matchType': 'EXACT',
              'confidence': 95,
              'kingdom': 'Animalia',
              'phylum': 'Chordata',
              'class': 'Mammalia',
              'order': 'Carnivora',
              'family': 'Canidae',
              'genus': 'Canis',
              'species': 'Canis lupus',
            }),
          );
        }
        if (req.url.path.endsWith('.jpg')) {
          return http.StreamedResponse(
            Stream.value(Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0, 0xAA, 0xBB])),
            200,
            contentLength: 6,
            headers: {'content-type': 'image/jpeg'},
          );
        }
        return _mockStreamedResponse(body: jsonEncode({'results': []}));
      });

      final inatService = InatService(client: client);
      final store = OfflineTaxaStore(
        writePhoto: (id, bytes) async => '/storage/offline_$id.jpg',
      );
      final offlineService = OfflineSpeciesService(inatService: inatService, store: store);

      const baseTaxon = InatTaxon(
        id: 909,
        name: 'Canis lupus chanco',
        commonName: 'Himalayan Wolf',
        rank: 'subspecies',
        regionalObservations: 12,
        totalObservations: 45,
        conservationStatus: 'Endangered',
        photoUrl: 'https://upload.wikimedia.org/himalayan_wolf.jpg',
        photoAttribution: 'Photographer C',
        photoLicense: 'cc-by',
        wikipediaUrl: 'https://en.wikipedia.org/wiki/Himalayan_wolf',
      );

      final result = await offlineService.download(baseTaxon);
      expect(result.photoSaved, isTrue);
      expect(result.taxon.wikipediaSummary, contains('ancient lineage'));
      expect(result.taxon.offlineTaxonomy['Family'], 'Canidae');
      expect(result.taxon.offlinePhotoPath, '/storage/offline_909.jpg');
    });
  });

  // ===========================================================================
  // GROUP 3: AUDIO & MEDIA ADVERSARIAL HARDENING
  // ===========================================================================
  group('Tier 5 - Group 3: Audio & Media Adversarial Hardening', () {
    testWidgets('3.1: InteractiveVocalizationWidget renders safely with all null properties', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: InteractiveVocalizationWidget(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(InteractiveVocalizationWidget), findsOneWidget);
      expect(find.text('VOCALIZATION & SOUNDS'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('3.2: InteractiveVocalizationWidget non-vocal species displays communication card and no play button', (tester) async {
      const nonVocalSpecies = ZoologySpecies(
        id: 'kashmir-rock-agama',
        commonName: 'Kashmiri Rock Agama',
        scientificName: 'Laudakia pakistanica',
        category: 'Reptile',
        region: 'Kashmir',
        status: 'Common',
        habitat: 'Rocky terrain',
        size: '25 cm',
        conservation: 'Least Concern',
        feature: 'Flattened body for rock crevices',
        funFact: 'Communicates using head-bobs and throat displays',
        isVocal: false,
        vocalization: '',
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: InteractiveVocalizationWidget(species: nonVocalSpecies),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('COMMUNICATION & ACOUSTICS'), findsOneWidget);
      expect(find.text('Non-vocal species communication mechanisms'), findsOneWidget);
      expect(find.byType(IconButton), findsNothing);
      expect(find.byType(Slider), findsNothing);
    });

    testWidgets('3.3: InteractiveVocalizationWidget non-vocal species displays custom bio-acoustic note', (tester) async {
      const customNoteSpecies = ZoologySpecies(
        id: 'test-gecko',
        commonName: 'Test Gecko',
        scientificName: 'Gecko testus',
        category: 'Reptile',
        region: 'Jammu',
        status: 'Present',
        habitat: 'Walls',
        size: '12 cm',
        conservation: 'Least Concern',
        feature: 'Adhesive toe pads',
        funFact: 'Acoustic testing',
        isVocal: false,
        vocalization: '',
        vocalizationNote: 'Communicates purely via tactile tail-wagging signals.',
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: InteractiveVocalizationWidget(species: customNoteSpecies),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Communicates purely via tactile tail-wagging signals.'), findsOneWidget);
    });

    testWidgets('3.4: InteractiveVocalizationWidget rapid 10-tap toggling stress test maintains consistency', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: InteractiveVocalizationWidget(
              commonName: 'Hangul',
              vocalization: 'Deep autumn bugle call',
              audioAsset: 'assets/audio/hangul.mp3',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final playBtn = find.byType(IconButton);
      expect(playBtn, findsOneWidget);

      final state = tester.state<InteractiveVocalizationWidgetState>(
        find.byType(InteractiveVocalizationWidget),
      );
      expect(state.isPlaying, isFalse);

      // Perform 10 rapid taps (even number -> final state should be false)
      for (int i = 0; i < 10; i++) {
        await tester.tap(playBtn);
        await tester.pump(const Duration(milliseconds: 10));
      }

      expect(state.isPlaying, isFalse);
      expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('3.5: InteractiveVocalizationWidget scrubbing slider when duration is zero is safely disabled', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: InteractiveVocalizationWidget(
              commonName: 'Common Leopard',
              vocalization: 'Sawing cough',
              audioAsset: 'assets/audio/common_leopard.mp3',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final sliderFinder = find.byType(Slider);
      expect(sliderFinder, findsOneWidget);

      final slider = tester.widget<Slider>(sliderFinder);
      expect(slider.onChanged, isNull);

      // Dragging a disabled slider must not throw
      await tester.drag(sliderFinder, const Offset(100, 0));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('3.6: InteractiveVocalizationWidget unmounting during active playback releases safely', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return const InteractiveVocalizationWidget(
                  commonName: 'Himalayan Wolf',
                  vocalization: 'Chorus howl',
                  audioAsset: 'assets/audio/himalayan_wolf.mp3',
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap play to start playback
      await tester.tap(find.byType(IconButton));
      await tester.pump(const Duration(milliseconds: 20));

      // Immediately unmount by swapping with an empty Container
      await tester.pumpWidget(const MaterialApp(home: Scaffold(body: SizedBox())));
      await tester.pumpAndSettle();

      expect(find.byType(InteractiveVocalizationWidget), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('3.7: SpeciesReferencePhoto falls back to art plate on broken or empty network URL', (tester) async {
      const brokenPhotoSpecies = ZoologySpecies(
        id: 'unbundled-broken-photo',
        commonName: 'Broken Image Creature',
        scientificName: 'Fractus imagus',
        category: 'Fish',
        region: 'Kashmir',
        status: 'Rare',
        habitat: 'Deep lake',
        size: '15 cm',
        conservation: 'Data Deficient',
        feature: 'Scales',
        funFact: 'Fallback test',
        imageUrl: '', // Empty URL triggers art plate
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SpeciesReferencePhoto(species: brokenPhotoSpecies, height: 200),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(SpeciesReferencePhoto), findsOneWidget);
      expect(find.text('Broken Image Creature'), findsAtLeast(1));
      expect(find.text('FISH'), findsAtLeast(1));
    });

    testWidgets('3.8: SpeciesReferencePhoto attribution formats exact vs broader match distinction', (tester) async {
      // Subspecies with broader species-level photo
      const subspeciesItem = ZoologySpecies(
        id: 'subspecies-sample',
        commonName: 'Kashmir Cave Bat',
        scientificName: 'Myotis longipes longipes',
        category: 'Mammal',
        region: 'Kashmir',
        status: 'Uncommon',
        habitat: 'Caves',
        size: '5 cm',
        conservation: 'Least Concern',
        feature: 'Cave dwelling',
        funFact: 'Echolocation test',
        imageUrl: 'https://example.org/photo.jpg',
        imageAttribution: 'Speleologist A',
        imageLicense: 'CC BY',
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SpeciesReferencePhoto(species: subspeciesItem, height: 220),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Renders attribution text
      expect(find.textContaining('Speleologist A'), findsOneWidget);
      expect(find.textContaining('CC BY'), findsOneWidget);
    });

    testWidgets('3.9: SpeciesReferencePhoto tap-to-zoom opens dialog and closes without leaks', (tester) async {
      final hangul = kSpeciesCatalog.firstWhere((s) => s.id == 'hangul');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SpeciesReferencePhoto(species: hangul, height: 240),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap on the reference photo
      await tester.tap(find.byType(SpeciesReferencePhoto));
      await tester.pumpAndSettle();

      // Fullscreen dialog opens
      expect(find.byType(InteractiveViewer), findsOneWidget);
      expect(find.byTooltip('Close photo'), findsOneWidget);

      // Close dialog
      await tester.tap(find.byTooltip('Close photo'));
      await tester.pumpAndSettle();

      expect(find.byType(InteractiveViewer), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('3.10: SpeciesReferencePhoto rapid double taps on image do not push duplicate dialogs', (tester) async {
      final markhor = kSpeciesCatalog.firstWhere((s) => s.id == 'markhor');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SpeciesReferencePhoto(species: markhor, height: 240),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap twice in rapid succession
      await tester.tap(find.byType(SpeciesReferencePhoto));
      await tester.pump(const Duration(milliseconds: 10));
      await tester.tap(find.byType(SpeciesReferencePhoto), warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(find.byType(InteractiveViewer), findsOneWidget);

      // Close modal
      await tester.tap(find.byTooltip('Close photo'));
      await tester.pumpAndSettle();

      expect(find.byType(InteractiveViewer), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });

  // ===========================================================================
  // GROUP 4: QUIZ & NAVIGATION ADVERSARIAL HARDENING
  // ===========================================================================
  group('Tier 5 - Group 4: Quiz & Navigation Adversarial Hardening', () {
    test('4.1: FaunaQuizController initialized with empty questions list starts in completed state', () {
      final controller = FaunaQuizController(questions: []);
      expect(controller.isCompleted, isTrue);
      expect(controller.totalQuestions, 0);
      expect(controller.currentQuestion, isNull);
      expect(controller.score, 0);

      // Operations on empty quiz do not crash
      controller.selectAnswer(0);
      expect(controller.score, 0);
      expect(controller.answered, isFalse);

      controller.nextQuestion();
      expect(controller.isCompleted, isTrue);

      controller.restartQuiz(shuffle: true);
      expect(controller.isCompleted, isTrue);
    });

    test('4.2: FaunaQuizController handles extreme answer index selection (-1, 999)', () {
      final List<FaunaQuizQuestion> testQuestions = [
        const FaunaQuizQuestion(
          id: 'q-test-1',
          prompt: 'What is the state animal of J&K?',
          options: ['Hangul', 'Snow Leopard', 'Markhor', 'Monal'],
          correctIndex: 0,
          explanation: 'Hangul is the state animal.',
          speciesId: 'hangul',
          category: 'Mammal',
          region: 'Kashmir',
        ),
      ];
      final controller = FaunaQuizController(questions: testQuestions);

      // Select negative index
      controller.selectAnswer(-1);
      expect(controller.answered, isTrue);
      expect(controller.selectedAnswer, -1);
      expect(controller.score, 0, reason: 'Negative index must not be scored as correct');

      // Subsequent selections ignored once answered
      controller.selectAnswer(0);
      expect(controller.selectedAnswer, -1);
      expect(controller.score, 0);
    });

    test('4.3: FaunaQuizController nextQuestion before answering is blocked; completes on last question', () {
      final List<FaunaQuizQuestion> testQuestions = [
        const FaunaQuizQuestion(
          id: 'q-test-1',
          prompt: 'Q1',
          options: ['A', 'B'],
          correctIndex: 0,
          explanation: 'Exp1',
          speciesId: 'species-1',
          category: 'Bird',
          region: 'Kashmir',
        ),
        const FaunaQuizQuestion(
          id: 'q-test-2',
          prompt: 'Q2',
          options: ['C', 'D'],
          correctIndex: 1,
          explanation: 'Exp2',
          speciesId: 'species-2',
          category: 'Mammal',
          region: 'Jammu',
        ),
      ];
      final controller = FaunaQuizController(questions: testQuestions);

      // Next question before answering Q1 is blocked
      controller.nextQuestion();
      expect(controller.currentIndex, 0);
      expect(controller.isCompleted, isFalse);

      // Answer Q1 correctly
      controller.selectAnswer(0);
      expect(controller.score, 1);

      // Advance to Q2
      controller.nextQuestion();
      expect(controller.currentIndex, 1);
      expect(controller.answered, isFalse);
      expect(controller.selectedAnswer, isNull);

      // Answer Q2
      controller.selectAnswer(1);
      expect(controller.score, 2);

      // Advance past final question
      controller.nextQuestion();
      expect(controller.isCompleted, isTrue);

      // Calling nextQuestion after completion is a no-op
      controller.nextQuestion();
      expect(controller.isCompleted, isTrue);
    });

    test('4.4: FaunaQuizController restart and shuffle behavior', () {
      final controller = FaunaQuizController(questions: kFaunaQuizQuestions);

      // Answer first question
      controller.selectAnswer(kFaunaQuizQuestions.first.correctIndex);
      controller.nextQuestion();
      expect(controller.currentIndex, 1);
      expect(controller.score, 1);

      // Restart without shuffle
      controller.restartQuiz(shuffle: false);
      expect(controller.currentIndex, 0);
      expect(controller.score, 0);
      expect(controller.answered, isFalse);
      expect(controller.currentQuestion?.id, kFaunaQuizQuestions.first.id);

      // Restart with shuffle
      controller.restartQuiz(shuffle: true);
      expect(controller.currentIndex, 0);
      expect(controller.score, 0);
      expect(controller.totalQuestions, kFaunaQuizQuestions.length);
    });

    testWidgets('4.5: InteractiveFaunaChallengeCard renders empty bank view without divide-by-zero', (tester) async {
      final controller = FaunaQuizController(questions: []);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InteractiveFaunaChallengeCard(controller: controller),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Fauna Challenge Complete!'), findsOneWidget);
      expect(find.text('Final Score: 0 / 0 (0%)'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('4.6: InteractiveFaunaChallengeCard score summary tier badges across all score thresholds', (tester) async {
      final List<FaunaQuizQuestion> testQ = const [
        FaunaQuizQuestion(
          id: 'q1',
          prompt: 'P1',
          options: ['A', 'B'],
          correctIndex: 0,
          explanation: 'E1',
          speciesId: 'species-1',
          category: 'Mammal',
          region: 'Ladakh',
        ),
      ];

      // 1. Master Naturalist (100%)
      final c1 = FaunaQuizController(questions: testQ);
      c1.selectAnswer(0);
      c1.nextQuestion();

      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: InteractiveFaunaChallengeCard(controller: c1))),
      );
      await tester.pumpAndSettle();
      expect(find.text('🏆 Himalayan Master Naturalist'), findsOneWidget);

      // 2. Junior Field Scout (0%)
      final c2 = FaunaQuizController(questions: testQ);
      c2.selectAnswer(1); // Incorrect
      c2.nextQuestion();

      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: InteractiveFaunaChallengeCard(controller: c2))),
      );
      await tester.pumpAndSettle();
      expect(find.text('🔍 Junior Field Scout'), findsOneWidget);
    });

    testWidgets('4.7: InteractiveFaunaChallengeCard option selection updates visual styling and shows explanation', (tester) async {
      final controller = FaunaQuizController(
        questions: const [
          FaunaQuizQuestion(
            id: 'q-vis-test',
            prompt: 'Which high-altitude ungulate has spiral horns?',
            options: ['Markhor', 'Hangul'],
            correctIndex: 0,
            explanation: 'The Markhor possesses distinctive flaring corkscrew horns.',
            speciesId: 'markhor',
            category: 'Mammal',
            region: 'Pir Panjal',
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: InteractiveFaunaChallengeCard(controller: controller),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Before answer: neutral state
      expect(find.byIcon(Icons.radio_button_unchecked), findsNWidgets(2));
      expect(find.text('Next Question'), findsNothing);

      // Tap correct option
      await tester.tap(find.text('Markhor'));
      await tester.pumpAndSettle();

      // After answer: green check icon, explanation card, and next question button visible
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
      expect(find.textContaining('distinctive flaring corkscrew horns'), findsOneWidget);
      expect(find.text('Next Question'), findsOneWidget);
    });

    testWidgets('4.8: SpeciesHomePage search with special punctuation characters only does not crash', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const KashmirZoologyApp());
      await tester.pumpAndSettle();

      // Switch to Guide tab
      await tester.tap(find.byKey(const Key('guideTab')));
      await tester.pumpAndSettle();

      final searchField = find.byKey(const Key('speciesSearchField'));
      expect(searchField, findsOneWidget);

      // Enter pure punctuation symbols
      await tester.enterText(searchField, '!@#\$%^&*()_+=-[]{}|;:,.<>?');
      await tester.pumpAndSettle();

      // Must not throw Regex or parse exceptions
      expect(tester.takeException(), isNull);
    });

    testWidgets('4.9: SpeciesHomePage search with 1000+ character query completes safely', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const KashmirZoologyApp());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('guideTab')));
      await tester.pumpAndSettle();

      final searchField = find.byKey(const Key('speciesSearchField'));
      await tester.enterText(searchField, 'Himalayan ' * 120); // ~1200 characters
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('4.10: SpeciesHomePage search query normalization: hyphens vs spaces and casing', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const KashmirZoologyApp());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('guideTab')));
      await tester.pumpAndSettle();

      final searchField = find.byKey(const Key('speciesSearchField'));

      // Hyphenated query
      await tester.enterText(searchField, 'snow-leopard');
      await tester.pumpAndSettle();
      expect(find.text('Snow Leopard'), findsAtLeast(1));

      // Spaced query
      await tester.enterText(searchField, 'SNOW LEOPARD');
      await tester.pumpAndSettle();
      expect(find.text('Snow Leopard'), findsAtLeast(1));
    });

    testWidgets('4.11: SpeciesHomePage regional and category filters strictly exclude all flora records', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const KashmirZoologyApp());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('guideTab')));
      await tester.pumpAndSettle();

      // Search for common plants to verify zero matches
      final searchField = find.byKey(const Key('speciesSearchField'));
      final plantKeywords = ['Pine', 'Cedar', 'Deodar', 'Lotus', 'Oak', 'Chinar', 'Flora'];

      for (final plant in plantKeywords) {
        await tester.enterText(searchField, plant);
        await tester.pumpAndSettle();

        // Verify zero plant cards rendered
        expect(
          find.text('PLANT'),
          findsNothing,
          reason: 'Plant entry found for query $plant in catalog',
        );
      }
    });

    testWidgets('4.12: SpeciesHomePage field observation rejects whitespace-only notes with snackbar', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const KashmirZoologyApp());
      await tester.pumpAndSettle();

      // Switch to Journal tab
      await tester.tap(find.byKey(const Key('journalTab')));
      await tester.pumpAndSettle();

      // Expand field notebook form
      await tester.tap(find.byKey(const Key('fieldNotebookToggle')));
      await tester.pumpAndSettle();

      final notesField = find.byKey(const Key('observationNotesField'));
      await tester.ensureVisible(notesField);
      await tester.enterText(notesField, '    \n\t   '); // whitespace only

      final saveButton = find.byKey(const Key('saveObservationButton'));
      await tester.ensureVisible(saveButton);
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      // Warning snackbar must be triggered
      expect(
        find.text('Add a note about what you observed before saving.'),
        findsOneWidget,
      );
    });

    testWidgets('4.13: SpeciesHomePage field observation saves with default unidentified species name', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const KashmirZoologyApp());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('journalTab')));
      await tester.pumpAndSettle();

      // Expand field notebook form
      await tester.tap(find.byKey(const Key('fieldNotebookToggle')));
      await tester.pumpAndSettle();

      // Leave species name blank, provide notes
      final notesField = find.byKey(const Key('observationNotesField'));
      await tester.ensureVisible(notesField);
      await tester.enterText(notesField, 'Saw mysterious tracks near Pir Panjal ridge.');

      final saveButton = find.byKey(const Key('saveObservationButton'));
      await tester.ensureVisible(saveButton);
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      expect(find.text('Field note saved on this device.'), findsOneWidget);
      expect(find.text('Unidentified observation'), findsAtLeast(1));
    });

    testWidgets('4.14: SpeciesHomePage rapid tab cycling preserves widget tree integrity', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const KashmirZoologyApp());
      await tester.pumpAndSettle();

      final discoverTab = find.byKey(const Key('discoverTab'));
      final journalTab = find.byKey(const Key('journalTab'));
      final guideTab = find.byKey(const Key('guideTab'));

      // Cycle tabs rapidly without settling between taps
      for (int i = 0; i < 4; i++) {
        await tester.tap(journalTab);
        await tester.pump(const Duration(milliseconds: 15));
        await tester.tap(guideTab);
        await tester.pump(const Duration(milliseconds: 15));
        await tester.tap(discoverTab);
        await tester.pump(const Duration(milliseconds: 15));
      }
      await tester.pumpAndSettle();

      expect(find.byType(InteractiveFaunaChallengeCard), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
