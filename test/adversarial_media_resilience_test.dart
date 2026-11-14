import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zoology_app/data/species_data.dart';
import 'package:zoology_app/models/zoology_species.dart';
import 'package:zoology_app/services/inat_service.dart';
import 'package:zoology_app/widgets/local_species_photo.dart';
import 'package:zoology_app/widgets/species_reference_photo.dart';
import 'package:zoology_app/widgets/zoomable_photo.dart';

/// Custom mock client for InatService to simulate transport & server failures
class _StressMockClient extends http.BaseClient {
  final Future<http.StreamedResponse> Function(http.BaseRequest request) _handler;
  _StressMockClient(this._handler);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) => _handler(request);
}

/// Custom HttpOverrides to simulate diverse network layer error boundaries for Image.network
class _AdversarialHttpOverrides extends HttpOverrides {
  final int statusCode;
  final List<int> responseBytes;
  final Exception? throwException;

  _AdversarialHttpOverrides({
    this.statusCode = 200,
    this.responseBytes = const <int>[],
    this.throwException,
  });

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return _AdversarialHttpClient(
      statusCode: statusCode,
      responseBytes: responseBytes,
      throwException: throwException,
    );
  }
}

class _AdversarialHttpClient implements HttpClient {
  final int statusCode;
  final List<int> responseBytes;
  final Exception? throwException;

  _AdversarialHttpClient({
    required this.statusCode,
    required this.responseBytes,
    this.throwException,
  });

  @override
  Future<HttpClientRequest> getUrl(Uri url) async {
    if (throwException != null) {
      throw throwException!;
    }
    return _AdversarialHttpClientRequest(statusCode: statusCode, responseBytes: responseBytes);
  }

