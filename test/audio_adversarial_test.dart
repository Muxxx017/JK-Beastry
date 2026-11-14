import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zoology_app/data/species_data.dart';
import 'package:zoology_app/models/zoology_species.dart';
import 'package:zoology_app/screens/species_detail_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Adversarial Audio Header & Integrity Verification', () {
    final audioDir = Directory('assets/audio');

    test('assets/audio directory exists and contains all required audio files', () {
      expect(audioDir.existsSync(), isTrue, reason: 'assets/audio directory missing');
      final files = audioDir.listSync().whereType<File>().toList();
      expect(files.length, greaterThanOrEqualTo(20),
          reason: 'Expected at least 20 audio files in assets/audio, found ${files.length}');
    });

    test('Empirical magic byte validation for every single file in assets/audio', () {
      final files = audioDir.listSync().whereType<File>().toList();
      final validHeaders = <String, String>{};

      for (final file in files) {
        final filename = file.uri.pathSegments.last;
        final bytes = file.readAsBytesSync();

        expect(bytes.length, greaterThan(1024),
            reason: '$filename is too small (${bytes.length} bytes), likely stub or placeholder');

        // Check for ASCII/HTML error pages disguised as MP3 (e.g. 404 Not Found)
        final asciiStart = String.fromCharCodes(bytes.take(20).map((b) => b >= 32 && b <= 126 ? b : 46));
        expect(asciiStart.toLowerCase().contains('<!doc') || asciiStart.toLowerCase().contains('<html'),
            isFalse,
            reason: '$filename appears to be an HTML page, not an audio file');

        // Magic byte checks:
        // 1. ID3v2 tag: "ID3" (0x49 0x44 0x33)
        final isId3 = bytes.length >= 3 &&
            bytes[0] == 0x49 &&
            bytes[1] == 0x44 &&
            bytes[2] == 0x33;

        // 2. RIFF WAVE: "RIFF" .... "WAVE"
        final isRiffWave = bytes.length >= 12 &&
            bytes[0] == 0x52 && bytes[1] == 0x49 && bytes[2] == 0x46 && bytes[3] == 0x46 &&
            bytes[8] == 0x57 && bytes[9] == 0x41 && bytes[10] == 0x56 && bytes[11] == 0x45;

        // 3. MP3 frame sync word: 11 bits set (0xFF followed by 0xE0..0xFF)
        final isMp3Sync = bytes.length >= 2 &&
            bytes[0] == 0xFF &&
            (bytes[1] & 0xE0) == 0xE0;

        expect(isId3 || isRiffWave || isMp3Sync, isTrue,
            reason: '$filename failed magic byte validation! First 4 bytes: 0x${bytes.take(4).map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ')}');

        String headerType = 'Unknown';
        if (isId3) headerType = 'ID3v2 (${bytes[3]}.${bytes[4]})';
        if (isRiffWave) headerType = 'RIFF WAVE';
        if (isMp3Sync) headerType = 'MP3 Sync (0x${bytes[0].toRadixString(16)} 0x${bytes[1].toRadixString(16)})';
        validHeaders[filename] = '$headerType, ${bytes.length} bytes';
      }

      expect(validHeaders.length, equals(files.length));
    });

    test('Catalog audioAsset integrity: all catalog references point to valid files', () {
      final speciesWithAudio = kSpeciesCatalog.where((s) => s.audioAsset != null).toList();
      expect(speciesWithAudio.length, greaterThanOrEqualTo(20));

      for (final sp in speciesWithAudio) {
        final asset = sp.audioAsset!;
        expect(asset.startsWith('assets/audio/'), isTrue,
            reason: '${sp.id} audioAsset does not start with assets/audio/: $asset');
        final file = File(asset);
        expect(file.existsSync(), isTrue,
            reason: '${sp.id} points to non-existent audio file: $asset');
        expect(file.lengthSync(), greaterThan(1024),
            reason: '${sp.id} audio file is suspiciously small: ${file.lengthSync()} bytes');
      }
    });
  });

  group('Adversarial Stress Test: Rapid Play/Pause Toggling', () {
    testWidgets('Rapid 5 taps in 100ms does not throw exceptions or deadlock', (tester) async {
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

      // Simulate 5 rapid taps within 100ms (20ms intervals)
      for (int i = 0; i < 5; i++) {
        await tester.tap(playBtn);
        await tester.pump(const Duration(milliseconds: 20));
      }

      // After 5 taps starting from false: true -> false -> true -> false -> true
      expect(state.isPlaying, isTrue);
      expect(find.byIcon(Icons.pause_rounded), findsOneWidget);

      // Settle animation and pending async operations
      await tester.pump(const Duration(milliseconds: 200));
      expect(tester.takeException(), isNull, reason: 'Rapid tapping threw an uncaught exception');
    });

    testWidgets('Ultra-rapid 10 taps in 50ms preserves deterministic state without race condition', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: InteractiveVocalizationWidget(
              commonName: 'Snow Leopard',
              vocalization: 'Canyon yowl and prusten',
              audioAsset: 'assets/audio/snow_leopard.mp3',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final playBtn = find.byType(IconButton);
      final state = tester.state<InteractiveVocalizationWidgetState>(
        find.byType(InteractiveVocalizationWidget),
      );

      // 10 taps at 5ms intervals (even count: false -> true -> ... -> false)
      for (int i = 0; i < 10; i++) {
        await tester.tap(playBtn);
        await tester.pump(const Duration(milliseconds: 5));
      }

      expect(state.isPlaying, isFalse);
      expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.takeException(), isNull);
    });

    testWidgets('Rapid toggle and immediate unmount does not throw setState on disposed widget', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return const InteractiveVocalizationWidget(
                  commonName: 'Common Leopard',
                  vocalization: 'Sawing cough call',
                  audioAsset: 'assets/audio/common_leopard.mp3',
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final playBtn = find.byType(IconButton);

      // Tap 3 times rapidly
      await tester.tap(playBtn);
      await tester.pump(const Duration(milliseconds: 10));
      await tester.tap(playBtn);
      await tester.pump(const Duration(milliseconds: 10));
      await tester.tap(playBtn);
      await tester.pump(const Duration(milliseconds: 10));

      // Replace widget with empty container immediately while async audio sync is in-flight
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox.shrink(),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 150));

      expect(tester.takeException(), isNull,
          reason: 'Unmounting widget during rapid toggle threw an exception (e.g. setState after dispose)');
    });
  });

  group('Adversarial Missing Audio, Corrupted Paths & Offline Resilience', () {
    testWidgets('Missing/non-existent audio file degrades gracefully with no red screen or crash', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: InteractiveVocalizationWidget(
              commonName: 'Imaginary Beast',
              vocalization: 'Supernatural sonic pulse',
              audioAsset: 'assets/audio/non_existent_aberration.mp3',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final playBtn = find.byType(IconButton);
      expect(playBtn, findsOneWidget);

      // Tapping play on non-existent audio
      await tester.tap(playBtn);
      await tester.pump(const Duration(milliseconds: 100));

      // Must not crash or show Flutter error widget
      expect(find.byType(InteractiveVocalizationWidget), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Empty string audio asset handles playback attempt safely', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: InteractiveVocalizationWidget(
              commonName: 'Empty Sound Animal',
              vocalization: 'Silent flutter',
              audioAsset: '',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final playBtn = find.byType(IconButton);
      await tester.tap(playBtn);
      await tester.pump(const Duration(milliseconds: 50));

      expect(tester.takeException(), isNull);
    });

    testWidgets('Null audioAsset for vocal species does not crash and renders info', (tester) async {
      const vocalSpeciesWithoutAudio = ZoologySpecies(
        id: 'mysterious-bat',
        commonName: 'Mysterious Bat',
        scientificName: 'Myotis mystacinus',
        category: 'Mammal',
        region: 'Kashmir',
        status: 'Uncommon',
        habitat: 'Caves and forested valleys',
        size: '4–5 cm',
        conservation: 'Least Concern',
        feature: 'Small whiskered vesper bat',
        funFact: 'Uses ultrasonic echolocation above human hearing range',
        isVocal: true,
        vocalization: 'Ultrasonic echolocation clicks between 40-75 kHz.',
        audioAsset: null,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: InteractiveVocalizationWidget(
              species: vocalSpeciesWithoutAudio,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('VOCALIZATION & SOUNDS'), findsOneWidget);
      expect(find.textContaining('Ultrasonic echolocation clicks'), findsOneWidget);

      // Tap play
      await tester.tap(find.byType(IconButton));
      await tester.pump(const Duration(milliseconds: 50));
      expect(tester.takeException(), isNull);
    });

    testWidgets('Scrubbing slider when duration is zero does not divide by zero or crash', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: InteractiveVocalizationWidget(
              commonName: 'Himalayan Wolf',
              vocalization: 'Haunting chorus howl',
              audioAsset: 'assets/audio/himalayan_wolf.mp3',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final sliderFinder = find.byType(Slider);
      expect(sliderFinder, findsOneWidget);

      final slider = tester.widget<Slider>(sliderFinder);
      expect(slider.onChanged, isNull, reason: 'Slider must be disabled when duration is zero');

      // Attempt drag on slider
      await tester.drag(sliderFinder, const Offset(50, 0));
      await tester.pump(const Duration(milliseconds: 50));

      expect(tester.takeException(), isNull);
    });
  });

  group('Catalog-Wide Zoology Acoustic & Boundary Stress Tests', () {
    testWidgets('Every single species in kSpeciesCatalog renders InteractiveVocalizationWidget cleanly', (tester) async {
      // Set comfortable viewport
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      for (final species in kSpeciesCatalog) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: InteractiveVocalizationWidget(species: species),
            ),
          ),
        );
        await tester.pump();

        if (!species.isVocal) {
          expect(find.text('COMMUNICATION & ACOUSTICS'), findsOneWidget,
              reason: 'Non-vocal species ${species.id} missing communication card');
          expect(find.byType(IconButton), findsNothing,
              reason: 'Non-vocal species ${species.id} must not render audio play button');
        } else {
          expect(find.text('VOCALIZATION & SOUNDS'), findsOneWidget,
              reason: 'Vocal species ${species.id} missing vocalization header');
          expect(find.byType(IconButton), findsOneWidget,
              reason: 'Vocal species ${species.id} missing play button');
        }
      }
    });

    testWidgets('F3-B2 boundary: species with isVocal=true but empty vocalization safely hidden in detail page', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const silentVocalSpecies = ZoologySpecies(
        id: 'silent-creature',
        commonName: 'Silent Creature',
        scientificName: 'Silens silens',
        category: 'Mammal',
        region: 'Kashmir',
        status: 'Rare',
        habitat: 'Valleys',
        size: '10 cm',
        conservation: 'Data Deficient',
        feature: 'Secretive habit',
        funFact: 'Has never been heard',
        isVocal: true,
        vocalization: '', // EMPTY vocalization string
        audioAsset: null,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: SpeciesDetailPage(species: silentVocalSpecies),
        ),
      );
      await tester.pumpAndSettle();

      // F3-B2 contract: when isVocal is true but vocalization is empty, InteractiveVocalizationWidget is hidden
      expect(find.byType(InteractiveVocalizationWidget), findsNothing,
          reason: 'SpeciesDetailPage should not display InteractiveVocalizationWidget when isVocal=true but vocalization is empty');
    });

    testWidgets('Non-vocal species with completely null/empty notes displays fallback sensory explanation', (tester) async {
      const nonVocalSpecies = ZoologySpecies(
        id: 'mute-cricket',
        commonName: 'Mute Cricket',
        scientificName: 'Gryllus mutus',
        category: 'Insect',
        region: 'Jammu',
        status: 'Common',
        habitat: 'Leaf litter',
        size: '2 cm',
        conservation: 'Least Concern',
        feature: 'Wingless',
        funFact: 'Lacks stridulation organs',
        isVocal: false,
        vocalization: '',
        vocalizationNote: null,
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
      expect(find.textContaining('substrate vibrations, chemical pheromones, or visual dewlap displays'), findsOneWidget);
    });
  });
}
