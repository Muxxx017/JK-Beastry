import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

Future<String> writeOfflineSpeciesPhoto(int taxonId, Uint8List bytes) async {
  final supportDirectory = await getApplicationSupportDirectory();
  final photoDirectory = Directory(
    '${supportDirectory.path}${Platform.pathSeparator}species_photos',
  );
  await photoDirectory.create(recursive: true);

  final destination = File(
    '${photoDirectory.path}${Platform.pathSeparator}$taxonId.img',
  );
  final temporary = File('${destination.path}.tmp');
  await temporary.writeAsBytes(bytes, flush: true);
  if (await destination.exists()) await destination.delete();
  await temporary.rename(destination.path);
  return destination.path;
}

Future<void> deleteOfflineSpeciesPhoto(String? path) async {
  if (path == null || path.isEmpty) return;
  final photo = File(path);
  if (await photo.exists()) await photo.delete();
}
