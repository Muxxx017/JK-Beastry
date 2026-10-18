import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:zoology_app/data/observation_store.dart';
import 'package:zoology_app/data/daily_animal_widget_data.dart';
import 'package:zoology_app/data/species_data.dart';
import 'package:zoology_app/main.dart';
import 'package:zoology_app/models/field_observation.dart';
import 'package:zoology_app/models/inat_taxon.dart';
import 'package:zoology_app/screens/online_species_page.dart';
import 'package:zoology_app/services/inat_service.dart';
import 'package:zoology_app/widgets/zoomable_photo.dart';

void main() {
  test('daily widget data includes animal facts and excludes plants', () {
    final records = buildDailyAnimalWidgetRecords(kSpeciesCatalog);

    expect(records, isNotEmpty);
    expect(
      records.map((record) => record['commonName']),
      contains('Snow Leopard'),
    );
    expect(
      records.map((record) => record['commonName']),
      isNot(contains('Oriental Plane (Chinar)')),
    );
    expect(
      records.every(
        (record) =>
            record['scientificName']!.isNotEmpty &&
            record['funFact']!.isNotEmpty,
      ),
      isTrue,
    );
  });

  testWidgets('app loads the Kashmir zoology home screen', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const KashmirZoologyApp());

    expect(find.text('J&K Bestiary'), findsOneWidget);
    expect(find.text('Field notebook'), findsOneWidget);
  });

  testWidgets('field notes can be saved and appear in recent notes', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const KashmirZoologyApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('fieldNotebookToggle')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('observationNotesField')));
    await tester.enterText(
      find.byKey(const Key('observationNotesField')),
      'Saw tracks near the stream.',
    );
    await tester.ensureVisible(find.byKey(const Key('saveObservationButton')));
    await tester.tap(find.byKey(const Key('saveObservationButton')));
    await tester.pumpAndSettle();

    expect(find.text('Unidentified observation'), findsOneWidget);
    expect(find.textContaining('Saw tracks near the stream.'), findsOneWidget);
  });

  testWidgets('plant category opens detailed offline botanical records', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const KashmirZoologyApp());
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const Key('speciesSearchField')));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ChoiceChip, 'Plant'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Oriental Plane (Chinar)'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('Oriental Plane (Chinar)'), findsOneWidget);
    await tester.tap(find.text('Oriental Plane (Chinar)'));
    await tester.pumpAndSettle();

    expect(find.text('Range & local records'), findsOneWidget);
    expect(find.text('Ecological role'), findsOneWidget);
    expect(find.text('Life cycle & breeding'), findsOneWidget);
    expect(find.text('Fun fact'), findsOneWidget);
    expect(find.text('Genus'), findsOneWidget);
    expect(find.text('Platanus'), findsOneWidget);
    expect(find.text('Research starting points'), findsOneWidget);
    expect(
      find.textContaining('cultivated rather than naturally occurring'),
      findsOneWidget,
    );
  });

  testWidgets('offline search matches facts, not only species names', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const KashmirZoologyApp());
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const Key('speciesSearchField')));
    await tester.enterText(
      find.byKey(const Key('speciesSearchField')),
      'aphids',
    );
    await tester.pumpAndSettle();

    expect(find.text('Seven-Spot Ladybird'), findsOneWidget);
  });

  testWidgets('online explorer shows species from its data source', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    late Uri requestUri;
    final service = InatService(
      client: _FakeClient((request) async {
        requestUri = request.url;
        return http.StreamedResponse(
          Stream.value(
            utf8.encode(
              jsonEncode({
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
                    },
                  },
                ],
              }),
            ),
          ),
          200,
        );
      }),
    );
    addTearDown(service.close);

    await tester.pumpWidget(
      MaterialApp(home: OnlineSpeciesPage(service: service)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Plain Tiger Butterfly'), findsOneWidget);
    expect(find.textContaining('42 regional observations'), findsOneWidget);
    expect(
      requestUri.queryParameters['place_id'],
      InatService.jammuKashmirPlaceId,
    );
  });

  testWidgets('online name search hides irrelevant taxa', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final service = InatService(
      client: _FakeClient((request) async {
        if (request.url.path.endsWith('/taxa/autocomplete')) {
          return http.StreamedResponse(
            Stream.value(
              utf8.encode(
                jsonEncode({
                  'total_results': 2,
                  'results': [
                    {
                      'id': 41964,
                      'name': 'Panthera leo',
                      'preferred_common_name': 'Lion',
                      'rank': 'species',
                    },
                    {
                      'id': 41963,
                      'name': 'Panthera pardus',
                      'preferred_common_name': 'Leopard',
                      'rank': 'species',
                    },
                  ],
                }),
              ),
            ),
            200,
          );
        }
        if (request.url.path.endsWith('/observations/species_counts') &&
            request.url.queryParameters.containsKey('taxon_id') &&
            request.url.queryParameters['taxon_id'] != '1' &&
            request.url.queryParameters['taxon_id'] != '47126') {
          return http.StreamedResponse(
            Stream.value(
              utf8.encode(
                jsonEncode({
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
                      'count': 6,
                      'taxon': {
                        'id': 41963,
                        'name': 'Panthera pardus',
                        'preferred_common_name': 'Leopard',
                        'rank': 'species',
                      },
                    },
                  ],
                }),
              ),
            ),
            200,
          );
        }
        return http.StreamedResponse(
          Stream.value(utf8.encode('{"total_results":0,"results":[]}')),
          200,
        );
      }),
    );
    addTearDown(service.close);

    await tester.pumpWidget(
      MaterialApp(home: OnlineSpeciesPage(service: service)),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('onlineSpeciesSearchField')),
      'lion',
    );
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    expect(find.text('Lion'), findsOneWidget);
    expect(find.text('Leopard'), findsNothing);
    expect(find.textContaining('whose names match “lion”'), findsOneWidget);
  });

  testWidgets('reference photos open in a zoomable viewer with credit', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: ZoomablePhoto(
              key: Key('testZoomablePhoto'),
              url: 'https://example.org/photo.jpg',
              height: 180,
              attribution: 'Photographer',
              license: 'CC BY',
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('testZoomablePhoto')));
    await tester.pumpAndSettle();

    expect(find.byType(InteractiveViewer), findsOneWidget);
    expect(find.textContaining('Photographer'), findsOneWidget);
    expect(find.textContaining('CC BY'), findsOneWidget);

    await tester.tap(find.byTooltip('Close photo'));
    await tester.pumpAndSettle();
    expect(find.byType(InteractiveViewer), findsNothing);
  });

  testWidgets(
    'failed encyclopedia and taxon requests show clean retry states',
    (tester) async {
      var taxonAttempts = 0;
      final service = InatService(
        client: _FakeClient((request) async {
          if (request.url.host == 'api.gbif.org') {
            return http.StreamedResponse(
              Stream.value(
                utf8.encode(
                  jsonEncode({
                    'usageKey': 2489005,
                    'scientificName': 'Panthera uncia',
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
                  }),
                ),
              ),
              200,
            );
          }
          if (request.url.host == 'en.wikipedia.org') {
            return http.StreamedResponse(Stream.value(utf8.encode('{}')), 503);
          }
          taxonAttempts++;
          if (taxonAttempts == 1) {
            return http.StreamedResponse(Stream.value(utf8.encode('{}')), 503);
          }
          return http.StreamedResponse(
            Stream.value(
              utf8.encode(
                jsonEncode({
                  'results': [
                    {
                      'id': 67835,
                      'name': 'Panthera uncia',
                      'rank': 'species',
                      'observations_count': 1000,
                      'taxon_photos': [],
                    },
                  ],
                }),
              ),
            ),
            200,
          );
        }),
      );
      addTearDown(service.close);
      const taxon = InatTaxon(
        id: 67835,
        name: 'Panthera uncia',
        commonName: 'Snow Leopard',
        rank: 'species',
        regionalObservations: 42,
        totalObservations: 1000,
        conservationStatus: null,
        photoUrl: null,
        photoAttribution: null,
        photoLicense: null,
        wikipediaUrl: 'https://en.wikipedia.org/wiki/Snow_leopard',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: OnlineTaxonDetailsPage(
            service: service,
            taxon: taxon,
            openUrl: (_) async {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Snow Leopard'), findsOneWidget);
      expect(
        find.text('The encyclopedia overview is temporarily unavailable.'),
        findsOneWidget,
      );
      expect(find.text('Taxonomy source: GBIF'), findsOneWidget);
      expect(find.textContaining('ClientException'), findsNothing);
      expect(find.textContaining('uri='), findsNothing);
      expect(taxonAttempts, 1);

      await tester.scrollUntilVisible(
        find.textContaining(
          'Extra species information is temporarily unavailable.',
        ),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      expect(
        find.textContaining(
          'Extra species information is temporarily unavailable.',
        ),
        findsOneWidget,
      );
      await tester.tap(find.text('Retry').last);
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('Identification photos'),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Identification photos'), findsOneWidget);
      expect(find.text('Natural history & fun fact'), findsOneWidget);
      expect(
        find.textContaining('Its tail acts like a blanket'),
        findsOneWidget,
      );
      expect(find.text('Habit & behavior'), findsOneWidget);
      expect(find.text('Life cycle & breeding'), findsOneWidget);
      expect(taxonAttempts, 2);
    },
  );

  test('field observations persist through the local store', () async {
    SharedPreferences.setMockInitialValues({});
    final store = ObservationStore();
    final observation = FieldObservation(
      id: 'test-observation',
      speciesName: 'Hangul',
      location: 'Dachigam',
      notes: 'Grazing at the forest edge.',
      photoBase64: base64Encode([1, 2, 3]),
      observedAt: DateTime(2026, 10, 18),
    );

    await store.save([observation]);
    final loaded = await store.load();

    expect(loaded, hasLength(1));
    expect(loaded.single.speciesName, 'Hangul');
    expect(loaded.single.location, 'Dachigam');
    expect(loaded.single.notes, 'Grazing at the forest edge.');
    expect(loaded.single.photoBytes, [1, 2, 3]);
  });
}

class _FakeClient extends http.BaseClient {
  final Future<http.StreamedResponse> Function(http.BaseRequest request)
  handler;

  _FakeClient(this.handler);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) =>
      handler(request);
}
