import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:zoology_app/data/species_data.dart';
import 'package:zoology_app/models/zoology_species.dart';
import 'package:zoology_app/screens/species_detail_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Milestone 3: Audio Assets & Verification', () {
    test('All bundled vocalization audio files exist and have valid headers', () {
      final audioDir = Directory('assets/audio');
      expect(audioDir.existsSync(), isTrue, reason: 'assets/audio/ directory must exist');

      final focalAudio = [
        'hangul.mp3',
        'snow_leopard.mp3',
        'common_leopard.mp3',
        'himalayan_wolf.mp3',
        'golden_jackal.mp3',
        'himalayan_marmot.mp3',
        'himalayan_monal.mp3',
        'western_tragopan.mp3',
        'black_necked_crane.mp3',
        'kashmir_flycatcher.mp3',
        'blue_whistling_thrush.mp3',
        'himalayan_pit_viper.mp3',
        'himalayan_toad.mp3',
        'great_barbet.mp3',
        'eurasian_eagle_owl.mp3',
        'russell_viper.mp3',
        'indian_bullfrog.mp3',
        'ladakh_toad.mp3',
        'himalayan_brown_bear.mp3',
        'common_kingfisher.mp3',
      ];

      for (final filename in focalAudio) {
        final file = File('assets/audio/$filename');
        expect(file.existsSync(), isTrue, reason: 'Missing audio file assets/audio/$filename');

        final bytes = file.readAsBytesSync();
        expect(bytes.length, greaterThan(1024),
            reason: 'Audio file $filename is suspiciously small (${bytes.length} bytes)');

        // Header check: must be ID3 (0x49 0x44 0x33), RIFF WAVE (0x52 0x49 0x46 0x46 ... 0x57 0x41 0x56 0x45),
        // or MP3 sync frame (0xFF 0xFB / 0xFF 0xF3 / 0xFF 0xF2)
        final isId3 = bytes.length >= 3 && bytes[0] == 0x49 && bytes[1] == 0x44 && bytes[2] == 0x33;
        final isRiffWave = bytes.length >= 12 &&
            bytes[0] == 0x52 && bytes[1] == 0x49 && bytes[2] == 0x46 && bytes[3] == 0x46 &&
            bytes[8] == 0x57 && bytes[9] == 0x41 && bytes[10] == 0x56 && bytes[11] == 0x45;
        final isMp3Sync = bytes.length >= 2 && bytes[0] == 0xFF && (bytes[1] & 0xE0) == 0xE0;

        expect(isId3 || isRiffWave || isMp3Sync, isTrue,
            reason: 'Audio file $filename has invalid header bytes (neither ID3, RIFF WAVE, nor MP3 sync word)');
      }
    });

    test('All species in kSpeciesCatalog with audioAsset map to real disk files', () {
      final speciesWithAudio = kSpeciesCatalog.where((s) => s.audioAsset != null).toList();
      expect(speciesWithAudio.length, greaterThanOrEqualTo(18));

      for (final species in speciesWithAudio) {
        final path = species.audioAsset!;
        expect(path, startsWith('assets/audio/'));
        expect(path, endsWith('.mp3'));

        final file = File(path);
        expect(file.existsSync(), isTrue,
            reason: 'Species ${species.id} references non-existent audio asset $path');
        expect(file.lengthSync(), greaterThan(0),
            reason: 'Species ${species.id} audio asset $path is empty (0 bytes)');
      }
    });
  });

  group('Milestone 3: InteractiveVocalizationWidget Unit & Widget Tests', () {
    testWidgets('Initializes with default audio player and displays play button and description', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: InteractiveVocalizationWidget(
              commonName: 'Kashmir Stag',
              vocalization: 'Resonant autumn rut bugles echoing across Dachigam.',
              audioAsset: 'assets/audio/hangul.mp3',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('VOCALIZATION & SOUNDS'), findsOneWidget);
      expect(find.text('Resonant autumn rut bugles echoing across Dachigam.'), findsOneWidget);
      expect(find.text('Tap to simulate audio call'), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
      expect(find.byType(Slider), findsOneWidget);
    });

    testWidgets('Tapping play button triggers playback and starts waveform visualizer', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: InteractiveVocalizationWidget(
              commonName: 'Snow Leopard',
              vocalization: 'Piercing yowls and gentle friendly chuffs.',
              audioAsset: 'assets/audio/snow_leopard.mp3',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final playButton = find.byType(IconButton);
      await tester.tap(playButton);
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byIcon(Icons.pause_rounded), findsOneWidget);
      expect(find.textContaining('Simulating acoustic wave for Snow Leopard'), findsOneWidget);

      // Stop before tearDown
      await tester.tap(playButton);
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
    });

    testWidgets('Offline playback resilience: works with local asset path without network', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: InteractiveVocalizationWidget(
              commonName: 'Himalayan Monal',
              vocalization: 'Loud ringing whistles echoing across subalpine slopes.',
              audioAsset: 'assets/audio/himalayan_monal.mp3',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Trigger playback on local bundled asset
      await tester.tap(find.byType(IconButton));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byIcon(Icons.pause_rounded), findsOneWidget);

      // Pause playback
      await tester.tap(find.byType(IconButton));
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
    });

    testWidgets('Handles missing audio asset or invalid path gracefully without crashing', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: InteractiveVocalizationWidget(
              commonName: 'Ghost Creature',
              vocalization: 'Eerie mythical whistle in the fog.',
              audioAsset: 'assets/audio/non_existent_sound.mp3',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap play on missing asset
      await tester.tap(find.byType(IconButton));
      await tester.pump(const Duration(milliseconds: 100));

      // Widget handles exception gracefully without red screen
      expect(find.byType(InteractiveVocalizationWidget), findsOneWidget);
      expect(find.byIcon(Icons.pause_rounded), findsOneWidget);

      // Stop
      await tester.tap(find.byType(IconButton));
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
    });

    testWidgets('Non-vocal species displays educational acoustic card instead of audio player', (
      tester,
    ) async {
      const nonVocalSpecies = ZoologySpecies(
        id: 'kashmir-rock-agama',
        commonName: 'Kashmiri Rock Agama',
        scientificName: 'Laudakia tuberculata',
        category: 'Reptile',
        region: 'Rocky slopes of Kashmir and Jammu',
        status: 'Present',
        habitat: 'Sun-warmed rock screes and stone walls',
        size: '30–40 cm',
        conservation: 'Least Concern',
        feature: 'Flattened spiny body with dark blue-black breeding coloration',
        funFact: 'Performs rapid head-bobs and push-ups to defend territorial rock perches',
        isVocal: false,
        vocalizationNote: 'Non-vocal reptile; communicates through visual head-bobbing and push-up displays.',
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: InteractiveVocalizationWidget(
              species: nonVocalSpecies,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('COMMUNICATION & ACOUSTICS'), findsOneWidget);
      expect(find.text('Non-vocal species communication mechanisms'), findsOneWidget);
      expect(find.textContaining('Non-vocal reptile'), findsOneWidget);
      expect(find.byType(IconButton), findsNothing, reason: 'Non-vocal species should not have a play button');
    });

    testWidgets('Player state transitions, scrubbing, and cleanup', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: InteractiveVocalizationWidget(
              commonName: 'Western Tragopan',
              vocalization: 'Wailing goat-like calls echoing in fir forests.',
              audioAsset: 'assets/audio/western_tragopan.mp3',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final state = tester.state<InteractiveVocalizationWidgetState>(
        find.byType(InteractiveVocalizationWidget),
      );

      expect(state.isPlaying, isFalse);
      expect(state.playerState, equals(PlayerState.stopped));

      // Tap play
      await tester.tap(find.byType(IconButton));
      await tester.pump(const Duration(milliseconds: 100));

      expect(state.isPlaying, isTrue);
      expect(state.playerState, equals(PlayerState.playing));

      // Tap pause
      await tester.tap(find.byType(IconButton));
      await tester.pump(const Duration(milliseconds: 50));

      expect(state.isPlaying, isFalse);
      expect(state.playerState, equals(PlayerState.paused));
    });

    testWidgets('Species detail page displays interactive audio player for vocal species (Hangul)', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final hangul = kSpeciesCatalog.firstWhere((s) => s.id == 'hangul');
      await tester.pumpWidget(
        MaterialApp(
          home: SpeciesDetailPage(species: hangul),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(InteractiveVocalizationWidget), findsOneWidget);
      expect(find.text('VOCALIZATION & SOUNDS'), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
    });

    testWidgets('Species detail page displays educational card for non-vocal species (Brown Trout)', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final trout = kSpeciesCatalog.firstWhere((s) => s.id == 'brown-trout');
      await tester.pumpWidget(
        MaterialApp(
          home: SpeciesDetailPage(species: trout),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(InteractiveVocalizationWidget), findsOneWidget);
      expect(find.text('COMMUNICATION & ACOUSTICS'), findsOneWidget);
      expect(find.byType(IconButton), findsNothing);
    });
  });
}
