import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zoology_app/data/species_data.dart';
import 'package:zoology_app/models/zoology_species.dart';
import 'package:zoology_app/widgets/species_reference_photo.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Milestone 2: Media & Offline Imagery Pipeline Tests', () {
    test('M2-1: All 144 catalog species have verified valid photo URLs (no 800px thumbnails)', () {
      expect(kSpeciesCatalog.length, 144);

      for (final species in kSpeciesCatalog) {
        expect(species.imageUrl, isNotEmpty,
            reason: 'Species ${species.id} must have a non-empty imageUrl');
        expect(
          species.imageUrl.startsWith('https://') || species.imageUrl.startsWith('http://'),
          isTrue,
          reason: 'Species ${species.id} imageUrl must be a valid HTTP(S) URL',
        );

        // Verify root-cause fix: No broken 800px Wikimedia thumbnail URLs
        expect(
          species.imageUrl.contains('800px'),
          isFalse,
          reason: 'Species ${species.id} has broken 800px thumbnail URL which causes HTTP 400',
        );

        // Verify attribution and license completeness
        expect(species.imageAttribution.trim(), isNotEmpty,
            reason: 'Species ${species.id} must have an imageAttribution');
        expect(species.imageLicense.trim(), isNotEmpty,
            reason: 'Species ${species.id} must have an imageLicense');
      }
    });

    test('M2-2: Complete offline image bundling exists for all 144 catalog species', () {
      for (final species in kSpeciesCatalog) {
        final file = File('assets/species/${species.id}.jpg');
        // Check either direct ID or known alias
        final fileExists = file.existsSync() ||
            (species.id == 'musk-deer' && File('assets/species/kashmir-musk-deer.jpg').existsSync()) ||
            (species.id == 'kashmiri-rock-agama' && File('assets/species/kashmir-rock-agama.jpg').existsSync());

        expect(fileExists, isTrue,
            reason: 'Missing bundled offline fallback image for species ${species.id}');

        final targetFile = file.existsSync() ? file : File('assets/species/kashmir-musk-deer.jpg');
        final bytes = targetFile.readAsBytesSync();
        expect(bytes.length, greaterThan(1000),
            reason: 'Asset for ${species.id} is too small (${bytes.length} bytes)');

        final isJpeg = bytes[0] == 0xFF && bytes[1] == 0xD8;
        final isPng = bytes[0] == 0x89 && bytes[1] == 0x50;
        expect(isJpeg || isPng, isTrue,
            reason: 'Asset for ${species.id} does not have valid image header bytes');
      }
    });

    testWidgets('M2-3: Bundled offline fallback image renders immediately for catalog species', (
      tester,
    ) async {
      // Test flagship species across diverse taxa
      const testSpeciesIds = [
        'hangul',
        'snow-leopard',
        'markhor',
        'monal',
        'himalayan-pit-viper',
        'kashmir-snow-trout',
        'kashmir-apollo',
      ];

      for (final id in testSpeciesIds) {
        final species = kSpeciesCatalog.firstWhere((s) => s.id == id);
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SpeciesReferencePhoto(species: species, height: 240),
            ),
          ),
        );
        await tester.pump();

        expect(find.byType(SpeciesReferencePhoto), findsOneWidget);
        expect(find.byType(Image), findsOneWidget,
            reason: 'Species $id should render bundled Image asset');
      }
    });

    testWidgets('M2-4: Graceful art plate fallback when network image fails or host is unreachable', (
      tester,
    ) async {
      const unreachableSpecies = ZoologySpecies(
        id: 'unreachable-offline-fauna',
        commonName: 'Unreachable Mountain Fauna',
        scientificName: 'Fauna unreachable',
        category: 'Mammal',
        region: 'Ladakh',
        status: 'Present',
        habitat: 'High peaks',
        size: '1 m',
        conservation: 'Least Concern',
        feature: 'Camouflage coat',
        funFact: 'Inhabits unreachable crags',
        imageUrl: 'https://unreachable.domain.offline.local/photo-404.jpg',
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SpeciesReferencePhoto(species: unreachableSpecies, height: 220),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(SpeciesReferencePhoto), findsOneWidget);
      expect(find.text('Unreachable Mountain Fauna'), findsAtLeast(1),
          reason: 'Art plate should display the species common name on network failure');
    });

    testWidgets('M2-5: Zero unhandled exceptions on malformed, empty, or 400 URLs', (
      tester,
    ) async {
      const testCases = [
        ZoologySpecies(
          id: 'test-empty-url',
          commonName: 'Empty URL Species',
          scientificName: 'Empty urlus',
          category: 'Bird',
          region: 'Kashmir',
          status: 'Present',
          habitat: 'Sky',
          size: '30 cm',
          conservation: 'Least Concern',
          feature: 'Wings',
          funFact: 'Glider',
          imageUrl: '',
        ),
        ZoologySpecies(
          id: 'test-http-400-url',
          commonName: 'HTTP 400 Species',
          scientificName: 'Bad requestus',
          category: 'Reptile',
          region: 'Jammu',
          status: 'Present',
          habitat: 'Forests',
          size: '50 cm',
          conservation: 'Vulnerable',
          feature: 'Scales',
          funFact: 'Sun basking',
          imageUrl: 'https://httpstat.us/400',
        ),
        ZoologySpecies(
          id: 'test-http-404-url',
          commonName: 'HTTP 404 Species',
          scientificName: 'Not foundus',
          category: 'Fish',
          region: 'Kashmir',
          status: 'Present',
          habitat: 'Rivers',
          size: '20 cm',
          conservation: 'Endangered',
          feature: 'Fins',
          funFact: 'Swimmer',
          imageUrl: 'https://httpstat.us/404',
        ),
      ];

      for (final species in testCases) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SpeciesReferencePhoto(species: species, height: 200),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(SpeciesReferencePhoto), findsOneWidget);
        expect(find.text(species.commonName), findsAtLeast(1));
      }
    });

    testWidgets('M2-6: Tap on photo opens full-screen interactive viewer and dismisses cleanly', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final hangul = kSpeciesCatalog.firstWhere((s) => s.id == 'hangul');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SpeciesReferencePhoto(species: hangul, height: 250),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify accessibility semantics on bundled catalog species
      expect(
        find.byWidgetPredicate(
          (w) =>
              w is Semantics &&
              w.properties.label == 'Reference photo of ${hangul.commonName}',
        ),
        findsOneWidget,
      );

      // Verify photo credit attribution overlay on the photo card
      expect(find.textContaining(hangul.imageAttribution), findsOneWidget);
      expect(find.textContaining(hangul.imageLicense), findsOneWidget);

      // Tap photo to open full-screen dialog
      await tester.tap(find.byType(GestureDetector).first);
      await tester.pumpAndSettle();

      expect(find.byType(InteractiveViewer), findsOneWidget);
      expect(find.byTooltip('Close photo'), findsOneWidget);

      // Verify photo credit attribution inside dialog
      expect(find.textContaining(hangul.imageAttribution), findsAtLeast(1));

      // Close photo
      await tester.tap(find.byTooltip('Close photo'));
      await tester.pumpAndSettle();

      expect(find.byType(InteractiveViewer), findsNothing);
    });

    testWidgets('M2-7: Boundary conditions: zero height and extreme layouts handle safely', (
      tester,
    ) async {
      final snowLeopard = kSpeciesCatalog.firstWhere((s) => s.id == 'snow-leopard');

      // Zero height
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SpeciesReferencePhoto(species: snowLeopard, height: 0),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(SpeciesReferencePhoto), findsOneWidget);

      // Large height
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SpeciesReferencePhoto(species: snowLeopard, height: 800),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(SpeciesReferencePhoto), findsOneWidget);
    });
  });
}