  @override
  void close({bool force = false}) {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _AdversarialHttpClientRequest implements HttpClientRequest {
  final int statusCode;
  final List<int> responseBytes;

  _AdversarialHttpClientRequest({
    required this.statusCode,
    required this.responseBytes,
  });

  @override
  final HttpHeaders headers = _DummyHttpHeaders();

  @override
  Future<HttpClientResponse> close() async {
    return _AdversarialHttpClientResponse(
      statusCode: statusCode,
      responseBytes: responseBytes,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _DummyHttpHeaders implements HttpHeaders {
  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) {}
  @override
  void add(String name, Object value, {bool preserveHeaderCase = false}) {}
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _AdversarialHttpClientResponse extends Stream<List<int>> implements HttpClientResponse {
  @override
  final int statusCode;
  final List<int> responseBytes;

  _AdversarialHttpClientResponse({
    required this.statusCode,
    required this.responseBytes,
  });

  @override
  int get contentLength => responseBytes.length;

  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;

  @override
  final HttpHeaders headers = _DummyHttpHeaders();

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return Stream<List<int>>.value(responseBytes).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Milestone 2 Empirical Challenger Suite: Media Resilience', () {
    // -------------------------------------------------------------------------
    // TEST 1: Exhaustive Catalog Imagery Integrity (All 144 Species)
    // -------------------------------------------------------------------------
    test('CH-M2-1: Rigorous verification of all 144 species image URLs and assets', () {
      expect(kSpeciesCatalog.length, 144,
          reason: 'Catalog must contain exactly 144 curated species records');

      final assetDir = Directory('assets/species');
      expect(assetDir.existsSync(), isTrue, reason: 'assets/species directory must exist');

      for (final species in kSpeciesCatalog) {
        // 1. URL validity checks
        expect(species.imageUrl.trim(), isNotEmpty,
            reason: 'Species ${species.id} must have non-empty imageUrl');
        expect(
          species.imageUrl.startsWith('https://') || species.imageUrl.startsWith('http://'),
          isTrue,
          reason: 'Species ${species.id} has invalid URL protocol: ${species.imageUrl}',
        );

        // 2. Strict check against broken 800px Wikimedia thumbnail pattern
        expect(
          species.imageUrl.contains('800px'),
          isFalse,
          reason: 'Species ${species.id} contains prohibited 800px thumbnail URL causing HTTP 400',
        );

        // 3. Attribution & License presence
        expect(species.imageAttribution.trim(), isNotEmpty,
            reason: 'Species ${species.id} missing imageAttribution');
        expect(species.imageLicense.trim(), isNotEmpty,
            reason: 'Species ${species.id} missing imageLicense');

        // 4. Bundled asset existence & byte integrity
        final file = File('assets/species/${species.id}.jpg');
        final aliasFile = species.id == 'musk-deer'
            ? File('assets/species/kashmir-musk-deer.jpg')
            : species.id == 'kashmiri-rock-agama'
                ? File('assets/species/kashmir-rock-agama.jpg')
                : file;

        expect(aliasFile.existsSync(), isTrue,
            reason: 'Missing bundled asset file on disk: ${aliasFile.path}');

        final bytes = aliasFile.readAsBytesSync();
        expect(bytes.length, greaterThan(1000),
            reason: 'Bundled asset ${aliasFile.path} is too small (${bytes.length} bytes)');

        // Valid magic header (JPEG 0xFF 0xD8 or PNG 0x89 0x50)
        final isJpeg = bytes.length >= 2 && bytes[0] == 0xFF && bytes[1] == 0xD8;
        final isPng = bytes.length >= 2 && bytes[0] == 0x89 && bytes[1] == 0x50;
        expect(isJpeg || isPng, isTrue,
            reason: 'Asset ${aliasFile.path} lacks valid JPEG or PNG header magic bytes');
      }
    });

    // -------------------------------------------------------------------------
    // TEST 2: Stress-test HTTP Error Boundaries (400, 401, 403, 404, 500, 502, 503)
    // -------------------------------------------------------------------------
    testWidgets('CH-M2-2: Widget error boundary survives HTTP 400, 401, 403, 404, 500, 502, 503', (
      tester,
    ) async {
      const httpStatusCodes = [400, 401, 403, 404, 500, 502, 503];

      for (final code in httpStatusCodes) {
        final species = ZoologySpecies(
          id: 'test-http-error-$code',
          commonName: 'HTTP $code Error Species',
          scientificName: 'Errorus status$code',
          category: 'Mammal',
          region: 'Kashmir',
          status: 'Present',
          habitat: 'Alpine',
          size: '10 cm',
          conservation: 'Least Concern',
          feature: 'Resilient',
          funFact: 'Tests HTTP $code handling',
          imageUrl: 'https://httpstat.us/$code',
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SpeciesReferencePhoto(species: species, height: 200),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(SpeciesReferencePhoto), findsOneWidget);
        // Fallback art plate displays the species common name
        expect(find.text('HTTP $code Error Species'), findsAtLeast(1),
            reason: 'SpeciesReferencePhoto should fall back to art plate on HTTP $code');
      }
    });

    // -------------------------------------------------------------------------
    // TEST 3: Network Transport and Socket Failure Stress Test
    // -------------------------------------------------------------------------
    testWidgets('CH-M2-3: Graceful degradation under SocketException, HttpException, and HandshakeException', (
      tester,
    ) async {
      final transportErrors = [
        const SocketException('Failed host lookup: "api.inaturalist.org"'),
        const HttpException('Connection reset by peer'),
        const HandshakeException('Handshake error: CERTIFICATE_VERIFY_FAILED'),
        TimeoutException('Connection timed out after 5000ms'),
      ];

      for (var i = 0; i < transportErrors.length; i++) {
        final error = transportErrors[i];
        final service = InatService(
          client: _StressMockClient((request) async {
            throw error;
          }),
        );

        final unbundledSpecies = ZoologySpecies(
          id: 'transport-fail-$i',
          commonName: 'Transport Fail Fauna $i',
          scientificName: 'Transportus defectus $i',
          category: 'Bird',
          region: 'Ladakh',
          status: 'Present',
          habitat: 'Sky',
          size: '25 cm',
          conservation: 'Least Concern',
          feature: 'Feathers',
          funFact: 'Testing transport errors',
          imageUrl: '', // Forces service lookup to trigger transport error
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SpeciesReferencePhoto(
                species: unbundledSpecies,
                service: service,
                height: 220,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(SpeciesReferencePhoto), findsOneWidget);
        expect(find.text('Transport Fail Fauna $i'), findsAtLeast(1),
            reason: 'Art plate should display common name when service throws $error');
      }
    });

    // -------------------------------------------------------------------------
    // TEST 4: Pathological, Corrupt, and Malformed Image URLs
    // -------------------------------------------------------------------------
    testWidgets('CH-M2-4: Malformed, empty, protocol-less, and giant URLs handled with zero exceptions', (
      tester,
    ) async {
      final pathologicalUrls = [
        '',
        '    ',
        'not-a-valid-url',
        'http://',
        'https://',
        'ftp://unsupported.protocol.org/photo.png',
        'http://[::1:invalid_ipv6_format',
        'https://example.com/photo with spaces & <script>alert(1)</script>.jpg',
        'https://example.com:99999999/overflow-port.jpg',
        'https://example.com/${'a' * 5000}.jpg', // Giant URL
      ];

      for (var i = 0; i < pathologicalUrls.length; i++) {
        final species = ZoologySpecies(
          id: 'malformed-url-$i',
          commonName: 'Malformed URL Species $i',
          scientificName: 'Malformedus urlus $i',
          category: 'Reptile',
          region: 'Jammu',
          status: 'Present',
          habitat: 'Rocks',
          size: '15 cm',
          conservation: 'Least Concern',
          feature: 'Scales',
          funFact: 'Testing malformed URL',
          imageUrl: pathologicalUrls[i],
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SpeciesReferencePhoto(species: species, height: 190),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(SpeciesReferencePhoto), findsOneWidget);
        expect(find.text('Malformed URL Species $i'), findsAtLeast(1));
      }
    });

    // -------------------------------------------------------------------------
    // TEST 5: Corrupt, HTML Error Pages, and 0-Byte Payloads via HttpOverrides
    // -------------------------------------------------------------------------
    testWidgets('CH-M2-5: HttpOverrides simulating 0-byte payload, corrupt bytes, and HTML 200 responses', (
      tester,
    ) async {
      // Scenario A: 0 bytes body with HTTP 200
      await HttpOverrides.runWithHttpOverrides(() async {
        const emptyByteSpecies = ZoologySpecies(
          id: 'zero-byte-species',
          commonName: 'Zero Byte Animal',
          scientificName: 'Zerous bytus',
          category: 'Fish',
          region: 'Kashmir',
          status: 'Present',
          habitat: 'Lake',
          size: '20 cm',
          conservation: 'Least Concern',
          feature: 'Gills',
          funFact: 'Empty byte payload test',
          imageUrl: 'https://test-server.local/empty.jpg',
        );

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: SpeciesReferencePhoto(species: emptyByteSpecies, height: 210),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(SpeciesReferencePhoto), findsOneWidget);
        expect(find.text('Zero Byte Animal'), findsAtLeast(1));
      }, _AdversarialHttpOverrides(statusCode: 200, responseBytes: <int>[]));

      // Scenario B: HTML Error Page body with HTTP 200 (Captive Portal / WAF)
      final htmlBytes = utf8.encode('<!DOCTYPE html><html><body>Error 404 Not Found</body></html>');
      await HttpOverrides.runWithHttpOverrides(() async {
        const htmlPayloadSpecies = ZoologySpecies(
          id: 'html-payload-species',
          commonName: 'HTML Payload Animal',
          scientificName: 'Htmlus captive',
          category: 'Insect',
          region: 'Jammu',
          status: 'Present',
          habitat: 'Forest',
          size: '3 cm',
          conservation: 'Least Concern',
          feature: 'Wings',
          funFact: 'HTML error payload test',
          imageUrl: 'https://test-server.local/login-portal.html',
        );

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: SpeciesReferencePhoto(species: htmlPayloadSpecies, height: 210),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(SpeciesReferencePhoto), findsOneWidget);
        expect(find.text('HTML Payload Animal'), findsAtLeast(1));
      }, _AdversarialHttpOverrides(statusCode: 200, responseBytes: htmlBytes));

      // Scenario C: SocketException thrown by HttpClient
      await HttpOverrides.runWithHttpOverrides(() async {
        const socketExceptionSpecies = ZoologySpecies(
          id: 'socket-exception-species',
          commonName: 'Socket Exception Animal',
          scientificName: 'Socketus broken',
          category: 'Mammal',
          region: 'Pir Panjal',
          status: 'Present',
          habitat: 'Ridge',
          size: '1 m',
          conservation: 'Least Concern',
          feature: 'Fur',
          funFact: 'Socket failure simulation',
          imageUrl: 'https://unreachable-s3-aws.local/image.jpg',
        );

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: SpeciesReferencePhoto(species: socketExceptionSpecies, height: 210),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(SpeciesReferencePhoto), findsOneWidget);
        expect(find.text('Socket Exception Animal'), findsAtLeast(1));
      }, _AdversarialHttpOverrides(
        throwException: const SocketException('Connection refused: unreachable-s3-aws.local:443'),
      ));
    });

    // -------------------------------------------------------------------------
    // TEST 6: Fallback to Bundled Asset in _PhotoImage and ArtPlate Cascade
    // -------------------------------------------------------------------------
    testWidgets('CH-M2-6: Cascade fallback: Network failure -> Bundled Asset -> Art Plate', (
      tester,
    ) async {
      // 1. Unbundled species: network fails -> Art Plate renders
      const unbundledSpecies = ZoologySpecies(
        id: 'unbundled-cascade-test',
        commonName: 'Cascade Test Creature',
        scientificName: 'Cascardus testus',
        category: 'Amphibian',
        region: 'Kashmir',
        status: 'Present',
        habitat: 'Stream',
        size: '8 cm',
        conservation: 'Critically Endangered',
        feature: 'Webbed feet',
        funFact: 'Cascade verification',
        imageUrl: 'https://bad-host.local/photo.jpg',
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SpeciesReferencePhoto(species: unbundledSpecies, height: 230),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(SpeciesReferencePhoto), findsOneWidget);
      expect(find.text('Cascade Test Creature'), findsAtLeast(1));
      expect(find.text('AMPHIBIAN'), findsAtLeast(1));

      // 2. Bundled species (e.g. hangul): renders bundled Image.asset immediately
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

    // -------------------------------------------------------------------------
    // TEST 7: LocalSpeciesPhoto and OfflineTaxaStore Resiliency
    // -------------------------------------------------------------------------
    testWidgets('CH-M2-7: LocalSpeciesPhoto handles non-existent or corrupted file paths gracefully', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LocalSpeciesPhoto(
              path: 'C:/nonexistent/invalid_file_location/does_not_exist.jpg',
              fit: BoxFit.cover,
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(LocalSpeciesPhoto), findsOneWidget);
      expect(find.byType(Image), findsOneWidget);
      expect(tester.takeException(), isNull,
          reason: 'LocalSpeciesPhoto must handle missing local files without unhandled exceptions');
    });

    // -------------------------------------------------------------------------
    // TEST 8: ZoomablePhoto Error Handling Under Adversarial URLs
    // -------------------------------------------------------------------------
    testWidgets('CH-M2-8: ZoomablePhoto gracefully handles broken URLs, 404s, and tap-open viewers', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: ZoomablePhoto(
                key: Key('adversarialZoomablePhoto'),
                url: 'https://httpstat.us/500',
                height: 200,
                attribution: 'Adversarial Tester',
                license: 'CC0',
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('adversarialZoomablePhoto')), findsOneWidget);
      expect(find.byIcon(Icons.broken_image_outlined), findsOneWidget);

      // Tap to open full screen viewer
      await tester.tap(find.byKey(const Key('adversarialZoomablePhoto')));
      await tester.pumpAndSettle();

      expect(find.byType(InteractiveViewer), findsOneWidget);
      expect(find.textContaining('Adversarial Tester'), findsOneWidget);

      // Close modal
      await tester.tap(find.byTooltip('Close photo'));
      await tester.pumpAndSettle();

      expect(find.byType(InteractiveViewer), findsNothing);
    });

    // -------------------------------------------------------------------------
    // TEST 9: Rapid Carousel & Memory/Lifecycle Stress
    // -------------------------------------------------------------------------
    testWidgets('CH-M2-9: Rapidly mounting, pumping, and disposing SpeciesReferencePhoto throws zero errors', (
      tester,
    ) async {
      // Pick 20 species across all 6 taxonomic classes
      final testSubSet = [
        ...kSpeciesCatalog.where((s) => s.category == 'Mammal').take(4),
        ...kSpeciesCatalog.where((s) => s.category == 'Bird').take(4),
        ...kSpeciesCatalog.where((s) => s.category == 'Reptile').take(4),
        ...kSpeciesCatalog.where((s) => s.category == 'Amphibian').take(4),
        ...kSpeciesCatalog.where((s) => s.category == 'Fish').take(2),
        ...kSpeciesCatalog.where((s) => s.category == 'Insect').take(2),
      ];

      for (final species in testSubSet) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SpeciesReferencePhoto(species: species, height: 180),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 20));
      }

      // Final unmount
      await tester.pumpWidget(const MaterialApp(home: Scaffold(body: SizedBox())));
      await tester.pumpAndSettle();

      expect(find.byType(SpeciesReferencePhoto), findsNothing);
    });
  });
}
