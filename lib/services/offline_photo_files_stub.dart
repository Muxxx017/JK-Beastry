import 'dart:typed_data';

Future<String> writeOfflineSpeciesPhoto(int taxonId, Uint8List bytes) =>
    Future.error(
      UnsupportedError(
        'Offline photo downloads are unavailable on this platform.',
      ),
    );

Future<void> deleteOfflineSpeciesPhoto(String? path) async {}
