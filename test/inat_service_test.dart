import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zoology_app/data/offline_taxa_store.dart';
import 'package:zoology_app/models/inat_taxon.dart';
import 'package:zoology_app/services/inat_service.dart';

void main() {
  test(
    'regional species search returns observation counts and photo credit',
    () async {
      late Uri autocompleteUri;
      late Uri countsUri;
      final client = _FakeClient((request) async {
        if (request.url.path.endsWith('/taxa/autocomplete')) {
          autocompleteUri = request.url;
          return _jsonResponse({
            'total_results': 1,
            'results': [
              {
                'id': 67835,
                'name': 'Danaus chrysippus',
                'preferred_common_name': 'Plain Tiger Butterfly',
                'rank': 'species',
                'observations_count': 100,
                'default_photo': {
                  'medium_url': 'https://example.org/photo.jpg',
                  'attribution': '(c) Photographer, CC BY',
                  'license_code': 'cc-by',
                },
                'conservation_status': {'status_name': 'Least Concern'},
                'wikipedia_url': 'http://en.wikipedia.org/wiki/Plain_tiger',
              },
            ],
          });
        }
        countsUri = request.url;
        return _jsonResponse({
          'total_results': 1,
          'results': [
            {
              'count': 42,
              'taxon': {
                'id': 67835,
                'name': 'Danaus chrysippus',
                'preferred_common_name': 'Plain Tiger Butterfly',
                'rank': 'species',
                'observations_count': 100,
                'default_photo': {
                  'medium_url': 'https://example.org/photo.jpg',
                  'attribution': '(c) Photographer, CC BY',
                  'license_code': 'cc-by',
                },
                'conservation_status': {'status_name': 'Least Concern'},
                'wikipedia_url': 'http://en.wikipedia.org/wiki/Plain_tiger',
              },
            },
          ],
        });
      });
      final service = InatService(client: client);
      addTearDown(service.close);

      final result = await service.searchRegionalSpecies(
        query: 'butterfly',
        plants: false,
      );

      expect(autocompleteUri.path, '/v1/taxa/autocomplete');
      expect(autocompleteUri.queryParameters['q'], 'butterfly');
      expect(autocompleteUri.queryParameters['taxon_id'], '1');
      expect(
        countsUri.queryParameters['place_id'],
        InatService.jammuKashmirPlaceId,
      );
      expect(countsUri.queryParameters['taxon_id'], '67835');
      expect(countsUri.queryParameters.containsKey('q'), isFalse);
      expect(countsUri.queryParameters['rank'], 'species');
      expect(result.totalResults, 1);
      expect(result.taxa.single.displayName, 'Plain Tiger Butterfly');
      expect(result.taxa.single.regionalObservations, 42);
      expect(result.taxa.single.photoAttribution, '(c) Photographer, CC BY');
      expect(
        result.taxa.single.wikipediaUrl,
        'https://en.wikipedia.org/wiki/Plain_tiger',
      );
    },
  );

  test(
    'name search excludes taxa that do not match the requested name',
    () async {
      late Uri countsUri;
      final service = InatService(
        client: _FakeClient((request) async {
          if (request.url.path.endsWith('/taxa/autocomplete')) {
            return _jsonResponse({
              'total_results': 53,
              'results': [
                {
                  'id': 41964,
                  'name': 'Panthera leo',
                  'preferred_common_name': 'Lion',
                  'rank': 'species',
                },
                {
                  'id': 43446,
                  'name': 'Macaca silenus',
                  'preferred_common_name': 'Lion-tailed Macaque',
                  'rank': 'species',
                },
                {
                  'id': 41963,
                  'name': 'Panthera pardus',
                  'preferred_common_name': 'Leopard',
                  'rank': 'species',
                },
              ],
            });
          }
          countsUri = request.url;
          return _jsonResponse({
            'total_results': 2,
            'results': [
              {
                'count': 11,
                'taxon': {
                  'id': 41964,
                  'name': 'Panthera leo',
                  'preferred_common_name': 'Lion',
                  'rank': 'species',
                },
              },
              {
                'count': 8,
                'taxon': {
                  'id': 41963,
                  'name': 'Panthera pardus',
                  'preferred_common_name': 'Leopard',
                  'rank': 'species',
                },
              },
            ],
          });
        }),
      );
      addTearDown(service.close);

      final result = await service.searchRegionalSpecies(
        query: 'lion',
        plants: false,
        placeIds: InatService.regionalPlaceIds,
      );

      expect(countsUri.queryParameters['taxon_id'], '41964,43446');
      expect(result.taxa, hasLength(1));
      expect(result.taxa.single.displayName, 'Lion');
      expect(result.taxa.single.regionalObservations, 11);
      expect(
        result.taxa.any((taxon) => taxon.displayName == 'Leopard'),
        isFalse,
      );
      expect(result.hasMore, isTrue);
    },
  );

  test('name matching uses whole words, not fuzzy substrings', () async {
    var requestedObservationCounts = false;
    final service = InatService(
      client: _FakeClient((request) async {
        if (request.url.path.endsWith('/taxa/autocomplete')) {
          return _jsonResponse({
            'total_results': 1,
            'results': [
              {
                'id': 12345,
                'name': 'Stagmomantis carolina',
                'preferred_common_name': 'Carolina Mantis',
                'rank': 'species',
              },
            ],
          });
        }
        requestedObservationCounts = true;
        return _jsonResponse({'total_results': 0, 'results': []});
      }),
    );
    addTearDown(service.close);

    final result = await service.searchRegionalSpecies(
      query: 'stag',
      plants: false,
    );

    expect(result.taxa, isEmpty);
    expect(requestedObservationCounts, isFalse);
  });

  test(
    'plant searches use the Plantae taxon and details include photo licenses',
    () async {
      final client = _FakeClient((request) async {
        if (request.url.path.endsWith('/observations/species_counts')) {
          expect(request.url.queryParameters['taxon_id'], '47126');
          return _jsonResponse({'total_results': 0, 'results': []});
        }
        return _jsonResponse({
          'results': [
            {
              'id': 123,
              'name': 'Azadirachta indica',
              'rank': 'species',
              'observations_count': 23,
              'taxon_photos': [
                {
                  'photo': {
                    'medium_url': 'https://example.org/neem.jpg',
                    'attribution': '(c) Photographer',
                    'license_code': 'cc-by-sa',
                  },
                },
              ],
            },
          ],
        });
      });
      final service = InatService(client: client);
      addTearDown(service.close);

      final page = await service.searchRegionalSpecies(query: '', plants: true);
      final detail = await service.getTaxonDetails(123);

      expect(page.taxa, isEmpty);
      expect(detail.photos.single.url, 'https://example.org/neem.jpg');
      expect(detail.photos.single.license, 'cc-by-sa');
    },
  );

  test('regional searches can be narrowed to Jammu and Kashmir', () async {
    late Uri requestUri;
    final service = InatService(
      client: _FakeClient((request) async {
        requestUri = request.url;
        return _jsonResponse({'total_results': 0, 'results': []});
      }),
    );
    addTearDown(service.close);

    await service.searchRegionalSpecies(
      query: '',
      plants: false,
      placeIds: InatService.jammuKashmirPlaceId,
    );

    expect(
      requestUri.queryParameters['place_id'],
      InatService.jammuKashmirPlaceId,
    );
  });

  test(
    'encyclopedia request uses its browser-friendly summary endpoint',
    () async {
      late Uri requestUri;
      final service = InatService(
        client: _FakeClient((request) async {
          requestUri = request.url;
          expect(request.url.path, '/api/rest_v1/page/summary/Snow_leopard');
          return _jsonResponse({
            'extract': 'Identification, range, diet and behavior.',
          });
        }),
      );
      addTearDown(service.close);

      final article = await service.getWikipediaSummary(
        'https://en.wikipedia.org/wiki/Snow_leopard',
      );

      expect(requestUri.host, 'en.wikipedia.org');
      expect(requestUri.path, '/api/rest_v1/page/summary/Snow_leopard');
      expect(article, contains('range, diet and behavior'));
    },
  );

  test('GBIF taxonomy matching returns major classification ranks', () async {
    late Uri requestUri;
    final service = InatService(
      client: _FakeClient((request) async {
        requestUri = request.url;
        return _jsonResponse({
          'usageKey': 2489005,
          'scientificName': 'Acridotheres tristis (Linnaeus, 1766)',
          'canonicalName': 'Acridotheres tristis',
          'rank': 'SPECIES',
          'status': 'ACCEPTED',
          'confidence': 99,
          'kingdom': 'Animalia',
          'phylum': 'Chordata',
          'class': 'Aves',
          'order': 'Passeriformes',
          'family': 'Sturnidae',
          'genus': 'Acridotheres',
          'species': 'Acridotheres tristis',
        });
      }),
    );
    addTearDown(service.close);

    final classification = await service.getTaxonomicClassification(
      'Acridotheres tristis',
    );

    expect(requestUri.host, 'api.gbif.org');
    expect(requestUri.path, '/v1/species/match');
    expect(requestUri.queryParameters['name'], 'Acridotheres tristis');
    expect(classification?.ranks.map((rank) => rank.key), [
      'Kingdom',
      'Phylum',
      'Class',
      'Order',
      'Family',
      'Genus',
      'Species',
    ]);
    expect(classification?.ranks.last.value, 'Acridotheres tristis');
    expect(classification?.sourceUrl, 'https://www.gbif.org/species/2489005');
  });

  test('GBIF does not create a classification for an unmatched name', () async {
    final service = InatService(
      client: _FakeClient(
        (request) async =>
            _jsonResponse({'confidence': 0, 'matchType': 'NONE'}),
      ),
    );
    addTearDown(service.close);

    expect(
      await service.getTaxonomicClassification('not a real species name'),
      isNull,
    );
  });

  test('GBIF low-confidence name matches are not shown as a lineage', () async {
    final service = InatService(
      client: _FakeClient(
        (request) async => _jsonResponse({
          'usageKey': 123,
          'scientificName': 'An unrelated name',
          'matchType': 'FUZZY',
          'confidence': 42,
        }),
      ),
    );
    addTearDown(service.close);

    expect(await service.getTaxonomicClassification('A species'), isNull);
  });

  test('service surfaces HTTP failures', () async {
    final service = InatService(
      client: _FakeClient(
        (request) async =>
            http.StreamedResponse(const Stream<List<int>>.empty(), 503),
      ),
    );
    addTearDown(service.close);

    expect(
      () => service.searchRegionalSpecies(query: 'neem', plants: true),
      throwsA(isA<http.ClientException>()),
    );
  });

  test(
    'species facts can be saved and removed from the offline library',
    () async {
      SharedPreferences.setMockInitialValues({});
      final store = OfflineTaxaStore();
      const taxon = InatTaxon(
        id: 42,
        name: 'Azadirachta indica',
        commonName: 'Neem',
        rank: 'species',
        regionalObservations: 19,
        totalObservations: 500,
        conservationStatus: null,
        photoUrl: 'https://example.org/neem.jpg',
        photoAttribution: '(c) Example photographer',
        photoLicense: 'cc-by',
        wikipediaUrl: 'https://en.wikipedia.org/wiki/Neem',
      );

      await store.save(taxon);
      final loaded = await store.load();

      expect(loaded, hasLength(1));
      expect(loaded.single.id, 42);
      expect(loaded.single.regionalObservations, 19);
      expect(loaded.single.photoAttribution, '(c) Example photographer');

      await store.remove(42);
      expect(await store.load(), isEmpty);
    },
  );
}

http.StreamedResponse _jsonResponse(Map<String, Object?> json) {
  return http.StreamedResponse(
    Stream.value(utf8.encode(jsonEncode(json))),
    200,
    headers: const {'content-type': 'application/json'},
  );
}

class _FakeClient extends http.BaseClient {
  final Future<http.StreamedResponse> Function(http.BaseRequest request)
  handler;

  _FakeClient(this.handler);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) =>
      handler(request);
}
