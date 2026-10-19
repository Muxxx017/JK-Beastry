import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zoology_app/data/offline_taxa_store.dart';
import 'package:zoology_app/models/inat_taxon.dart';
import 'package:zoology_app/services/inat_service.dart';
import 'package:zoology_app/services/offline_species_service.dart';

void main() {
  test(
    'offline download saves taxon facts, source summary, taxonomy and photo',
    () async {
      SharedPreferences.setMockInitialValues({});
      final directory = await Directory.systemTemp.createTemp(
        'jk-bestiary-offline-',
      );
      addTearDown(() => directory.delete(recursive: true));
      final store = OfflineTaxaStore(
        writePhoto: (id, bytes) async {
          final photo = File('${directory.path}\\$id.img');
          await photo.writeAsBytes(bytes, flush: true);
          return photo.path;
        },
        deletePhoto: (path) async {
          if (path != null) {
            final photo = File(path);
            if (await photo.exists()) await photo.delete();
          }
        },
      );
      final service = InatService(
        client: _FakeClient((request) async {
          if (request.url.path == '/v1/taxa/42') {
            return _jsonResponse({
              'results': [
                {
                  'id': 42,
                  'name': 'Panthera uncia',
                  'preferred_common_name': 'Snow Leopard',
                  'rank': 'species',
                  'observations_count': 1234,
                  'conservation_status': {'status_name': 'Vulnerable'},
                  'wikipedia_url': 'http://en.wikipedia.org/wiki/Snow_leopard',
                  'default_photo': {
                    'medium_url':
                        'https://static.inaturalist.org/photos/42/medium.jpg',
                    'attribution': '(c) Field Photographer',
                    'license_code': 'cc-by',
                  },
                },
              ],
            });
          }
          if (request.url.host == 'en.wikipedia.org') {
            return _jsonResponse({
              'extract': 'An elusive high-altitude cat of the mountains.',
            });
          }
          if (request.url.host == 'api.gbif.org') {
            return _jsonResponse({
              'usageKey': 2435099,
              'scientificName': 'Panthera uncia',
              'status': 'ACCEPTED',
              'rank': 'SPECIES',
              'confidence': 99,
              'kingdom': 'Animalia',
              'phylum': 'Chordata',
              'class': 'Mammalia',
              'order': 'Carnivora',
              'family': 'Felidae',
              'genus': 'Panthera',
              'species': 'Panthera uncia',
            });
          }
          if (request.url.host == 'static.inaturalist.org') {
            return http.StreamedResponse(
              Stream.value([255, 216, 255, 217]),
              200,
              headers: const {'content-type': 'image/jpeg'},
            );
          }
          throw StateError('Unexpected request: ${request.url}');
        }),
      );
      addTearDown(service.close);
      final offline = OfflineSpeciesService(inatService: service, store: store);
      const selectedTaxon = InatTaxon(
        id: 42,
        name: 'Panthera uncia',
        commonName: 'Snow Leopard',
        rank: 'species',
        regionalObservations: 10,
        totalObservations: 1234,
        conservationStatus: 'Vulnerable',
        photoUrl: null,
        photoAttribution: null,
        photoLicense: null,
        wikipediaUrl: 'https://en.wikipedia.org/wiki/Snow_leopard',
      );

      final result = await offline.download(selectedTaxon);

      expect(result.photoSaved, isTrue);
      expect(result.taxon.offlineTaxonomy['Family'], 'Felidae');
      expect(
        result.taxon.wikipediaSummary,
        'An elusive high-altitude cat of the mountains.',
      );
      expect(result.taxon.offlinePhotoAttribution, '(c) Field Photographer');
      expect(result.taxon.offlinePhotoLicense, 'cc-by');
      expect(
        result.taxon.offlinePhotoSourceUrl,
        'https://www.inaturalist.org/taxa/42',
      );
      expect(result.taxon.offlinePhotoPath, isNotNull);
      expect(await File(result.taxon.offlinePhotoPath!).readAsBytes(), [
        255,
        216,
        255,
        217,
      ]);

      await offline.remove(42);
      expect(await offline.loadSaved(), isEmpty);
      expect(await File(result.taxon.offlinePhotoPath!).exists(), isFalse);
    },
  );

  test(
    'offline photo eligibility excludes restrictive and unknown licenses',
    () {
      InatTaxon taxonWithLicense(String? license) => InatTaxon(
        id: 1,
        name: 'Panthera uncia',
        commonName: 'Snow Leopard',
        rank: 'species',
        regionalObservations: null,
        totalObservations: 0,
        conservationStatus: null,
        photoUrl: 'https://static.inaturalist.org/photos/42/medium.jpg',
        photoAttribution: 'Photographer',
        photoLicense: license,
        wikipediaUrl: null,
      );

      expect(taxonWithLicense('cc0').hasReusableOfflinePhoto, isTrue);
      expect(taxonWithLicense('public-domain').hasReusableOfflinePhoto, isTrue);
      expect(taxonWithLicense('cc-by').hasReusableOfflinePhoto, isTrue);
      expect(taxonWithLicense('cc-by-2.0').hasReusableOfflinePhoto, isTrue);
      expect(taxonWithLicense('CC BY 2.0').hasReusableOfflinePhoto, isTrue);
      expect(taxonWithLicense('cc-by-sa').hasReusableOfflinePhoto, isFalse);
      expect(taxonWithLicense('cc-by-nc').hasReusableOfflinePhoto, isFalse);
      expect(taxonWithLicense('cc-by-nd').hasReusableOfflinePhoto, isFalse);
      expect(taxonWithLicense(null).hasReusableOfflinePhoto, isFalse);
    },
  );

  test('Commons photo lookup requires an exact taxonomy match and reusable license', () async {
    final service = InatService(
      client: _FakeClient((request) async {
        expect(request.url.host, 'commons.wikimedia.org');
        return _jsonResponse({
          'query': {
            'pages': {
              '1': {
                'index': 1,
                'imageinfo': [
                  {
                    'thumburl':
                        'https://upload.wikimedia.org/thumb/unrelated.jpg',
                    'descriptionurl':
                        'https://commons.wikimedia.org/wiki/File:Unrelated.jpg',
                    'extmetadata': {
                      'Categories': {'value': 'Other species'},
                      'LicenseShortName': {'value': 'CC BY 4.0'},
                      'License': {'value': 'cc-by-4.0'},
                    },
                  },
                ],
              },
              '2': {
                'index': 2,
                'imageinfo': [
                  {
                    'thumburl':
                        'https://upload.wikimedia.org/thumb/restrictive.jpg',
                    'descriptionurl': 'https://commons.wikimedia.org/wiki/File:Restrictive.jpg',
                    'extmetadata': {
                      'Categories': {'value': 'Platanus orientalis'},
                      'LicenseShortName': {'value': 'CC BY-SA 4.0'},
                      'License': {'value': 'cc-by-sa-4.0'},
                    },
                  },
                ],
              },
              '3': {
                'index': 3,
                'imageinfo': [
                  {
                    'thumburl': 'https://upload.wikimedia.org/thumb/plane.jpg',
                    'descriptionurl':
                        'https://commons.wikimedia.org/wiki/File:Plane.jpg',
                    'extmetadata': {
                      'Categories': {'value': 'Platanus orientalis'},
                      'LicenseShortName': {'value': 'CC BY 2.0'},
                      'License': {'value': 'cc-by-2.0'},
                      'Artist': {
                        'value': '<a href="/wiki/User:Artist">A &amp; B</a>',
                      },
                    },
                  },
                ],
              },
            },
          },
        });
      }),
    );
    addTearDown(service.close);

    final photo = await service.findCommonsPhoto('Platanus orientalis');

    expect(photo?.url, 'https://upload.wikimedia.org/thumb/plane.jpg');
    expect(photo?.attribution, 'A & B');
    expect(photo?.license, 'CC BY 2.0');
    expect(
      photo?.sourceUrl,
      'https://commons.wikimedia.org/wiki/File:Plane.jpg',
    );
  });

  test('offline download falls back to a credited Commons image', () async {
    SharedPreferences.setMockInitialValues({});
    final directory = await Directory.systemTemp.createTemp(
      'jk-bestiary-commons-',
    );
    addTearDown(() => directory.delete(recursive: true));
    final store = OfflineTaxaStore(
      writePhoto: (id, bytes) async {
        final photo = File('${directory.path}\\$id.img');
        await photo.writeAsBytes(bytes, flush: true);
        return photo.path;
      },
    );
    final service = InatService(
      client: _FakeClient((request) async {
        if (request.url.path == '/v1/taxa/42') {
          return _jsonResponse({
            'results': [
              {
                'id': 42,
                'name': 'Platanus orientalis',
                'preferred_common_name': 'Oriental plane',
                'rank': 'species',
                'observations_count': 20,
                'default_photo': {
                  'medium_url':
                      'https://static.inaturalist.org/photos/42/medium.jpg',
                  'attribution': 'Photographer',
                  'license_code': 'cc-by-nc',
                },
              },
            ],
          });
        }
        if (request.url.host == 'api.gbif.org') {
          return _jsonResponse({'matchType': 'NONE'});
        }
        if (request.url.host == 'commons.wikimedia.org') {
          return _jsonResponse({
            'query': {
              'pages': {
                '1': {
                  'index': 1,
                  'imageinfo': [
                    {
                      'thumburl': 'https://thumb.wikimedia.org/thumb/plane.jpg',
                      'descriptionurl':
                          'https://commons.wikimedia.org/wiki/File:Plane.jpg',
                      'extmetadata': {
                        'Categories': {'value': 'Platanus orientalis'},
                        'LicenseShortName': {'value': 'CC0'},
                        'License': {'value': 'cc0-1.0'},
                        'Artist': {'value': 'Botanical Photographer'},
                      },
                    },
                  ],
                },
              },
            },
          });
        }
        if (request.url.host == 'thumb.wikimedia.org') {
          return http.StreamedResponse(
            Stream.value([255, 216, 255, 217]),
            200,
            headers: const {'content-type': 'image/jpeg'},
          );
        }
        throw StateError('Unexpected request: ${request.url}');
      }),
    );
    addTearDown(service.close);
    final offline = OfflineSpeciesService(inatService: service, store: store);
    const taxon = InatTaxon(
      id: 42,
      name: 'Platanus orientalis',
      commonName: 'Oriental plane',
      rank: 'species',
      regionalObservations: 10,
      totalObservations: 20,
      conservationStatus: null,
      photoUrl: null,
      photoAttribution: null,
      photoLicense: null,
      wikipediaUrl: null,
    );

    final result = await offline.download(taxon);

    expect(result.photoSaved, isTrue);
    expect(result.taxon.offlinePhotoAttribution, 'Botanical Photographer');
    expect(result.taxon.offlinePhotoLicense, 'CC0');
    expect(
      result.taxon.offlinePhotoSourceUrl,
      'https://commons.wikimedia.org/wiki/File:Plane.jpg',
    );
    expect(await File(result.taxon.offlinePhotoPath!).readAsBytes(), [
      255,
      216,
      255,
      217,
    ]);
  });

  test(
    'photo download enforces trusted hosts and a streamed byte limit',
    () async {
      var sentRequests = 0;
      final service = InatService(
        client: _FakeClient((request) async {
          sentRequests++;
          return http.StreamedResponse(
            Stream.value(List<int>.filled(12 * 1024 * 1024 + 1, 1)),
            200,
            headers: const {'content-type': 'image/jpeg'},
          );
        }),
      );
      addTearDown(service.close);

      await expectLater(
        service.downloadPhoto(
          const InatTaxonPhoto(
            url: 'https://static.inaturalist.org.evil.example/photo.jpg',
            attribution: null,
            license: 'CC0',
          ),
        ),
        throwsFormatException,
      );
      expect(sentRequests, 0);

      await expectLater(
        service.downloadPhoto(
          const InatTaxonPhoto(
            url: 'https://static.inaturalist.org/photos/large.jpg',
            attribution: null,
            license: 'CC0',
          ),
        ),
        throwsFormatException,
      );
      expect(sentRequests, 1);
    },
  );
}

http.StreamedResponse _jsonResponse(Map<String, Object?> json) =>
    http.StreamedResponse(
      Stream.value(utf8.encode(jsonEncode(json))),
      200,
      headers: const {'content-type': 'application/json'},
    );

class _FakeClient extends http.BaseClient {
  final Future<http.StreamedResponse> Function(http.BaseRequest request)
  handler;

  _FakeClient(this.handler);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) =>
      handler(request);
}
